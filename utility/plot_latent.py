from pathlib import Path
import pandas as pd
import matplotlib
matplotlib.use("TkAgg")   # or "QtAgg" if you have Qt installed
import matplotlib.pyplot as plt
import re


# -------------------------------------------------
# 1) Latent variables + sign convention
# -------------------------------------------------
LATENT_VARS = {
    # Infiltration
    "Zone Infiltration Latent Heat Gain Energy": +1,
    "Zone Infiltration Latent Heat Loss Energy": -1,

    # Ventilation
    "Zone Ventilation Latent Heat Gain Energy": +1,
    "Zone Ventilation Latent Heat Loss Energy": -1,

    # Internal gains
    "Zone People Latent Gain Energy": +1,
    "Zone Electric Equipment Latent Gain Energy": +1,
    "Zone Total Internal Latent Gain Energy": +1,
}

# -------------------------------------------------
# 2) Load summed results (Wh)
# -------------------------------------------------
CSV_PATH = r"F:\Repos\OrgGenSim\Output\run\017_results\report_variables_ZoneTimestep-Sum.csv"

df = pd.read_csv(CSV_PATH)
# 1) Normalize headers: remove trailing units in brackets, e.g. "... Energy[Wh]" -> "... Energy"
df.columns = [re.sub(r"\s*\[[^\]]+\]\s*$", "", c).strip() for c in df.columns]

# 2) Sum numeric columns
totals_wh = df.sum(axis=0, numeric_only=True)

# -------------------------------------------------
# 3) Build signed series (MWh)
# -------------------------------------------------
data = {}
for var, sign in LATENT_VARS.items():
    if var in totals_wh:
        data[var] = totals_wh[var] * sign / 1_000_000.0  # Wh → MWh
    else:
        data[var] = 0.0

s = pd.Series(data).sort_values()
print(s)
# -------------------------------------------------
# 4) Plot
# -------------------------------------------------
fig, ax = plt.subplots(figsize=(10, 5))

ax.barh(s.index, s.values)
ax.axvline(0, linewidth=1)

ax.set_xlabel("Latent Energy (MWh, signed)")
ax.set_title("Zone latent energy balance (no aggregation)")

ax.grid(True, axis="x", linestyle="--", linewidth=0.5)
ax.invert_yaxis()

# value labels
for y, v in enumerate(s.values):
    ax.text(
        v,
        y,
        f"{v:.2f}",
        va="center",
        ha="left" if v >= 0 else "right",
        fontsize=9,
    )

fig.tight_layout()
fig.savefig("latent_balance_simple_MWh.png", dpi=240)
plt.show()
