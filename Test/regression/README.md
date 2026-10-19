# Regression runs of the building typologies

Runs the 9 building typologies (`building_typologies/*.osw`) and the 3 complete exports of test
environment IV (`Test/parameter_sets/env_iv/test_0*.osw`, cases `env_iv_test_0*`) without Excel and
compares the key results between branches or commits, to see whether a change of the measures
changes the results. The env_iv files are laid over the base workflow like the typologies, which adds
the arguments that newer measures require and the older files lack.

- `base_workflow.osw`: a complete GenSim export with the default inputs. Each typology only holds the
  parameters that differ from these defaults and is laid over it per measure step, like the Excel import.
- `run_regression.rb`: builds and simulates every typology with ideal loads (`ideal`) and with the
  detailed HVAC, i.e. DOAS and radiant surfaces (`detailed`). Arguments and measure steps that the
  measures of the tested branch do not know are dropped and listed as notes, so older branches can run
  the same inputs.
- `compare_results.rb`: compares two or more result directories and lists every value that changed by
  more than the tolerance.
- `diff_idf.rb`: compares the `run/in.idf` of two runs object by object (independent of object order
  and numbering), to find the inputs behind a result difference.
- `RESULTS_LOG.md`: the explained differences found so far. Add an entry for every comparison.

## Feature variants

The typologies alone leave several features untested (they all use sensible or no heat recovery,
no DOAS coils, no manual window ventilation, binary operating schedules, one climate, one hemisphere
and one sizing method). `variants.json` adds feature variants: each one is laid over the listed
typologies like an extra typology layer, in the listed modes, and runs as its own case
`<typology>__<mode>__<variant>`.

| variant | typologies | modes | covers |
|---|---|---|---|
| enthalpy_recovery | Office | ideal, detailed | enthalpy heat recovery (latent effectiveness 0.6) |
| doas_coils | Office | detailed | DOAS heating and cooling coils with heat recovery |
| doas_coils_no_recovery | Multi-family house | detailed | central ventilation with DOAS coils, no heat recovery |
| no_ventilation | School | detailed | no mechanical ventilation (system type 3) |
| manual_ventilation | Multi-family house, Office | ideal, detailed | manual window ventilation |
| fractional_fan | Office | detailed | fractional operating schedule (reduced DOAS fan flow) |
| infiltration_doe2 | Single-family house | ideal | DOE-2 infiltration coefficients (BLAST is the default) |
| climate_2045 | Restaurant | ideal, detailed | TRY2045 weather |
| southern_hemisphere | Office | ideal, detailed | Santiago de Chile weather, latitude switch of the DOAS SAT seasons |
| sizing_ddy | Kindergarten | ideal | design days from the DDY file |
| controls_off | Retail | ideal, detailed | no shading/lighting control, window ventilation or infiltration |
| output_debug | Single-family house | ideal | Debug output level |

`--variants all|none|REGEX` selects the variants (default: all), `--only-variants` skips the plain
typologies. To cover a new feature, add a variant with the inputs that switch it on. Schedule inputs
can be given as `[[value, count], ...]` (quarter hours, 96 per day).

Extracted per case (from the EnergyPlus tabular reports): end uses in kWh and kWh/m², totals per fuel,
peak demands, unmet heating and cooling hours, hours not comfortable (ASHRAE 55), and the number of
EnergyPlus warnings and severe errors.

## Usage

```
cd <repo>
C:\openstudio-3.10.0\bin\openstudio.exe Test\regression\run_regression.rb --jobs 6
```

Results go to `Output\regression\<branch>` (not versioned). One run of the 24 plain cases takes about
15 minutes with 6 parallel jobs; the 19 variant cases add about as much. Options: `--cases REGEX`,
`--modes ideal,detailed`, `--variants all|none|REGEX`, `--only-variants`, `--out DIR`,
`--repo DIR` (measures of another checkout, e.g. a `git worktree` of another branch), `--keep-runs`
(keep the complete EnergyPlus output, about 0.5 GB per case), `--prepare-only`, and
`--set MEASURE.ARGUMENT=VALUE` (override an input in every case, repeatable, e.g.
`--set add_infiltration.infiltration_type=EnergyPlus`, to test whether an input explains a difference).
The runs need about 1 GB of memory each; with little free memory use `--jobs 2` to `4`.

Comparing two branches, e.g. `main` against `varFanTest`:

```
git worktree add ..\GenSim-main main
C:\openstudio-3.10.0\bin\openstudio.exe Test\regression\run_regression.rb --repo ..\GenSim-main --out Output\regression\main
C:\openstudio-3.10.0\bin\openstudio.exe Test\regression\run_regression.rb --out Output\regression\varFanTest
C:\openstudio-3.10.0\bin\openstudio.exe Test\regression\compare_results.rb Output\regression\main Output\regression\varFanTest --csv Output\regression\compare.csv
```

`--repo` only selects the measures. The typologies, the base workflow and the weather files always come
from the checkout the script is run from, so every branch is simulated with identical inputs.

## Limits

- The typologies are laid over `base_workflow.osw` per measure argument. Values that Excel derives from
  other inputs (e.g. the ventilation lead/follow-up time applied to the operating schedule) are taken as
  stored, so the runs do not reproduce a GenSim GUI run exactly. They are meant for comparing code
  versions with identical inputs.
- The typologies predate manual window ventilation, so it stays off unless a typology enables it.
- `base_workflow.osw` is frozen: when the Excel export gains new required arguments, add them there.
