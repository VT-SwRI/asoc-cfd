import os
import glob
import math
import argparse
import sys
from pathlib import Path

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import h5py


# ============================================================================
# Path constants
# ============================================================================

SCRIPT_DIR     = Path(__file__).parent
COMPARISON_DIR = SCRIPT_DIR / "comparisonfiles"
RESULTS_DIR    = SCRIPT_DIR / "results"


# ============================================================================
# Configuration defaults
# ============================================================================

ADC_BITS = 12
ADC_RANGE_V = 2.5
ADC_MAX_CODE = 2**ADC_BITS - 1  # 4095

POS_TOL_MM = 1.0
CHARGE_TOL_PCT = 10.0


# ============================================================================
# File resolution helpers
# ============================================================================

def list_available_test_names() -> list[str]:
    """Return sorted stems of every .csv file in comparisonfiles/."""
    if not COMPARISON_DIR.is_dir():
        return []
    return sorted(p.stem for p in COMPARISON_DIR.glob("*.csv"))


def list_h5_files() -> list[Path]:
    """Return all .h5 / .hdf5 files in comparisonfiles/."""
    if not COMPARISON_DIR.is_dir():
        return []
    return sorted(list(COMPARISON_DIR.glob("*.h5")) + list(COMPARISON_DIR.glob("*.hdf5")))


def find_unmatched_h5_files() -> list[Path]:
    """Return .h5 files in comparisonfiles/ that have no same-stem .csv partner."""
    csv_stems = {p.stem for p in COMPARISON_DIR.glob("*.csv")}
    return [p for p in list_h5_files() if p.stem not in csv_stems]


def prompt_for_unmatched_h5(test_name: str) -> Path:
    """Offer to rename the newest unmatched .h5 to <test_name>.h5."""
    unmatched = find_unmatched_h5_files()

    if not unmatched:
        raise FileNotFoundError(
            f"No '{test_name}.h5' found in {COMPARISON_DIR.name}/, and no "
            f"unmatched .h5 files are available to rename.\n"
            f"Place the .h5 file from the GUI into {COMPARISON_DIR.name}/ and try again."
        )

    newest = max(unmatched, key=lambda p: p.stat().st_mtime)

    print(f"\nNo {test_name}.h5 found in {COMPARISON_DIR.name}/.")
    print(f"Newest unmatched .h5 is '{newest.name}'.")
    response = input(f"Use it as {test_name}.h5? [y/N] ").strip().lower()

    if response in ("y", "yes"):
        new_path = COMPARISON_DIR / f"{test_name}.h5"
        newest.rename(new_path)
        print(f"Renamed: {newest.name} -> {new_path.name}")
        return new_path

    raise FileNotFoundError(
        f"Cancelled. No matching .h5 paired with '{test_name}.csv'."
    )


def resolve_pair(test_name: str | None) -> tuple[Path, Path, str]:
    """
    Return (csv_path, h5_path, resolved_test_name).

    If test_name is given:
      - csv_path = comparisonfiles/<test_name>.csv (must exist)
      - h5_path  = comparisonfiles/<test_name>.h5 if present,
                   else interactively rename the newest unmatched .h5

    If test_name is None and exactly one .csv + one .h5 exist in
    comparisonfiles/, use that pair (no renaming). The test name returned is
    the .csv's stem.
    """
    if test_name is not None:
        csv_path = COMPARISON_DIR / f"{test_name}.csv"
        if not csv_path.exists():
            available = list_available_test_names()
            hint = ", ".join(available) if available else "(none)"
            raise FileNotFoundError(
                f"Expected file not found: {csv_path}\n"
                f"Available test names in {COMPARISON_DIR.name}/: {hint}"
            )

        h5_path = COMPARISON_DIR / f"{test_name}.h5"
        if not h5_path.exists():
            alt_path = COMPARISON_DIR / f"{test_name}.hdf5"
            if alt_path.exists():
                h5_path = alt_path
            else:
                h5_path = prompt_for_unmatched_h5(test_name)

        return csv_path, h5_path, test_name

    # Auto-pick fallback
    csvs = sorted(COMPARISON_DIR.glob("*.csv"))
    h5s  = list_h5_files()

    if len(csvs) == 1 and len(h5s) == 1:
        print(f"Auto-picking the only pair in {COMPARISON_DIR.name}/:")
        print(f"  expected: {csvs[0].name}")
        print(f"  actual:   {h5s[0].name}")
        return csvs[0], h5s[0], csvs[0].stem

    available = list_available_test_names()
    h5_names = [p.name for p in h5s]
    raise FileNotFoundError(
        f"No test name given and {COMPARISON_DIR.name}/ does not contain "
        f"exactly one .csv and one .h5.\n"
        f"  .csv files: {available or '(none)'}\n"
        f"  .h5  files: {h5_names or '(none)'}\n"
        f"Specify a test name, e.g. `python CompareResults.py bird`."
    )


