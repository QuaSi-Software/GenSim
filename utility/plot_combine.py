"""
Compare two balance approaches in ONE grouped bar chart (horizontal),
with optional stacking when multiple variables map to one category.

- Reads a one-row CSV like /mnt/data/report_variables_ZoneTimestep-Sum.csv
  where columns are variable names like "Zone ...[Wh]" and the single row
  contains the summed values in Wh.

- Produces a grouped, signed, stacked horizontal bar chart:
    * For each CATEGORY: two bars next to each other (Source A vs Source B)
    * Within each bar: multiple variables can be stacked (positive and negative
      stacks handled separately so signs remain correct)

Adjust CATEGORY_MAP below to match your conceptual mapping.
"""

from __future__ import annotations

import re
from pathlib import Path
from typing import Dict, List, Tuple

import pandas as pd
import matplotlib.pyplot as plt


# ---------------------------
# 1) Your two "SIGN" dicts
# ---------------------------

SIGN_A = {
    # HVAC delivered
    "Zone Air Terminal Sensible Heating Energy": +1,
    "Zone Air Terminal Sensible Cooling Energy": -1,
    "Zone Radiant HVAC Heating Energy": +1,
    "Zone Radiant HVAC Cooling Energy": -1,
    "Baseboard Total Heating Energy": +1,

    # Internal gains
    "Zone People Sensible Heating Energy": +1,
    "Zone Lights Total Heating Energy": +1,
    "Zone Electric Equipment Total Heating Energy": +1,

    # Outdoor air exchange
    "Zone Infiltration Sensible Heat Gain Energy": +1,
    "Zone Infiltration Sensible Heat Loss Energy": -1,
    "Zone Ventilation Sensible Heat Gain Energy": +1,
    "Zone Ventilation Sensible Heat Loss Energy": -1,

    # Opaque transmission
    "Zone Opaque Surface Inside Faces Total Conduction Heat Gain Energy": +1,
    "Zone Opaque Surface Inside Faces Total Conduction Heat Loss Energy": -1,

    # Window split (aggregated)
    "Zone Windows Total Heat Gain Energy": +1,
    "Zone Windows Total Heat Loss Energy": -1,

    # Optional interzone
    "Zone Interzone Air Transfer Heat Gain Energy": +1,
    "Zone Interzone Air Transfer Heat Loss Energy": -1,

    # Storage (air)
    "Zone Air Heat Balance Air Energy Storage Rate": +1,
}

SIGN_B = {
    "Zone Air Heat Balance Internal Convective Heat Gain Rate": +1,
    "Zone Air Heat Balance Surface Convection Rate": +1,
    "Zone Air Heat Balance Interzone Air Transfer Rate": +1,
    "Zone Air Heat Balance Outdoor Air Transfer Rate": +1,
    "Zone Air Heat Balance System Air Transfer Rate": +1,
    "Zone Air Heat Balance System Convective Heat Gain Rate": +1,
    "Zone Air Heat Balance Air Energy Storage Rate": -1,
    "Zone Air Heat Balance Deviation Rate": -1,
}

SIMPLIFY = {
    # Internal
    "Zone People Sensible Heating Energy": "People",
    "Zone Lights Total Heating Energy": "Lights",
    "Zone Electric Equipment Total Heating Energy": "Equipment",

    # HVAC
    "Zone Air Terminal Sensible Heating Energy": "Terminal heating",
    "Zone Air Terminal Sensible Cooling Energy": "Terminal cooling",
    "Zone Radiant HVAC Heating Energy": "Radiant heating",
    "Zone Radiant HVAC Cooling Energy": "Radiant cooling",
    "Baseboard Total Heating Energy": "Baseboard",

    # Transmission
    "Zone Opaque Surface Inside Faces Total Conduction Heat Gain Energy": "Opaque gain",
    "Zone Opaque Surface Inside Faces Total Conduction Heat Loss Energy": "Opaque loss",
    "Zone Windows Total Heat Gain Energy": "Window gain",
    "Zone Windows Total Heat Loss Energy": "Window loss",

    # Air exchange
    "Zone Infiltration Sensible Heat Gain Energy": "Infiltration gain",
    "Zone Infiltration Sensible Heat Loss Energy": "Infiltration loss",
    "Zone Ventilation Sensible Heat Gain Energy": "Ventilation gain",
    "Zone Ventilation Sensible Heat Loss Energy": "Ventilation loss",

    # Zone air balance terms
    "Zone Air Heat Balance Internal Convective Heat Gain Rate": "Internal convection",
    "Zone Air Heat Balance Surface Convection Rate": "Surface convection",
    "Zone Air Heat Balance Outdoor Air Transfer Rate": "Outdoor air transfer",
    "Zone Air Heat Balance Interzone Air Transfer Rate": "Interzone transfer",
    "Zone Air Heat Balance System Air Transfer Rate": "System air transfer",
    "Zone Air Heat Balance System Convective Heat Gain Rate": "System convection",
    "Zone Air Heat Balance Air Energy Storage Rate": "Air storage",
    "Zone Air Heat Balance Deviation Rate": "Balance deviation",
}


