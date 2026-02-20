"""
Compare EnergyPlus balance terms: NOW vs BEFORE (both from CSV Output:Variable totals)

- Replaces the old HTML "Sensible Heat Gain Summary" source.
- Uses two CSV files (NOW / BEFORE) that contain summed timestep variables, typically exported as
  report_variables_ZoneTimestep-Sum.csv with columns like "... Energy[Wh]".
- Plots signed, stacked horizontal bars per category, with NOW solid and BEFORE hatched.

Typical use:
    - Set CSV_NOW and CSV_BEFORE paths at the bottom.
    - Run: python plot_compare_now_vs_before.py
Outputs:
    compare_now_vs_before_MWh.png
"""

from __future__ import annotations

import re
from pathlib import Path
from typing import Dict, List, Tuple

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors


# =============================================================================
# 1) SIGN dictionaries (Wh columns are summed; we apply sign for balance)
# =============================================================================

SIGN_NOW: Dict[str, int] = {
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

SIGN_BEFORE: Dict[str, int] = {
    # Transmission (surface-average version)
    "Surface Average Face Conduction Heat Gain Rate": +1,
    "Surface Average Face Conduction Heat Loss Rate": -1,
    "Surface Window Heat Gain Energy": +1,
    "Surface Window Heat Loss Energy": -1,

    # Outdoor air total (combined sensible+latent)
    "Zone Infiltration Total Heat Gain Energy": +1,
    "Zone Infiltration Total Heat Loss Energy": -1,
    "Zone Ventilation Total Heat Gain Energy": +1,
    "Zone Ventilation Total Heat Loss Energy": -1,

    # Internal total (incl latent)
    "Zone Electric Equipment Total Heating Energy": +1,
    "Zone Lights Total Heating Energy": +1,
    "Zone People Total Heating Energy": +1,

    # Facility meters (requested)
    "METER TOTAL HEATING": +1,
    "METER TOTAL COOLING": -1,

    "Zone Mechanical Ventilation No Load Heat Removal Energy": -1,
    "Zone Mechanical Ventilation No Load Heat Addition Energy": +1,
}


# =============================================================================
# 2) Category mapping: NOW vs BEFORE
# =============================================================================

CATEGORY_MAP: Dict[str, Dict[str, List[str]]] = {
    "Internal gains / internal convection": {
        "NOW": [
            "Zone Lights Total Heating Energy",
            "Zone Electric Equipment Total Heating Energy",
            "Zone People Sensible Heating Energy",
        ],
        "BEFORE": [
            "Zone Lights Total Heating Energy",
            "Zone Electric Equipment Total Heating Energy",
            "Zone People Total Heating Energy",
        ],
    },
    "Surfaces convection (envelope lumped)": {
        "NOW": [
            "Zone Opaque Surface Inside Faces Total Conduction Heat Gain Energy",
            "Zone Opaque Surface Inside Faces Total Conduction Heat Loss Energy",
        ],
        "BEFORE": [
            "Surface Average Face Conduction Heat Gain Rate",
            "Surface Average Face Conduction Heat Loss Rate",
        ],
    },
    "Surfaces convection (windows)": {
        "NOW": [
            "Zone Windows Total Heat Gain Energy",
            "Zone Windows Total Heat Loss Energy",
        ],
        "BEFORE": [
            "Surface Window Heat Gain Energy",
            "Surface Window Heat Loss Energy",
        ],
    },
    "Outdoor air transfer (infil + vent)": {
        "NOW": [
            "Zone Infiltration Sensible Heat Gain Energy",
            "Zone Infiltration Sensible Heat Loss Energy",
            "Zone Ventilation Sensible Heat Gain Energy",
            "Zone Ventilation Sensible Heat Loss Energy",
        ],
        "BEFORE": [
            "Zone Infiltration Total Heat Gain Energy",
            "Zone Infiltration Total Heat Loss Energy",
            "Zone Ventilation Total Heat Gain Energy",
            "Zone Ventilation Total Heat Loss Energy",
        ],
    },
    "System to zone (air transfer)": {
        "NOW": [
            "Zone Air Terminal Sensible Heating Energy",
            "Zone Air Terminal Sensible Cooling Energy",
        ],
        "BEFORE": [
            "Zone Mechanical Ventilation No Load Heat Removal Energy",
            "Zone Mechanical Ventilation No Load Heat Addition Energy",
        ],
    },
    "System to zone (convective)": {
        "NOW": [
            "Zone Radiant HVAC Heating Energy",
            "Zone Radiant HVAC Cooling Energy",
            "Baseboard Total Heating Energy",
        ],
        "BEFORE": [
            "METER TOTAL HEATING",
            "METER TOTAL COOLING",
        ],
    },
    "Storage": {
        "NOW": [
            # if you keep it in A; otherwise make A empty
            "Zone Air Heat Balance Air Energy Storage Rate",
        ],
        "BEFORE": [
            "Zone Air Heat Balance Air Energy Storage Rate",
        ],
    },
    "Deviation (should be ~0 if perfectly closed)": {
        "NOW": [],
        "BEFORE": [
        ],
    },
}

# Optional: nicer per-variable labels in legend/segment tooltips (not required)
SIMPLIFY: Dict[str, str] = {
    # NOW
    "Zone Opaque Surface Inside Faces Total Conduction Heat Gain Energy": "Opaque Inside Cond +",
    "Zone Opaque Surface Inside Faces Total Conduction Heat Loss Energy": "Opaque Inside Cond -",
    "Zone Windows Total Heat Gain Energy": "Win Heat Gain +",
    "Zone Windows Total Heat Loss Energy": "Win Heat Loss -",
    "Zone Infiltration Sensible Heat Gain Energy": "Infil + (sens)",
    "Zone Infiltration Sensible Heat Loss Energy": "Infil - (sens)",
    "Zone Ventilation Sensible Heat Gain Energy": "Vent + (sens)",
    "Zone Ventilation Sensible Heat Loss Energy": "Vent - (sens)",
    "Zone Electric Equipment Total Heating Energy": "Geräte",
    "Zone Lights Total Heating Energy": "Licht",
    "Zone People Sensible Heating Energy": "Personen (sens)",
    "Zone Air Terminal Sensible Heating Energy": "Term heat",
    "Zone Air Terminal Sensible Cooling Energy": "Term cool",
    "Zone Radiant HVAC Heating Energy": "Rad heat",
    "Zone Radiant HVAC Cooling Energy": "Rad cool",
    "Baseboard Total Heating Energy": "Baseboard heat",
    # BEFORE
    "Surface Average Face Conduction Heat Gain Rate": "Wände + (avg)",
    "Surface Average Face Conduction Heat Loss Rate": "Wände - (avg)",
    "Surface Window Heat Gain Energy": "Fenster + (surf)",
    "Surface Window Heat Loss Energy": "Fenster - (surf)",
    "Zone Infiltration Total Heat Gain Energy": "Infil + (total)",
    "Zone Infiltration Total Heat Loss Energy": "Infil - (total)",
    "Zone Ventilation Total Heat Gain Energy": "Vent + (total)",
    "Zone Ventilation Total Heat Loss Energy": "Vent - (total)",
    "Zone People Total Heating Energy": "Personen (total)",
    # Facility
    "DistrictHeatingWater:Facility": "District Heat",
    "DistrictCooling:Facility": "District Cool",
    "Zone Mechanical Ventilation No Load Heat Removal Energy": "Mech Vent Cool",
    "Zone Mechanical Ventilation No Load Heat Addition Energy": "Mech Vent Heat",
}

def build_category_labels(categories, category_map, simplify=None):
    simplify = simplify or {}

    def simp_list(vars_):
        if not vars_:
            return "—"
        return ", ".join(simplify.get(v, v) for v in vars_)

    # auto-detect the two scenario keys used inside CATEGORY_MAP
    # e.g. {"NOW":[...], "BEFORE":[...]} or {"A":[...], "B":[...]}
    sample = None
    for c in categories:
        if c in category_map:
            sample = category_map[c]
            break
    keys = [k for k in (sample or {}).keys() if k not in ("name",)]
    # keep stable order preference
    if "A" in keys and "B" in keys:
        k1, k2 = "A", "B"
    elif "NOW" in keys and "BEFORE" in keys:
        k1, k2 = "NOW", "BEFORE"
    else:
        # fallback to first two keys
        k1, k2 = (keys + ["A", "B"])[:2]

    labels = []
    for cat in categories:
        if "Residual" in cat or "NET" in cat:
            labels.append(
                "Residual (NET)\n"
                f"{k1}: sum of shown terms\n"
                f"{k2}: sum of shown terms"
            )
            continue

        a_vars = category_map.get(cat, {}).get(k1, [])
        b_vars = category_map.get(cat, {}).get(k2, [])

        labels.append(
            f"{cat}\n"
            f"{k1}: {simp_list(a_vars)}\n"
            f"{k2}: {simp_list(b_vars)}"
        )
    return labels


# =============================================================================
# 3) CSV loading helpers
# =============================================================================

def _clean_col(col: str) -> str:
    """
    Normalizes CSV headers:
      - Removes trailing unit suffix like "[Wh]" or " [W]" (also matches "...Energy[Wh]" without space)
      - Unescapes "&amp;"
    """
    s = str(col).replace("&amp;", "&")
    s = re.sub(r"\s*\[[^\]]+\]\s*$", "", s).strip()
    return s


def load_totals_wh(csv_path: str | Path) -> pd.Series:
    """
    Loads the 'ZoneTimestep-Sum' CSV and returns column sums (Wh) with cleaned column names.
    Assumes columns are timestep *energies* already (e.g., [Wh]) and summing is correct.
    """
    csv_path = Path(csv_path)
    df = pd.read_csv(csv_path)

    # Clean headers so dict keys match
    df.columns = [_clean_col(c) for c in df.columns]

    # Sum numeric columns only
    totals = df.sum(axis=0, numeric_only=True)
    totals.name = "Wh"
    return totals


# =============================================================================
# 4) Plotting (signed, stacked horizontal bars, NOW vs BEFORE)
# =============================================================================

def _shade_color(base_color: str, idx: int, n: int, lighten_max: float = 0.55):
    """Blend base color toward white to create visible stacks."""
    rgb = mcolors.to_rgb(base_color)
    if n <= 1:
        t = lighten_max / 2.0
    else:
        t = lighten_max * (idx / (n - 1))
    return (rgb[0] + (1 - rgb[0]) * t, rgb[1] + (1 - rgb[1]) * t, rgb[2] + (1 - rgb[2]) * t)


def _signed_total(totals_wh: pd.Series, var: str, sign_map: Dict[str, int]) -> float:
    return float(totals_wh.get(var, 0.0)) * float(sign_map.get(var, 1))


def plot_now_vs_before(
    totals_wh_now: pd.Series,
    totals_wh_before: pd.Series,
    out_png: str = "compare_now_vs_before_MWh.png",
    unit: str = "MWh",
    source_labels: Tuple[str, str] = ("NOW", "BEFORE"),
    add_residual_row: bool = True,
    label_segments: bool = False,
):
    unit_l = unit.lower()
    if unit_l == "mwh":
        factor = 1.0 / 1_000_000.0
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
    if add_residual_row:
        categories = categories + ["NET (sum of shown terms)"]

    # base colors from matplotlib cycle
    cycle = plt.rcParams["axes.prop_cycle"].by_key()["color"]
    cat_base_colors = {c: (cycle[i % len(cycle)] if "NET" not in c else "0.35")
                       for i, c in enumerate(categories)}

    fig, ax = plt.subplots(figsize=(14, 7))
    bar_h = 0.36
    y_positions = list(range(len(categories)))

    # offsets: NOW above, BEFORE below
    y_now = [y - bar_h / 2 for y in y_positions]
    y_before = [y + bar_h / 2 for y in y_positions]

    # keep totals for labeling
    totals_for_label_now: List[Tuple[float, float]] = []
    totals_for_label_before: List[Tuple[float, float]] = []

    # precompute net for residual row
    def compute_net(totals_wh: pd.Series, sign_map: Dict[str, int], which: str) -> float:
        s = 0.0
        for cat in CATEGORY_MAP:
            for v in CATEGORY_MAP[cat].get(which, []):
                s += _signed_total(totals_wh, v, sign_map)
        return s * factor

    net_now = compute_net(totals_wh_now, SIGN_NOW, "NOW")
    net_before = compute_net(totals_wh_before, SIGN_BEFORE, "BEFORE")

    for i, cat in enumerate(categories):
        base = cat_base_colors[cat]

        if "NET" in cat:
            # NOW
            ax.barh(y_now[i], net_now, height=bar_h, color=base, alpha=0.95)
            totals_for_label_now.append((net_now, y_now[i]))

            # BEFORE (hatched)
            ax.barh(y_before[i], net_before, height=bar_h, color=base, alpha=0.35,
                    hatch="///", edgecolor="black", linewidth=0.6)
            totals_for_label_before.append((net_before, y_before[i]))
            continue

        now_vars = CATEGORY_MAP[cat].get("NOW", [])
        before_vars = CATEGORY_MAP[cat].get("BEFORE", [])

        # components (signed, converted)
        comps_now = [(_signed_total(totals_wh_now, v, SIGN_NOW) * factor) for v in now_vars]
        comps_before = [(_signed_total(totals_wh_before, v, SIGN_BEFORE) * factor) for v in before_vars]

        # --- NOW stacked (positive and negative separately)
        pos_now = [(v, val) for v, val in zip(now_vars, comps_now) if val > 0]
        neg_now = [(v, val) for v, val in zip(now_vars, comps_now) if val < 0]

        left = 0.0
        for j, (v, val) in enumerate(pos_now):
            c = _shade_color(base, j, max(1, len(pos_now)))
            ax.barh(y_now[i], val, left=left, height=bar_h, color=c, alpha=0.95)
            if label_segments and abs(val) > 0:
                ax.text(left + val / 2, y_now[i], f"{val:.2f}", va="center", ha="center", fontsize=8, color="white")
            left += val

        left = 0.0
        for j, (v, val) in enumerate(neg_now):
            c = _shade_color(base, j, max(1, len(neg_now)))
            ax.barh(y_now[i], val, left=left, height=bar_h, color=c, alpha=0.95)
            if label_segments and abs(val) > 0:
                ax.text(left + val / 2, y_now[i], f"{val:.2f}", va="center", ha="center", fontsize=8, color="white")
            left += val

        total_now = sum(comps_now)
        totals_for_label_now.append((total_now, y_now[i]))

        # --- BEFORE stacked (hatched)
        pos_b = [(v, val) for v, val in zip(before_vars, comps_before) if val > 0]
        neg_b = [(v, val) for v, val in zip(before_vars, comps_before) if val < 0]

        left = 0.0
        for j, (v, val) in enumerate(pos_b):
            c = _shade_color(base, j, max(1, len(pos_b)))
            ax.barh(y_before[i], val, left=left, height=bar_h, color=c, alpha=0.35,
                    hatch="///", edgecolor="black", linewidth=0.4)
            if label_segments and abs(val) > 0:
                ax.text(left + val / 2, y_before[i], f"{val:.2f}", va="center", ha="center", fontsize=8, color="black")
            left += val

        left = 0.0
        for j, (v, val) in enumerate(neg_b):
            c = _shade_color(base, j, max(1, len(neg_b)))
            ax.barh(y_before[i], val, left=left, height=bar_h, color=c, alpha=0.35,
                    hatch="///", edgecolor="black", linewidth=0.4)
            if label_segments and abs(val) > 0:
                ax.text(left + val / 2, y_before[i], f"{val:.2f}", va="center", ha="center", fontsize=8, color="black")
            left += val

        total_before = sum(comps_before)
        totals_for_label_before.append((total_before, y_before[i]))

    ax.axvline(0, linewidth=1)
    ax.grid(True, axis="x", linestyle="--", linewidth=0.5)
    ax.set_xlabel(f"Energy ({unit_disp}, signed)")
    ax.set_title(f"NOW vs BEFORE — EnergyPlus balance comparison\n{source_labels[0]} (solid) vs {source_labels[1]} (hatched)")

    ax.set_yticks(y_positions)
    ax.set_yticklabels(
        build_category_labels(
            categories=categories,
            category_map=CATEGORY_MAP,
            simplify=SIMPLIFY,
        ),
        fontsize=10,
    )
    ax.invert_yaxis()

    # annotate totals at bar ends
    xmin, xmax = ax.get_xlim()
    xpad = 0.01 * (xmax - xmin)

    for total, y in totals_for_label_now:
        ax.text(
            total + (xpad if total >= 0 else -xpad),
            y,
            f"{total:.2f}",
            va="center",
            ha=("left" if total >= 0 else "right"),
            fontsize=9,
        )

    for total, y in totals_for_label_before:
        ax.text(
            total + (xpad if total >= 0 else -xpad),
            y,
            f"{total:.2f}",
            va="center",
            ha=("left" if total >= 0 else "right"),
            fontsize=9,
        )

    # small legend proxy
    ax.plot([], [], linewidth=8, label=source_labels[0])
    ax.plot([], [], linewidth=8, alpha=0.35, label=source_labels[1])
    ax.legend(loc="upper right")

    fig.tight_layout()
    fig.savefig(out_png, dpi=240)
    print(f"Saved: {out_png}")


# =============================================================================
# 5) Main
# =============================================================================

if __name__ == "__main__":
    CSV = r"F:\Repos\OrgGenSim\Output\run\017_results\report_variables_ZoneTimestep-Sum.csv"

    totals = load_totals_wh(CSV)

    # Optional: quick diagnostics for missing variables
    def _missing(totals: pd.Series, vars_needed: List[str]) -> List[str]:
        return [v for v in vars_needed if v not in totals.index]

    needed_now = sorted({v for cat in CATEGORY_MAP for v in CATEGORY_MAP[cat]["NOW"]})
    needed_before = sorted({v for cat in CATEGORY_MAP for v in CATEGORY_MAP[cat]["BEFORE"]})

    miss_now = _missing(totals, needed_now)
    miss_before = _missing(totals, needed_before)

    if miss_now:
        print("\nMissing in NOW CSV (after header cleaning):")
        for v in miss_now:
            print("  -", v)

    if miss_before:
        print("\nMissing in BEFORE CSV (after header cleaning):")
        for v in miss_before:
            print("  -", v)

    plot_now_vs_before(
        totals_wh_now=totals,
        totals_wh_before=totals,
        out_png="compare_now_vs_before_MWh.png",
        unit="MWh",
        source_labels=("NOW", "BEFORE"),
        add_residual_row=True,
        label_segments=False,  # set True if you want numbers per segment
    )
