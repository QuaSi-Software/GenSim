# Regression results log

Explains the result differences found with the regression runs between branches and commits.
Add new comparisons at the top, with the commits, the numbers and how each cause was confirmed.

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
- **Detailed mode only:** the ERV setpoint (`SAT Year Schedule`) also changed, from a constant
  10 °C in main to a constant 18 °C (`SAT Week Schedule Low`) in lüftung. With heat recovery,
  the detailed heating increase is therefore the sum of both changes. Without heat recovery
  (Single- and Multi-family house), the increase is the same as with ideal loads. The two shares
  were not separated (needs a run of lüftung with `--set add_infiltration.infiltration_type=EnergyPlus
  --set inject_zone_ventilation_idf.infiltration_type=EnergyPlus --modes detailed`).
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