import textwrap

def short_vars(vars_list, max_chars=45):
    names = [SIMPLIFY.get(v, v) for v in vars_list]
    s = ", ".join(names)
    return s if len(s) <= max_chars else s[:max_chars-1] + "…"

def build_yticklabels():
    labels = []
    for cat in CATEGORY_MAP.keys():
        a_vars = CATEGORY_MAP[cat].get("A", [])
        b_vars = CATEGORY_MAP[cat].get("B", [])

        # Make it truly "two-line": category + compact mapping summary
        # (If you want 3 lines instead, split A and B onto separate lines.)
        a_txt = short_vars(a_vars, max_chars=40).replace("\n", " / ")
        b_txt = short_vars(b_vars, max_chars=40).replace("\n", " / ")

        labels.append(f"{cat}\nA: {short_vars(a_vars, 60)}\nB: {short_vars(b_vars, 60)}")
    return labels


# ---------------------------
# 2) Category mapping
#    (Edit this!)
# ---------------------------
# Each category can contain multiple variables from either source.
# Those will be stacked within that source's bar.
CATEGORY_MAP: Dict[str, Dict[str, List[str]]] = {
    "Internal gains": {
        "A": [
            "Zone People Sensible Heating Energy",
            "Zone Lights Total Heating Energy",
            "Zone Electric Equipment Total Heating Energy",
        ],
        "B": [
            "Zone Air Heat Balance Internal Convective Heat Gain Rate",
        ],
    },
    "Transmission (opaque + windows)": {
        "A": [
            "Zone Opaque Surface Inside Faces Total Conduction Heat Gain Energy",
            "Zone Opaque Surface Inside Faces Total Conduction Heat Loss Energy",
            "Zone Windows Total Heat Gain Energy",
            "Zone Windows Total Heat Loss Energy",
        ],
        "B": [
            "Zone Air Heat Balance Surface Convection Rate",
        ],
    },
    "Outdoor air exchange": {
        "A": [
            "Zone Infiltration Sensible Heat Gain Energy",
            "Zone Infiltration Sensible Heat Loss Energy",
            "Zone Ventilation Sensible Heat Gain Energy",
            "Zone Ventilation Sensible Heat Loss Energy",
        ],
        "B": [
            "Zone Air Heat Balance Outdoor Air Transfer Rate",
        ],
    },
    "Interzone transfer": {
        "A": [
            "Zone Interzone Air Transfer Heat Gain Energy",
            "Zone Interzone Air Transfer Heat Loss Energy",
        ],
        "B": [
            "Zone Air Heat Balance Interzone Air Transfer Rate",
        ],
    },
    "HVAC (delivered / system)": {
        "A": [
            "Zone Air Terminal Sensible Heating Energy",
            "Zone Air Terminal Sensible Cooling Energy",
            "Zone Radiant HVAC Heating Energy",
            "Zone Radiant HVAC Cooling Energy",
            "Baseboard Total Heating Energy",
        ],
        "B": [
            "Zone Air Heat Balance System Convective Heat Gain Rate",
            "Zone Air Heat Balance System Air Transfer Rate",
        ],
    },
    "Storage / residual": {
        "A": [
            "Zone Air Heat Balance Air Energy Storage Rate",
        ],
        "B": [
            "Zone Air Heat Balance Air Energy Storage Rate",
            "Zone Air Heat Balance Deviation Rate",
        ],
    },
}


# ---------------------------
# 3) Helpers
# ---------------------------

def _clean_col(col: str) -> str:
    # e.g. "Zone ...[Wh]" -> "Zone ..."
    return re.sub(r"\s*\[.*?\]\s*$", "", col).strip()

