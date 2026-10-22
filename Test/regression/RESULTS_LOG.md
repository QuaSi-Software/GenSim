# Regression results log

Explains the result differences found with the regression runs between branches and commits.
Add new comparisons at the top, with the commits, the numbers and how each cause was confirmed.

## 2026-10-19: main → manualwindows → lüftungMitSchedule → varFanTest (24 plain cases)

Commits: main 3a4a1f0, manualwindows e710ff1, lüftungMitSchedule 133e5ee, varFanTest b719fa1;
the 18 typology cases and, for the first time, the 6 test environment IV cases. Inputs are
identical for all branches. Cooling, kWh/m² (ideal / detailed):

| case | main | manualwindows | lüftung | varFanTest |
|---|---|---|---|---|
| Hotel | 11.05 / 17.13 | 11.12 / 17.13 | 11.12 / 17.13 | 11.12 / 17.13 |
| Kindergarten | 8.42 / 13.57 | 8.35 / 13.50 | 8.35 / 13.50 | 8.35 / 13.46 |
| Multi-family house | 1.62 / 2.52 | 1.65 / 2.54 | 1.65 / 2.54 | 1.65 / 2.54 |
| Office | 6.81 / 9.47 | 6.74 / 9.41 | 6.74 / 9.41 | 6.74 / 9.51 |
| Restaurant | 8.44 / 14.23 | 8.47 / 14.25 | 8.47 / 14.25 | 8.47 / 14.67 |
| Retail | 8.78 / 13.41 | 8.75 / 13.41 | 8.75 / 13.41 | 8.75 / 13.50 |
| School | 10.19 / 15.53 | 10.13 / 15.48 | 10.13 / 15.48 | 10.13 / 15.41 |
| Single-family house | 0.41 / 0.86 | 0.42 / 0.87 | 0.42 / 0.87 | 0.42 / 0.87 |
| Sports hall | 11.96 / 14.22 | 11.60 / 13.88 | 11.60 / 13.88 | 11.60 / 13.84 |
| env_iv test_01 | 10.78 / 14.47 | 10.73 / 14.44 | 10.73 / 14.44 | 10.73 / 14.44 |
| env_iv test_02 | 5.80 / 6.70 | 5.77 / 6.71 | 5.77 / 6.71 | 5.77 / 6.71 |
| env_iv test_03 | 10.00 / 14.84 | 10.15 / 15.03 | 10.15 / 15.03 | 10.15 / 15.00 |

Heating, kWh/m² (ideal / detailed), for the steps that change it:

| case | main | manualwindows = lüftung | varFanTest |
|---|---|---|---|
| Hotel | 37.27 / 31.17 | 39.87 / 33.73 | 39.87 / 33.73 |
| Kindergarten | 9.89 / 11.89 | 11.81 / 15.12 | 11.81 / 15.17 |
| Office | 15.13 / 14.40 | 16.45 / 16.19 | 16.45 / 16.00 |
| Restaurant | 25.36 / 17.32 | 26.78 / 18.69 | 26.78 / 18.17 |
| Retail | 28.40 / 23.74 | 31.07 / 26.70 | 31.07 / 26.51 |
| School | 8.26 / 9.85 | 10.11 / 12.98 | 10.11 / 13.11 |
| Sports hall | 18.79 / 18.04 | 25.14 / 25.63 | 25.14 / 25.66 |

All 96 runs complete without severe errors.

### main → manualwindows: infiltration coefficients (cooling −3 to +2 %)

- `diff_idf.rb` (Office, detailed): the only result-relevant change is the `ZoneInfiltration` and
  window `ZoneVentilation` coefficients, constant (blank = 1/0/0/0) in main, BLAST
  (0.606 / 0.03636·ΔT / 0.1177·wind) in manualwindows (e710ff1). Manual window ventilation adds
  its schedules, but it is off in all cases.
- BLAST raises the air exchange with the indoor-outdoor temperature difference and the wind. In
  winter that is the heating increase (+3 to +42 %, decided to keep, see below). In summer it is
  about the nominal rate during the day (small ΔT) and above it on cool, windy nights, so the
  night air cools the building a little more: cooling −0.3 to −3 % (largest in the Sports hall,
  which has the highest infiltration and no window ventilation). Cooling rises by 0.6 to 2 % where
  the window ventilation matters more (env_iv test_03, a school with 2 ach from 24 °C; the houses;
  the Hotel). Likely cause, not separated by a run: the BLAST coefficients also apply to the window
  ventilation and reduce it on warm, calm days, when ΔT and wind are small.

### manualwindows → lüftungMitSchedule: no result change

