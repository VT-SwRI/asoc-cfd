///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: SwRI/VT
//
// File: event_builder.v
// File history:
//
//      
// Description:
//
// Matches position results (from the CFD + position calculator) with magnitude results
// (from the peak detector) by matching 64-bit event timestamp tags. Outputs X, Y, magnitude, 
// and tag for each matched event.    
//
// Two register-based FIFOs (depth 4) buffer incoming results. A 3-stage pipelined matcher
// compares head tags each cycle: 
// Tags match:      pop both and output the combined event.  
// Position older:  drop stale position entry.      
// Magnitude older: drop stale magnitude entry.
//  
// The magnitude FIFO uses force-push: when full, the oldest entry is evicted to make room.
// This prevents blockage when consecutive events fail or are rejected, since the magnitude
// path always arrives before the position path for the same event due to differences in latency.
//
// Latency: 3 cycles per matcher decision.   
//
// Targeted device: <Family::ProASIC3E> <Die::A3PE1500> <Package::208 PQFP>
// Author: VT MDE S26-23
//
///////////////////////////////////////////////////////////////////////////////////////////////////

module event_builder #(
    parameter integer TAG_WIDTH   = 64,
    parameter integer POS_WIDTH   = 32,
    parameter integer MAG_WIDTH   = 16,    
    parameter integer DEPTH_LOG2  = 2
)(
    input  wire                          clk, 
    input  wire                          rst,

    // position calculator input
    input  wire                          pos_valid, 
    input  wire [TAG_WIDTH-1:0]          pos_tag,
    input  wire signed [POS_WIDTH-1:0]   pos_x,
    input  wire signed [POS_WIDTH-1:0]   pos_y,  
   
    // peak detector input
    input  wire                          mag_valid,
    input  wire [TAG_WIDTH-1:0]          mag_tag,
    input  wire signed [MAG_WIDTH-1:0]   mag_val,

    // combined output
    output reg                           out_valid,    
    output reg  [TAG_WIDTH-1:0]          out_tag,
    output reg  signed [POS_WIDTH-1:0]   out_x,
    output reg  signed [POS_WIDTH-1:0]   out_y,
    output reg  signed [MAG_WIDTH-1:0]   out_mag,  
     
    // diagnostics (active one cycle each)
    output reg                           drop_pos,      // position dropped due to being stale
    output reg                           drop_mag,      // magnitude dropped due to being stale    
    output reg                           mag_force_pop  // magnitude dropped due to full FIFO
);  

    localparam integer DEPTH = (1 << DEPTH_LOG2);                

    // position FIFO storage (synthesized as registers to avoid inefficient usage of RAM blocks)
    (* syn_ramstyle = "registers" *) reg [TAG_WIDTH-1:0]        pos_mem_tag [0:DEPTH-1];
    (* syn_ramstyle = "registers" *) reg signed [POS_WIDTH-1:0] pos_mem_x   [0:DEPTH-1];    
    (* syn_ramstyle = "registers" *) reg signed [POS_WIDTH-1:0] pos_mem_y   [0:DEPTH-1];

    // magnitude FIFO storage (synthesized as registers to avoid inefficient usage of RAM blocks)
    (* syn_ramstyle = "registers" *) reg [TAG_WIDTH-1:0]        mag_mem_tag [0:DEPTH-1];
    (* syn_ramstyle = "registers" *) reg signed [MAG_WIDTH-1:0] mag_mem_val [0:DEPTH-1];  

    // FIFO pointers and counts  
    reg [DEPTH_LOG2:0] pos_wptr, pos_rptr, pos_count;
    reg [DEPTH_LOG2:0] mag_wptr, mag_rptr, mag_count;

    wire [DEPTH_LOG2-1:0] pos_waddr = pos_wptr[DEPTH_LOG2-1:0];
    wire [DEPTH_LOG2-1:0] pos_raddr = pos_rptr[DEPTH_LOG2-1:0];
    wire [DEPTH_LOG2-1:0] mag_waddr = mag_wptr[DEPTH_LOG2-1:0];
    wire [DEPTH_LOG2-1:0] mag_raddr = mag_rptr[DEPTH_LOG2-1:0];       
  
    wire pos_full  = (pos_count == DEPTH[DEPTH_LOG2:0]);     
    wire pos_empty = (pos_count == {(DEPTH_LOG2+1){1'b0}});
    wire mag_full  = (mag_count == DEPTH[DEPTH_LOG2:0]);
    wire mag_empty = (mag_count == {(DEPTH_LOG2+1){1'b0}});
         

    // FIFO head reads
    wire [TAG_WIDTH-1:0]        pos_head_tag = pos_mem_tag[pos_raddr];   
    wire signed [POS_WIDTH-1:0] pos_head_x   = pos_mem_x  [pos_raddr]; 
    wire signed [POS_WIDTH-1:0] pos_head_y   = pos_mem_y  [pos_raddr]; 

    wire [TAG_WIDTH-1:0]        mag_head_tag = mag_mem_tag[mag_raddr];
    wire signed [MAG_WIDTH-1:0] mag_head_val = mag_mem_val[mag_raddr];   

    // stage 2 action flags (drive pops this cycle)
    reg act_match;    
    reg act_drop_pos;
    reg act_drop_mag;

    // flags for popping position and magnitude
    wire pop_pos = act_match | act_drop_pos;
    wire pop_mag = act_match | act_drop_mag;

    // position push (blocks when full)
    wire push_pos = pos_valid & ~pos_full;  

    // magnitude push (always accepts, force-pops oldest if full)
    wire push_mag      = mag_valid;
    wire mag_force_req = mag_valid & mag_full & ~pop_mag;

    // registered head data captured with the action decision
    reg [TAG_WIDTH-1:0]        act_pos_tag;
    reg signed [POS_WIDTH-1:0] act_pos_x;
    reg signed [POS_WIDTH-1:0] act_pos_y;   
    reg signed [MAG_WIDTH-1:0] act_mag_val;

    // stage 1: 64-bit tag comparison
    reg cmp_tags_eq;
    reg cmp_pos_older;
    reg cmp_valid;     

    wire any_action = pop_pos | pop_mag; 
    wire any_push   = push_pos | push_mag;
  
    // safe to compare when both FIFOs have data and nothing else is happening
    wire cmp_start = ~cmp_valid & ~any_action & ~any_push
                   & ~pos_empty & ~mag_empty;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // set to zero on reset
            cmp_tags_eq   <= 1'b0;
            cmp_pos_older <= 1'b0;   
            cmp_valid     <= 1'b0;
        end else begin
            if (cmp_valid) begin 
                cmp_valid <= 1'b0;
            end else if (cmp_start) begin
                // set flags on new comparison
                cmp_tags_eq   <= (pos_head_tag == mag_head_tag); 
                cmp_pos_older <= (pos_head_tag <  mag_head_tag);
                cmp_valid     <= 1'b1;  
            end
        end
    end

    // stage 2: action decision
    always @(posedge clk or posedge rst) begin 
        if (rst) begin
            // reset to 0
            act_match    <= 1'b0;
            act_drop_pos <= 1'b0;            
            act_drop_mag <= 1'b0;
            act_pos_tag  <= {TAG_WIDTH{1'b0}};
            act_pos_x    <= {POS_WIDTH{1'b0}};
            act_pos_y    <= {POS_WIDTH{1'b0}};
            act_mag_val  <= {MAG_WIDTH{1'b0}};   
        end else begin
            // don't act by default   
            act_match    <= 1'b0;
            act_drop_pos <= 1'b0;       
            act_drop_mag <= 1'b0;

            if (cmp_valid) begin
                // capture head data (heads change after pop)
                act_pos_tag <= pos_head_tag;
                act_pos_x   <= pos_head_x;   
                act_pos_y   <= pos_head_y;
                act_mag_val <= mag_head_val;

                if (cmp_tags_eq)   
                    act_match <= 1'b1;  
                else if (cmp_pos_older)
                    act_drop_pos <= 1'b1;
                else
                    act_drop_mag <= 1'b1;
            end
        end
    end

    // position FIFO
    always @(posedge clk or posedge rst) begin  
        if (rst) begin 
            // set values to zero on reset
            pos_wptr  <= {(DEPTH_LOG2+1){1'b0}};
            pos_rptr  <= {(DEPTH_LOG2+1){1'b0}};  
            pos_count <= {(DEPTH_LOG2+1){1'b0}};   
        end else begin
            case ({push_pos, pop_pos})  
                2'b10: begin
                    // push a new position
                    pos_mem_tag[pos_waddr] <= pos_tag;
                    pos_mem_x  [pos_waddr] <= pos_x;
                    pos_mem_y  [pos_waddr] <= pos_y;
                    pos_wptr  <= pos_wptr  + 1'b1;
                    pos_count <= pos_count + 1'b1;  
                end
                2'b01: begin
                    // pop a position
                    pos_rptr  <= pos_rptr  + 1'b1; 
                    pos_count <= pos_count - 1'b1;
                end 
                2'b11: begin
                    // push and pop positions
                    pos_mem_tag[pos_waddr] <= pos_tag;          
                    pos_mem_x  [pos_waddr] <= pos_x;
                    pos_mem_y  [pos_waddr] <= pos_y;
                    pos_wptr <= pos_wptr + 1'b1;   
                    pos_rptr <= pos_rptr + 1'b1;
                end
                default: ; // do nothing by default
            endcase
        end    
    end

    // magnitude FIFO (force-pops oldest value when full and new data arrives)
    always @(posedge clk or posedge rst) begin  
        if (rst) begin 
            // set values to 0 on reset
            mag_wptr  <= {(DEPTH_LOG2+1){1'b0}};
            mag_rptr  <= {(DEPTH_LOG2+1){1'b0}};   
            mag_count <= {(DEPTH_LOG2+1){1'b0}};
        end else begin
            if (push_mag && pop_mag) begin
                // simultaneous push and matcher pop
                mag_mem_tag[mag_waddr] <= mag_tag;
                mag_mem_val[mag_waddr] <= mag_val;
                mag_wptr <= mag_wptr + 1'b1;
                mag_rptr <= mag_rptr + 1'b1;
            end else if (push_mag && !mag_full) begin
                // normal push
                mag_mem_tag[mag_waddr] <= mag_tag;  
                mag_mem_val[mag_waddr] <= mag_val;
                mag_wptr  <= mag_wptr  + 1'b1;
                mag_count <= mag_count + 1'b1;
            end else if (push_mag && mag_full) begin
                // force-push: pop and discard oldest, and write new
                mag_mem_tag[mag_waddr] <= mag_tag;
                mag_mem_val[mag_waddr] <= mag_val;
                mag_wptr <= mag_wptr + 1'b1;   
                mag_rptr <= mag_rptr + 1'b1;
            end else if (pop_mag) begin
                // matcher pop only
                mag_rptr  <= mag_rptr  + 1'b1;
                mag_count <= mag_count - 1'b1;   
            end
        end
    end

    // outputs and diagnostics   
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // set to 0 on reset
            out_valid     <= 1'b0;
            out_tag       <= {TAG_WIDTH{1'b0}};
            out_x         <= {POS_WIDTH{1'b0}};
            out_y         <= {POS_WIDTH{1'b0}};   
            out_mag       <= {MAG_WIDTH{1'b0}};
            drop_pos      <= 1'b0;
            drop_mag      <= 1'b0;
            mag_force_pop <= 1'b0;  
        end else begin
            // default values
            out_valid     <= 1'b0;
            drop_pos      <= 1'b0;
            drop_mag      <= 1'b0;
            mag_force_pop <= 1'b0;  

            if (act_match) begin
                // output valid data
                out_valid <= 1'b1;
                out_tag   <= act_pos_tag;
                out_x     <= act_pos_x;  
                out_y     <= act_pos_y;
                out_mag   <= act_mag_val;
            end

            // report position dropped due to being stale
            if (act_drop_pos)
                drop_pos <= 1'b1;
  
            // report magnitude dropped due to being stale
            if (act_drop_mag)
                drop_mag <= 1'b1; 

            // report forced pop in magnitude FIFO
            if (mag_force_req)
                mag_force_pop <= 1'b1;
        end   
    end
  
endmodule 