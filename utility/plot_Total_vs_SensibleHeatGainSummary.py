"""
plot_A_vs_SensibleHeatGainSummary.py

Compare TWO sensible-zone-balance approaches:

A) Variable-based "SIGN_A" aggregation (from your CSV of Output:Variable totals; typically Wh)
B) EnergyPlus tabular report: "Report: Sensible Heat Gain Summary"
   Table: "Annual Building Sensible Heat Gain Components" (typically GJ)
   Row: "Total Facility" (or sum of zones if that row is missing)

Output:
- A vs B grouped signed stacked horizontal bars (same plotting style as plot_combine.py)
- residual/net row for both approaches

Notes / caveats:
- Tabular report (B) does NOT include "Ventilation" explicitly (often only infiltration + interzone + surfaces + windows + HVAC terms).
  This script therefore either:
    (i) keeps "Ventilation" as an A-only category, or
    (ii) merges it into Outdoor Air (and you accept mismatch).
  See CATEGORY_MAP below.

- Column signs in the tabular report:
  In your eplustbl.htm, the "Removal" columns already appear as negative values for "Total Facility".
  Still, the script contains a safety rule: if a column name contains "Removal" and the parsed value is positive,
  it will be negated.

Dependencies: pandas, matplotlib
"""

from __future__ import annotations

import re
from io import StringIO
import warnings
from pathlib import Path
from typing import Dict, List, Tuple

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib as mpl
import matplotlib.patches as mpatches
import matplotlib.colors as mcolors


# ---------------------------------------------------------------------
# 1) Source A: variable sign dictionary (from your existing script)
# ---------------------------------------------------------------------

SIGN_A: Dict[str, int] = {
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

    # Window split (aggregated)
    "Zone Windows Total Heat Gain Energy": +1,
    "Zone Windows Total Heat Loss Energy": -1,

    # Optional interzone
    "Zone Interzone Air Transfer Heat Gain Energy": +1,
    "Zone Interzone Air Transfer Heat Loss Energy": -1,

    # Storage (air) - often used as a "residual-like" term in aggregated balances
    "Zone Air Heat Balance Air Energy Storage Rate": +1,
}


# ---------------------------------------------------------------------
# 2) Source B: tabular columns from "Sensible Heat Gain Summary"
# ---------------------------------------------------------------------
# We treat the HTML table columns as "variables" for plotting.
# Keys must match the cleaned column headers extracted from the HTML table (see _clean_col()).

# A small simplifier for y-axis annotations
SIMPLIFY_A: Dict[str, str] = {
    "Zone People Total Heating Energy": "People",
    "Zone Lights Total Heating Energy": "Lights",
    "Zone Electric Equipment Total Heating Energy": "Equipment",
    "Zone Air Terminal Sensible Heating Energy": "Terminal heat",
    "Zone Air Terminal Sensible Cooling Energy": "Terminal cool",
    "Zone Radiant HVAC Heating Energy": "Radiant heat",
    "Zone Radiant HVAC Cooling Energy": "Radiant cool",
    "Baseboard Total Heating Energy": "Baseboard",
    "Zone Opaque Surface Inside Faces Total Conduction Heat Gain Energy": "Opaque Conduction gain",
    "Zone Opaque Surface Inside Faces Total Conduction Heat Loss Energy": "Opaque Conduction loss",
    "Zone Windows Total Heat Gain Energy": "Window gain",
    "Zone Windows Total Heat Loss Energy": "Window loss",
    "Zone Infiltration Total Heat Gain Energy": "Infil gain",
    "Zone Infiltration Total Heat Loss Energy": "Infil loss",
    "Zone Ventilation Total Heat Gain Energy": "Vent gain",
    "Zone Ventilation Total Heat Loss Energy": "Vent loss",
    "Zone Interzone Air Transfer Heat Gain Energy": "Interzone gain",
    "Zone Interzone Air Transfer Heat Loss Energy": "Interzone loss",
    "Zone Air Heat Balance Air Energy Storage Rate": "Air storage",
}