- The results are identical in all 24 cases; only 0–2 warnings differ. The DOAS coil support of
  lüftung is off in all cases, and the SAT schedule only got new names ("10 deg C" held 18 °C
  already, see the correction in the 2026-10-13 entry).

### lüftungMitSchedule → varFanTest: heat exchanger setpoint follows the heating setpoint

- Ideal mode: identical (the DOAS changes do not apply). Detailed mode without heat recovery
  (Single- and Multi-family house, env_iv test_01/02): identical.
- Detailed with heat recovery: cooling −0.5 to +2.9 %, heating −2.8 to +1.2 %. Cause: the heat
  exchanger outlet setpoint is a constant 18 °C in lüftung and the heating setpoint −2 K in
  varFanTest (`HX Setpoint Schedule`, 3b5cac1). The IDF shows e.g. 17 °C at night and 19 °C
  during operation for the Restaurant (heating profile 19–21 °C).
  - Restaurant, Office, Retail: heating profiles up to 21 °C, so the setpoint is 19 °C while the
    DOAS runs. In winter the exchanger recovers up to 19 instead of 18 °C; on cool summer days it
    also tempers the outdoor air to 19 °C, which the radiant cooling removes again (cooling +0.7 to
    +2.9 %, heating −0.7 to −2.8 %).
  - Kindergarten, School, Sports hall, env_iv test_03: heating profiles 19–20 °C, setpoint
    17–18 °C, i.e. at most the lüftung value: slightly less tempering, cooling −0.2 to −0.5 %,
    heating +0.1 to +1.2 %.
  - Hotel: constant 20 °C heating, setpoint 18 °C as in lüftung: identical results, which confirms
    the cause.
- The economizer (59719db) should add little here (not separated by a run): it bypasses the
  exchanger only above the heating design SAT, where the outlet temperature control already stops
  heating.
- The 2026-10-13 increase of +24 to +96 % is gone (it came from the summer SAT of cooling + 2 K,
  fixed by 59719db and 3b5cac1).

## 2026-10-19: first run of the feature variants (varFanTest 3b5cac1)

All 19 variant cases of `variants.json` complete without EnergyPlus failures. kWh/m²:

| case | heating | cooling | warnings | notes |
|---|---:|---:|---:|---|
| Office ideal / detailed enthalpy_recovery | 16.5 / 16.0 | 6.7 / 9.5 | 227 / 218 | |
| Office detailed doas_coils | 28.6 | 19.7 | 257 | |
| Multi-family house detailed doas_coils_no_recovery | 32.4 | 6.5 | 222 | |
| School detailed no_ventilation | 8.7 | 23.5 | 51594 | condensation shut-offs of the radiant cooling, 585 unmet cooling hours |
| Multi-family house ideal / detailed manual_ventilation | 25.6 / 25.6 | 1.5 / 2.4 | 227 / 223 | |
| Office ideal / detailed manual_ventilation | 19.7 / 20.6 | 6.3 / 9.0 | 227 / 218 | |
| Office detailed fractional_fan | 19.7 | 7.7 | 95200 | heat exchanger flow < 50 % of nominal |
| Single-family house ideal infiltration_doe2 | 27.3 | 0.6 | 227 | |
| Restaurant ideal / detailed climate_2045 | 18.5 / 11.0 | 15.5 / 21.4 | 228 / 1806 | |
| Office ideal / detailed southern_hemisphere | 2.4 / 1.9 | 13.2 / 18.7 | 227 / 218 | 264 unmet cooling hours (detailed) |
| Kindergarten ideal sizing_ddy | 11.8 | 8.3 | 226 | 4 severe: warm-up not converged on the DDY heating design day |
| Retail ideal / detailed controls_off | 14.4 / 10.3 | 45.5 / 61.4 | 231 / 22874 | condensation shut-offs, no infiltration or window ventilation |
| Single-family house ideal output_debug | 29.8 | 0.4 | 227 | |

- **fractional_fan:** 94,981 of the warnings are "HeatExchanger:AirToAir:SensibleAndLatent: Average
  air volume flow rate is <50% or >130%". At 30 % night flow the exchanger runs outside the range of
  its effectiveness inputs, and EnergyPlus extrapolates. This is a limitation of the fractional fan
  flow; open.
- **no_ventilation, controls_off:** without ventilation or infiltration the zones get humid and the
  radiant cooling shuts off for condensation. Expected for these inputs.
- **sizing_ddy:** the 4 severe errors are warm-up convergence failures by a few hundredths of a
  kelvin (0.42–0.50 vs. 0.40) on "Stuttgart Ann Htg 99.6% Condns DB"; the run completes.
