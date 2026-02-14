|                             |                               |                                 |
| --------------------------- | ----------------------------- | ------------------------------- |
| **Techniker HF Informatik** | **Kurs Scripting / Big data** | ![Logo](./../x_gitres/logo.png) |

# Big Data mit MongoDB

PowerShell + MongoDB



# HF Praxisprojekt – Skripting & Big Data

Dieses Projekt dient als Musterlösung für den HF-Unterricht.

## Inhalte
- CSV Massendatenverarbeitung
- Fehleranalyse mit PowerShell
- MongoDB JSON Import

## MongoDB Import
mongoimport --db hf_bigdata --collection sensors --file sensor_data_mongodb.json --jsonArray




ag 5 – Arbeiten mit CSV (Datenverarbeitung)
Theorie

Strukturierte Daten

CSV als Austauschformat

Datenqualität & Probleme

Praxis

Übung 5: CSV verarbeiten

CSV importieren

Filtern

Aggregieren

$data = Import-Csv daten.csv
$data | Group-Object Status


Praxisauftrag

Analysiere Fehler pro Maschine aus einer CSV-Datei.