def load_totals_wh(csv_path: str | Path) -> pd.Series:
    df = pd.read_csv(csv_path)
    if len(df) < 1:
        raise ValueError("CSV has no rows.")
    df = df.rename(columns={c: _clean_col(c) for c in df.columns})
    # If there are multiple rows, sum them; if one row, that's fine too.
    totals = df.sum(axis=0, numeric_only=True)
    totals.name = "Wh"
    return totals

def signed_value_wh(totals_wh: pd.Series, var: str, sign: int) -> float:
    v = float(totals_wh.get(var, 0.0))
    return sign * v

def split_pos_neg(values: List[float]) -> Tuple[List[float], List[float]]:
    pos = [v for v in values if v > 0]
    neg = [v for v in values if v < 0]
    return pos, neg


def plot_grouped_signed_stacked(
    totals_wh: pd.Series,
    out_png: str = "combined_balance_overlay.png",
    unit: str = "kWh",
    source_labels: Tuple[str, str] = ("Aggregated", "Zone Air Balance"),
):
    # unit conversion
    factor = 1.0
    if unit.lower() == "kwh":
        factor = 1.0 / 1000.0
    elif unit.lower() == "wh":
        factor = 1.0
    else:
        raise ValueError("unit must be 'Wh' or 'kWh'")

    categories = list(CATEGORY_MAP.keys())
    y = list(range(len(categories)))

    # bar geometry
    bar_h = 0.36
    off = 0.20  # vertical offset between the two sources within a category

    fig, ax = plt.subplots(figsize=(12, 6))

    # We'll draw each category; for each, draw Source A and Source B at different y positions,
    # stacking components separately for positive and negative.
    for i, cat in enumerate(categories):
        # --- Source A ---
        vars_a = CATEGORY_MAP[cat].get("A", [])
        comps_a = []
        for v in vars_a:
            sign = SIGN_A.get(v, 1)
            comps_a.append(signed_value_wh(totals_wh, v, sign) * factor)

        pos_a, neg_a = split_pos_neg(comps_a)

        # stack positives to the right
        left_pos = 0.0
        for val in pos_a:
            ax.barh(i - off, val, left=left_pos, height=bar_h, label=None)
            left_pos += val

        # stack negatives to the left (more negative)
        left_neg = 0.0
        for val in neg_a:
            ax.barh(i - off, val, left=left_neg, height=bar_h, label=None)
            left_neg += val

        # --- Source B ---
        vars_b = CATEGORY_MAP[cat].get("B", [])
        comps_b = []
        for v in vars_b:
            sign = SIGN_B.get(v, 1)
            comps_b.append(signed_value_wh(totals_wh, v, sign) * factor)

        pos_b, neg_b = split_pos_neg(comps_b)

        left_pos = 0.0
        for val in pos_b:
            ax.barh(i + off, val, left=left_pos, height=bar_h, label=None, alpha=0.7, hatch="///")
            left_pos += val

        left_neg = 0.0
        for val in neg_b:
            ax.barh(i + off, val, left=left_neg, height=bar_h, label=None, alpha=0.7, hatch="///")
            left_neg += val

    # Cosmetics
    ax.axvline(0, linewidth=1)
    ax.set_yticks(y)
    ax.set_yticklabels(build_yticklabels(), fontsize=9)
    ax.invert_yaxis()
    ax.set_xlabel(f"Energy ({unit}, signed)")
    ax.set_title("Combined comparison: grouped + stacked (two balance approaches)")

    # Build a simple legend proxy for the two sources
    import matplotlib.patches as mpatches
    p_a = mpatches.Patch(label=source_labels[0])
    p_b = mpatches.Patch(label=source_labels[1], hatch="///", alpha=0.7)
    ax.legend(handles=[p_a, p_b], loc="upper right")

    ax.grid(True, axis="x", linestyle="--", linewidth=0.5)

    fig.tight_layout()
    fig.subplots_adjust(left=0.42)  # increase if needed (0.35–0.50 typical)
    fig.savefig(out_png, dpi=200)
    print(f"Saved: {out_png}")


# ---------------------------
# 4) Main
# ---------------------------
if __name__ == "__main__":
    CSV_PATH = r"F:\Repos\OrgGenSim\Output\run\017_results\report_variables_ZoneTimestep-Sum.csv"
    totals = load_totals_wh(CSV_PATH)
    plot_grouped_signed_stacked(
        totals_wh=totals,
        out_png="combined_balance_overlay.png",
        unit="kWh",
        source_labels=("Aggregated balance", "Zone Air Heat Balance"),
    )
