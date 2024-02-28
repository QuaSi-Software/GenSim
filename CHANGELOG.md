# Current version: 2.15b

## v2.15b
* Add several building types as parameter sets for various types typically used to perform building energy simulations. These types are specific to Germany, but can also provide a general base from which to create a new building type or specific building.

## v2.15
* Add the changelog. A list of all changes of older versions is unfortunately not available.
* Release the code of GenSim under MIT license.
* Add the GUI based on MS Excel.
* Add a CLI for developers to interface with GenSim.
* Major refactoring of the GUI code and and how simulations are run. Unfortunately this introduces a backwards incompatability with OSW files older than v2.15. However the simulation results are confirmed to be unchanged for the same inputs as with v2.14.