SIMPLIFY_B: Dict[str, str] = {
    "HVAC Zone Eq & Other Sensible Air Heating": "HVAC zone eq heat",
    "HVAC Zone Eq & Other Sensible Air Cooling": "HVAC zone eq cool",
    "HVAC Terminal Unit Sensible Air Heating": "Terminal heat",
    "HVAC Terminal Unit Sensible Air Cooling": "Terminal cool",
    "HVAC Input Heated Surface Heating": "Heated surface",
    "HVAC Input Cooled Surface Cooling": "Cooled surface",
    "People Sensible Heat Addition": "People",
    "Lights Sensible Heat Addition": "Lights",
    "Equipment Sensible Heat Addition": "Equipment add",
    "Equipment Sensible Heat Removal": "Equipment rem",
    "Window Heat Addition": "Window add",
    "Window Heat Removal": "Window rem",
    "Interzone Air Transfer Heat Addition": "Interzone add",
    "Interzone Air Transfer Heat Removal": "Interzone rem",
    "Infiltration Heat Addition": "Infil add",
    "Infiltration Heat Removal": "Infil rem",
    "Opaque Surface Conduction and Other Heat Addition": "Opaque add",
    "Opaque Surface Conduction and Other Heat Removal": "Opaque rem",
}

# ---------------------------------------------------------------------
# 2b) Source B signs for tabular report (known-working approach)
# ---------------------------------------------------------------------
HTML_COL_SIGNS: Dict[str, int] = {
    "HVAC Zone Eq & Other Sensible Air Heating": +1,
    "HVAC Zone Eq & Other Sensible Air Cooling": -1,
    "HVAC Terminal Unit Sensible Air Heating": +1,
    "HVAC Terminal Unit Sensible Air Cooling": -1,
    "HVAC Input Heated Surface Heating": +1,
    "HVAC Input Cooled Surface Cooling": -1,
    "People Sensible Heat Addition": +1,
    "Lights Sensible Heat Addition": +1,
    "Equipment Sensible Heat Addition": +1,
    "Window Heat Addition": +1,
    "Interzone Air Transfer Heat Addition": +1,
    "Infiltration Heat Addition": +1,
    "Opaque Surface Conduction and Other Heat Addition": +1,
    "Equipment Sensible Heat Removal": -1,
    "Window Heat Removal": -1,
    "Interzone Air Transfer Heat Removal": -1,
    "Infiltration Heat Removal": -1,
    "Opaque Surface Conduction and Other Heat Removal": -1,
}

def _normalize_html_header(h: str) -> str:
    h = re.sub(r"\s*\[.*?\]\s*$", "", str(h))  # strip [GJ]
    h = h.replace("&amp;", "&")
    h = re.sub(r"\s+", " ", h).strip()
    return h


# ---------------------------------------------------------------------
# 3) Category mapping (EDIT THIS!)
# ---------------------------------------------------------------------
# The key design choice: do you want "Ventilation" visible as A-only,
# or lump it into Outdoor Air with B being infiltration-only?
#
# Default below:
# - Split "Infiltration" and "Ventilation" (Ventilation is A-only; B has none)
# - Split windows vs opaque (because tabular does)
# - Keep "Equipment Sensible Heat Removal" as its own sink (A has none)

CATEGORY_MAP: Dict[str, Dict[str, List[str]]] = {
    "HVAC (delivered / system)": {
        "A": [
            "Zone Air Terminal Sensible Heating Energy",
            "Zone Air Terminal Sensible Cooling Energy",
            "Zone Radiant HVAC Heating Energy",
            "Zone Radiant HVAC Cooling Energy",
            "Baseboard Total Heating Energy",
        ],
        "B": [
            "HVAC Zone Eq & Other Sensible Air Heating",
            "HVAC Zone Eq & Other Sensible Air Cooling",
            "HVAC Terminal Unit Sensible Air Heating",
            "HVAC Terminal Unit Sensible Air Cooling",
            "HVAC Input Heated Surface Heating",
            "HVAC Input Cooled Surface Cooling",
        ],
    },
    "Internal gains": {
        "A": [
            "Zone People Total Heating Energy",
            "Zone Lights Total Heating Energy",
            "Zone Electric Equipment Total Heating Energy",
        ],
        "B": [
            "People Sensible Heat Addition",
            "Lights Sensible Heat Addition",
            "Equipment Sensible Heat Addition",
        ],
    },
    "Internal sinks (equipment removal)": {
        "A": [],
        "B": [
            "Equipment Sensible Heat Removal",
        ],
    },
    "Transmission (opaque)": {
        "A": [
            "Zone Opaque Surface Inside Faces Total Conduction Heat Gain Energy",
            "Zone Opaque Surface Inside Faces Total Conduction Heat Loss Energy",
        ],
        "B": [
            "Opaque Surface Conduction and Other Heat Addition",
            "Opaque Surface Conduction and Other Heat Removal",
        ],
    },
    "Transmission (windows)": {
        "A": [
            "Zone Windows Total Heat Gain Energy",
            "Zone Windows Total Heat Loss Energy",
        ],
        "B": [
            "Window Heat Addition",
            "Window Heat Removal",
        ],
    },
    "Interzone air transfer": {
        "A": [
            "Zone Interzone Air Transfer Heat Gain Energy",
            "Zone Interzone Air Transfer Heat Loss Energy",
        ],
        "B": [
            "Interzone Air Transfer Heat Addition",
            "Interzone Air Transfer Heat Removal",
        ],
    },
    "Infiltration & Ventilation": {
        "A": [
            "Zone Infiltration Total Heat Gain Energy",
            "Zone Infiltration Total Heat Loss Energy",
            "Zone Ventilation Total Heat Gain Energy",
            "Zone Ventilation Total Heat Loss Energy",
        ],
        "B": [
            "Infiltration Heat Addition",
            "Infiltration Heat Removal",
        ],
    },
    "Storage / other (A-only)": {
        "A": [
            "Zone Air Heat Balance Air Energy Storage Rate",
        ],
        "B": [],
    },
}


