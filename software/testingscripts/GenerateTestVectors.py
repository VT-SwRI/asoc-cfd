"""
GenerateTestVectors.py
=========================================================================
Test Vector Generator for FPGA Event Decoder Pipeline

  1. Define a grid of known (x, y) positions (the EXPECTED output).
  2. From each position, compute the pulse arrival times using
     delay-line physics.
  3. Generate realistic 4-channel ADC waveforms with pulses at
     those arrival times.
  4. Quantize to 12-bit unsigned codes (modeling ADC behavior).
  5. Export:
       - hexdata/<name>.hex          -> $readmemh in Verilog testbench
                                        and consumed by uartsource.py
       - comparisonfiles/<name>.csv  -> "answer key" of expected (x, y, charge)
                                        consumed by CompareResults.py

Part of the FPGA test workflow alongside uartsource.py and CompareResults.py.

Author : VT MDE S26-23 (Python port)
Date   : 2026
=========================================================================
"""

import argparse
import sys
from pathlib import Path
from datetime import datetime

import numpy as np
import matplotlib.pyplot as plt
# from scipy.io import savemat   # only needed if you uncomment the .mat save


# =========================================================================
#  PATH CONSTANTS  (relative to this script's location)
# =========================================================================

SCRIPT_DIR     = Path(__file__).parent
HEXDATA_DIR    = SCRIPT_DIR / "hexdata"
COMPARISON_DIR = SCRIPT_DIR / "comparisonfiles"


# =========================================================================
#  USER PARAMETERS  (modify for each test case)
# =========================================================================

# --- Test name (drives output filenames) ---
# Outputs:  hexdata/<TEST_NAME>.hex  and  comparisonfiles/<TEST_NAME>.csv
# Override on the CLI with:  --test-name <name>
TEST_NAME = "test_vectors"

# --- Pulse Shape ---
peak_min_V  = 0.200       # minimum peak height (V)
peak_max_V  = 0.500       # maximum peak height (V)
noise_pct   = 0.00        # noise as fraction of peak height (0 = clean)
                          # e.g. 0.05 = 5% RMS noise

# --- Sampling ---
fs_GHz      = 3.0         # sample rate (GHz) - within 2.4-3.6 range
fs          = fs_GHz * 1e9  # sample rate (Hz)

# --- Test Grid ---
n_grid       = 20         # grid points per axis (20x20 = 400 positions)
grid_margin  = 3          # mm inset from detector edge to avoid boundary

# --- CFD Parameters (recorded in the output files for reference) ---
# no effect on data generation
cfd_delay     = 40        # delay line depth (samples)
cfd_att_frac  = 0.9       # attenuation fraction (0 to 1)
cfd_threshold = 2300      # threshold (in SQ12.3 codes)
cfd_zc_neg    = 10        # required negative samples before zero-crossing

# --- Invalid Events ---
invalid_events = False    # when True, channel X1 holds DC + noise only
                          # making all events undecodable.
                          # The expected outputs CSV will contain no rows.

# --- Outside Area ---
outside_area   = False    # when True, events are placed in a single square
                          # ring grid_margin mm outside the detector boundary.
                          # The expected outputs CSV will contain no rows.

# =========================================================================
#  STATIC PARAMETERS  (should remain constant across test cases)
# =========================================================================

# --- Detector / Physics ---
vpx         = 1.39        # X propagation velocity (mm/ns)
vpy         = 1.33        # Y propagation velocity (mm/ns)
det_half_mm = 51          # detector half-width (mm), range is [-51, +51]

# --- ADC Model ---
adc_bits     = 12                       # ADC resolution
adc_range_V  = 2.5                      # ADC full-scale voltage range (V)
dc_offset_V  = 1.0                      # DC offset applied by front-end (V)
adc_max_code = 2**adc_bits - 1          # 4095 for 12-bit

# --- Event Timing ---
event_window_ns = 225     # total time window per event (ns)
event_window_s  = event_window_ns * 1e-9
t0_ns           = 10      # earliest pulse center offset from event start (ns)
idle_gap_clks   = 1       # idle clocks between events


# =========================================================================
#  CLI PARSING  (overrides TEST_NAME and plot behavior)
# =========================================================================