# ============================================================================
# Loaders
# ============================================================================

def normalize_csv_actual_table(df: pd.DataFrame) -> tuple[pd.DataFrame, bool]:
    """
    Normalize legacy CSV results into a table with:
        x_mm, y_mm, [charge_sum]
    Accepts either x_mm/y_mm or x_microns/y_microns style columns.
    """
    cols = {c.lower().strip(): c for c in df.columns}

    def get_col(*aliases):
        for alias in aliases:
            if alias in cols:
                return cols[alias]
        return None

    x_mm_col = get_col("x_mm", "xpos", "x", "pos_x")
    y_mm_col = get_col("y_mm", "ypos", "y", "pos_y")
    x_um_col = get_col("x_microns", "x_um", "x_micron", "xpos_um", "xpos_microns")
    y_um_col = get_col("y_microns", "y_um", "y_micron", "ypos_um", "ypos_microns")

    if x_mm_col and y_mm_col:
        out = pd.DataFrame({
            "x_mm": pd.to_numeric(df[x_mm_col], errors="coerce"),
            "y_mm": pd.to_numeric(df[y_mm_col], errors="coerce"),
        })
    elif x_um_col and y_um_col:
        out = pd.DataFrame({
            "x_mm": pd.to_numeric(df[x_um_col], errors="coerce") / 1000.0,
            "y_mm": pd.to_numeric(df[y_um_col], errors="coerce") / 1000.0,
        })
    else:
        raise ValueError(
            "CSV actual-results file must contain either "
            "(x_mm, y_mm) or (x_microns, y_microns)."
        )

    charge_col = get_col("charge_sum", "charge_adc", "charge", "adc_sum", "magnitude", "mag")
    has_charge = charge_col is not None
    if has_charge:
        out["charge_sum"] = pd.to_numeric(df[charge_col], errors="coerce").round()

    out = out.dropna(subset=["x_mm", "y_mm"]).reset_index(drop=True)
    return out, has_charge


def load_h5_actual_table(
    filename: Path,
    extracted_csv_path: Path | None = None,
) -> tuple[pd.DataFrame, bool, str]:
    """Load actual results from the GUI .h5 file."""
    with h5py.File(filename, "r") as f:
        if "photons" not in f:
            available = list(f.keys())
            raise KeyError(
                f"HDF5 dataset '/photons' not found. Top-level datasets/groups: {available}"
            )
        dset = f["photons"]
        data = dset[:]

    if data.dtype.names is None:
        raise ValueError("Dataset '/photons' is not a compound dataset with named fields.")

    field_names = set(data.dtype.names)
    required = {"xpos", "ypos"}
    if not required.issubset(field_names):
        raise ValueError(
            f"Dataset '/photons' missing required fields. Found: {sorted(field_names)}"
        )

    out = pd.DataFrame({
        "x_mm": data["xpos"].astype(np.float64) / 1000.0,
        "y_mm": data["ypos"].astype(np.float64) / 1000.0,
    })

    has_charge = False
    if "mag" in field_names:
        out["charge_sum"] = np.round(data["mag"].astype(np.float64))
        has_charge = True
    elif "magnitude" in field_names:
        out["charge_sum"] = np.round(data["magnitude"].astype(np.float64))
        has_charge = True

    if extracted_csv_path is not None:
        extracted_csv_path.parent.mkdir(parents=True, exist_ok=True)
        # Add event_id column for readability
        out_with_id = out.reset_index(drop=True)
        out_with_id.insert(0, "event_id", np.arange(1, len(out_with_id) + 1))
        out_with_id.to_csv(extracted_csv_path, index=False)
        print(f"FPGA results written to: {extracted_csv_path}")

    return out.reset_index(drop=True), has_charge, "/photons"


