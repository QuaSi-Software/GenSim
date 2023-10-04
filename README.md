# GenSim
![GenSim](docs/logo_gensim.jpg "GenSim")

Generische Gebäudesimulation auf Basis von EnergyPlus™.

GenSim erzeugt anhand einfacher Eingabeparameter ein vollständiges EnergyPlus™-Gebäudemodell, simuliert dieses und gibt anschließend Ergebnisse in Form von Lastprofilen und Jahreswerten zurück.

**Die Benutzeroberfläche (GUI) für GenSim ist derzeit noch nicht im Repository enthalten. Diese wird derzeit noch für die Veröffentlichung vorbereitet und integriert sobald dies abgeschlossen ist.**

# Benutzung
Eine detailierte Dokumentation der Benutzung von GenSim wird auf der [offiziellen Dokumentation](https://quasi-software.readthedocs.io/en/latest/) des übergeordneten Projekts QuaSi zur Verfügung gestellt werden. Im Folgenden gibt es eine schnelle Einführung in die Installation und Benutzung.

## Installation
1. OpenStudio in Version 2.7.0 installieren. Ältere Versionen sind auf der [OpenStudio GitHub Seite](https://github.com/NREL/OpenStudio/releases) zu finden.
1. Ruby in Version 2.5.x installieren. Ältere Versionen sind auf der [offiziellen Webseite von Ruby](https://www.ruby-lang.org/en/downloads/releases/) zu finden. Hierbei sind mehrere Dinge zu beachten:
    1. Als Zielort sollte ein Unterordner namens `ruby-install` innerhalb des OpenStudio Verzeichnisses sein. Dieser sollte direkt als Oberverzeichnis für die Ruby-Installation dienen, die Ruby-Executable sollte z.B. unter `C:\openstudio-2.7.0\ruby-install\bin\ruby.exe` vorliegen.
    1. Wenn weitere Ruby-Installationen auf dem System existieren, sollte ggf. diese Installation nicht in die `PATH` Systemumgebungsvariable aufgenommen werden. GenSim verwendet zur internen Benutzung von Ruby direkte Pfade, jedoch kann es zur Entwicklung nützlich sein diese Installation auch als Alias für `ruby` zu verwenden.

## Benutzung
Wird bald ergänzt.

# Lizenz
GenSim ist unter der MIT Lizenz veröffentlicht. Der Lizenztext ist in Datei `LICENSE.md` zu finden. Die gelisteten Personen sind als Autor\*innen von GenSim im Sinne des Urheberrechts zu verstehen. Wo nicht anders angegeben sind alle mitgelieferten Quell- und Binärdateien als von den Autor\*innen verfasst und unter der MIT Lizenz veröffentlich zu verstehen. Davon unberührt bleiben eingebundene Drittpartei-Quellen, welche mit deren entsprechender Lizenz versehen sind.

## Zusätzliche Datenquellen

### Gebäudestandards Nichtwohngebäude
Aus "Typologie und Bestand beheizter Nichtwohngebäude in Deutschland" von *[Bundesinstitut für Bau-, Stadt- und Raumforschung](http://www.bbsr.bund.de)* BBSR Bonn 2011 unter [Datenlizenz Deutschland – Namensnennung – Version 2.0](https://www.govdata.de/dl-de/by-2-0).

# Herausgeber und Förderung
GenSim wurde im Rahmen des Forschungsprojektes **ES-West_P2G2P: Klimaneutrales Stadtquartier Neue Weststadt Esslingen** entwickelt und wird im Rahmen des Forschungsprojektes **QuaSi_II: Simulationssoftware zur Planung Bewertung nachhaltiger Energieversorgung von Stadtquartieren** weiterentwickelt und herausgegeben.

Hauptentwickler und Herausgeber sind:
* Maile Consulting
* siz energieplus

Nach einer Idee von Thilo Sautter.

![Gefördert durch das Bundesministerium für Wirtschaft und Klimaschutz](docs/f%C3%B6rderung_bmwk.png "Gefördert durch das Bundesministerium für Wirtschaft und Klimaschutz")
![Gefördert durch das Bundesministerium für Bildung und Forschung](docs/f%C3%B6rderung_bmbf.png "Gefördert durch das Bundesministerium für Bildung und Forschung")