def _parse_cli_args():
    parser = argparse.ArgumentParser(
        prog="GenerateTestVectors.py",
        description=(
            "Generate test vectors for the FPGA event decoder pipeline.\n\n"
            "Edit the parameters at the top of this file (peak voltages, "
            "sample rate, grid size, CFD settings, etc.) to match your test "
            "case, then run.\n\n"
            "Outputs:\n"
            "  hexdata/<test_name>.hex          - packed hex test vectors for the FPGA\n"
            "  comparisonfiles/<test_name>.csv  - expected (x, y) answer key\n\n"
            "Output filenames are driven by TEST_NAME (set near the top of the "
            "script). Use --test-name to override on the command line.\n\n"
            "Both output folders are created automatically if missing.\n\n"
            "Part of the FPGA test workflow alongside uartsource.py and "
            "CompareResults.py."
        ),
        epilog=(
            "Examples:\n"
            "  python GenerateTestVectors.py\n"
            "  python GenerateTestVectors.py --test-name bird\n"
            "  python GenerateTestVectors.py --test-name bird --no-plots"
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--test-name",
        default=None,
        metavar="NAME",
        help=(
            "name used for the generated files (default: TEST_NAME constant "
            "in the script). Produces hexdata/<NAME>.hex and "
            "comparisonfiles/<NAME>.csv."
        ),
    )
    parser.add_argument(
        "--no-plots",
        action="store_true",
        help="skip the matplotlib verification plots (useful for batch runs)",
    )
    return parser.parse_args()


_args = _parse_cli_args()
if _args.test_name:
    TEST_NAME = _args.test_name
SHOW_PLOTS = not _args.no_plots


# =========================================================================
#  DERIVED OUTPUT PATHS  (folders are created if they don't exist)
# =========================================================================

HEXDATA_DIR.mkdir(parents=True, exist_ok=True)
COMPARISON_DIR.mkdir(parents=True, exist_ok=True)

out_hex_file = HEXDATA_DIR / f"{TEST_NAME}.hex"
out_csv_file = COMPARISON_DIR / f"{TEST_NAME}.csv"
out_mat_file = COMPARISON_DIR / f"{TEST_NAME}.mat"  # only used if savemat is uncommented


# =========================================================================
#  LOCAL FUNCTIONS
# =========================================================================

def gen_pulse(fs, win, t0, peak_V, noise_pct, rng):
    """Generate a single AC-coupled detector pulse.

    Produces the same pulse shape as the SystemVerilog testbench:
    Gaussian -> HP filter -> LP filter -> normalize positive peak to 1 ->
    scale by peak_V. The resulting waveform has a positive lobe followed
    by a negative undershoot (characteristic of AC coupling). The
    undershoot is preserved -- it sits below baseline (added by the caller)
    and is essential for correct CFD operation.
    """
    dt = 1.0 / fs
    n_samples = int(round(win / dt)) + 1
    t = np.arange(n_samples) * dt

    tau   = 20e-9    # HP/LP filter time constant
    sigma = 4e-9     # Gaussian pulse width

    input_sig = np.exp(-(t - t0) ** 2 / (2 * sigma ** 2))

    alpha_hp = tau / (tau + dt)
    y_hp = np.zeros_like(input_sig)
    for n in range(1, len(input_sig)):
        y_hp[n] = alpha_hp * (y_hp[n - 1] + input_sig[n] - input_sig[n - 1])

    alpha_lp = dt / (tau + dt)
    y_lp = np.zeros_like(y_hp)
    for n in range(1, len(y_hp)):
        y_lp[n] = y_lp[n - 1] + alpha_lp * (y_hp[n] - y_lp[n - 1])

    y_lp = y_lp / np.max(y_lp)
    y = y_lp * peak_V

    if noise_pct > 0:
        noise_rms = noise_pct * peak_V
        y = y + noise_rms * rng.standard_normal(y.shape)

    return t, y


def voltage_to_adc(v, full_scale_V, max_code):
    """Convert voltage waveform to unsigned ADC integer codes."""
    adc = np.round(np.asarray(v) / full_scale_V * max_code).astype(np.int64)
    adc = np.clip(adc, 0, max_code)
    return adc


def write_channel_hex(filename, data, hex_digits):
    """Write a single-column hex file for one signal."""
    fmt = f'%0{hex_digits}X\n'
    with open(filename, 'w') as fid:
        for k in range(len(data)):
            fid.write(fmt % int(data[k]))
    print(f'  Wrote {filename} ({len(data)} values)')


# =========================================================================
#  GENERATE TEST GRID
# =========================================================================

print(f"Test name: {TEST_NAME}")
print(f"Hex output : {out_hex_file}")
print(f"CSV output : {out_csv_file}")
print()

if outside_area:
    outer  = det_half_mm + grid_margin
    edge   = np.linspace(-outer,  outer, n_grid)
    edge_r = np.linspace( outer, -outer, n_grid)

    x_list = np.concatenate([
        edge[:-1],
         outer * np.ones(n_grid - 1),
        edge_r[:-1],
        -outer * np.ones(n_grid - 1),
    ])
    y_list = np.concatenate([
        -outer * np.ones(n_grid - 1),
        edge[:-1],
         outer * np.ones(n_grid - 1),
        edge_r[:-1],
    ])
    x_positions = None
    y_positions = None
else:
    x_positions = np.linspace(-det_half_mm + grid_margin,
                               det_half_mm - grid_margin, n_grid)
    y_positions = np.linspace(-det_half_mm + grid_margin,
                               det_half_mm - grid_margin, n_grid)

    X_grid, Y_grid = np.meshgrid(x_positions, y_positions)
    x_list = X_grid.flatten(order='F')
    y_list = Y_grid.flatten(order='F')

n_events = len(x_list)

print(f'Generating {n_events} test events...')
if outside_area:
    print('  NOTE: outside_ring=true. Events lie outside detector boundary.')
    print('  Expected outputs CSV will contain no event rows.')
if invalid_events:
    print('  NOTE: invalid_events=true. X1 channel will hold DC only.')
    print('  Expected outputs CSV will contain no event rows.')


# =========================================================================
#  MAIN LOOP: Generate waveforms for each event
# =========================================================================

dt = 1.0 / fs
n_samples_per_event = int(round(event_window_s / dt)) + 1
t = np.arange(n_samples_per_event) * dt

print(f'Samples per event: {n_samples_per_event}')
print(f'Idle gap between events: {idle_gap_clks} clocks')

all_adc_x1_chunks = []
all_adc_x2_chunks = []
all_adc_y1_chunks = []
all_adc_y2_chunks = []
all_valid_chunks  = []

expected = np.zeros((n_events, 5))

line_length_mm = 102

rng = np.random.default_rng(42)

idle_code = int(voltage_to_adc(np.array([dc_offset_V]), adc_range_V, adc_max_code)[0])

for ev in range(n_events):
    x_mm = x_list[ev]
    y_mm = y_list[ev]

    peak_x1 = peak_min_V + (peak_max_V - peak_min_V) * rng.random()
    peak_x2 = peak_min_V + (peak_max_V - peak_min_V) * rng.random()
    peak_y1 = peak_min_V + (peak_max_V - peak_min_V) * rng.random()
    peak_y2 = peak_min_V + (peak_max_V - peak_min_V) * rng.random()

    t0_s  = t0_ns * 1e-9
    tx1_s = t0_s + ((line_length_mm / 2 - x_mm) / vpx) * 1e-9
    tx2_s = t0_s + ((line_length_mm / 2 + x_mm) / vpx) * 1e-9
    ty1_s = t0_s + ((line_length_mm / 2 - y_mm) / vpy) * 1e-9
    ty2_s = t0_s + ((line_length_mm / 2 + y_mm) / vpy) * 1e-9

    if invalid_events:
        noise_rms = noise_pct * peak_x1
        w_x1 = noise_rms * rng.standard_normal(t.shape)
    else:
        _, w_x1 = gen_pulse(fs, event_window_s, tx1_s, peak_x1, noise_pct, rng)
    _, w_x2 = gen_pulse(fs, event_window_s, tx2_s, peak_x2, noise_pct, rng)
    _, w_y1 = gen_pulse(fs, event_window_s, ty1_s, peak_y1, noise_pct, rng)
    _, w_y2 = gen_pulse(fs, event_window_s, ty2_s, peak_y2, noise_pct, rng)

    w_x1 = w_x1 + dc_offset_V
    w_x2 = w_x2 + dc_offset_V
    w_y1 = w_y1 + dc_offset_V
    w_y2 = w_y2 + dc_offset_V

    adc_x1 = voltage_to_adc(w_x1, adc_range_V, adc_max_code)
    adc_x2 = voltage_to_adc(w_x2, adc_range_V, adc_max_code)
    adc_y1 = voltage_to_adc(w_y1, adc_range_V, adc_max_code)
    adc_y2 = voltage_to_adc(w_y2, adc_range_V, adc_max_code)

    charge_approx = int(np.sum(adc_x1) + np.sum(adc_x2)
                        + np.sum(adc_y1) + np.sum(adc_y2))

    peak_avg = (peak_x1 + peak_x2 + peak_y1 + peak_y2) / 4.0
    expected[ev, :] = [x_mm, y_mm, peak_avg, charge_approx, n_samples_per_event]

    all_adc_x1_chunks.append(adc_x1)
    all_adc_x2_chunks.append(adc_x2)
    all_adc_y1_chunks.append(adc_y1)
    all_adc_y2_chunks.append(adc_y2)
    all_valid_chunks.append(np.ones(n_samples_per_event, dtype=np.int64))

    all_adc_x1_chunks.append(np.full(idle_gap_clks, idle_code, dtype=np.int64))
    all_adc_x2_chunks.append(np.full(idle_gap_clks, idle_code, dtype=np.int64))
    all_adc_y1_chunks.append(np.full(idle_gap_clks, idle_code, dtype=np.int64))
    all_adc_y2_chunks.append(np.full(idle_gap_clks, idle_code, dtype=np.int64))
    all_valid_chunks.append(np.zeros(idle_gap_clks, dtype=np.int64))

    if (ev + 1) % 100 == 0:
        print(f'  Generated event {ev + 1} / {n_events}')

all_adc_x1 = np.concatenate(all_adc_x1_chunks)
all_adc_x2 = np.concatenate(all_adc_x2_chunks)
all_adc_y1 = np.concatenate(all_adc_y1_chunks)
all_adc_y2 = np.concatenate(all_adc_y2_chunks)
all_valid  = np.concatenate(all_valid_chunks)

total_clocks = len(all_valid)
print(f'Total clock cycles: {total_clocks}')


# =========================================================================
#  EXPORT 1: HEX FILE  (for $readmemh in Verilog testbench)
# =========================================================================

print(f'Writing HEX file: {out_hex_file}')
with open(out_hex_file, 'w') as fid:
    fid.write('// Test vectors generated by GenerateTestVectors.py\n')
    fid.write(f'// Test name: {TEST_NAME}\n')
    fid.write(f'// Date: {datetime.now().strftime("%d-%b-%Y %H:%M:%S")}\n')
    fid.write(f'// Events: {n_events}, Samples/event: {n_samples_per_event}, '
              f'Idle gap: {idle_gap_clks}\n')
    fid.write(f'// Sample rate: {fs_GHz:.1f} GHz, DC offset: {dc_offset_V:.3f} V\n')
    fid.write('// Format per line: VALID_X1_X2_Y1_Y2 (13 hex digits packed)\n')
    fid.write('// Bit packing: [48]=valid, [47:36]=x1, [35:24]=x2, [23:12]=y1, [11:0]=y2\n')
    fid.write('//\n')

    for k in range(total_clocks):
        packed = ((int(all_valid[k])  << 48) |
                  (int(all_adc_x1[k]) << 36) |
                  (int(all_adc_x2[k]) << 24) |
                  (int(all_adc_y1[k]) << 12) |
                   int(all_adc_y2[k]))
        fid.write(f'{packed:013X}\n')

print(f'  Wrote {total_clocks} lines to {out_hex_file}')


# =========================================================================
#  EXPORT 2: PER-CHANNEL HEX FILES  (kept commented to mirror MATLAB)
# =========================================================================

# print('Writing per-channel HEX files...')
# write_channel_hex(HEXDATA_DIR / f'{TEST_NAME}_valid.hex', all_valid, 1)
# write_channel_hex(HEXDATA_DIR / f'{TEST_NAME}_x1.hex',   all_adc_x1, 3)
# write_channel_hex(HEXDATA_DIR / f'{TEST_NAME}_x2.hex',   all_adc_x2, 3)
# write_channel_hex(HEXDATA_DIR / f'{TEST_NAME}_y1.hex',   all_adc_y1, 3)
# write_channel_hex(HEXDATA_DIR / f'{TEST_NAME}_y2.hex',   all_adc_y2, 3)


# =========================================================================
#  EXPORT 3: CSV ANSWER KEY
# =========================================================================

print(f'Writing CSV answer key: {out_csv_file}')
with open(out_csv_file, 'w') as fid:
    fid.write('event_id,x_mm,y_mm,peak_V,charge_approx,n_samples\n')
    if not invalid_events and not outside_area:
        for ev in range(n_events):
            fid.write(f'{ev + 1},'
                      f'{expected[ev, 0]:.4f},'
                      f'{expected[ev, 1]:.4f},'
                      f'{expected[ev, 2]:.4f},'
                      f'{expected[ev, 3]:.1f},'
                      f'{int(expected[ev, 4])}\n')


# =========================================================================
#  EXPORT 4: MAT FILE  (everything, for flexibility)
# =========================================================================

# config = { ... }  # see MATLAB original for the full struct
# savemat(out_mat_file, { ... })


# =========================================================================
#  VERIFICATION PLOT  (quick sanity check)
# =========================================================================

if SHOW_PLOTS:
    print('\nGenerating verification plots...')

    plt.figure(num='Test Grid Positions')
    plt.scatter(x_list, y_list, s=15)
    plt.xlabel('X Position (mm)')
    plt.ylabel('Y Position (mm)')
    plt.title(f'Test Grid: {n_events} Events ({n_grid}x{n_grid})')
    plt.axis('equal')
    plt.xlim([-det_half_mm, det_half_mm])
    plt.ylim([-det_half_mm, det_half_mm])
    plt.grid(True)

    center_ev_idx = int(round(n_events / 2)) - 1
    cx = x_list[center_ev_idx]
    cy = y_list[center_ev_idx]

    t0_s = t0_ns * 1e-9
    ctx1 = t0_s + ((line_length_mm / 2 - cx) / vpx) * 1e-9
    ctx2 = t0_s + ((line_length_mm / 2 + cx) / vpx) * 1e-9
    cty1 = t0_s + ((line_length_mm / 2 - cy) / vpy) * 1e-9
    cty2 = t0_s + ((line_length_mm / 2 + cy) / vpy) * 1e-9

    _, pw_x1 = gen_pulse(fs, event_window_s, ctx1, 0.250, 0, rng)
    _, pw_x2 = gen_pulse(fs, event_window_s, ctx2, 0.400, 0, rng)
    _, pw_y1 = gen_pulse(fs, event_window_s, cty1, 0.300, 0, rng)
    _, pw_y2 = gen_pulse(fs, event_window_s, cty2, 0.450, 0, rng)

    t_ns = t * 1e9

    fig2, axs = plt.subplots(2, 2, num='Example Event Waveforms (Analog, before ADC)')
    for ax, w, label, pos_label in [
        (axs[0, 0], pw_x1, 'X1', f'x={cx:.1f} mm'),
        (axs[0, 1], pw_x2, 'X2', f'x={cx:.1f} mm'),
        (axs[1, 0], pw_y1, 'Y1', f'y={cy:.1f} mm'),
        (axs[1, 1], pw_y2, 'Y2', f'y={cy:.1f} mm'),
    ]:
        ax.plot(t_ns, w + dc_offset_V); ax.grid(True)
        ax.set_xlabel('Time (ns)'); ax.set_ylabel('Voltage (V)')
        ax.set_title(f'{label} ({pos_label})')
        ax.set_ylim([0, adc_range_V * 0.5])
    fig2.tight_layout()

    ev_start = center_ev_idx * (n_samples_per_event + idle_gap_clks)
    ev_end   = ev_start + n_samples_per_event
    samp_idx = slice(ev_start, ev_end)

    fig3, axs2 = plt.subplots(2, 2, num='Example Event ADC Codes (12-bit)')
    for ax, data, label in [
        (axs2[0, 0], all_adc_x1[samp_idx], 'X1'),
        (axs2[0, 1], all_adc_x2[samp_idx], 'X2'),
        (axs2[1, 0], all_adc_y1[samp_idx], 'Y1'),
        (axs2[1, 1], all_adc_y2[samp_idx], 'Y2'),
    ]:
        ax.plot(data); ax.grid(True)
        ax.set_xlabel('Sample'); ax.set_ylabel('ADC Code')
        ax.set_title(f'{label} (12-bit)')
        ax.set_ylim([0, adc_max_code])
    fig3.tight_layout()

print('\n=== DONE ===')
print('Files written:')
print(f'  {out_hex_file}  (packed HEX, {total_clocks} lines)')
print(f'  {out_csv_file}  (answer key, {n_events} events)')
print('\nNext steps:')
print(f'  1. python uartsource.py {TEST_NAME}      # transmit to FPGA')
print(f'  2. (collect <name>.h5 from the GUI host PC, drop into comparisonfiles/)')
print(f'  3. python CompareResults.py {TEST_NAME}  # compare results')

if SHOW_PLOTS:
    plt.show()