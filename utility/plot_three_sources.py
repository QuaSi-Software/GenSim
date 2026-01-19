"""
Compare three sensible heat-balance data sources in ONE grouped horizontal bar chart:

A) Aggregated "custom zone balance" terms from the variable CSV (Wh)
B) EnergyPlus "Zone Air Heat Balance" terms from the variable CSV (Wh)
C) EnergyPlus HTML tabular report: "Sensible Heat Gain Summary" (Entire Facility) (GJ -> Wh)

Features:
- Grouped bars per category (A vs B vs C)
- Stacked segments within each bar (multiple variables mapped to one category)
- Consistent topic color per category; within-bar segments vary by tint for readability
- Zone Air Heat Balance "Deviation" segment drawn with white edges ("white lines")
- Values converted to MWh, with numeric labels for each stacked segment and totals
- 3-line y-axis labels: category + A/B/C variable summaries (simplified)

Usage:
    python plot_three_sources.py \
        --csv report_variables_ZoneTimestep-Sum.csv \
        --html ../eplustbl.htm \
        --out comparison_3sources.png

Notes:
- The CSV is expected to have columns like: VariableName, Value (Wh), or similar.
  The loader below tries to auto-detect common layouts.
- The HTML parser extracts the row "Total Facility" from:
  "Sensible Heat Gain Summary" -> "Annual Building Sensible Heat Gain Components" table.
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path
from typing import Dict, List, Tuple

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.colors import to_rgba


# -----------------------
# 1) Variable sign maps
# -----------------------

# A) Aggregated custom balance (energies)
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

    # Window (aggregated)
    "Zone Windows Total Heat Gain Energy": +1,
    "Zone Windows Total Heat Loss Energy": -1,

    # Optional interzone
    "Zone Interzone Air Transfer Heat Gain Energy": +1,
    "Zone Interzone Air Transfer Heat Loss Energy": -1,

    # Storage (air) (note: this is a *rate* in many reports; keep only if yours is energy)
    "Zone Air Heat Balance Air Energy Storage Rate": +1,
}

# B) Zone Air Heat Balance (rates/energies, but your CSV contains Wh already)
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

# C) HTML table columns (GJ) from "Sensible Heat Gain Summary"
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


# -----------------------
# 2) Category mapping
# -----------------------

CATEGORY_MAP = {
    "Internal gains": {
        "A": [
            "Zone People Sensible Heating Energy",
            "Zone Lights Total Heating Energy",
            "Zone Electric Equipment Total Heating Energy",
        ],
        "B": [
            "Zone Air Heat Balance Internal Convective Heat Gain Rate",
        ],
        "C": [
            "People Sensible Heat Addition",
            "Lights Sensible Heat Addition",
            "Equipment Sensible Heat Addition",
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
        "C": [
            "Window Heat Addition",
            "Window Heat Removal",
            "Opaque Surface Conduction and Other Heat Addition",
            "Opaque Surface Conduction and Other Heat Removal",
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
        "C": [
            "Infiltration Heat Addition",
            "Infiltration Heat Removal",
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
        "C": [
            "Interzone Air Transfer Heat Addition",
            "Interzone Air Transfer Heat Removal",
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
        "C": [
            "HVAC Zone Eq & Other Sensible Air Heating",
            "HVAC Zone Eq & Other Sensible Air Cooling",
            "HVAC Terminal Unit Sensible Air Heating",
            "HVAC Terminal Unit Sensible Air Cooling",
            "HVAC Input Heated Surface Heating",
            "HVAC Input Cooled Surface Cooling",
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
        "C": [
            # Not reported in this table
        ],
    },
    "Residual (NET)": {"A": [], "B": [], "C": []},
}

SOURCE_ORDER = [
    ("A", "Aggregated balance"),
    ("B", "Zone Air Heat Balance"),
    ("C", "HTML Sensible Heat Gain Summary"),
]


# -----------------------
# 3) Helpers: reading CSV
# -----------------------

def load_variable_csv(csv_path: Path) -> pd.DataFrame:
    """
    Load a report variable CSV and return a tidy dataframe with:
        variable, value_Wh

    Supports two common layouts:
    1) "Long" format: rows with columns like VariableName + Value
    2) "Wide" format: a single row where each column is "Some Variable[Wh]" and the cell is the total

    We aggregate by variable name (sum) and strip unit suffixes like "[Wh]".
    """
    df = pd.read_csv(csv_path)

    # ---- Case 2: Wide (often: one row, many columns) ----
    if df.shape[0] == 1 and df.shape[1] > 5:
        row = df.iloc[0]
        records = []
        for col in df.columns:
            v = pd.to_numeric(row[col], errors="coerce")
            if pd.isna(v):
                continue
            var = re.sub(r"\s*\[.*?\]\s*$", "", str(col)).strip()  # remove [Wh], [hr], etc.
            records.append((var, float(v)))
        out = pd.DataFrame(records, columns=["variable", "value_Wh"])
        out = out.groupby("variable", as_index=False)["value_Wh"].sum()
        return out

    # ---- Case 1: Long ----
    cols_lower = {c.lower(): c for c in df.columns}
    var_candidates = ["variablename", "variable name", "name", "variable"]
    val_candidates = ["value", "value (wh)", "sum", "wh", "value_wh"]

    var_col = next((cols_lower[v] for v in var_candidates if v in cols_lower), None)
    if var_col is None:
        var_col = df.columns[0]

    val_col = next((cols_lower[v] for v in val_candidates if v in cols_lower), None)
    if val_col is None:
        # pick numeric-ish column with most numbers
        best, best_count = None, -1
        for c in df.columns:
            s = pd.to_numeric(df[c], errors="coerce")
            cnt = int(s.notna().sum())
            if cnt > best_count:
                best_count = cnt
                best = c
        val_col = best

    out = df[[var_col, val_col]].rename(columns={var_col: "variable", val_col: "value"}).copy()
    out["value"] = pd.to_numeric(out["value"], errors="coerce")
    out = out.dropna(subset=["variable", "value"])
    out["variable"] = out["variable"].astype(str).apply(lambda s: re.sub(r"\s*\[.*?\]\s*$", "", s).strip())
    out = out.groupby("variable", as_index=False)["value"].sum()
    out = out.rename(columns={"value": "value_Wh"})
    return out




# -----------------------
# 4) Helpers: reading HTML sensible heat gain summary
# -----------------------

def _normalize_html_header(h: str) -> str:
    h = re.sub(r"\s*\[.*?\]\s*$", "", h)  # strip [GJ]
    h = h.replace("&amp;", "&")
    h = re.sub(r"\s+", " ", h).strip()
    return h

def load_html_sensible_heat_gain(html_path: Path) -> Dict[str, float]:
    """
    Extract "Total Facility" row from:
      Sensible Heat Gain Summary -> Annual Building Sensible Heat Gain Components

    Robust to two layouts from pandas.read_html:
      - Proper header row in DataFrame.columns
      - Header row appears as the first *data row* (columns are 0..N)

    Returns dict: {col_base_name: signed_value_Wh} with signs applied.
    Values in HTML are in GJ.
    """
    from io import StringIO

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

        # Case: header is embedded as first row (common in EnergyPlus eplustbl.htm)
        first_row = [str(x) for x in t.iloc[0].tolist()]
        if any("People Sensible Heat Addition" in x for x in first_row):
            headers = [_normalize_html_header(x) for x in first_row]
            t2 = t.iloc[1:].copy()
            t2.columns = headers
        else:
            headers = [_normalize_html_header(str(c)) for c in t.columns]
            t2 = t.copy()
            t2.columns = headers

        if required.issubset(set(t2.columns)):
            target = t2
            break

    if target is None:
        raise RuntimeError("Could not find the 'Annual Building Sensible Heat Gain Components' table in the HTML file.")

    first_col = target.columns[0]
    mask = target[first_col].astype(str).str.strip().str.lower() == "total facility"
    if not mask.any():
        raise RuntimeError("Could not find 'Total Facility' row in the HTML sensible heat gain table.")

    row = target.loc[mask].iloc[0]

    out: Dict[str, float] = {}
    for col in target.columns[1:]:
        base = _normalize_html_header(str(col))
        if base not in HTML_COL_SIGNS:
            continue
        v_gj = pd.to_numeric(row[col], errors="coerce")
        if pd.isna(v_gj):
            continue
        sign = HTML_COL_SIGNS[base]
        # 1 GJ = 277,777.777... Wh
        v_Wh = float(v_gj) * 277_777.77777777775
        out[base] = sign * v_Wh

    return out



# -----------------------
# 5) Pretty names
# -----------------------

def simplify_var(name: str) -> str:
    repl = [
        ("Zone Air Heat Balance ", ""),
        ("Zone ", ""),
        ("Sensible ", ""),
        ("Total ", ""),
        (" Energy", ""),
        (" Rate", ""),
        ("Inside Faces ", ""),
        ("Opaque Surface ", "Opaque "),
        ("Electric Equipment", "Equipment"),
        ("Air Terminal", "Terminal"),
        ("Radiant HVAC", "Radiant"),
        ("Ventilation", "Vent"),
        ("Infiltration", "Infil"),
        ("Interzone Air Transfer", "Interzone"),
        ("System Convective Heat Gain", "System conv."),
        ("System Air Transfer", "System air"),
        ("Outdoor Air Transfer", "Outdoor air"),
        ("Surface Convection", "Surface conv."),
        ("Internal Convective Heat Gain", "Internal conv."),
        ("Air Energy Storage", "Air storage"),
    ]
    s = name
    for a, b in repl:
        s = s.replace(a, b)
    return " ".join(s.split()).strip()

def pretty_vars(vars_: List[str], max_items: int = 4) -> str:
    if not vars_:
        return "-"
    short = [simplify_var(v) for v in vars_]
    if len(short) <= max_items:
        return ", ".join(short)
    return ", ".join(short[:max_items]) + f", …(+{len(short)-max_items})"


# -----------------------
# 6) Color helpers
# -----------------------

def tint(color, t: float):
    """Blend a color toward white by factor t in [0,1]."""
    r, g, b, a = to_rgba(color)
    r = r + (1 - r) * t
    g = g + (1 - g) * t
    b = b + (1 - b) * t
    return (r, g, b, a)

def lum(rgba):
    r, g, b, a = rgba
    return 0.2126*r + 0.7152*g + 0.0722*b

def fmt(x: float) -> str:
    return f"{x:.1f}"


# -----------------------
# 7) Compute contributions
# -----------------------

def signed_values_from_df(df_vars: pd.DataFrame, sign_map: Dict[str, int]) -> Dict[str, float]:
    lookup = dict(zip(df_vars["variable"], df_vars["value_Wh"]))
    out = {}
    for var, sg in sign_map.items():
        if var in lookup:
            out[var] = float(lookup[var]) * sg
    return out

def category_segments(values: Dict[str, float], category: str, source_key: str) -> List[Tuple[str, float]]:
    vars_ = CATEGORY_MAP[category][source_key]
    segs = []
    for v in vars_:
        segs.append((v, float(values.get(v, 0.0))))
    nonzero = [(n, v) for n, v in segs if abs(v) > 1e-12]
    return nonzero if nonzero else segs

def compute_residual(cat_totals: Dict[str, float]) -> float:
    s = sum(v for k, v in cat_totals.items() if k != "Residual (NET)")
    return -s


# -----------------------
# 8) Plot
# -----------------------

def plot_3sources(df_vars: pd.DataFrame, html_vals: Dict[str, float], out_path: Path) -> None:
    values_A = signed_values_from_df(df_vars, SIGN_A)
    values_B = signed_values_from_df(df_vars, SIGN_B)
    values_C = html_vals  # already signed Wh

    per_source = {"A": values_A, "B": values_B, "C": values_C}

    categories = list(CATEGORY_MAP.keys())
    y = np.arange(len(categories))

    # compute category totals and residual so each source closes to 0 when including residual
    cat_totals = {sk: {} for sk, _ in SOURCE_ORDER}
    cat_segs = {sk: {} for sk, _ in SOURCE_ORDER}

    for sk, _ in SOURCE_ORDER:
        vals = per_source[sk]
        for cat in categories:
            if cat == "Residual (NET)":
                continue
            segs = category_segments(vals, cat, sk)
            cat_segs[sk][cat] = segs
            cat_totals[sk][cat] = sum(v for _, v in segs)
        cat_totals[sk]["Residual (NET)"] = compute_residual(cat_totals[sk])
        cat_segs[sk]["Residual (NET)"] = [("Residual", cat_totals[sk]["Residual (NET)"])]

    # convert Wh -> MWh
    to_mwh = lambda wh: wh / 1e6
    cat_segs_mwh = {sk: {cat: [(n, to_mwh(v)) for n, v in segs] for cat, segs in d.items()} for sk, d in cat_segs.items()}

    cat_totals_mwh = {sk: {cat: to_mwh(v) for cat, v in d.items()} for sk, d in cat_totals.items()}

    bar_h = 0.22
    offsets = {"A": -bar_h, "B": 0.0, "C": +bar_h}
    hatches = {"A": None, "B": "///", "C": "xx"}

    fig, ax = plt.subplots(figsize=(20, 10))
    ax.axvline(0, linewidth=1)

    # topic colors per category
    cycle = plt.rcParams["axes.prop_cycle"].by_key().get("color", ["C0","C1","C2","C3","C4","C5","C6"])
    base_colors = {cat: cycle[i % len(cycle)] for i, cat in enumerate(categories)}

    # plot
    for sk, label in SOURCE_ORDER:
        for i, cat in enumerate(categories):
            segs = cat_segs_mwh[sk][cat]
            base = base_colors[cat]

            pos_left = 0.0
            neg_left = 0.0

            n = max(1, len(segs))
            tints = np.linspace(0.0, 0.55, n)

            for j, (name, val) in enumerate(segs):
                if abs(val) < 1e-12:
                    continue

                c = tint(base, float(tints[j]))
                edgecolor = None
                lw = 0.0

                # Deviation emphasis (white lines)
                if sk == "B" and "Deviation" in name:
                    edgecolor = "white"
                    lw = 1.8

                if val >= 0:
                    left = pos_left
                    pos_left += val
                else:
                    left = neg_left
                    neg_left += val

                ax.barh(
                    y[i] + offsets[sk],
                    val,
                    left=left,
                    height=bar_h * 0.95,
                    color=c,
                    hatch=hatches[sk],
                    edgecolor=edgecolor,
                    linewidth=lw,
                    label=label if (i == 0 and j == 0) else None,
                )

                # label each segment at center
                cx = left + val / 2.0
                cy = y[i] + offsets[sk]
                txt = fmt(val)
                tc = "white" if lum(to_rgba(c)) < 0.45 else "black"
                ax.text(cx, cy, txt, ha="center", va="center", fontsize=9, color=tc, clip_on=True)

            # total label at end
            total = cat_totals_mwh[sk][cat]
            if abs(total) > 1e-12:
                if total >= 0:
                    ax.text(pos_left + 0.8, y[i] + offsets[sk], fmt(total), ha="left", va="center", fontsize=9)
                else:
                    ax.text(neg_left - 0.8, y[i] + offsets[sk], fmt(total), ha="right", va="center", fontsize=9)

    # y labels (4 lines: title + A/B/C)
    ylabels = []
    for cat in categories:
        if cat == "Residual (NET)":
            ylabels.append("Residual (NET)\nA: -sum(shown)\nB: -sum(shown)\nC: -sum(shown)")
        else:
            ylabels.append(
                f"{cat}\n"
                f"A: {pretty_vars(CATEGORY_MAP[cat]['A'])}\n"
                f"B: {pretty_vars(CATEGORY_MAP[cat]['B'])}\n"
                f"C: {pretty_vars(CATEGORY_MAP[cat]['C'])}"
            )

    ax.set_yticks(y)
    ax.set_yticklabels(ylabels, fontsize=9)
    ax.set_xlabel("Energy (MWh, signed)")
    ax.set_title("Reconciled zone sensible balance: Aggregated vs Zone Air Heat Balance vs HTML Sensible Heat Gain Summary")
    ax.grid(True, axis="x", linestyle="--", linewidth=0.6, alpha=0.6)
    ax.legend(loc="upper right")

    ax.set_ylim(-0.8, len(categories) - 0.2)
    fig.subplots_adjust(left=0.44)
    fig.tight_layout()
    fig.savefig(out_path, dpi=200)
    plt.close(fig)


# -----------------------
# 9) CLI
# -----------------------

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", type=Path, default=Path(r"F:\Repos\OrgGenSim\Output\run\017_results\report_variables_ZoneTimestep-Sum.csv"), help="Path to report_variables_ZoneTimestep-Sum.csv (Wh).")
    ap.add_argument("--html", type=Path, default=Path(r"F:\Repos\OrgGenSim\Output\run\eplustbl.htm"), help="Path to eplustbl.htm.")
    ap.add_argument("--out", type=Path, default=Path("comparison_3sources.png"), help="Output image path.")
    args = ap.parse_args()

    df_vars = load_variable_csv(args.csv)
    html_vals = load_html_sensible_heat_gain(args.html)

    plot_3sources(df_vars, html_vals, args.out)
    print(f"Wrote: {args.out.resolve()}")

if __name__ == "__main__":
    main()
