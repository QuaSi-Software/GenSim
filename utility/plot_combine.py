"""
plot_combine.py

Grouped comparison bar chart from TWO balance approaches with:
- per-category base color
- within-bar stacked segments shaded (distinguish variables)
- Zone Air Balance (B) uses lighter shade + white hatch lines
- extra "Residual (NET)" row
- units in MWh (CSV values assumed Wh)
- numeric labels for:
    * TOTAL of each bar (A and B per category)
    * EACH stacked segment (each variable portion)
"""

from __future__ import annotations

import re
from pathlib import Path
from typing import Dict, List, Tuple

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib as mpl
import matplotlib.patches as mpatches
import matplotlib.colors as mcolors


# ---------------------------------------------------------------------
# 1) Variable sign dictionaries (your two data sources)
# ---------------------------------------------------------------------

SIGN_A: Dict[str, int] = {
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

SIGN_B: Dict[str, int] = {
    "Zone Air Heat Balance Internal Convective Heat Gain Rate": +1,
    "Zone Air Heat Balance Surface Convection Rate": +1,
    "Zone Air Heat Balance Interzone Air Transfer Rate": +1,
    "Zone Air Heat Balance Outdoor Air Transfer Rate": +1,
    "Zone Air Heat Balance System Air Transfer Rate": +1,
    "Zone Air Heat Balance System Convective Heat Gain Rate": +1,
    "Zone Air Heat Balance Air Energy Storage Rate": -1,
    "Zone Air Heat Balance Deviation Rate": -1,
}


# ---------------------------------------------------------------------
# 2) Category mapping (EDIT THIS to match your conceptual reconciliation)
# ---------------------------------------------------------------------

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
    "Storage / deviation": {
        "A": [
            "Zone Air Heat Balance Air Energy Storage Rate",
        ],
        "B": [
            "Zone Air Heat Balance Air Energy Storage Rate",
            "Zone Air Heat Balance Deviation Rate",
        ],
    },
}


# ---------------------------------------------------------------------
# 3) Simplified variable names for axis annotations (optional)
# ---------------------------------------------------------------------

SIMPLIFY: Dict[str, str] = {
    "Zone People Sensible Heating Energy": "People",
    "Zone Lights Total Heating Energy": "Lights",
    "Zone Electric Equipment Total Heating Energy": "Equipment",

    "Zone Air Terminal Sensible Heating Energy": "Terminal heat",
    "Zone Air Terminal Sensible Cooling Energy": "Terminal cool",
    "Zone Radiant HVAC Heating Energy": "Radiant heat",
    "Zone Radiant HVAC Cooling Energy": "Radiant cool",
    "Baseboard Total Heating Energy": "Baseboard",

    "Zone Opaque Surface Inside Faces Total Conduction Heat Gain Energy": "Opaque gain",
    "Zone Opaque Surface Inside Faces Total Conduction Heat Loss Energy": "Opaque loss",
    "Zone Windows Total Heat Gain Energy": "Window gain",
    "Zone Windows Total Heat Loss Energy": "Window loss",

    "Zone Infiltration Sensible Heat Gain Energy": "Infil gain",
    "Zone Infiltration Sensible Heat Loss Energy": "Infil loss",
    "Zone Ventilation Sensible Heat Gain Energy": "Vent gain",
    "Zone Ventilation Sensible Heat Loss Energy": "Vent loss",

    "Zone Interzone Air Transfer Heat Gain Energy": "Interzone gain",
    "Zone Interzone Air Transfer Heat Loss Energy": "Interzone loss",

    "Zone Air Heat Balance Internal Convective Heat Gain Rate": "Internal conv.",
    "Zone Air Heat Balance Surface Convection Rate": "Surface conv.",
    "Zone Air Heat Balance Outdoor Air Transfer Rate": "Outdoor air",
    "Zone Air Heat Balance Interzone Air Transfer Rate": "Interzone air",
    "Zone Air Heat Balance System Air Transfer Rate": "System air",
    "Zone Air Heat Balance System Convective Heat Gain Rate": "System conv.",
    "Zone Air Heat Balance Air Energy Storage Rate": "Air storage",
    "Zone Air Heat Balance Deviation Rate": "Deviation",
}