def load_actual_results(
    filename: Path,
    extracted_csv_path: Path | None = None,
) -> tuple[pd.DataFrame, bool, str]:
    ext = filename.suffix.lower()

    if ext == ".csv":
        df = pd.read_csv(filename)
        actual_table, has_charge = normalize_csv_actual_table(df)
        return actual_table, has_charge, "CSV file"

    if ext in {".h5", ".hdf5"}:
        actual_table, has_charge, source_desc = load_h5_actual_table(
            filename, extracted_csv_path=extracted_csv_path,
        )
        return actual_table, has_charge, f"HDF5 dataset {source_desc}"

    raise ValueError(f"Unsupported actual-results file extension: {ext}")


def load_expected_results(filename: Path) -> pd.DataFrame:
    if not filename.is_file():
        raise FileNotFoundError(f"Expected outputs file not found: {filename}")

    df = pd.read_csv(filename)

    required = {"x_mm", "y_mm", "peak_V"}
    missing = required - set(df.columns)
    if missing:
        raise ValueError(f"Expected CSV missing required columns: {sorted(missing)}")

    return df.reset_index(drop=True)


# ============================================================================
# Main comparison
# ============================================================================

def compare_results(
    expected_file: Path,
    fpga_file: Path,
    results_csv_path: Path,
    pos_tol_mm: float = POS_TOL_MM,
    charge_tol_pct: float = CHARGE_TOL_PCT,
    show_plots: bool = True,
) -> None:
    print(f"Loading expected results from: {expected_file}")
    exp_table = load_expected_results(expected_file)

    print(f"Loading actual results from:   {fpga_file}")
    actual_table, has_charge_actual, actual_source_desc = load_actual_results(
        fpga_file, extracted_csv_path=results_csv_path,
    )
    print(f"Actual data source used: {actual_source_desc}")

    n_expected = len(exp_table)
    n_actual = len(actual_table)

    print(f"\nExpected events: {n_expected}")
    print(f"Actual events:   {n_actual}")

    if n_actual < n_expected:
        print("WARNING: Actual file returned fewer events than expected.")
        print(f"  Missing events: {n_expected - n_actual} ({(n_expected - n_actual)/max(n_expected,1)*100:.1f}%)")
    elif n_actual > n_expected:
        print("WARNING: Actual file returned more events than expected.")

    n_compare = min(n_expected, n_actual)
    if n_compare == 0:
        print("\nNo overlapping events to compare.")
        return

    exp_x_mm = exp_table.loc[:n_compare - 1, "x_mm"].to_numpy(dtype=float)
    exp_y_mm = exp_table.loc[:n_compare - 1, "y_mm"].to_numpy(dtype=float)
    act_x_mm = actual_table.loc[:n_compare - 1, "x_mm"].to_numpy(dtype=float)
    act_y_mm = actual_table.loc[:n_compare - 1, "y_mm"].to_numpy(dtype=float)

    err_x_mm = act_x_mm - exp_x_mm
    err_y_mm = act_y_mm - exp_y_mm
    err_r_mm = np.sqrt(err_x_mm**2 + err_y_mm**2)

    pos_pass = err_r_mm <= pos_tol_mm

    exp_peak_v = exp_table.loc[:n_compare - 1, "peak_V"].to_numpy(dtype=float)
    exp_charge_adc = 4 * np.round(exp_peak_v / ADC_RANGE_V * ADC_MAX_CODE)

    if has_charge_actual and "charge_sum" in actual_table.columns:
        act_charge = actual_table.loc[:n_compare - 1, "charge_sum"].to_numpy(dtype=float)
        charge_err_abs = np.abs(act_charge - exp_charge_adc)
        with np.errstate(divide="ignore", invalid="ignore"):
            charge_err_pct = np.where(exp_charge_adc != 0,
                                      charge_err_abs / exp_charge_adc * 100.0,
                                      np.nan)
        charge_pass = charge_err_pct <= charge_tol_pct
        has_charge = True
    else:
        has_charge = False
        act_charge = None
        charge_err_pct = None
        charge_pass = np.ones(n_compare, dtype=bool)

    overall_pass = pos_pass & charge_pass

    print("\n=================== VERIFICATION RESULTS ===================")
    print(f"Position tolerance:  +/- {pos_tol_mm:.2f} mm")
    print(f"Charge tolerance:    +/- {charge_tol_pct:.1f}%")

    print("\n--- Position ---")
    print(f"  Pass: {np.sum(pos_pass)} / {n_compare} ({np.sum(pos_pass)/n_compare*100:.1f}%)")
    print(f"  Mean radial error:   {np.mean(err_r_mm):.4f} mm")
    print(f"  RMS  radial error:   {np.sqrt(np.mean(err_r_mm**2)):.4f} mm")
    print(f"  Max  radial error:   {np.max(err_r_mm):.4f} mm")
    print(f"  Mean X error:        {np.mean(err_x_mm):+.4f} mm")
    print(f"  Mean Y error:        {np.mean(err_y_mm):+.4f} mm")

    if has_charge:
        print("\n--- Charge (ADC Counts) ---")
        print(f"  Pass: {np.sum(charge_pass)} / {n_compare} ({np.sum(charge_pass)/n_compare*100:.1f}%)")
        print(f"  Mean error: {np.nanmean(charge_err_pct):.2f}%")
        print(f"  Max  error: {np.nanmax(charge_err_pct):.2f}%")

        print("\n  Per-event charge detail:")
        print(f"  {'Event':<6}  {'peak_V':<10}  {'Exp ADC':<12}  {'Act ADC':<12}  {'Err %':<8}")
        for k in range(n_compare):
            print(
                f"  {k+1:<6d}  "
                f"{exp_peak_v[k]:<10.4f}  "
                f"{int(exp_charge_adc[k]):<12d}  "
                f"{int(round(act_charge[k])):<12d}  "
                f"{charge_err_pct[k]:<8.2f}"
            )
    else:
        print("\n--- Charge ---")
        print("  Skipped.")
        print("  No charge-like field was found in the actual file.")

    print("\n--- Overall ---")
    print(f"  {np.sum(overall_pass)} / {n_compare} PASS ({np.sum(overall_pass)/n_compare*100:.1f}%)")

    if np.all(overall_pass):
        print("\n  *** ALL TESTS PASSED ***")
    else:
        print(f"\n  *** {np.sum(~overall_pass)} TESTS FAILED ***")
        fail_idx = np.where(~overall_pass)[0]
        n_show = min(10, len(fail_idx))
        print(f"\n  First {n_show} failures:")
        print(f"  {'Event':<6}  {'Exp X(mm)':<10} {'Exp Y(mm)':<10}  {'Got X(mm)':<10} {'Got Y(mm)':<10}  {'Err(mm)':<8}")
        for idx in fail_idx[:n_show]:
            print(
                f"  {idx+1:<6d}  "
                f"{exp_x_mm[idx]:<10.2f} {exp_y_mm[idx]:<10.2f}  "
                f"{act_x_mm[idx]:<10.2f} {act_y_mm[idx]:<10.2f}  "
                f"{err_r_mm[idx]:<8.3f}"
            )

    print("=============================================================")

    if show_plots:
        plt.figure("Expected vs Actual Positions")
        plt.scatter(exp_x_mm, exp_y_mm, s=40, label="Expected")
        plt.scatter(act_x_mm, act_y_mm, s=25, marker="x", label="Actual")
        plt.xlabel("X (mm)")
        plt.ylabel("Y (mm)")
        plt.title("Expected vs Actual Output")
        plt.axis("equal")
        plt.grid(True)
        plt.legend()

        plt.figure("Position Error Map")
        plt.quiver(exp_x_mm, exp_y_mm, err_x_mm, err_y_mm, angles="xy", scale_units="xy", scale=1)
        fail_mask = ~pos_pass
        if np.any(fail_mask):
            plt.scatter(exp_x_mm[fail_mask], exp_y_mm[fail_mask], s=60, marker="x", label="FAIL")
            plt.legend()
        plt.xlabel("X (mm)")
        plt.ylabel("Y (mm)")
        plt.title("Position Error Vectors")
        plt.axis("equal")
        plt.grid(True)

        plt.figure("Radial Error Distribution")
        plt.hist(err_r_mm, bins=50)
        plt.axvline(pos_tol_mm, linestyle="--")
        plt.xlabel("Radial Error (mm)")
        plt.ylabel("Count")
        plt.title("Distribution of Position Errors")
        plt.grid(True)

        if has_charge:
            plt.figure("Charge Comparison")
            plt.subplot(1, 2, 1)
            x = np.arange(n_compare)
            width = 0.4
            plt.bar(x - width / 2, exp_charge_adc, width=width, label="Expected")
            plt.bar(x + width / 2, act_charge, width=width, label="Actual")
            plt.xlabel("Event")
            plt.ylabel("ADC Counts")
            plt.title("Expected vs Actual Charge")
            plt.legend()
            plt.grid(True)

            plt.subplot(1, 2, 2)
            plt.hist(charge_err_pct[~np.isnan(charge_err_pct)], bins=50)
            plt.axvline(charge_tol_pct, linestyle="--")
            plt.xlabel("Charge Error (%)")
            plt.ylabel("Count")
            plt.title("Charge Error Distribution")
            plt.grid(True)

        plt.tight_layout()
        plt.show()

    print(f"\nFPGA results CSV written to: {results_csv_path}")
    print("Done. Review the plots and the results CSV for visual inspection.")


