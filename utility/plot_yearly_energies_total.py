"""
Zone Total energy balance plot (signed), incl. NET residual and NET% vs Σ|E|.

- Reads a CSV (typically a yearly sum with a single row).
- Converts J/Wh/W columns to kWh and strips unit suffixes from column names.
- Applies SIGN mapping to compute signed contributions.
- Computes:
    NET = Σ(signed contributions)
    Σ|E| = Σ(abs(signed contributions))
    NET% = 100 * NET / Σ|E|
- Plots a horizontal bar chart with an explicit residual name.

Residual naming:
    "Zone Thermal Storage / Unreported Terms Residual (NET)"
means: whatever is left to close the balance beyond the explicitly included terms
(e.g., surface thermal mass storage terms, any missing surface/air coupling terms,
timestep coupling / numerical effects, etc.).
"""

from __future__ import annotations

import argparse
import re
import pandas as pd
import matplotlib
import matplotlib.pyplot as plt


# Choose an interactive backend if you run locally (optional).
# You can comment this out if it causes issues in your environment.
matplotlib.use("TkAgg")  # or "QtAgg" if you have PyQt/PySide installed


SIGN = {
    # HVAC delivered
    "Zone Air Terminal Sensible Heating Energy": +1,
    "Zone Air Terminal Sensible Cooling Energy": -1,
    "Zone Radiant HVAC Heating Energy": +1,
    "Zone Radiant HVAC Cooling Energy": -1,
    "Baseboard Total Heating Energy": +1,

    # Internal gains
    "Zone People Total Heating Energy": +1,
    "Zone Lights Total Heating Energy": +1,
    "Zone Electric Equipment Total Heating Energy": +1,

    # Outdoor air exchange
    "Zone Infiltration Total Heat Gain Energy": +1,
    "Zone Infiltration Total Heat Loss Energy": -1,
    "Zone Ventilation Total Heat Gain Energy": +1,
    "Zone Ventilation Total Heat Loss Energy": -1,

    # Opaque transmission
    "Zone Opaque Surface Inside Faces Total Conduction Heat Gain Energy": +1,
    "Zone Opaque Surface Inside Faces Total Conduction Heat Loss Energy": -1,

    # NOTE: This one is a Rate in many outputs; keep only if you know it is energy
    # or you intentionally convert W->kWh with implicit 1h (see convert_units()).
    #"Zone Air Heat Balance Surface Convection Rate": +1,

    # Window split (aggregated)
    "Zone Windows Total Heat Gain Energy": +1,
    "Zone Windows Total Heat Loss Energy": -1,

    # Optional interzone
    "Zone Interzone Air Transfer Heat Gain Energy": +1,
    "Zone Interzone Air Transfer Heat Loss Energy": -1,

    # Storage (air)
    "Zone Air Heat Balance Air Energy Storage Rate": +1,
}


RESIDUAL_LABEL = "Zone Thermal Storage / Unreported Terms Residual (NET)"


def read_csv(filename: str) -> pd.DataFrame:
    """Read the given CSV file and provide a pandas data frame for it."""
    return pd.read_csv(filename)


def j_to_kwh(x: float) -> float:
    """Convert J to kWh."""
    return x / 3_600_000.0


def w_to_kwh(x: float) -> float:
    """Convert W to kWh, using an implicit time of 1 h."""
    return x * 0.001


def wh_to_kwh(x: float) -> float:
    """Convert Wh to kWh."""
    return x * 0.001


def convert_units(df: pd.DataFrame) -> None:
    """
    Convert the units in the given data frame to kWh for units J, Wh and W.
    Then strip trailing unit tokens from column names.
    """
    for column in list(df.columns):
        col = str(column)
        if "[J]" in col:
            df[column] = pd.to_numeric(df[column], errors="coerce").fillna(0.0).apply(j_to_kwh)
        elif "[Wh]" in col:
            df[column] = pd.to_numeric(df[column], errors="coerce").fillna(0.0).apply(wh_to_kwh)
        elif "[W]" in col:
            # conversion from power to energy works only with implicit time step of 1 h
            df[column] = pd.to_numeric(df[column], errors="coerce").fillna(0.0).apply(w_to_kwh)

    # remove unit suffixes in headers
    df.rename(columns=lambda c: str(c).replace("[J]", "").replace("[W]", "").replace("[Wh]", "").replace("[hr]", ""), inplace=True)
    df.rename(columns=lambda c: str(c).strip(), inplace=True)


def _strip_units(col: str) -> str:
    # In case some columns still carry "[...]" suffixes
    return re.sub(r"\s*\[[^\]]+\]\s*$", "", str(col)).strip()


def try_first(df: pd.DataFrame, key: str) -> float:
    """Return the first value of the given column, if it exists, 0 otherwise."""
    if key not in df.columns or df.empty:
        return 0.0
    val = df.at[0, key]
    try:
        return float(val)
    except Exception:
        return float(pd.to_numeric(pd.Series([val]), errors="coerce").fillna(0.0).iloc[0])