- **southern_hemisphere:** the `SAT Year Schedule` is High / Low / High, i.e. the seasons are swapped as
  intended.
- **infiltration_doe2:** `infiltration_type` is missing from the measure.xml files, so variant inputs
  are passed on like `--set` overrides (heating 29.8 → 27.3 kWh/m² vs. BLAST).

## 2026-10-19: heat exchanger setpoint = heating SAT all year

Change in `add_detailed_hvac`: the `SetpointManager:Scheduled` on the heat exchanger outlet uses a
new `HX Setpoint Schedule` (only the `SAT Week Schedule Low` week, heating setpoint −2 K) instead
of the `SAT Year Schedule`. The DOAS coils keep the seasonal SAT Year Schedule, and the economizer
stays. On cool summer nights the exchanger now only tempers the outdoor air to the heating SAT
instead of heating it towards the summer SAT (cooling setpoint + 2 K).

Detailed mode, kWh/m² (same 4 cases as below):

| case | cooling lüftung | economizer | HX setpoint | heating |
|---|---:|---:|---:|---|
| Kindergarten | 13.5 | 14.8 | 13.5 | unchanged (< 1 %) |
| Office | 9.4 | 11.1 | 9.5 | unchanged |
| Restaurant | 14.3 | 18.7 | 14.7 | unchanged |
| Single-family house (no heat recovery) | 0.87 | 0.87 | 0.87 | unchanged |

- Cooling is back at the lüftung level; heating, heating peak and the warnings are unchanged
  (Kindergarten warnings +1.4 %).
- Alternative tested on the Restaurant IDF only (EnergyPlus run directly): the
  `Time of Day Economizer Control Schedule` of the outdoor air controller, set to 1 from May to
  September, bypasses the exchanger regardless of the economizer limits. Cooling was 150 GJ
  (this change: 158 GJ, economizer: 202 GJ), but heating rose by 13 % (222 vs. 196 GJ), and the
  cooling recovery on hot days is lost too. Without the economizer minimum limit, the heat recovery
  is bypassed all winter (heating 1339 GJ). EnergyPlus has no EMS actuator for the bypass or the
  economizer limits (checked in the `.edd`).

## 2026-10-13: varFanTest with economizer (heat exchanger bypass)

Change in `add_detailed_hvac` (only with heat recovery): the outdoor air controller gets a
`DifferentialDryBulb` economizer with the minimum limit = heating design SAT (heating setpoint
−2 K), heat recovery bypass `BypassWhenWithinEconomizerLimits`, and a scheduled setpoint (SAT
schedule) on the mixed air node, which E+ requires for an economizer. The DOAS runs on 100 %
outdoor air, so the economizer does not change the flow; it only bypasses the heat exchanger while
the outdoor air is between the heating design SAT and the return air temperature. This fixes the
open design question of the entry below: cool outdoor air is no longer heated with exhaust air in summer.

Detailed mode, kWh/m² (4 cases, `--modes detailed --cases "office|restaurant|kindergarten|single"`):

| case | cooling lüftung | varFanTest | economizer | heating varFanTest | economizer | condensation-driven warnings varFanTest → economizer |
|---|---:|---:|---:|---:|---:|---:|
| Kindergarten | 13.5 | 18.7 | 14.8 | 15.17 | 15.17 | 1218 → 887 |
| Office | 9.4 | 13.8 | 11.1 | 15.99 | 15.99 | 218 → 218 |
| Restaurant | 14.3 | 27.9 | 18.7 | 18.17 | 18.17 | 933 → 659 |
| Single-family house (no heat recovery) | 0.87 | 0.87 | 0.87 | 29.76 | 29.76 | 224 → 224 |

- Heating and heating peak are unchanged: in winter, above the heating design SAT the exchanger
  was already bypassed by its outlet temperature control, so no heat recovery is lost.
- Most of the extra cooling is gone. The rest comes from summer hours with outdoor air below the heating
  design SAT (cool nights), when the exchanger still heats the outdoor air towards the summer SAT.
  A lower minimum limit would remove that too, but would also bypass the heat recovery in winter
  between that limit and the heating design SAT.
- Unmet cooling hours are back at the lüftung level. No new warning types, no severe errors.

## 2026-10-13: main vs. lüftungMitSchedule vs. varFanTest

Runs (all 9 typologies, ideal loads and detailed HVAC, `--jobs 4`, OpenStudio 3.10.0):

| label | branch | measures at commit |
|---|---|---|
| main | regressionTests (main + these scripts) | aa69aad |
| lüftung | lüftungMitSchedule | 8202f89 |
| varFanTest | varFanTest | db7e1ea |

