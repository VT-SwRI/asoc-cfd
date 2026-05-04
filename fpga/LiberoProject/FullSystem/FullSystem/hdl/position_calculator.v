///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: SwRI/VT
//
// File: position_calc.v
// File history:
//
//
// Description:
//
// Computes event position from CFD zero-crossing timestamps:
//   x_pos = (tx2 - tx1) * Kx
//   y_pos = (ty2 - ty1) * Ky
//
// Kx and Ky are UQ1.19 propagation constants used for determining position from timing difference
//
// Uses a sequential shift-and-add multiply (signed dt * unsigned K)
// that takes 20 cycles per axis. This keeps latency under 64 cycles, thus meeting worse-case
// scenario of events only 64-cycles long.
//
// Events outside the position window are rejected.
//
// Latency: 45 cycles from event_valid to pos_valid.
//
// Targeted device: <Family::ProASIC3E> <Die::A3PE1500> <Package::208 PQFP>
// Author: VT MDE S26-23
//
///////////////////////////////////////////////////////////////////////////////////////////////////



module position_calc #(
    parameter integer IDX_W      = 10,
    parameter integer FRAC_BITS  = 10,
    parameter integer K_WIDTH    = 20,
    parameter integer K_FRAC     = 19,
    parameter integer POS_WIDTH  = 32,
    parameter integer WINDOW_X   = 51000,  // +/- 51 mm rejection window
    parameter integer WINDOW_Y   = 51000   // modify as needed to fit detector area
)(
    input  wire                           clk,
    input  wire                           rst,

    // from CFD module, active on pulses of event_valid      
    input  wire                          event_valid,
    input  wire [IDX_W-1:0]              tx1_int,
    input  wire [FRAC_BITS-1:0]          tx1_frac,   
    input  wire [IDX_W-1:0]              tx2_int,
    input  wire [FRAC_BITS-1:0]          tx2_frac,
    input  wire [IDX_W-1:0]              ty1_int,
    input  wire [FRAC_BITS-1:0]          ty1_frac,  
    input  wire [IDX_W-1:0]              ty2_int,
    input  wire [FRAC_BITS-1:0]          ty2_frac,

    // propagation constants (UQ1.19)
    input  wire [K_WIDTH-1:0]            kx,
    input  wire [K_WIDTH-1:0]            ky,

    // event timestamp tag
    input  wire [63:0]                   tag_in,

 
    // outputs, valid on pulses of pos_valid or pos_rejected
    output reg signed [POS_WIDTH-1:0]    x_pos,
    output reg signed [POS_WIDTH-1:0]    y_pos,
    output reg                           pos_valid,
    output reg                           pos_rejected,
    output reg [63:0]                    tag_out
);
   

    // calculated bit lengths
    localparam integer TS_W   = IDX_W + FRAC_BITS;   // 20: full timestamp width    
    localparam integer DT_W   = TS_W + 1;            // 21: signed difference  
    localparam integer PROD_W = DT_W + K_WIDTH;      // 41: full product

    // FSM states
    localparam [2:0] S_IDLE    = 3'd0,
                     S_CALC_DT = 3'd1, 
                     S_MULT_X  = 3'd2,
                     S_STORE_X = 3'd3,  
                     S_MULT_Y  = 3'd4,   
                     S_STORE_Y = 3'd5,
                     S_OUTPUT  = 3'd6;

    reg [2:0]  state;
    reg [4:0]  bit_cnt;

    // inputs are on event_valid so we don't depend on
    // external signals staying stable during the 45-cycle computation
    reg [63:0]        tag_reg;
    reg [K_WIDTH-1:0] kx_reg, ky_reg;
    reg [TS_W-1:0]    tx1_reg, tx2_reg, ty1_reg, ty2_reg;

    reg signed [DT_W-1:0] dt_y;       // saved Y-axis timestamp difference

    // sequential multiplier state
    reg signed [PROD_W-1:0] accum;
    reg [K_WIDTH-1:0]       k_shift;   // K constant, shifted left each cycle
    reg signed [DT_W-1:0]   dt_active; // dt for the current axis

    // sign-extended dt for addition into the accumulator
    wire signed [PROD_W-1:0] dt_ext = {{(PROD_W-DT_W){dt_active[DT_W-1]}}, dt_active};

    reg signed [POS_WIDTH-1:0] x_result, y_result;
 
    // round and shift product to get integer microns
    wire signed [PROD_W-1:0] accum_rounded = accum + (1 <<< (K_FRAC - 1));
    wire signed [PROD_W-1:0] pos_shifted = accum_rounded >>> K_FRAC;


    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // reset values to 0 on reset
            state        <= S_IDLE;         
            bit_cnt      <= 5'd0;
            pos_valid    <= 1'b0;
            pos_rejected <= 1'b0;  
            x_pos        <= {POS_WIDTH{1'b0}};
            y_pos        <= {POS_WIDTH{1'b0}};
            tag_out      <= 64'd0;
            tag_reg      <= 64'd0;
            kx_reg       <= {K_WIDTH{1'b0}};   
            ky_reg       <= {K_WIDTH{1'b0}};
            tx1_reg      <= {TS_W{1'b0}};
            tx2_reg      <= {TS_W{1'b0}};
            ty1_reg      <= {TS_W{1'b0}};
            ty2_reg      <= {TS_W{1'b0}};
            dt_y         <= {DT_W{1'b0}};
            accum        <= {PROD_W{1'b0}};
            k_shift      <= {K_WIDTH{1'b0}};
            dt_active    <= {DT_W{1'b0}};
            x_result     <= {POS_WIDTH{1'b0}};
            y_result     <= {POS_WIDTH{1'b0}};
        end else begin
            // default output validity      
            pos_valid    <= 1'b0;
            pos_rejected <= 1'b0;

            case (state)
                S_IDLE: begin
                    // wait for a new event, latch all inputs
                    if (event_valid) begin
                        tag_reg <= tag_in;
                        kx_reg  <= kx;   
                        ky_reg  <= ky;
                        tx1_reg <= {tx1_int, tx1_frac};
                        tx2_reg <= {tx2_int, tx2_frac};
                        ty1_reg <= {ty1_int, ty1_frac};
                        ty2_reg <= {ty2_int, ty2_frac};
                        state   <= S_CALC_DT;
                    end
                end
  
                S_CALC_DT: begin
                    // compute signed timestamp differences and prepare for
                    // x multiplication
                    dt_y      <= $signed({1'b0, ty2_reg}) - $signed({1'b0, ty1_reg});
                    dt_active <= $signed({1'b0, tx2_reg}) - $signed({1'b0, tx1_reg});
                    k_shift   <= kx_reg;
                    accum     <= {PROD_W{1'b0}};  
                    bit_cnt   <= K_WIDTH[4:0];   
                    state     <= S_MULT_X;
                end

                S_MULT_X: begin
                    // shift-and-add: accum = (accum << 1) + dt if k bit set
                    if (k_shift[K_WIDTH-1])
                        accum <= ({accum[PROD_W-2:0], 1'b0}) + dt_ext;
                    else
                        accum <= {accum[PROD_W-2:0], 1'b0};

                    k_shift <= {k_shift[K_WIDTH-2:0], 1'b0};
                    bit_cnt <= bit_cnt - 5'd1;

                    if (bit_cnt == 5'd1)
                        state <= S_STORE_X;
                end             

                S_STORE_X: begin
                    // store the result of the x position calculation and prepare for
                    // y multiplication
                    x_result  <= pos_shifted[POS_WIDTH-1:0];
                    dt_active <= dt_y;
                    k_shift   <= ky_reg;            
                    accum     <= {PROD_W{1'b0}};
                    bit_cnt   <= K_WIDTH[4:0];
                    state     <= S_MULT_Y;
                end

                S_MULT_Y: begin
                    // shift-and-add: accum = (accum << 1) + dt if k bit set
                    if (k_shift[K_WIDTH-1])
                        accum <= ({accum[PROD_W-2:0], 1'b0}) + dt_ext;
                    else
                        accum <= {accum[PROD_W-2:0], 1'b0};

                    k_shift <= {k_shift[K_WIDTH-2:0], 1'b0};
                    bit_cnt <= bit_cnt - 5'd1;

                    if (bit_cnt == 5'd1)
                        state <= S_STORE_Y;
                end


                S_STORE_Y: begin        
                    // store the result of the y position calculation
                    y_result <= pos_shifted[POS_WIDTH-1:0];
                    state    <= S_OUTPUT;
                end  

                S_OUTPUT: begin
                    x_pos   <= x_result;
                    y_pos   <= y_result;    
                    tag_out <= tag_reg;

                    // reject if outside position window
                    if ((x_result > $signed(WINDOW_X)) ||
                        (x_result < -$signed(WINDOW_X)) ||   
                        (y_result > $signed(WINDOW_Y)) ||  
                        (y_result < -$signed(WINDOW_Y)))
                        pos_rejected <= 1'b1;
                    else
                        pos_valid <= 1'b1;

                    state <= S_IDLE;
                end   

                default: state <= S_IDLE;   
            endcase
        end   
    end


endmodule  