def get_col_value(df: pd.DataFrame, desired_name: str, default: float = 0.0) -> float:
    """
    Find a column in df that matches desired_name ignoring trailing [units],
    then return try_first(df, actual_column_name).
    """
    desired_base = _strip_units(desired_name)

    # base_name -> actual column name (first occurrence wins)
    base_to_actual: dict[str, str] = {}
    for c in df.columns:
        base_to_actual.setdefault(_strip_units(c), c)

    actual = base_to_actual.get(desired_base)
    if actual is None:
        return default
    return try_first(df, actual)


def signed_value(df: pd.DataFrame, name: str) -> float:
    """
    Return signed value according to SIGN dictionary.
    Uses robust column lookup ignoring unit suffixes.
    Falls back to +1 if variable is not explicitly listed.
    """
    sign = SIGN.get(name, +1)
    v = get_col_value(df, name, default=0.0)
    return sign * v


def create_new_barchart(title: str, labels: list[str], values: list[float]) -> None:
    import numpy as np

    vals = np.array(values, dtype=float)
    y = np.arange(len(labels))

    fig, ax = plt.subplots(figsize=(12, max(4, 0.35 * len(labels))))

    colors = ["tab:red" if v < 0 else "tab:blue" for v in vals]
    ax.barh(y, vals, color=colors)

    ax.set_yticks(y)
    ax.set_yticklabels(labels, fontsize=9)
    ax.set_title(title)
    ax.axvline(0)
    ax.set_xlabel("Energy (kWh, signed)")

    # annotate bars
    for i, v in enumerate(vals):
        ax.text(v, i, f" {v:,.3g}", va="center", fontsize=8)

    ax.grid(True, axis="x", linestyle="--", linewidth=0.5)
    plt.tight_layout()
    plt.show()


def debug_lookup(df: pd.DataFrame, base_names: list[str]) -> None:
    """Quick helper to see which columns are found/missing."""
    print("DF shape:", df.shape)
    print("First 25 columns:")
    for c in list(df.columns)[:25]:
        print("  -", repr(c))

    base_to_actual = {}
    for c in df.columns:
        base_to_actual.setdefault(_strip_units(c), c)

    missing = []
    for base in base_names:
        actual = base_to_actual.get(_strip_units(base))
        if actual is None:
            missing.append(base)
        else:
            s = df[actual]
            print(f"\nFOUND: {base}  ->  {repr(actual)}")
            print("  dtype:", s.dtype)
            print("  head:", s.head(3).tolist())
            try:
                print("  sum:", float(pd.to_numeric(s, errors="coerce").sum()))
            except Exception as e:
                print("  sum: <failed>", e)
            print("  try_first:", try_first(df, actual))

    if missing:
        print("\nMISSING (no matching column found):")
        for m in missing:
            print("  -", m)


def create_zone_balance_plot(df: pd.DataFrame, include_abs_sum_bar: bool = False) -> None:
    convert_units(df)

    # Compute signed contributions in SIGN order
    columns = list(SIGN.keys())
    contrib_values = [signed_value(df, c) for c in columns]

    net = sum(contrib_values)
    abs_sum = sum(abs(v) for v in contrib_values)
    pct_net_vs_abs = 0.0 if abs_sum == 0 else 100.0 * net / abs_sum

    print("\n--- Balance summary ---")
    print(f"NET (residual): {net:,.6f} kWh")
    print(f"Σ|E|:          {abs_sum:,.6f} kWh")
    print(f"NET/Σ|E|:      {pct_net_vs_abs:,.6f} %")

    labels = columns.copy()
    values = contrib_values.copy()

    if include_abs_sum_bar:
        labels.append("Σ|E| (sum of absolute terms)")
        values.append(abs_sum)

    labels.append(RESIDUAL_LABEL)
    values.append(net)

    title = f"Zone TotalTotal balance (signed) | NET={net:,.2f} kWh ({pct_net_vs_abs:,.2f}% of Σ|E|)"
    create_new_barchart(title=title, labels=labels, values=values)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "csv",
        nargs="?",
        default=r"F:\Repos\OrgGenSim\Output\run\017_results\report_variables_ZoneTimestep-Sum.csv",
        help="Path to the CSV file (EnergyPlus report variables).",
    )
    parser.add_argument("--debug", action="store_true", help="Print column lookup diagnostics.")
    parser.add_argument(
        "--absbar",
        action="store_true",
        help="Also plot Σ|E| as an additional bar (magnitude reference).",
    )
    args = parser.parse_args()

    df = read_csv(args.csv)

    if args.debug:
        # debug against SIGN keys
        debug_lookup(df, list(SIGN.keys()))

    create_zone_balance_plot(df, include_abs_sum_bar=args.absbar)


if __name__ == "__main__":
    main()