# ---------------------------------------------------------------------
# 4) Helpers
# ---------------------------------------------------------------------

def _clean_col(col: str) -> str:
    return re.sub(r"\s*\[.*?\]\s*$", "", str(col)).strip()


def load_totals_wh(csv_path: str | Path) -> pd.Series:
    df = pd.read_csv(csv_path)
    if df.shape[0] < 1:
        raise ValueError("CSV has no rows.")
    df = df.rename(columns={c: _clean_col(c) for c in df.columns})
    totals = df.sum(axis=0, numeric_only=True)
    totals.name = "Wh"
    return totals


def signed_value_wh(totals_wh: pd.Series, var: str, sign: int) -> float:
    return float(totals_wh.get(var, 0.0)) * sign


def pretty_vars(vars_list: List[str], max_chars: int = 60) -> str:
    names = [SIMPLIFY.get(v, v) for v in vars_list]
    s = ", ".join(names) if names else "—"
    return s if len(s) <= max_chars else s[: max_chars - 1] + "…"


def build_yticklabels(categories: List[str]) -> List[str]:
    labels: List[str] = []
    for cat in categories:
        if cat == "Residual (NET)":
            labels.append("Residual (NET)\nA: sum of shown terms\nB: sum of shown terms")
            continue
        a_vars = CATEGORY_MAP[cat].get("A", [])
        b_vars = CATEGORY_MAP[cat].get("B", [])
        labels.append(f"{cat}\nA: {pretty_vars(a_vars)}\nB: {pretty_vars(b_vars)}")
    return labels


def collect_all_vars(which: str) -> List[str]:
    seen = set()
    out: List[str] = []
    for cat in CATEGORY_MAP:
        for v in CATEGORY_MAP[cat].get(which, []):
            if v not in seen:
                seen.add(v)
                out.append(v)
    return out


def compute_net(totals_wh: pd.Series, which: str, factor: float) -> float:
    if which == "A":
        vars_used = collect_all_vars("A")
        sign_map = SIGN_A
    elif which == "B":
        vars_used = collect_all_vars("B")
        sign_map = SIGN_B
    else:
        raise ValueError("which must be 'A' or 'B'")

    net = 0.0
    for v in vars_used:
        net += signed_value_wh(totals_wh, v, sign_map.get(v, 1)) * factor
    return net


def shade_color(base_color: str, idx: int, n: int, lighten_min: float, lighten_max: float):
    """Blend base color toward white by a factor t in [lighten_min, lighten_max]."""
    rgb = mcolors.to_rgb(base_color)
    if n <= 1:
        t = (lighten_min + lighten_max) / 2.0
    else:
        t = lighten_min + (lighten_max - lighten_min) * (idx / (n - 1))
    return (rgb[0] + (1 - rgb[0]) * t, rgb[1] + (1 - rgb[1]) * t, rgb[2] + (1 - rgb[2]) * t)


def add_segment_label(
    ax,
    x_left: float,
    width: float,
    y_center: float,
    text: str,
    min_abs_width: float,
    hatch: bool = False,
):
    """
    Add label centered in the segment if segment is wide enough.
    min_abs_width is in data units (same as x-axis units).
    """
    if abs(width) < min_abs_width:
        return

    x_center = x_left + width / 2.0
    # White text reads better on darker fills; on hatched light bars, black is usually better.
    color = "black" if hatch else "white"

    ax.text(
        x_center, y_center, text,
        va="center", ha="center",
        fontsize=8,
        color=color,
        clip_on=True,
    )


# ---------------------------------------------------------------------
# 5) Plot
# ---------------------------------------------------------------------

