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

    # Storage (air) - often used as a "residual-like" term in aggregated balances
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
# 2) Source B: tabular columns from "Sensible Heat Gain Summary"
# ---------------------------------------------------------------------
# We treat the HTML table columns as "variables" for plotting.
# Keys must match the cleaned column headers extracted from the HTML table (see _clean_col()).

# A small simplifier for y-axis annotations
SIMPLIFY_A: Dict[str, str] = {
    "Zone People Sensible Heating Energy": "People",
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
    "Zone Infiltration Sensible Heat Gain Energy": "Infil gain",
    "Zone Infiltration Sensible Heat Loss Energy": "Infil loss",
    "Zone Ventilation Sensible Heat Gain Energy": "Vent gain",
    "Zone Ventilation Sensible Heat Loss Energy": "Vent loss",
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
    "Internal gains / internal convection": {
        "A": [
            "Zone People Sensible Heating Energy",
            "Zone Lights Total Heating Energy",
            "Zone Electric Equipment Total Heating Energy",
        ],
        "B": [
            "Zone Air Heat Balance Internal Convective Heat Gain Rate",
        ],
    },
    "Surfaces convection (envelope + windows lumped)": {
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
    "Interzone air transfer": {
        "A": [
            "Zone Interzone Air Transfer Heat Gain Energy",
            "Zone Interzone Air Transfer Heat Loss Energy",
        ],
        "B": [
            "Zone Air Heat Balance Interzone Air Transfer Rate",
        ],
    },
    "Outdoor air transfer (infil + vent)": {
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
    "System to zone (air transfer + convective)": {
        "A": [
            "Zone Air Terminal Sensible Heating Energy",
            "Zone Air Terminal Sensible Cooling Energy",
            "Zone Radiant HVAC Heating Energy",
            "Zone Radiant HVAC Cooling Energy",
            "Baseboard Total Heating Energy",
        ],
        "B": [
            "Zone Air Heat Balance System Air Transfer Rate",
            "Zone Air Heat Balance System Convective Heat Gain Rate",
        ],
    },
    "Storage": {
        "A": [
            # if you keep it in A; otherwise make A empty
            "Zone Air Heat Balance Air Energy Storage Rate",
        ],
        "B": [
            "Zone Air Heat Balance Air Energy Storage Rate",
        ],
    },
    "Deviation (should be ~0 if perfectly closed)": {
        "A": [],
        "B": [
            "Zone Air Heat Balance Deviation Rate",
        ],
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

def _strip_units(col: str) -> str:
    # "Var Name[W]" -> "Var Name", "Var Name [Wh]" -> "Var Name"
    s = str(col)
    s = s.replace("&amp;", "&")
    s = re.sub(r"\s*\[[^\]]+\]\s*$", "", s).strip()
    return s

def _extract_unit(col: str) -> str | None:
    m = re.search(r"\[([^\]]+)\]\s*$", str(col).strip())
    return m.group(1) if m else None

def _parse_eplus_datetime(series: pd.Series) -> pd.DatetimeIndex:
    """
    Parses EnergyPlus Date/Time like ' 01/01  00:10:00' and handles '24:00:00'
    by rolling to next day.
    """
    s = series.astype(str).str.strip()

    # split "MM/DD  HH:MM:SS"
    parts = s.str.split(r"\s+", n=1, expand=True)
    md = parts[0]
    hms = parts[1].fillna("00:00:00")

    # handle 24:xx:xx -> 00:xx:xx next day
    is_24 = hms.str.startswith("24:")
    hms_fixed = hms.where(~is_24, hms.str.replace("^24:", "00:", regex=True))

    # add dummy year (EnergyPlus often omits year)
    dt = pd.to_datetime("2001/" + md + " " + hms_fixed, errors="coerce")

    # roll forward rows that were 24:..
    dt = dt + pd.to_timedelta(is_24.astype(int), unit="D")
    return pd.DatetimeIndex(dt)

def compute_totals_from_csv_energy_or_rate(
    csv_path: str | Path,
    variables: List[str],
    signs: Dict[str, int],
) -> pd.Series:
    """
    Returns totals in Wh (signed) for requested variables.
    - If a column is [Wh] / [J] etc (energy-like), it is summed directly.
    - If a column is [W] (rate-like), it is integrated using timestep hours from Date/Time.
    """
    csv_path = Path(csv_path)
    df = pd.read_csv(csv_path)

    # find Date/Time column if present (needed for integrating W -> Wh)
    dt_col = None
    for cand in ["Date/Time", "DateTime", "Datetime", "Time", "date/time"]:
        if cand in df.columns:
            dt_col = cand
            break

    dt_hours = None
    if dt_col is not None:
        dti = _parse_eplus_datetime(df[dt_col])
        # robust timestep from median diff
        diffs = dti.to_series().diff().dropna()
        if not diffs.empty:
            dt_hours = diffs.median().total_seconds() / 3600.0

    # build mapping of "base name" -> (original col name, unit)
    col_map = {}
    for c in df.columns:
        base = _strip_units(c)
        unit = _extract_unit(c)
        col_map[base] = (c, unit)

    out = {}
    for v in variables:
        sign = signs.get(v, 1)

        if v not in col_map:
            out[v] = 0.0
            continue

        orig_col, unit = col_map[v]
        vals = pd.to_numeric(df[orig_col], errors="coerce").fillna(0.0)

        # decide integrate vs sum
        if unit is not None and unit.strip().lower() == "w":
            if dt_hours is None:
                # fallback: assume data already timestep-summed or hourly
                # (better than silently returning 0)
                wh = float(vals.sum())  # not perfect, but avoids “all zeros”
            else:
                wh = float((vals * dt_hours).sum())
        else:
            # treat as energy-like (Wh, J, kWh, etc.) and just sum;
            # if it's J, you’d convert, but your workflow usually exports Wh.
            wh = float(vals.sum())

        out[v] = wh * sign

    return pd.Series(out, name="Wh")




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


def compute_net_b(totals_wh_b: pd.Series, factor: float) -> float:
    """
    totals_wh_b is the tabular Series (GJ). factor is GJ->unit (e.g., MWh).
    """
    net = 0.0
    for c in collect_all_b_cols():
        net += float(totals_wh_b.get(c, 0.0)) * factor
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
    totals_wh_b: pd.Series,
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
        factor_b = 1.0 / 1_000_000.0
        unit_disp = "MWh"
    elif unit_l == "kwh":
        factor_a = 1.0 / 1000.0
        factor_b = 1.0 / 1000.0
        unit_disp = "kWh"
    elif unit_l == "wh":
        factor_a = 1.0
        factor_b = 1.0
        unit_disp = "Wh"
    else:
        raise ValueError("unit must be 'Wh', 'kWh', or 'MWh'")

    categories = list(CATEGORY_MAP.keys())

    net_a = compute_net_a(totals_wh_a, factor_a)
    net_b = compute_net_b(totals_wh_b, factor_b)
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
        comps_b = [float(totals_wh_b.get(c, 0.0)) * factor_b for c in cols_b]
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
    b_vars = collect_all_b_cols()
    totals_b = compute_totals_from_csv_energy_or_rate(
        csv_path=CSV_PATH,
        variables=b_vars,
        signs=SIGN_B,
    )

    plot_grouped_signed_stacked(
        totals_wh_a=totals_a,
        totals_wh_b=totals_b,
        out_png="combined_A_vs_ZoneAirHeatBalance_MWh.png",
        unit="MWh",
        source_labels=("A: SIGN_A (energy vars)", "B: Zone Air Heat Balance (rates integrated)"),
        add_residual_row=True,
        label_segments=True,
    )