# ---------------------------------------------------------------------
# 4) Helpers
# ---------------------------------------------------------------------

def _clean_col(col: str) -> str:
    """
    Remove unit suffixes like ' [GJ]' and trim.
    Also unescape HTML leftovers in column headers as needed.
    """
    s = str(col)
    s = s.replace("&amp;", "&")
    s = re.sub(r"\s*\[.*?\]\s*$", "", s).strip()
    return s


def load_totals_wh(csv_path: str | Path) -> pd.Series:
    """
    Load a wide CSV with one column per variable and many timesteps,
    return column sums (Wh).
    """
    df = pd.read_csv(csv_path)
    if df.shape[0] < 1:
        raise ValueError("CSV has no rows.")
    df = df.rename(columns={c: _clean_col(c) for c in df.columns})
    totals = df.sum(axis=0, numeric_only=True)
    totals.name = "Wh"
    return totals


def signed_value_a(totals_wh: pd.Series, var: str, factor: float) -> float:
    sign = SIGN_A.get(var, 1)
    return float(totals_wh.get(var, 0.0)) * sign * factor


def _negate_if_needed(colname: str, val: float) -> float:
    """
    Safety rule: some versions may show 'Removal' columns as positive magnitudes.
    If so, make them negative.
    """
    if val is None:
        return 0.0
    if "Removal" in colname and val > 0:
        return -val
    return val


def parse_sensible_gain_summary_totalfacility(html_path: str | Path) -> pd.Series:
    """
    Known-working parser (borrowed from plot_three_sources.py logic):
    Extract the 'Total Facility' row from:
      Sensible Heat Gain Summary -> Annual Building Sensible Heat Gain Components

    Robust to:
      - header row embedded as first data row (columns are 0..N)
      - proper header row

    Returns:
      pd.Series indexed by normalized column names, values in GJ (signed).
    """
    from io import StringIO
    html_path = Path(html_path)

    with open(html_path, "r", encoding="utf-8", errors="ignore") as f:
        html_text = f.read()

    tables = pd.read_html(StringIO(html_text))
    target = None

    required = {
        "People Sensible Heat Addition",
        "Window Heat Addition",
        "Opaque Surface Conduction and Other Heat Addition",
    }

    for t in tables:
        if t.shape[0] < 2 or t.shape[1] < 8:
            continue

        # Case: header is embedded as first row
        first_row = [str(x) for x in t.iloc[0].tolist()]
        if any("People Sensible Heat Addition" in x for x in first_row):
            headers = [_normalize_html_header(x) for x in first_row]
            t2 = t.iloc[1:].copy()
            t2.columns = headers
        else:
            headers = [_normalize_html_header(c) for c in t.columns]
            t2 = t.copy()
            t2.columns = headers

        if required.issubset(set(t2.columns)):
            target = t2
            break

    if target is None:
        raise ValueError("Could not find the 'Annual Building Sensible Heat Gain Components' table in the HTML file.")

    first_col = target.columns[0]
    mask = target[first_col].astype(str).str.strip().str.lower().eq("total facility")
    if not mask.any():
        raise ValueError("Could not find 'Total Facility' row in the HTML sensible heat gain table.")

    row = target.loc[mask].iloc[0]

    out = {}
    for col in target.columns[1:]:
        base = _normalize_html_header(col)
        if base not in HTML_COL_SIGNS:
            continue
        v_gj = pd.to_numeric(row[col], errors="coerce")
        if pd.isna(v_gj):
            continue
        out[base] = abs(float(v_gj)) * float(HTML_COL_SIGNS[base])

    return pd.Series(out, name="GJ")