# ============================================================================
# CLI
# ============================================================================

def main():
    # Make sure the workflow folders exist so commands like --list don't crash
    # on a fresh clone.
    COMPARISON_DIR.mkdir(parents=True, exist_ok=True)
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)

    available = list_available_test_names()
    examples_block = (
        "Examples:\n"
        "  python CompareResults.py bird            # compare bird.csv vs bird.h5\n"
        "  python CompareResults.py                 # auto-pick if only one pair exists\n"
        "  python CompareResults.py bird --no-plots # text-only output\n"
        "  python CompareResults.py --list          # list available test names"
    )

    parser = argparse.ArgumentParser(
        prog="CompareResults.py",
        description=(
            "Compare expected test vector outputs against actual FPGA results.\n\n"
            "Reads from comparisonfiles/:\n"
            "  comparisonfiles/<test_name>.csv  - expected outputs (from GenerateTestVectors.py)\n"
            "  comparisonfiles/<test_name>.h5   - actual outputs (from the FPGA/GUI workflow)\n\n"
            "Writes to results/:\n"
            "  results/<test_name>_fpga_results.csv  - parsed FPGA results in CSV form\n\n"
            "On-screen output: position/charge pass-fail report and matplotlib plots.\n\n"
            "If <test_name>.h5 doesn't exist but an unmatched .h5 file is in "
            "comparisonfiles/ (e.g. a freshly transferred file from the GUI host PC), "
            "the script will offer to rename it to <test_name>.h5 for you.\n\n"
            "If no test name is given, and exactly one .csv plus one .h5 exist in "
            "comparisonfiles/, those are used automatically.\n\n"
            "Both comparisonfiles/ and results/ are created automatically if missing.\n\n"
            "Part of the FPGA test workflow alongside GenerateTestVectors.py and "
            "uartsource.py."
        ),
        epilog=examples_block,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "test_name",
        nargs="?",
        default=None,
        help=(
            "name of the test to compare (e.g. 'bird' -> looks for "
            "comparisonfiles/bird.csv and comparisonfiles/bird.h5). "
            "If omitted, the script auto-picks when exactly one pair exists."
        ),
    )
    parser.add_argument(
        "--no-plots",
        action="store_true",
        help="disable matplotlib plots (text-only report)",
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="list test names available in comparisonfiles/ and exit",
    )
    parser.add_argument(
        "--pos-tol",
        type=float,
        default=POS_TOL_MM,
        metavar="MM",
        help=f"position pass tolerance in mm (default: {POS_TOL_MM})",
    )
    parser.add_argument(
        "--charge-tol",
        type=float,
        default=CHARGE_TOL_PCT,
        metavar="PCT",
        help=f"charge pass tolerance in percent (default: {CHARGE_TOL_PCT})",
    )

    args = parser.parse_args()

    if args.list:
        if available:
            print(f"Available test names in {COMPARISON_DIR}/:")
            for name in available:
                csv_path = COMPARISON_DIR / f"{name}.csv"
                h5_path  = COMPARISON_DIR / f"{name}.h5"
                h5_alt   = COMPARISON_DIR / f"{name}.hdf5"
                tag = "  (paired)" if (h5_path.exists() or h5_alt.exists()) else "  (no .h5 yet)"
                print(f"  {name}{tag}")
            unmatched = find_unmatched_h5_files()
            if unmatched:
                print("\nUnmatched .h5 files (no same-stem .csv):")
                for p in unmatched:
                    print(f"  {p.name}")
        else:
            print(f"No .csv files found in {COMPARISON_DIR}/")
            print("Run GenerateTestVectors.py to create one.")
        return

    try:
        csv_path, h5_path, resolved_name = resolve_pair(args.test_name)
    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

    results_csv_path = RESULTS_DIR / f"{resolved_name}_fpga_results.csv"

    compare_results(
        expected_file=csv_path,
        fpga_file=h5_path,
        results_csv_path=results_csv_path,
        pos_tol_mm=args.pos_tol,
        charge_tol_pct=args.charge_tol,
        show_plots=not args.no_plots,
    )


if __name__ == "__main__":
    main()