All 54 runs completed, no severe errors. Arguments that a branch does not know are dropped
(main does not know the manual ventilation inputs, both older branches do not know the HVAC
schedule/setpoint inputs of `add_ideal_loads`). Energies in kWh/m² net conditioned area.

| ideal | heating main | lüftung | varFanTest | cooling main | lüftung | varFanTest | unmet cooling h main / lüftung / varFanTest | warnings main / lüftung / varFanTest |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Hotel | 37.3 | 39.9 | 39.9 | 11.0 | 11.1 | 11.1 | 0 / 0 / 0 | 218 / 227 / 227 |
| Kindergarten | 9.9 | 11.8 | 11.8 | 8.4 | 8.3 | 8.3 | 83 / 78 / 78 | 217 / 226 / 226 |
| Multi-family house | 19.6 | 20.5 | 20.5 | 1.6 | 1.6 | 1.6 | 0 / 0 / 0 | 218 / 227 / 227 |
| Office | 15.1 | 16.4 | 16.4 | 6.8 | 6.7 | 6.7 | 0 / 0 / 0 | 218 / 227 / 227 |
| Restaurant | 25.4 | 26.8 | 26.8 | 8.4 | 8.5 | 8.5 | 0 / 0 / 0 | 218 / 227 / 227 |
| Retail | 28.4 | 31.1 | 31.1 | 8.8 | 8.8 | 8.8 | 28 / 25 / 25 | 218 / 227 / 227 |
| School | 8.3 | 10.1 | 10.1 | 10.2 | 10.1 | 10.1 | 0 / 0 / 0 | 217 / 226 / 226 |
| Single-family house | 28.9 | 29.8 | 29.8 | 0.4 | 0.4 | 0.4 | 0 / 0 / 0 | 218 / 227 / 227 |
| Sports hall | 18.8 | 25.1 | 25.1 | 12.0 | 11.6 | 11.6 | 0 / 0 / 0 | 224 / 233 / 233 |

| detailed | heating main | lüftung | varFanTest | cooling main | lüftung | varFanTest | unmet cooling h main / lüftung / varFanTest | warnings main / lüftung / varFanTest |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Hotel | 31.2 | 33.7 | 33.7 | 17.1 | 17.1 | 21.3 | 13 / 12 / 12 | 1769 / 1832 / 1932 |
| Kindergarten | 11.9 | 15.1 | 15.2 | 13.6 | 13.5 | 18.7 | 53 / 52 / 40 | 835 / 897 / 1218 |
| Multi-family house | 19.7 | 20.6 | 20.6 | 2.5 | 2.5 | 2.5 | 0 / 0 / 0 | 213 / 224 / 222 |
| Office | 14.4 | 16.2 | 16.0 | 9.5 | 9.4 | 13.8 | 50 / 49 / 35 | 212 / 220 / 218 |
| Restaurant | 17.3 | 18.7 | 18.2 | 14.2 | 14.2 | 27.9 | 30 / 31 / 24 | 630 / 646 / 933 |
| Retail | 23.7 | 26.7 | 26.5 | 13.4 | 13.4 | 20.5 | 77 / 76 / 58 | 257 / 266 / 400 |
| School | 9.9 | 13.0 | 13.1 | 15.5 | 15.5 | 22.0 | 57 / 57 / 40 | 925 / 973 / 1252 |
| Single-family house | 28.9 | 29.8 | 29.8 | 0.9 | 0.9 | 0.9 | 0 / 0 / 0 | 215 / 226 / 224 |
| Sports hall | 18.0 | 25.6 | 25.7 | 14.2 | 13.9 | 20.2 | 0 / 0 / 0 | 1009 / 1093 / 1339 |

Fan energy is identical in all three branches.

### 1. main → lüftung: heating +3 to +42 % (ideal and detailed)

**Cause (confirmed by IDF comparison): the infiltration/window ventilation coefficients changed
from constant to BLAST.** Commit 3c407b7 added the argument `infiltration_type` to
`add_infiltration`, `inject_zone_ventilation_idf` and `inject_manual_ventilation_idf`, and
e710ff1 changed its default from `EnergyPlus` to `BLAST`. The Excel export does not write this
argument, so every GenSim run uses the default.

**Decided (2026-10-19): BLAST stays the default**, since its coefficients are more realistic. The
heating increase is intended. The `infiltration_doe2` variant keeps the other coefficient path tested.