def pretty_vars_a(vars_list: List[str], max_chars: int = 60) -> str:
    names = [SIMPLIFY_A.get(v, v) for v in vars_list]
    s = ", ".join(names) if names else "—"
    return s if len(s) <= max_chars else s[: max_chars - 1] + "…"


def pretty_vars_b(vars_list: List[str], max_chars: int = 60) -> str:
    names = [SIMPLIFY_B.get(v, v) for v in vars_list]
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
        labels.append(f"{cat}\nA: {pretty_vars_a(a_vars)}\nB: {pretty_vars_b(b_vars)}")
    return labels


def collect_all_a_vars() -> List[str]:
    seen = set()
    out: List[str] = []
    for cat in CATEGORY_MAP:
        for v in CATEGORY_MAP[cat].get("A", []):
            if v not in seen:
                seen.add(v)
                out.append(v)
    return out


def collect_all_b_cols() -> List[str]:
    seen = set()
    out: List[str] = []
    for cat in CATEGORY_MAP:
        for v in CATEGORY_MAP[cat].get("B", []):
            if v not in seen:
                seen.add(v)
                out.append(v)
    return out


def compute_net_a(totals_wh: pd.Series, factor: float) -> float:
    net = 0.0
    for v in collect_all_a_vars():
        net += signed_value_a(totals_wh, v, factor)
    return net