def plot_grouped_signed_stacked(
    totals_wh: pd.Series,
    out_png: str = "combined_balance_overlay_MWh.png",
    unit: str = "MWh",
    source_labels: Tuple[str, str] = ("Aggregated balance", "Zone Air Heat Balance"),
    add_residual_row: bool = True,
    label_segments: bool = True,
):
    # Unit conversion (CSV in Wh)
    unit_l = unit.lower()
    if unit_l == "mwh":
        factor = 1.0 / 1_000_000.0  # Wh -> MWh
        unit_disp = "MWh"
    elif unit_l == "kwh":
        factor = 1.0 / 1000.0
        unit_disp = "kWh"
    elif unit_l == "wh":
        factor = 1.0
        unit_disp = "Wh"
    else:
        raise ValueError("unit must be 'Wh', 'kWh', or 'MWh'")

    categories = list(CATEGORY_MAP.keys())

    net_a = compute_net(totals_wh, "A", factor)
    net_b = compute_net(totals_wh, "B", factor)
    if add_residual_row:
        categories = categories + ["Residual (NET)"]

    y = list(range(len(categories)))

    bar_h = 0.36
    off = 0.20

    # Hatch styling ("white lines")
    mpl.rcParams["hatch.linewidth"] = 1.3

    # One base color per category
    cycle = plt.rcParams["axes.prop_cycle"].by_key()["color"]
    cat_colors: Dict[str, str] = {}
    for idx, cat in enumerate(categories):
        cat_colors[cat] = "0.35" if cat == "Residual (NET)" else cycle[idx % len(cycle)]

    fig, ax = plt.subplots(figsize=(13.5, 7.8))

    # collect totals to label after x-limits known
    totals_for_labels: List[Tuple[float, float]] = []  # (total_value, y_pos)

    # We need min segment width in data units, so compute it after first draw;
    # but we can approximate using a fraction of overall magnitude.
    # We'll update it after all bars are placed by looking at x-lims.
    segment_label_records: List[Tuple[float, float, float, bool]] = []
    # records: (x_left, width, y_center, hatch_flag) + text stored separately in a parallel list
    segment_label_texts: List[str] = []

    for i, cat in enumerate(categories):
        if cat == "Residual (NET)":
            # A residual
            ax.barh(i - off, net_a, height=bar_h, color=cat_colors[cat], alpha=0.95)
            totals_for_labels.append((net_a, i - off))

            # B residual (hatched)
            ax.barh(
                i + off, net_b, height=bar_h,
                color=cat_colors[cat], alpha=0.35,
                hatch="///", edgecolor="white", linewidth=0.0
            )
            totals_for_labels.append((net_b, i + off))
            continue

        base = cat_colors[cat]

        # -------------------------
        # Source A
        # -------------------------
        vars_a = CATEGORY_MAP[cat].get("A", [])
        comps_a = [signed_value_wh(totals_wh, v, SIGN_A.get(v, 1)) * factor for v in vars_a]
        total_a = sum(comps_a)

        # Stack positives and negatives separately (preserve sign)
        pos_items_a = [(v, val) for v, val in zip(vars_a, comps_a) if val > 0]
        neg_items_a = [(v, val) for v, val in zip(vars_a, comps_a) if val < 0]

        # positive stack
        left = 0.0
        for j, (vname, val) in enumerate(pos_items_a):
            c = shade_color(base, j, max(1, len(pos_items_a)), lighten_min=0.00, lighten_max=0.35)
            ax.barh(i - off, val, left=left, height=bar_h, color=c, alpha=0.95)

            if label_segments:
                # store record; label later when we know min_abs_width
                segment_label_records.append((left, val, i - off, False))
                segment_label_texts.append(f"{val:.1f}")

            left += val

        # negative stack
        left = 0.0
        for j, (vname, val) in enumerate(neg_items_a):
            c = shade_color(base, j, max(1, len(neg_items_a)), lighten_min=0.00, lighten_max=0.35)
            ax.barh(i - off, val, left=left, height=bar_h, color=c, alpha=0.95)

            if label_segments:
                segment_label_records.append((left, val, i - off, False))
                segment_label_texts.append(f"{val:.1f}")

            left += val

        totals_for_labels.append((total_a, i - off))

        # -------------------------
        # Source B (lighter + hatch)
        # -------------------------
        vars_b = CATEGORY_MAP[cat].get("B", [])
        comps_b = [signed_value_wh(totals_wh, v, SIGN_B.get(v, 1)) * factor for v in vars_b]
        total_b = sum(comps_b)

        pos_items_b = [(v, val) for v, val in zip(vars_b, comps_b) if val > 0]
        neg_items_b = [(v, val) for v, val in zip(vars_b, comps_b) if val < 0]

        left = 0.0
        for j, (vname, val) in enumerate(pos_items_b):
            c = shade_color(base, j, max(1, len(pos_items_b)), lighten_min=0.35, lighten_max=0.75)
            ax.barh(
                i + off, val, left=left, height=bar_h,
                color=c, alpha=0.65,
                hatch="///", edgecolor="white", linewidth=0.0
            )

            if label_segments:
                segment_label_records.append((left, val, i + off, True))
                segment_label_texts.append(f"{val:.1f}")

            left += val

        left = 0.0
        for j, (vname, val) in enumerate(neg_items_b):
            c = shade_color(base, j, max(1, len(neg_items_b)), lighten_min=0.35, lighten_max=0.75)
            ax.barh(
                i + off, val, left=left, height=bar_h,
                color=c, alpha=0.65,
                hatch="///", edgecolor="white", linewidth=0.0
            )

            if label_segments:
                segment_label_records.append((left, val, i + off, True))
                segment_label_texts.append(f"{val:.1f}")

            left += val

        totals_for_labels.append((total_b, i + off))

    # Axis cosmetics
    ax.axvline(0, linewidth=1)

    labels = build_yticklabels(categories)
    assert len(labels) == len(y), f"Tick/label mismatch: {len(y)} ticks vs {len(labels)} labels"
    ax.set_yticks(y)
    ax.set_yticklabels(labels, fontsize=9)
    ax.invert_yaxis()

    ax.set_xlabel(f"Energy ({unit_disp}, signed)")
    ax.set_title("Reconciled zone sensible balance: Aggregated vs EnergyPlus Zone Air Heat Balance")
    ax.grid(True, axis="x", linestyle="--", linewidth=0.5)

    # Legend encodes approach style (color encodes topic)
    p_a = mpatches.Patch(facecolor="0.2", alpha=0.95, label=source_labels[0])
    p_b = mpatches.Patch(facecolor="0.2", alpha=0.55, hatch="///", edgecolor="white", label=source_labels[1])
    ax.legend(handles=[p_a, p_b], loc="upper right")

    # Room for 3-line y labels
    fig.subplots_adjust(left=0.46)

    # Render once to get axis limits
    fig.canvas.draw()
    xmin, xmax = ax.get_xlim()
    xpad = 0.01 * (xmax - xmin)

    # ---- TOTAL labels at bar end ----
    for total, y_pos in totals_for_labels:
        txt = "0.00" if abs(total) < 1e-12 else f"{total:.2f}"
        x_text = total + (xpad if total >= 0 else -xpad)
        ha = "left" if total >= 0 else "right"
        ax.text(x_text, y_pos, txt, va="center", ha=ha, fontsize=9)

    # ---- SEGMENT labels inside each portion ----
    if label_segments and segment_label_records:
        # label only segments >= 1.5% of x-range (tune this)
        min_abs_width = 0.015 * (xmax - xmin)

        for (x_left, width, y_center, hatch_flag), text in zip(segment_label_records, segment_label_texts):
            add_segment_label(
                ax=ax,
                x_left=x_left,
                width=width,
                y_center=y_center,
                text=text,
                min_abs_width=min_abs_width,
                hatch=hatch_flag,
            )

    fig.tight_layout()
    fig.savefig(out_png, dpi=240)
    print(f"Saved: {out_png}")


# ---------------------------------------------------------------------
# 6) Main
# ---------------------------------------------------------------------

if __name__ == "__main__":
    CSV_PATH = r"F:\Repos\OrgGenSim\Output\run\017_results\report_variables_ZoneTimestep-Sum.csv"  # adjust as needed
    totals = load_totals_wh(CSV_PATH)

    plot_grouped_signed_stacked(
        totals_wh=totals,
        out_png="combined_balance_overlay_MWh_labeled.png",
        unit="MWh",
        source_labels=("Aggregated balance", "Zone Air Heat Balance"),
        add_residual_row=True,
        label_segments=True,
    )