- `diff_idf.rb` of the ideal-loads Office: apart from the order of zones in some lists, the only
  differences are `ZoneInfiltration:DesignFlowRate` and `ZoneVentilation:DesignFlowRate`. In main,
  the coefficients are blank (E+ default 1 / 0 / 0 / 0, i.e. constant). In lüftung they are
  0.606 / 0.03636 / 0.1177 / 0 (constant / temperature difference / wind speed / wind speed²).
  The manual ventilation schedules also appear, but they are all zero because manual ventilation is off.
- BLAST scales the infiltration with the indoor-outdoor temperature difference and the wind, so
  infiltration is about 1.5–2 times the nominal rate in winter and below it in summer. This
  matches more heating and slightly less cooling. The effect is largest in the Sports hall (high
  infiltration rate, large volume), which has no window ventilation, so infiltration alone causes it.
- Heating peak demand rises by +2 to +49 %, and the warnings rise by 9 (new schedule notices).
- ~~Detailed mode only: the ERV setpoint changed from a constant 10 °C in main to 18 °C.~~
  **Corrected 2026-10-19:** this was read from the schedule names. In main the schedule is named
  "SAT Week Schedule 10 deg C" but holds 18 °C, the same value as in lüftung; only the names
  changed. The whole difference main → lüftung is the infiltration coefficients (see the
  2026-10-19 four-branch entry above).
- Side finding: the `measure.xml` of the three measures does not list `infiltration_type` (on
  lüftungMitSchedule and varFanTest). OpenStudio accepts it anyway, but tools reading the XML do
  not see it. The first attempt to override it with `--set` was dropped for this reason, so
  overrides now bypass the XML filter.

### 2. lüftung → varFanTest: cooling +24 to +96 % in detailed mode, with heat recovery only

Unmet cooling hours fall by 10–30 %, pump energy rises, and radiant cooling condensation shut-offs
(the only warning type that changed) rise by 30–55 %. Ideal-loads results are identical.

**Cause (confirmed by IDF comparison and by the pattern over the typologies): the ERV supply
temperature setpoint now follows the seasonal SAT schedule.**

- Bisect (Office, Restaurant, Kindergarten, detailed):
  - fe12a5c (fan flow-fraction schedule, 0d9559a–fe12a5c): results identical to lüftung. The
    typologies have on/off operating schedules, so the fractional fan schedule has no effect.
  - ae590e9 (SAT = heating −2 K / cooling +2 K): small, heating −1 to −3 %, cooling +1 to +3 %.
  - c10e3f9 + 9fa76a9: the whole jump. The run of c10e3f9 alone was aborted (memory), so the two
    commits were not separated by simulation, but the IDF comparison below shows the cause.
- `diff_idf.rb` of ae590e9 vs. varFanTest (Restaurant, detailed): the only substantial difference
  is `SAT Year Schedule`. Before (date bug in `OpenStudio::Date.new`, fixed in c10e3f9), it held
  only the Low week all year. Now it switches to the High week (cooling setpoint +2 K, e.g. 26–28 °C) from 2 May to 1 Oct.
  `Sizing:System` also changed, but the typologies have no DOAS water coils, so it has no effect.
- The typologies have no DOAS coils, so the schedule is only used by the `SetpointManager:Scheduled` on
  the outlet of the heat exchanger (`HeatExchanger:AirToAir:SensibleAndLatent`, sensible
  effectiveness 0.7, `Supply Air Outlet Temperature Control = Yes`). With a summer setpoint of
  cooling +2 K, the heat exchanger heats cool outdoor air (nights, mild days) with the exhaust air
  up to about 28 °C instead of supplying it unheated. This replaces the former free cooling by
  the outdoor air with additional load for the radiant cooling, so there is more cooling energy and more
  condensation shut-offs (the radiant cooling runs more often).
- Consistent with this: the 7 typologies with `heat_recovery_method = Sensible` show the
  increase. The Single- and Multi-family house (`None`) show no change.

**Open design question:** in summer the ERV should probably bypass when the outdoor air is cooler
than the exhaust air (free cooling), e.g. supply air setpoint = heating setpoint −2 K all year for
the heat exchanger and the cooling +2 K limit only for a cooling coil, or an economizer-style
lockout. The previous behaviour (Low week all year) was a side effect of the date bug, not a design decision.

### How these runs were made

```
git worktree add <dir> <branch-or-commit>
openstudio.exe Test\regression\run_regression.rb --repo <dir> --out <out>\<label> --jobs 4
openstudio.exe Test\regression\compare_results.rb <out>\main <out>\lueftung <out>\varFanTest --csv <out>\compare.csv
openstudio.exe Test\regression\diff_idf.rb <out>\a\Office__ideal\run\in.idf <out>\b\Office__ideal\run\in.idf
```