def compute_net_b(totals_gj: pd.Series, factor: float) -> float:
    """
    totals_gj is the tabular Series (GJ). factor is GJ->unit (e.g., MWh).
    """
    net = 0.0
    for c in collect_all_b_cols():
        net += float(totals_gj.get(c, 0.0)) * factor
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
    """Add label centered in the segment if segment is wide enough."""
    if abs(width) < min_abs_width:
        return
    x_center = x_left + width / 2.0
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
    totals_wh_a: pd.Series,
    totals_gj_b: pd.Series,
    out_png: str = "combined_A_vs_SensibleHeatGainSummary_MWh.png",
    unit: str = "MWh",
    source_labels: Tuple[str, str] = ("SIGN_A (CSV vars)", "Tabular: Sensible Heat Gain Summary"),
    add_residual_row: bool = True,
    label_segments: bool = True,
):
    # Unit conversion
    unit_l = unit.lower()
    if unit_l == "mwh":
        factor_a = 1.0 / 1_000_000.0  # Wh -> MWh
        factor_b = 277.77777777777777  # GJ -> kWh
        factor_b = factor_b / 1000.0   # GJ -> MWh
        unit_disp = "MWh"
    elif unit_l == "kwh":
        factor_a = 1.0 / 1000.0
        factor_b = 277.77777777777777  # GJ -> kWh
        unit_disp = "kWh"
    elif unit_l == "wh":
        factor_a = 1.0
        factor_b = 277.77777777777777 * 1000.0  # GJ -> Wh
        unit_disp = "Wh"
    else:
        raise ValueError("unit must be 'Wh', 'kWh', or 'MWh'")

    categories = list(CATEGORY_MAP.keys())

    net_a = compute_net_a(totals_wh_a, factor_a)
    net_b = compute_net_b(totals_gj_b, factor_b)
    if add_residual_row:
        categories = categories + ["Residual (NET)"]

    y = list(range(len(categories)))
    bar_h = 0.36
    off = 0.20

    mpl.rcParams["hatch.linewidth"] = 1.3

    cycle = plt.rcParams["axes.prop_cycle"].by_key()["color"]
    cat_colors: Dict[str, str] = {}
    for idx, cat in enumerate(categories):
        cat_colors[cat] = "0.35" if cat == "Residual (NET)" else cycle[idx % len(cycle)]

    fig, ax = plt.subplots(figsize=(13.8, 8.4))

    totals_for_labels: List[Tuple[float, float]] = []
    segment_label_records: List[Tuple[float, float, float, bool]] = []
    segment_label_texts: List[str] = []

    for i, cat in enumerate(categories):
        if cat == "Residual (NET)":
            ax.barh(i - off, net_a, height=bar_h, color=cat_colors[cat], alpha=0.95)
            totals_for_labels.append((net_a, i - off))

            ax.barh(
                i + off, net_b, height=bar_h,
                color=cat_colors[cat], alpha=0.35,
                hatch="///", edgecolor="white", linewidth=0.0
            )
            totals_for_labels.append((net_b, i + off))
            continue

        base = cat_colors[cat]

        # -------------------------
        # A segments (from CSV vars)
        # -------------------------
        vars_a = CATEGORY_MAP[cat].get("A", [])
        comps_a = [signed_value_a(totals_wh_a, v, factor_a) for v in vars_a]
        total_a = sum(comps_a)

        pos_items_a = [(v, val) for v, val in zip(vars_a, comps_a) if val > 0]
        neg_items_a = [(v, val) for v, val in zip(vars_a, comps_a) if val < 0]

        left = 0.0
        for j, (vname, val) in enumerate(pos_items_a):
            c = shade_color(base, j, max(1, len(pos_items_a)), lighten_min=0.00, lighten_max=0.35)
            ax.barh(i - off, val, left=left, height=bar_h, color=c, alpha=0.95)
            if label_segments:
                segment_label_records.append((left, val, i - off, False))
                segment_label_texts.append(f"{val:.1f}")
            left += val

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
        # B segments (from tabular columns)
        # -------------------------
        cols_b = CATEGORY_MAP[cat].get("B", [])
        comps_b = [float(totals_gj_b.get(c, 0.0)) * factor_b for c in cols_b]
        total_b = sum(comps_b)

        pos_items_b = [(c, val) for c, val in zip(cols_b, comps_b) if val > 0]
        neg_items_b = [(c, val) for c, val in zip(cols_b, comps_b) if val < 0]

        left = 0.0
        for j, (cname, val) in enumerate(pos_items_b):
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
        for j, (cname, val) in enumerate(neg_items_b):
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

    ax.axvline(0, linewidth=1)
    labels = build_yticklabels(categories)
    ax.set_yticks(y)
    ax.set_yticklabels(labels, fontsize=9)
    ax.invert_yaxis()

    ax.set_xlabel(f"Energy ({unit_disp}, signed)")
    ax.set_title("Reconciled sensible balance: SIGN_A (vars) vs Tabular Sensible Heat Gain Summary")
    ax.grid(True, axis="x", linestyle="--", linewidth=0.5)

    p_a = mpatches.Patch(facecolor="0.2", alpha=0.95, label=source_labels[0])
    p_b = mpatches.Patch(facecolor="0.2", alpha=0.55, hatch="///", edgecolor="white", label=source_labels[1])
    ax.legend(handles=[p_a, p_b], loc="upper right")

    fig.subplots_adjust(left=0.48)

    fig.canvas.draw()
    xmin, xmax = ax.get_xlim()
    xpad = 0.01 * (xmax - xmin)

    for total, y_pos in totals_for_labels:
        txt = "0.00" if abs(total) < 1e-12 else f"{total:.2f}"
        x_text = total + (xpad if total >= 0 else -xpad)
        ha = "left" if total >= 0 else "right"
        ax.text(x_text, y_pos, txt, va="center", ha=ha, fontsize=9)

    if label_segments and segment_label_records:
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
    # Adjust these paths
    CSV_PATH = r"F:\Repos\OrgGenSim\Output\run\017_results\report_variables_ZoneTimestep-Sum.csv"
    HTML_PATH = r"F:\Repos\OrgGenSim\Output\run\eplustbl.htm"

    totals_a = load_totals_wh(CSV_PATH)
    totals_b = parse_sensible_gain_summary_totalfacility(HTML_PATH)

    plot_grouped_signed_stacked(
        totals_wh_a=totals_a,
        totals_gj_b=totals_b,
        out_png="combined_A_vs_SensibleHeatGainSummary_MWh_labeled.png",
        unit="MWh",
        source_labels=("SIGN_A (CSV vars)", "Tabular Sensible Heat Gain Summary"),
        add_residual_row=True,
        label_segments=True,
    )
