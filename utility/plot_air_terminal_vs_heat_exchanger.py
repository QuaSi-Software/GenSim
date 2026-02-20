"""Plot: Air Terminal vs Heat Exchanger heating/cooling (sensible + total).

Reads GenSim/OpenStudio results CSVs produced by the `Measures/results` reporting measure.
Typical inputs:
  - report_variables_ZoneTimestep-net-Sum.csv  (annual sums)
  - report_variables_ZoneTimestep-net.csv      (timeseries)

Convention:
  - Heating is plotted positive.
  - Cooling is plotted negative.

The exporter usually appends units in brackets (e.g. "[Wh]"). This script strips the
unit suffixes and converts J/Wh/W values to kWh.

Usage (PowerShell):
  python utility\plot_air_terminal_vs_heat_exchanger.py F:\Repos\OrgGenSim\Output\run\017_results\report_variables_ZoneTimestep-net-Sum.csv
"""

from __future__ import annotations

import argparse
import re
from typing import Dict

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


AIR_TERMINAL_VARS: Dict[str, str] = {
    "Air Terminal Sensible Heating": "Zone Air Terminal Sensible Heating Energy",
    "Air Terminal Sensible Cooling": "Zone Air Terminal Sensible Cooling Energy",
}

HEAT_EXCHANGER_VARS: Dict[str, str] = {
    "HX Sensible Heating": "Heat Exchanger Sensible Heating Energy",
    "HX Total Heating": "Heat Exchanger Total Heating Energy",
    "HX Sensible Cooling": "Heat Exchanger Sensible Cooling Energy",
    "HX Total Cooling": "Heat Exchanger Total Cooling Energy",
}


def read_csv(path: str) -> pd.DataFrame:
    return pd.read_csv(path)


def convert_units_inplace_to_kwh_and_strip_headers(df: pd.DataFrame) -> None:
    """Convert J/Wh/W columns to kWh, then remove unit suffix tokens in headers."""
    for column in list(df.columns):
        col = str(column)
        s = pd.to_numeric(df[column], errors="coerce").fillna(0.0)

        if "[J]" in col:
            df[column] = s / 3_600_000.0
        elif "[Wh]" in col:
            df[column] = s * 0.001
        elif "[W]" in col:
            # implicit 1-hour timestep (matches other plotting utilities in the repo)
            df[column] = s * 0.001
        else:
            df[column] = s

    # Remove common unit suffixes.
    df.rename(
        columns=lambda c: str(c)
        .replace("[J]", "")
        .replace("[W]", "")
        .replace("[Wh]", "")
        .replace("[hr]", "")
        .strip(),
        inplace=True,
    )


def _strip_bracket_units(s: str) -> str:
    # e.g. "Foo Bar[Wh]" -> "Foo Bar"
    return re.sub(r"\s*\[[^]]+]\s*$", "", str(s)).strip()


def get_first_value(df: pd.DataFrame, desired_col_name: str, default: float = 0.0) -> float:
    """Find column by name, ignoring trailing [units]; return first row value."""
    desired = _strip_bracket_units(desired_col_name)

    # Map base header -> actual header
    base_to_actual: dict[str, str] = {}
    for c in df.columns:
        base_to_actual.setdefault(_strip_bracket_units(c), c)

    actual = base_to_actual.get(desired)
    if actual is None or df.empty:
        return default

    v = df.at[0, actual]
    try:
        return float(v)
    except Exception:
        return float(pd.to_numeric(pd.Series([v]), errors="coerce").fillna(default).iloc[0])


def make_plot(df: pd.DataFrame, title: str | None = None) -> plt.Figure:
    """Create grouped bar chart: Air Terminal vs Heat Exchanger."""

    # Energies are expected as *positive magnitudes* in the CSV. We apply sign here.
    at_heat = get_first_value(df, AIR_TERMINAL_VARS["Air Terminal Sensible Heating"], 0.0)
    at_cool = -get_first_value(df, AIR_TERMINAL_VARS["Air Terminal Sensible Cooling"], 0.0)

    hx_sens_heat = get_first_value(df, HEAT_EXCHANGER_VARS["HX Sensible Heating"], 0.0)
    hx_tot_heat = get_first_value(df, HEAT_EXCHANGER_VARS["HX Total Heating"], 0.0)
    hx_sens_cool = -get_first_value(df, HEAT_EXCHANGER_VARS["HX Sensible Cooling"], 0.0)
    hx_tot_cool = -get_first_value(df, HEAT_EXCHANGER_VARS["HX Total Cooling"], 0.0)

    groups = ["Air Terminal", "Heat Exchanger"]
    x = np.arange(len(groups))

    series = [
        ("Sensible Heating", [at_heat, hx_sens_heat], "tab:orange"),
        ("Total Heating", [0.0, hx_tot_heat], "tab:red"),
        ("Sensible Cooling", [at_cool, hx_sens_cool], "tab:cyan"),
        ("Total Cooling", [0.0, hx_tot_cool], "tab:blue"),
    ]

    width = 0.18
    offsets = np.linspace(-1.5 * width, 1.5 * width, num=len(series))

    fig, ax = plt.subplots(figsize=(10, 5))

    for (label, vals, color), dx in zip(series, offsets):
        ax.bar(x + dx, vals, width=width, label=label, color=color)

    ax.axhline(0.0, color="black", linewidth=0.8)
    ax.set_xticks(x)
    ax.set_xticklabels(groups)
    ax.set_ylabel("Energy (kWh)  [heating +, cooling −]")
    ax.set_title(title or "Air Terminal vs Heat Exchanger (Sensible/Total, Heating/Cooling)")
    ax.grid(True, axis="y", linestyle="--", linewidth=0.5)
    ax.legend(ncols=2, fontsize=9)

    # annotate bars
    for container in ax.containers:
        for bar in container:
            h = float(bar.get_height())
            if abs(h) < 1e-12:
                continue
            ax.text(
                float(bar.get_x() + bar.get_width() / 2.0),
                h,
                f"{h:,.3g}",
                ha="center",
                va="bottom" if h >= 0 else "top",
                fontsize=8,
            )

    fig.tight_layout()
    return fig


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "csv",
        nargs="?",
        default=r"F:\Repos\OrgGenSim\Output\run\017_results\report_variables_ZoneTimestep-net-Sum.csv",
        help="Path to results CSV (e.g., report_variables_ZoneTimestep-net-Sum.csv)",
    )
    ap.add_argument("--title", default=None, help="Optional plot title")
    ap.add_argument(
        "--out",
        default=None,
        help="Optional output image path (PNG). If omitted, saves next to the CSV.",
    )
    ap.add_argument(
        "--show",
        action="store_true",
        help="Also display the plot interactively (may fail in some PyCharm backends).",
    )
    args = ap.parse_args()

    df = read_csv(args.csv)
    convert_units_inplace_to_kwh_and_strip_headers(df)
    fig = make_plot(df, title=args.title)

    # In PyCharm, some matplotlib backends (e.g., InterAgg) can crash on plt.show().
    # Writing the figure is reliable and still gives you a usable artifact.
    out_path = args.out
    if out_path is None:
        # save alongside csv
        out_path = re.sub(r"\.csv$", "", args.csv, flags=re.IGNORECASE) + "_air_terminal_vs_hx.png"
    fig.savefig(out_path, dpi=200)
    print(f"Saved: {out_path}")

    if args.show:
        plt.show()


if __name__ == "__main__":
    main()

