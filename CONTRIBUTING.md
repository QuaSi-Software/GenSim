# Mitwirken
Das Mitwirken an der Weiterentwicklung von GenSim ist immer willkommen, auch für nur kleinere Anpassungen. Die Organisation findet über das [GitHub Repository](https://github.com/QuaSi-Software/GenSim) von GenSim statt, aber auch andere Kanäle des übergeordneten QuaSi-Projekts (siehe [die Dokumentation](https://quasi-software.readthedocs.io/en/latest/contributions/)) stehen zur Verfügung.

# Entwicklung
Im Folgenden sind Informationen spezifisch zur Entwicklung von GenSim dargestellt. Für die Benutzung sind diese nicht notwendig (oder zielführend). Entwickler*innen sind angehalten die Informationen aktuell zu halten und zu ergänzen.

## Import/Export VBA Code
Um den im Excel-File direkt hinterlegten VBA-Code mit Git unter Versionsverwaltung zu stellen, wird ein VBA-Import/Export Skript eingesetzt. Dieses nutzt die Funktionalität des Excel-VBA-Editors, bestehende Module und Klassen in einfache textbasierte Dateien (.bas/.cls) zu exportieren bzw. diese zu importieren. Darüber hinaus wird damit die Möglichkeit geschaffen bei Bedarf den VBA-Code in einem beliebigen Editor zu bearbeiten.

### Export-Skript
Das Export-Skript **löscht alle bestehenden Dateien** im Unterordner `VBAProjectFiles` und exportiert dann alle User-Forms, Klassen und Module im VBA-Projekt. Aufruf über das Tastenkürzel `STRG+e` in Excel oder als Makro `ExportVBACode`.

### Import-Skript
Das Import Skript **löscht alle bestehenden User-Forms, Klassen und Module** (mit Ausnahme des Moduls `ImportExport`) im VBA-Projekt und importiert alle `.cls`, `-frm` und `.bas` Dateien aus dem Unterordner `VBAProjectFiles`. Aufruf über das Tastenkürzel `STRG+i` in Excel oder als Makro `ExportVBACode`.

Wird der VBA-Code direkt im VBA-Editor bearbeitet, muss dieser vor jedem Commit mit dem Export-Skript exportiert werden. Wird der VBA-Code hingegen in einem externen Editor bearbeitet, muss dieser für die Anwendung im Excel-File vorher importiert werden.

### Konventionen

**Änderungen am Excel-File (`GenSim.xlsm`) die lediglich durch Änderungen am VBA-Code enstehen, egal ob durch einen Import oder durch direkte Änderungen im VBA-Editor, sollen nicht in Git commitet werden.** Denn der VBA-Code ist bereits durch die Export-Dateien in der Versionsverwalung. Ansonsten würde es ständig zu Konflikten bei der Datei `GenSim.xlsm` kommen! Nur wenn tatsächlich Änderungen am Excel-File (betrifft nur Excel-Oberfläche) getätigt wurden, wird das Excel-File in Git commitet. Eine Ausnahme ist das Erstellen einer neuer Version von GenSim, zu der dann der aktuelle Stand des Quellcodes auch im Excel-File hinterlegt sein muss.

**Des weiteren sollte die Excel-File nur in einem Branch gleichzeitig bearbeitet werden.** Grund hierfür ist, dass Excel-Dateien keine textbasierten Dateien sind, die somit von Git nicht Zeilenweise verfolgt können. (Git stellt lediglich fest, dass es eine Änderung gibt.) Ein Zusammenführen (merge) von zwei Versionen des Excel-Files mit Git ist daher nicht möglich!

## Ausführen von Tests
Es existieren eine Reihe von Tests um während der Entwicklung zu helfen die Korrektheit zu wahren. Natürlich können diese nicht perfekt sein, aber sollten stets in einem hilfreichen Stand sein. Dazu gehört auch, dass fehlschlagende Tests nicht im Hauptzweig landen dürfen.

Die Tests sind vier Testumgebungen eingeteilt, wobei derzeit zwei bereits implementiert und zwei in Planung sind. Diese testen die Funktionalität auf unterschiedlichen Ebenen und mit unterschiedlichen Methoden. Eine vollständige Automatisierung aller Tests ist daher nur schwer möglich und wird nicht angestrebt.

### Testumgebung I: Measures Tests
Voraussetzungen:
* Docker Desktop (Windows) 4.20.1 oder später

In dieser Testumgebung werden die einzelnen Measures und das Durchführen eines Workflows (als Serie von Measures) getestet.

Im ersten Schritt wird ein Docker Image `gensin-testenv` aufgebaut. In der Regel muss dies nur einmal gemacht werden, außer es ändert sich etwas in der Datei `Gemfile` in der die notwendigen Ruby-Pakete angegeben sind.
1. In das Verzeichnis, in dem GenSim liegt, wechseln: `cd /path/to/GenSim`
1. Das Docker image erstellen: `docker build -t gensim-testenv .`

Anschließend können die Tests ausgeführt werden. Dabei wird ein Container anhand des Images erstellt, der dann die Tests ausführt. Dabei wird das GenSim-Verzeichnis eingebunden, sodass die Test-Ergebnisse auch wieder dort landen.

1. In das Verzeichnis, in dem GenSim liegt, wechseln: `cd /path/to/GenSim`
1. Tests ausführen: `docker run --rm -w /gensim/Measures -v "$(pwd):/gensim" gensim-testenv`
1. Übersicht über die Ergebnisse im Browser aufrufen unter: `/path/to/GenSim/Measures/test_results/dashboard/index.html`
1. (Optional) Detailergebnisse aufrufen unter: `/path/to/GenSim/Measures/test/html_reports/index.html`

### Testumgebung II: Tests zwischen GUI und OSW
Voraussetzungen:
* Ruby 2.5.9 oder später
* MS Excel 2016 oder später

In dieser Testumgebung wird geprüft, ob die auf Excel-basierende GUI die notwendigen Parameter und das Modell korrekt in die OpenStudio Workflow (OSW) Datei überträgt und diese auch korrekt importiert.

#### Export Tests

1. Die GUI auf dem aktuellsten Stand öffnen. Wenn zwischenzeitlich Änderungen an der GUI gemacht wurden (und die Datei gespeichert wurde) ist zu klären ob die Änderungen geprüft werden sollen. Wenn nicht, empfiehlt es sich diese zu verwerfen.
1. Mit dem Makro `ImportVBACOde` (Tastenkürzel `Strg+i`) den aktuellsten VBA Code importieren. Dies ist nur notwendig wenn Änderungen am VBA Code gemacht wurden, die nun getestet werden sollen und welche noch nicht in einem Release-Commit in die GUI aufgenommen wurden.
1. Über den Knopf `Export` einen Export ausführen. Dabei sollte die Datei unter `/path/to/GenSim/Output/Model.osw` gespeichert bzw. überschrieben werden.
1. Auf der Kommandozeile:
    1. In das GenSim Verzeichnis und den `Test` Unterordner wechseln: `cd /path/to/GenSim/Test`
    1. Die Tests ausführen: `ruby ./osw_tests.rb --testcase=TestExportToOSW`
    1. Die Ergebnisse werden direkt auf der Kommandozeile ausgegeben. Dort wird bei fehlschlagenden Tests auch ausgegeben welchen Grund dies hat. Insbesondere wird mit erwarteten Werten in Datei `Test/expected/exported_defaults.osw` verglichen.

#### Import Tests

Die Parameter sind in drei Sets eingeteilt, die Parameter mehr oder weniger thematisch gruppieren. Für die folgende Anleitung sind diese Namen exakt als `$name` zu verwenden:

1. building_standards
1. generic_geometry_and_weather
1. hvac_parameters

Für ein Parameter Set können die Tests wie folgt ausgeführt werden:

1. Die GUI auf dem aktuellsten Stand öffnen. Wenn mehrere Parameter Sets hintereinander getestet werden, empfiehlt es sich die GUI zwischendurch ohne zu speichern zu schließen und neu zu öffnen.
2. Mit dem Makro `ImportVBACOde` (Tastenkürzel `Strg+i`) den aktuellsten VBA Code importieren.
3. Über den Knopf `Import` die Datei `Test/parameter_sets/env_ii/$name.osw` importieren.
4. Ohne jegliche weitere Änderungen über den Knopf `Export` die Parameter in Datei `Output/$name.osw` exportieren.
5. Option 1:
    1. In das GenSim Verzeichnis und den `Test` Unterordner wechseln: `cd /path/to/GenSim/Test`
    1. Die Tests ausführen: `ruby ./osw_tests.rb --name=test_$name`
6. Option 2:
    1. Schritte 1-4 für die restlichen Sets wiederholen
    1. In das GenSim Verzeichnis und den `Test` Unterordner wechseln: `cd /path/to/GenSim/Test`
    1. Die Tests ausführen: `ruby ./osw_tests.rb --testcase=TestImportedOSW`

### Testumgebung IV: End-to-End Tests
Voraussetzungen:
* Ruby 2.5.9 oder später
* Zum Ausführen von GenSim:
    * OpenStudio 2.7.0
    * MS Excel 2016 oder später

In dieser Testumgebung wird der komplette Prozess beginnend mit der Eingabe in der GUI bis hin zum Evaluieren der Ergebnisse getestet. Daher beinhaltet das Ausführen auch manuelle Arbeitsschritte. Verglichen wird mit vorbestimmten Ergebnissen für drei Typgebäude. Das heißt auch, dass diese erwarteten Werte angepasst werden müssen, wenn sich etwas in der Berechnungslogik von GenSim verändert. Die Tests sind besser dazu geeignet Änderungen zu prüfen, die theoretisch nichts an der Berechnung ändern sollten. Um "falschen Alarm" durch geringfügige Änderungen zu vermeiden werden die Ergebnisse mit gewissen Toleranzen verglichen.

Der erste Teil der Testumgebung ist das Ausführen von Tests mit der zu prüfenden Version von GenSim mit den Eingabedaten der Typgebäude:
1. Öffnen von GenSim in der zu testenden Version
1. Importieren des Parametersatzes für das Typgebäude 1 (Mehrfamilienhaus) durch Import der Datei `Test/parameter_sets/env_iv/test_01.osw`.
1. Prüfen ob die Parameter, insbesondere ausgewählte Profile, richtig eingelesen wurden, da die Importfunktion nicht in allen Fällen 100% zuverlässig ist
1. Ausführen der Simulation mit GenSim
1. Öffnen der Datei `Test/Results_to_JSON.xlsm`
1. Übertragen der Ergebnisse aus GenSim in die Datei. Eine kurze Anweisung welche Bereiche kopiert werden müssen und was zu beachten gilt steht auch dort vermerkt. Die Export-Datei sollte als `test_01.json` benannt werden und wird standardmäßig im Unterverzeichnis `Test` gespeichert.
1. Verschieben/Kopieren der Datei `test_01.json` in das Verzeichnis `Output/end2end`

Diese Anweisungen müssen nun auch für die beiden Typgebäude 2 (Bürogebäude) und 3 (Allgemeinbildende Schule) wiederholt werden. Dabei die Namen der Dateien entsprechend durchnummerieren. Anschließend können die Ergebnisse mit den erwarteten Werten verglichen werden.

1. `cd Test`: Die Tests müssen im Verzeichnis `Test` ausgeführt werden, da die Dateipfade relativ dazu sind.
1. `ruby ./end_to_end_tests.rb`: Dies führt alle Tests aus und gibt das Ergebnis auf der Kommandozeile aus.

Alternativ:
1. `ruby ./end_to_end_tests.rb --name="test_case_01"`: Dies führt den einzelnen Test `test_case_01` aus.
1. `ruby ./end_to_end_tests.rb --name=/test_case_0[12]/`: Dies führt Tests aus die dem angegebenen Pattern entsprechen, in diesem Fall die ersten beiden Testfälle.

## GenSim CLI
Statt der GUI kann auch die interne CLI benutzt werden um Simulationen durchzuführen. In diesem Fall muss die OSW-Datei auf anderem Weg erstellt werden. Die CLI basiert auf Ruby, daher bietet es sich an die Ruby-Installation, die auch für die GUI verwendet wird, zu benutzen. Im Folgenden wird davon ausgegangen, dass der Befehl `ruby` auf die korrekt Installation verweist.

1. (Einmalig) Notwendige Gems installieren: `gem install thor`
1. In das Hauptverzeichnis wechseln: `cd /path/to/GenSim`
    1. Im Folgenden wird davon ausgegangen, dass dieser Pfad für `.` steht. Obwohl manche Commands relative Pfade mit `.` verarbeiten können, kann dieses Verhalten nicht garantiert werden. Wenn ein Command nicht funktioniert, versuche vollständige Pfade zu verwenden statt der `.` Abkürzung.
1. Eine leere OSM-Datei erzeugen: `ruby ./Measures/gensim_cli.rb create_empty_osm --output_folder=./Output Model.osm`
1. Die Simulation ausführen: `ruby ./Measures/gensim_cli.rb run_workflow --output_folder=./Output --os_bin_path=C:\openstudio-2.7.0\bin\openstudio.exe Model.osw`
1. Den ESO Output in CSV umwandeln: `ruby ./Measures/gensim_cli.rb convert_eso_to_csv --output_folder=./Output/run --converter_exe=./ReadVarsEso/ReadVarsESO.exe eplusout.eso`