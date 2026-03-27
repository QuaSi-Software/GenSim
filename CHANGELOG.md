# Changelog

## v2.16
### Update to OpenStudio version 3.10
* The results are largely the same, however some differences are expected and mainly concern updates in how GenSim output variables are defined (see below).

### Major feature: New output mechanism
* Refactor reading of EnergyPlus™ results into a separate measure that extracts the results from the output SQLite database into CSV files, which can then be processed further
  * Previously the extractions was partially done in the VBA code. It is now much more modular and available via the CLI as it is a measure like any other which is run during execution of a workflow
  * It now also easier to define which EnergyPlus™ are extracted, as this data is stored in a central location (file `Measures/output_variables.json`).
  * This replaces the `ReadVarsESO` program (from EnergyPlus™ ecosystem) that was previously shipped with GenSim as it is no longer needed
* Update which EnergyPlus™ variables are used for constructing which output variables of GenSim.
  * Considerable thought was put into identifying the best fitting matches, however poor documentation of EnergyPlus™ makes it impossible to find a perfect fit between the meaning the GenSim output variables ought to have and what EnergyPlus™ actually captures.
* Implement three levels of output verbosity: `Reduced`, `Normal` and `Debug`
  * This is implemented both as CLI option (in measure `results`) and a GUI selection element
  * Choosing a level with fewer output variables can offer a significant performance increase as the extraction is slow

### Major feature: IFC model import
* Update the model construction workflow so that both OSM and IDF files can be imported without manual conversion
* Add the option to import IFC files based on the [BIM2SIM library](https://github.com/BIM2SIM/bim2sim)
  * The code for converting an IFC file into an IDF file is placed in a [separate Docker container](https://hub.docker.com/r/tmaile/epone), which is used by a local script to perform the conversion. The IDF file is then used in the existing mechanism for model import.
  * Using this feature requires the user to have Docker Desktop installed
  * The code cannot handle arbitrary IFC files, given how broad the IFC standard is defined and used in various BIM tools. The accepted format for GenSim is designed for a specific use case. A future update might expand the accepted range and might specify the required structure and data in more detail.

### Major feature: Remove the need for DDY files
* Implement three options for creating design days, which are in turn required for auto-sizing of heating and cooling loops
  * The first option is the previous mechanism of requiring DDY files, which are created alongside the EPW files when creating from raw weather data. This option is good for backward compatibility and to give users precise control over the design days considered during auto-sizing.
  * The second option creates design days with parameters fixed in the code. This option is good when no input is available as it does not require any input.
  * The third option creates the design days automatically from the provided EPW file containing the weather data. It chooses appropriate parameter values from the data and uses the identified days for the auto-sizing. This is the default option as it automatically adapts to the weather data and does not require DDY files.

### Minor feature: Machine-readable profile / construction data
* Add machine-readable data (JSON) for the available presets of constructions and profiles
  * This feature is mostly required for integrating GenSim into other systems, e.g. a webservice
  * This eliminates the need to read the data from the Excel file
  * Future updates are easier to integrate as they are much clearer when changing the JSON files as compared to changing a table in the Excel file
* Included profiles: Activity, occupation, heating / cooling setpoint, demand for electric devices, demand for lights, ventilation schedule
* Included constructions: Interior walls, construction sets each having: roof, ceiling, exterior wall, base plate, windows
* Other: Holidays, NFA/GBA ratio

### Other changes
* Implement the option to capture the OpenStudio output to a file, which was previously not possible
* Remove remaining references and GUI elements for PV subsimulation, which had been removed in v2.15
* Increase the number of material layers a construction can have to 10, up from 4
  * A future update might remove the restriction to a fixed number of layers entirely, however this was considered low priority
* Add option to enable OpenStudio debug mode to GenSim CLI
* Fix an issue with dropdown selection when custom profiles have the same name as a standard profile
* Fix an issue where the north axis / orientation supplied was not set correctly, leading to all simulations having the default 0° orientation regardless of input value
* Update hidden parameter values for pressure rise of the ventilation system fans from 250 to 750.
  * This induces a higher electricity consumption for the ventilation system, but the new values have been deemed more realistic.
  * A future update might add these parameters as input variables. At the moment they can only be changed via the CLI by manually updating the workflow file.
* Add option to have no mechanical ventilation at all, whereas previously it was only possible to reduce the volume flow to near zero
* Update GUI sheet with Gebäudebilanz for new calculation and include information on the difference between sensible-only and latent variable calculation
* Fix an issue where updating the pivot table during sensitivity analysis would lead to an unnecessary drop in performance

## v2.15b
* Add several building types as parameter sets for various types typically used to perform building energy simulations. These types are specific to Germany, but can also provide a general base from which to create a new building type or specific building.

## v2.15
* Add the changelog. A list of all changes of older versions is unfortunately not available.
* Release the code of GenSim under MIT license.
* Add the GUI based on MS Excel.
* Add a CLI for developers to interface with GenSim.
* Major refactoring of the GUI code and and how simulations are run. Unfortunately this introduces a backwards incompatability with OSW files older than v2.15. However the simulation results are confirmed to be unchanged for the same inputs as with v2.14.