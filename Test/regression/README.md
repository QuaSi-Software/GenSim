# Regression runs of the building typologies

Runs the 9 building typologies (`building_typologies/*.osw`) without Excel and compares the key
results between branches or commits, to see whether a change of the measures changes the results.

- `base_workflow.osw`: a complete GenSim export with the default inputs. Each typology only holds the
  parameters that differ from these defaults and is laid over it per measure step, like the Excel import.
- `run_regression.rb`: builds and simulates every typology with ideal loads (`ideal`) and with the
  detailed HVAC, i.e. DOAS and radiant surfaces (`detailed`). Arguments and measure steps that the
  measures of the tested branch do not know are dropped and listed as notes, so older branches can run
  the same inputs.
- `compare_results.rb`: compares two or more result directories and lists every value that changed by
  more than the tolerance.

Extracted per case (from the EnergyPlus tabular reports): end uses in kWh and kWh/m², totals per fuel,
peak demands, unmet heating and cooling hours, hours not comfortable (ASHRAE 55), and the number of
EnergyPlus warnings and severe errors.

## Usage

```
cd <repo>
C:\openstudio-3.10.0\bin\openstudio.exe Test\regression\run_regression.rb --jobs 6
```

Results go to `Output\regression\<branch>` (not versioned). One run of all 18 cases takes about
10 minutes with 6 parallel jobs. Options: `--cases REGEX`, `--modes ideal,detailed`, `--out DIR`,
`--repo DIR` (measures of another checkout, e.g. a `git worktree` of another branch), `--keep-runs`
(keep the complete EnergyPlus output, about 0.5 GB per case), `--prepare-only`.

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
