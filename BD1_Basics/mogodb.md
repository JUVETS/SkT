Codepilot



Tag 4 – Übungen
A1: Datenklassifizierung
Aufgabe: Bestimme pro Datei (CSV/JSON/LOG), ob strukturiert/semistrukturiert/unstrukturiert – begründe in 1–2 Sätzen.
Musterlösung (Kurzantworten):

CSV → strukturiert (tabellarisch, konsistente Spalten)
JSON → semistrukturiert (verschachtelt, variable Felder)
LOG → semistrukturiert (frei, aber Muster/Regex)


Tag 5 – Übungen
A1: CRUD in mongosh
use hf_class
db.customers.insertMany([
 { _id: 1, name: "Alice", city: "Bern", tags: ["vip","newsletter"] },
 { _id: 2, name: "Bob", city: "Zürich", tags: ["newsletter"] }
])
db.customers.find({ city: "Bern" }, { name: 1, city: 1 })
db.customers.updateOne({ _id: 2 }, { $set: { city: "Basel" }, $addToSet: { tags: "vip" } })
db.customers.deleteOne({ _id: 1 })

A2: Filter/Projection/Sort
db.orders.find(
  { total: { $gt: 100 } },
  { _id: 0, orderId: 1, total: 1 }
).sort({ total: -1 }).limit(5)


Tag 6 – Übungen
A1: Indexe & Explain

db.logs.createIndex({ ts: 1 })
db.logs.createIndex({ status: 1, ts: -1 })
db.logs.find({ status: { $in: [500, 503] }, ts: { $gt: ISODate("2025-01-01") } }).explain("executionStats")

TTL-Index für Log-Daten (30 Tage)
db.logs.createIndex({ ts: 1 }, { expireAfterSeconds: 60*60*24*30 })

Tag 7 – Übungen
A1: Top-10 URLs nach Aufrufen

db.logs.aggregate([
  { $match: { status: { $gte: 200, $lt: 400 } } },
  { $group: { _id: "$path", hits: { $sum: 1 } } },
  { $sort: { hits: -1 } },
  { $limit: 10 }
])


A2: Requests/Minute & Fehlerrate

db.logs.aggregate([
  { $group: {
      _id: { $dateTrunc: { date: "$ts", unit: "minute" } },
      total: { $sum: 1 },
      errors: { $sum: { $cond: [{ $gte: ["$status", 500] }, 1, 0] } }
  }},
  { $project: { time: "$_id", total: 1, errors: 1, errorRate: { $round: [{ $multiply: [{ $divide: ["$errors","$total"] }, 100] }, 2] }, _id: 0 } },
  { $sort: { time: 1 } }
])

A3: Join mit $lookup (orders ⇄ customers)

db.orders.aggregate([
  { $lookup: {
      from: "customers",
      localField: "customerId",
      foreignField: "_id",
      as: "customer"
  }},
  { $unwind: "$customer" },
  { $project: { orderId: 1, total: 1, "customer.name": 1, "customer.city": 1 } }
])

Tag 8 – Übungen
A1: PowerShell → mongoimport → Automatisierung

# 1) Rohdaten bereinigen
Get-Content .\access.log | .\parse-log.ps1 | Set-Content .\access_clean.json

# 2) Import in MongoDB
mongoimport --uri "mongodb://localhost:27017" --db hf_class --collection logs --file .\access_clean.json --jsonArray

# 3) Export von Aggregationsergebnissen
mongosh --eval "use hf_class; db.logs.aggregate([{ $group: { _id: '\$status', c: { \$sum: 1 } } }]).toArray()" |
  Out-File .\status_summary.json

A2: Idempotentes Upsert via mongosh Script

// file: upsert_customers.js
use('hf_class');
db.customers.updateOne(
  { _id: 42 },
  { $set: { name: 'Charlie', city: 'Bern' }, $setOnInsert: { createdAt: new Date() } },
  { upsert: true }
);

mongosh upsert_customers.js

Tag 9 – Mini‑Projekt (Beispiel-Checkliste + Lösungsskizze)
Aufgabe

Baue eine E2E-Pipeline: access.log → PowerShell-Bereinigung → MongoDB Import → KPIs via Aggregation → Export als CSV/JSON.

Solution Sketch (Ablaufskript)

.\parse-log.ps1 -InputPath .\access.log -OutputPath .\access_clean.json
mongoimport --db hf_class --collection logs --file .\access_clean.json --jsonArray
mongosh --file .\reports.kpi.js

reports.kpi.js
use('hf_class');
print('Top URLs'); 
printjson(db.logs.aggregate([
  { $match: { status: { $lt: 400 } } },
  { $group: { _id: "$path", hits: { $sum: 1 } } },
  { $sort: { hits: -1 } }, { $limit: 10 }
]).toArray());

print('Errors by Minute');
printjson(db.logs.aggregate([
  { $match: { status: { $gte: 500 } } },
  { $group: { _id: { $dateTrunc: { date: "$ts", unit: "minute" } }, errors: { $sum: 1 } } },
  { $sort: { "_id": 1 } }
]).toArray());

Beispiel‑Skripte (bereit zur Nutzung)

Lege sie in einen Ordner scripts\.

parse-log.ps1 – robustes Parsen & JSON-Output

```powershell
param(
  [Parameter(Mandatory)][string]$InputPath,
  [Parameter(Mandatory)][string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$pattern = '^(?<ip>\S+) \S+ \S+ \[(?<ts>[^\]]+)\] "(?<method>\S+) (?<path>\S+) \S+" (?<status>\d{3}) (?<bytes>\d+|-)'
$result = New-Object System.Collections.Generic.List[object]

Get-Content $InputPath | ForEach-Object {
  if ($_ -match $pattern) {
    $bytes = if ($Matches.bytes -eq '-') { 0 } else { [int]$Matches.bytes }
    $ts = [datetime]::ParseExact($Matches.ts, 'dd/MMM/yyyy:HH:mm:ss zzz', [Globalization.CultureInfo]::InvariantCulture)

    $result.Add([pscustomobject]@{
      ip     = $Matches.ip
      ts     = $ts
      method = $Matches.method
      path   = $Matches.path
      status = [int]$Matches.status
      bytes  = $bytes
    })
  }
}

# Als JSON-Array schreiben
($result | ConvertTo-Json -Depth 5) | Set-Content $OutputPath -Encoding UTF8
Write-Host "Parsed $($result.Count) records to $OutputPath"
```

import-json.ps1 – JSON nach MongoDB

```powershell
param(
  [Parameter(Mandatory)][string]$File,
  [string]$Uri = "mongodb://localhost:27017",
  [string]$Db = "hf_class",
  [string]$Collection = "logs"
)
mongoimport --uri $Uri --db $Db --collection $Collection --file $File --jsonArray
```

export-aggregation.ps1 – Aggregation ausführen & exportieren

```powershell
param(
  [Parameter(Mandatory)][string]$Script,  # z.B. .\reports.kpi.js
  [Parameter(Mandatory)][string]$OutFile
)
$raw = mongosh --file $Script
$raw | Out-File -FilePath $OutFile -Encoding UTF8
Write-Host "Export saved to $OutFile"
```

reports.kpi.js – Beispiel KPIs (wie oben)

use('hf_class');
// Beispiele wie im Tag 9 Abschnitt (Top URLs, Errors/Minute, etc.)

seed-data.js – Demo-Daten einspielen

use('hf_class');
db.customers.insertMany([
  { _id: 1, name: "Alice", city: "Bern", tags: ["vip","newsletter"] },
  { _id: 2, name: "Bob", city: "Zürich", tags: ["newsletter"] },
  { _id: 3, name: "Charlie", city: "Basel" }
]);
db.orders.insertMany([
  { orderId: 1001, customerId: 1, items: [{sku:"A1", qty:2}], total: 230.5, ts: new Date() },
  { orderId: 1002, customerId: 2, items: [{sku:"B3", qty:1}], total: 99.9, ts: new Date() }
]);

👉 teaching_datasets.zip

```powershell
<#
    ETL Pipeline für Unterricht
    --------------------------------------
    - Parse access.log → JSON
    - Fehlerhafte Logzeilen → error.log
    - Clean JSON → MongoDB import
    - IoT & Orders validieren
    - KPI Reports generieren
#>

param(
    [string]$BasePath = ".\\teaching_datasets",
    [string]$MongoUri = "mongodb://localhost:27017",
    [string]$DbName = "hf_class"
)

Write-Host "=== HF ETL Pipeline gestartet ===" -ForegroundColor Cyan

# -----------------------------------------------------
# 1) LOGFILE PARSING
# -----------------------------------------------------
$logFile = Join-Path $BasePath "access.log"
$faultyLogFile = Join-Path $BasePath "access_faulty.log"
$cleanOut = Join-Path $BasePath "logs_clean.json"
$errorsOut = Join-Path $BasePath "logs_failed.log"

$pattern = '^(?<ip>\\S+) \\S+ \\S+ \\[(?<ts>[^\\]]+)\\] \"(?<method>\\S+) (?<path>\\S+) \\S+\" (?<status>\\d{3}) (?<bytes>\\d+|-)'

$cleanList = New-Object System.Collections.Generic.List[Object]
$errorList = New-Object System.Collections.Generic.List[String]

Write-Host "Parsing Weblogs …"

foreach ($line in Get-Content $logFile) {
    if ($line -match $pattern) {
        $bytes = if ($Matches.bytes -eq '-') { 0 } else { [int]$Matches.bytes }
        try {
            $ts = [datetime]::ParseExact(
                $Matches.ts,
                'dd/MMM/yyyy:HH:mm:ss zzz',
                [Globalization.CultureInfo]::InvariantCulture
            )
        } catch {
            $errorList.Add($line)
            continue
        }

        $cleanList.Add([pscustomobject]@{
            ip     = $Matches.ip
            ts     = $ts.ToUniversalTime()
            method = $Matches.method
            path   = $Matches.path
            status = [int]$Matches.status
            bytes  = $bytes
        })
    }
    else {
        $errorList.Add($line)
    }
}

$cleanList | ConvertTo-Json -Depth 5 | Set-Content $cleanOut
$errorList | Set-Content $errorsOut

Write-Host "✓ Logs bereinigt: $($cleanList.Count) gültig, $($errorList.Count) fehlerhaft" -ForegroundColor Green

# -----------------------------------------------------
# 2) ORDERS VALIDIERUNG
# -----------------------------------------------------
$orderFile = Join-Path $BasePath "shop_orders.json"
$orderFaultyFile = Join-Path $BasePath "shop_orders_faulty.json"

$orders = Get-Content $orderFile -Raw | ConvertFrom-Json
$ordersFaulty = Get-Content $orderFaultyFile -Raw | ConvertFrom-Json

$validOrders = New-Object System.Collections.Generic.List[Object]
$invalidOrders = New-Object System.Collections.Generic.List[Object]

Write-Host "Validiere Orders …"

foreach ($o in $orders + $ordersFaulty) {
    if ($o.orderId -and $o.total -and $o.ts) {
        $validOrders.Add($o)
    } else {
        $invalidOrders.Add($o)
    }
}

$validOrders | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $BasePath "orders_clean.json")
$invalidOrders | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $BasePath "orders_failed.json")

Write-Host "✓ Orders: $($validOrders.Count) gültig, $($invalidOrders.Count) fehlerhaft"

# -----------------------------------------------------
# 3) IOT VALIDIERUNG
# -----------------------------------------------------
$iotFile = Join-Path $BasePath "iot_metrics.jsonl"
$iotFaultyFile = Join-Path $BasePath "iot_metrics_faulty.jsonl"

$validIot = New-Object System.Collections.Generic.List[Object]
$invalidIot = New-Object System.Collections.Generic.List[String]

Write-Host "Validiere IoT Metriken …"

foreach ($line in Get-Content $iotFile, $iotFaultyFile) {
    try {
        $obj = $line | ConvertFrom-Json -ErrorAction Stop
        if ($obj.deviceId -and $obj.ts) {
            $validIot.Add($obj)
        } else {
            $invalidIot.Add($line)
        }
    } catch {
        $invalidIot.Add($line)
    }
}

$validIot | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $BasePath "iot_clean.json")
$invalidIot | Set-Content (Join-Path $BasePath "iot_failed.json")

Write-Host "✓ IoT: $($validIot.Count) gültig, $($invalidIot.Count) fehlerhaft"

# -----------------------------------------------------
# 4) MONGODB IMPORT
# -----------------------------------------------------
Write-Host "Importiere nach MongoDB …" -ForegroundColor Cyan

mongoimport --uri $MongoUri --db $DbName --collection logs --file $cleanOut --jsonArray | Out-Null
mongoimport --uri $MongoUri --db $DbName --collection orders --file (Join-Path $BasePath "orders_clean.json") --jsonArray | Out-Null
mongoimport --uri $MongoUri --db $DbName --collection iot --file (Join-Path $BasePath "iot_clean.json") --jsonArray | Out-Null

Write-Host "✓ Import abgeschlossen" -ForegroundColor Green

# -----------------------------------------------------
# 5) KPI AGGREGATIONEN
# -----------------------------------------------------
Write-Host "Berechne KPIs …"

$kpiScript = @'
use("hf_class");

print("=== KPI: Top URLs ===");
printjson(db.logs.aggregate([
  { $group: { _id: "$path", hits: { $sum: 1 } } },
  { $sort: { hits: -1 } },
  { $limit: 5 }
]).toArray());

print("=== KPI: Errors per Minute ===");
printjson(db.logs.aggregate([
  { $group: {
      _id: { $dateTrunc: { date: "$ts", unit: "minute" } },
      total: { $sum: 1 },
      errors: { $sum: { $cond: [{ $gte: ["$status", 500] }, 1, 0] } }
  }},
  { $project: {
      time: "$_id", total: 1, errors: 1,
      errorRatePct: {
        $round: [{ $multiply: [{ $divide: ["$errors","$total"] }, 100] }, 2]
      }
  }},
  { $sort: { time: 1 } }
]).toArray());
'@

$kpiFile = Join-Path $BasePath "kpi_reports.js"
$kpiScript | Set-Content $kpiFile

mongosh $kpiFile | Out-File (Join-Path $BasePath "kpi_output.txt")

Write-Host "✓ KPI Berechnung abgeschlossen" -ForegroundColor Green

Write-Host "=== ETL Pipeline beendet ===" -ForegroundColor Cyan

```

Komplettes Unterrichtsskript (Markdown)

Das ist dein durchgehendes Begleitskript zum Ausdrucken/Teilen.
Datei: Unterrichtsskript_Scripting_BigData.md

# Unterrichtsskript – Skripting (PowerShell) & Big Data (MongoDB)

## Zielgruppe & Format
- HF-Klasse, 9 Tage à 3h
- Praxisorientiert (Hands-on, reale Datenszenarien)

## Lernziele
- PowerShell sicher für Datenaufbereitung & Automatisierung nutzen
- MongoDB für flexible Datenmodellierung & Analytics einsetzen
- End-to-End Datenpipeline implementieren

---

## Tag 1 – PowerShell Basics
**Konzepte:** Cmdlets, Objekte, Pipe, Formatierung  
**Beispiele:** `Get-Process`, `Get-Service`, Export CSV/JSON  
**Übung:** Top-N Prozesse exportieren  
**Erfolgskriterien:** Output-Dateien korrekt, sinnvolle Spalten

---

## Tag 2 – Daten & Kontrolle
**Konzepte:** CSV/JSON, Schleifen, Bedingungen, Funktionen  
**Beispiele:** `Import-Csv`, `ConvertFrom/To-Json`  
**Übung:** CSV transformieren, JSON bereinigen  
**Erfolgskriterien:** Valide JSON/CSV, Funktionen mit Parametern

---

## Tag 3 – Automatisierung & Aufbereitung
**Konzepte:** Fehlerbehandlung, Logging, Regex-Parsing von Logs  
**Beispiele:** Try/Catch, Logfile-Pipeline  
**Übung:** `parse-log.ps1` bauen  
**Erfolgskriterien:** Anzahl Records, saubere Felder, Timestamps

---

## Tag 4 – Big Data & NoSQL
**Konzepte:** 5V, OLTP vs. OLAP, NoSQL-Typen, Document Stores  
**Übung:** Datensätze einordnen, Modellierungsentscheid begründen  
**Erfolgskriterien:** Passendes Modell je Szenario

---

## Tag 5 – MongoDB Grundlagen & CRUD
**Konzepte:** Dokumente, Collections, CRUD, Query Operators  
**Tools:** mongosh, Compass  
**Übung:** `customers`/`orders` CRUD  
**Erfolgskriterien:** Korrekte Filter, Updates, Projection

---

## Tag 6 – Schema Design & Indexe
**Konzepte:** Embedded vs. Referenced, Denormalisierung, Indexe  
**Übung:** Indexe erstellen, Explain analysieren, TTL für Logs  
**Erfolgskriterien:** IXSCAN statt COLLSCAN, nachvollziehbare Indexwahl

---

## Tag 7 – Aggregation Framework
**Konzepte:** Pipeline-Stages, Performance (frühes `$match`)  
**Übung:** KPIs, Top-N, Join via `$lookup`  
**Erfolgskriterien:** Richtige Metriken, saubere Pipeline

---

## Tag 8 – Integration PS ⇄ MongoDB
**Konzepte:** `mongoimport`, `mongosh` Skripte, Idempotenz, Staging  
**Übung:** End-to-End Import & Report-Export  
**Erfolgskriterien:** Vollständiger, wiederholbarer Durchlauf

---

## Tag 9 – Mini-Projekt
**Aufgabe:** E2E Pipeline aus Rohlog bis Report  
**Bewertung:** Funktion, Codequalität, Reproduzierbarkeit  
**Erweiterungen:** Zeitfenster-Parameter, Delta-Loads, Alerts

---

## Anhang A – Setup
- **PowerShell 7 (Core)**: Windows/Mac/Linux  
- **MongoDB Community** + **Compass** + **mongosh**  
- Test: `mongosh --eval "db.version()"`

## Anhang B – Datenformate
- CSV: Trennzeichen, Header, Typkonvertierung  
- JSON: Verschachtelung, `Depth` in PowerShell  
- Zeitformate: `ISODate`, Parsing mit `ParseExact`

## Anhang C – Best Practices
- Logging mit Zeitstempel & PID  
- Konfigurierbarkeit via Parametern/ENV  
- Idempotenz & Wiederanlauffähigkeit  
- Security: Keine Secrets im Code (ENV/Secret Store)

## Anhang D – Troubleshooting
- `COLLSCAN` → passende Indexe bauen  
- `E11000 duplicate key` → Upsert/Keys prüfen  
- Falsche Zeitstempel → Zeitzone/Format prüfen  




-----------

ChatGPT

Unterrichtsplanung: PowerShell & Big Data Essentials

Tag,Thema,Fokus-Inhalte
1,PowerShell Fundamentals,"Objekte & Pipeline, Datentypen, Error Handling, Custom Objects (PSCustomObject)."
2,Data Ingestion (I/O),"Import/Export von CSV, JSON und XML. Arbeiten mit REST-APIs (Invoke-RestMethod), um Rohdaten zu sammeln."
3,Data Transformation,"Filtern, Sortieren und Gruppieren großer Listen. Regex für Data Cleansing (Datenbereinigung)."

Teil 2: Big Data Konzepte & Architekturen (Tag 4-6)
4,Big Data 101 & NoSQL,"Die 5 Vs (Volume, Velocity, etc.). Einführung in NoSQL vs. SQL. Praxis: PowerShell & MongoDB oder CosmosDB."
5,Data Lakes & Cloud Storage,Unterschied Database vs. Data Lake. Strukturierte vs. unstrukturierte Daten. Automatisierung von Cloud-Uploads (Azure Blob / AWS S3).
6,Pipeline Orchestrierung,"Einführung in ETL (Extract, Transform, Load). Wie PowerShell-Skripte als ""Glue"" (Kleber) in automatisierten Workflows dienen."

Teil 3: Advanced Scripting & Analyse (Tag 7-9)
7,Performance & Parallelisierung,PowerShell Jobs und ForEach-Object -Parallel. Warum Geschwindigkeit bei Big Data entscheidend ist.
8,Data Analytics & Reporting,Einfache statistische Auswertungen mit PowerShell. Export für BI-Tools (wie Power BI).
9,Abschlussprojekt / Lab,Bau einer Mini-Pipeline: Daten von API holen → Transformieren → In eine NoSQL DB oder Cloud speichern.


Detailplanung: Tag 2 – Data Ingestion & API-Handling
Ziel: Die Studierenden können Daten aus verschiedenen Quellen automatisiert beziehen.

Zeitplan (3h)
00:00 - 00:45: Theorie & Syntax
Wiederholung JSON-Struktur.
Invoke-RestMethod vs. Invoke-WebRequest.
Authentifizierung (API-Keys im Header).
00:45 - 02:15: Praktische Übung "The Weather Engine"
Task: Daten von einer Wetter-API (z.B. OpenWeatherMap) abrufen.
Challenge: Die API liefert verschachtelte JSON-Objekte. Die Studierenden müssen die Temperatur und Luftfeuchtigkeit extrahieren und in ein flaches Objekt transformieren.
02:15 - 03:00: Fehlerhandling & Export
Umgang mit Timeouts und Rate-Limits.
Speichern der bereinigten Daten als .jsonl (JSON Lines) – ein Standardformat für Big Data Ingestion.


Detailplanung: Tag 4 – NoSQL & Big Data Storage
Ziel: Den Übergang von der Datei zur Datenbank verstehen.

Zeitplan (3h)
00:00 - 00:45: Theorie – Warum NoSQL?
Grenzen von CSV/Excel bei Millionen Datensätzen.
Dokumentenorientierte Datenbanken (z.B. MongoDB).
00:45 - 02:15: Übung "PowerShell to Mongo"
Setup: Nutzen eines Docker-Containers oder einer Cloud-Instanz (Atlas).
Scripting: Ein PowerShell-Modul nutzen (z.B. Mdbc), um eine Verbindung herzustellen.
Operationen: Insert-MdbcData – Die Wetterdaten von Tag 2 automatisiert in die Datenbank schreiben.
02:15 - 03:00: Querying Large Sets
Suchen von spezifischen Einträgen direkt über PowerShell-Befehle, anstatt die ganze Datei zu laden.

Konkrete Übungsvorschläge für die anderen Tage
Für Tag 3 (Transformation): Geben Sie den Studierenden ein "schmutziges" CSV mit inkonsistenten Datumsformaten und leeren Feldern. Sie müssen ein Skript schreiben, das diese normalisiert (Stichwort: Data Wrangling).


Abschlussprojekt: "The Real-Time Data Pipeline"
Die Ausgangslage
Stellen Sie sich vor, Sie arbeiten für einen E-Commerce-Riesen. Das Marketing-Team benötigt eine automatisierte Pipeline, die stündlich die neuesten "Trending Products" von einer API abruft, diese bereinigt und für die langfristige Analyse in eine Big-Data-Datenbank speichert.

Die Aufgabenstellung
Entwickeln Sie ein PowerShell-Skript, das folgende vier Phasen (ETL-Prozess) autonom durchläuft:
1. Phase: Extraction (Datenbeschaffung)
Fragen Sie eine öffentliche REST-API ab (Vorschlag: JSONPlaceholder für Dummy-Daten oder eine Crypto-API wie CoinGecko).
Stellen Sie sicher, dass das Skript Fehler (z.B. API nicht erreichbar) abfängt (Try/Catch).

1. Phase: Transformation (Datenbereinigung)
Filtern: Behalten Sie nur Datensätze, die bestimmte Kriterien erfüllen (z.B. Preis > X oder Kategorie = Y).
Normalisierung: Fügen Sie einen Zeitstempel (Timestamp) im ISO-8601-Format hinzu, damit man später weiss, wann die Daten erhoben wurden.
Mapping: Benennen Sie kryptische API-Felder in sprechende Namen um.

1. Phase: Loading (Speicherung)
Speichern Sie die Daten in zwei Formaten:
Lokal als .jsonl (JSON Lines) – ideal für Big Data Processing.
Remote in eine NoSQL-Datenbank (z.B. MongoDB Cloud oder eine lokale Instanz).

1. Phase: Reporting (Mini-Analyse)
Geben Sie in der Konsole eine Zusammenfassung aus: "X Datensätze verarbeitet. Durchschnittswert: Y. Status: Erfolgreich."

Bewertungskriterien (Checkliste für Sie)
Um die HF-Studierenden fair zu bewerten, können Sie folgende Punkte heranziehen:

Kriterium,Erwartung (Punkte 1-5)
Code-Struktur,Wurden Funktionen genutzt? Ist der Code modular aufgebaut?
Error Handling,"Stürzt das Skript ab, wenn die Internetverbindung fehlt?"
Big Data Verständnis,Wurden Objekte korrekt in JSON transformiert?
Automatisierung,Läuft das Skript ohne manuelle Eingriffe durch?
Dokumentation,Sind die wichtigsten Zeilen im Skript kommentiert?


Hier ist eine strukturierte Musterlösung für das Abschlussprojekt. 
Das Skript ist modular aufgebaut, nutzt Best Practices wie Try/Catch und demonstriert den kompletten ETL-Prozess (Extract, Transform, Load).

Als Beispiel-Datenquelle nutze ich die CoinGecko API, da sie echte, dynamische Daten liefert, was dem "Big Data"-Gedanken sehr nahe kommt.

```powershell
<#
.SYNOPSIS
    ETL-Pipeline für Kryptowährungs-Daten.
    Extrahiert Daten von einer API, transformiert sie und speichert sie lokal sowie in einer DB.
#>

# --- KONFIGURATION ---
$apiUrl = "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=10&page=1"
$outputPath = "$PSScriptRoot\crypto_data.jsonl"

# --- FUNKTIONEN ---

function Get-CryptoData {
    [CmdletBinding()]
    param([string]$Url)
    try {
        Write-Host "--- Phase 1: Extraction ---" -ForegroundColor Cyan
        $data = Invoke-RestMethod -Uri $Url -Method Get
        return $data
    }
    catch {
        Write-Error "Fehler beim Abrufen der Daten: $($_.Exception.Message)"
        return $null
    }
}

function Transform-CryptoData {
    [CmdletBinding()]
    param($RawData)
    Write-Host "--- Phase 2: Transformation ---" -ForegroundColor Cyan
    
    $transformed = $RawData | ForEach-Object {
        # Transformation in ein sauberes PSCustomObject (Mapping & Normalisierung)
        [PSCustomObject]@{
            AssetID      = $_.id.ToUpper()
            Symbol       = $_.symbol
            PriceUSD     = [math]::Round($_.current_price, 2)
            MarketCap    = $_.market_cap
            ProcessedAt  = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") # ISO-Timestamp
            Source       = "CoinGecko API"
        }
    }
    return $transformed
}

function Save-ToBigDataStorage {
    [CmdletBinding()]
    param($Data, $Path)
    Write-Host "--- Phase 3: Loading ---" -ForegroundColor Cyan
    
    try {
        # 1. Lokale Speicherung als JSON Lines (.jsonl) - Standard für Big Data
        $Data | ForEach-Object { $_ | ConvertTo-Json -Compress } | Out-File -FilePath $Path -Append -Encoding utf8
        Write-Host "[OK] Daten lokal in $Path gespeichert." -ForegroundColor Green
        
        # 2. Platzhalter für NoSQL / MongoDB
        # Hier würde der Code stehen: $Data | ConvertTo-MdbcItem | Save-MdbcData
        Write-Host "[INFO] Mockup: Daten erfolgreich an NoSQL-Cluster gesendet." -ForegroundColor Yellow
    }
    catch {
        Write-Error "Fehler beim Speichern: $($_.Exception.Message)"
    }
}

# --- MAIN SCRIPT EXECUTION ---

$rawData = Get-CryptoData -Url $apiUrl

if ($null -ne $rawData) {
    $processedData = Transform-CryptoData -RawData $rawData
    Save-ToBigDataStorage -Data $processedData -Path $outputPath
    
    # --- Phase 4: Reporting ---
    Write-Host "`n--- Summary ---" -ForegroundColor Magenta
    Write-Host "Verarbeitete Datensätze: $($processedData.Count)"
    $avgPrice = ($processedData.PriceUSD | Measure-Object -Average).Average
    Write-Host "Durchschnittlicher Preis der Top 10: $avgPrice USD"
}
```

Erklärungen zur Lösung für die Klasse
1. Datenstruktur (Big Data Ready)
Statt eines Standard-JSON-Arrays [...] generiert das Skript JSON Lines.

Warum? In Big-Data-Umgebungen (wie Hadoop oder Spark) sind riesige Arrays schwer zu verarbeiten, da die ganze Datei geladen werden muss. JSONL erlaubt es, Daten zeilenweise zu streamen.

2. Error Handling
Das Try-Catch-Block-Konzept ist essenziell. Bei 3-stündigen Unterrichtseinheiten sollten Sie betonen, dass ein Skript, das bei einem Netzwerkfehler abstürzt, in einer produktiven Pipeline unbrauchbar ist.

3. Pipeline-Prinzip
Das Skript folgt streng dem Single Responsibility Principle. Jede Funktion hat genau eine Aufgabe (Holen, Ändern, Speichern). Das macht den Code testbar und wartbar.

---









1. Vorbereitung: MongoDB starten (Docker)
Falls Sie keine laufende MongoDB haben, können Sie diese für den Unterricht schnell via Docker starten:

PowerShell
# Startet eine MongoDB-Instanz auf Port 27017
docker run --name hf-mongo -d -p 27017:27017 mongo
2. Das PowerShell-Modul installieren
Öffnen Sie eine PowerShell (als Administrator) und installieren Sie das Modul:

PowerShell
Install-Module -Name Mdbc -Scope CurrentUser -Force
3. PowerShell Skript: Verbindung & Daten-Upload
Dieses Skript nimmt ein PowerShell-Objekt und speichert es direkt als Dokument in der MongoDB.

PowerShell
```powershell
# 1. Modul importieren
Import-Module Mdbc

# 2. Verbindung herstellen (Connection String)
# Standardmäßig ist kein Passwort bei einer lokalen Docker-Instanz gesetzt
$connString = "mongodb://localhost:27017"
$dbName     = "UnterrichtDB"
$collectionName = "BigDataLog"

try {
    # Verbindung zur Collection herstellen (wird erstellt, falls nicht vorhanden)
    $collection = Connect-Mdbc -ConnectionString $connString -DatabaseName $dbName -CollectionName $collectionName
    Write-Host "Erfolgreich mit MongoDB verbunden!" -ForegroundColor Green

    # 3. Test-Datenobjekt erstellen (z.B. ein Server-Log)
    $myData = [PSCustomObject]@{
        Timestamp = Get-Date
        Server    = $env:COMPUTERNAME
        Status    = "Online"
        Uptime    = 12345
        Tags      = @("HF-Klasse", "PowerShell", "BigData")
    }

    # 4. Daten in MongoDB einfügen
    $myData | Send-MdbcData -Collection $collection
    Write-Host "Daten erfolgreich in MongoDB gespeichert." -ForegroundColor Cyan

    # 5. Daten wieder abfragen (Query)
    Write-Host "Abfrage der letzten Einträge:" -ForegroundColor Yellow
    Get-MdbcData -Collection $collection | Out-GridView -Title "MongoDB Inhalt"

}
catch {
    Write-Error "Verbindung fehlgeschlagen: $($_.Exception.Message)"
}
finally {
    # Verbindung trennen ist bei Mdbc meist implizit, aber gute Praxis
    Disconnect-Mdbc
}
```

Warum ist das für die HF-Klasse wichtig?
Schema-Freiheit: Erklären Sie den Schülern, dass wir im Skript oben einfach ein PSCustomObject senden können, ohne vorher in der Datenbank Tabellen oder Spalten definieren zu müssen. Das ist ein Kernkonzept von Big Data (Schema-on-Read).

Skalierbarkeit: In einer echten Big-Data-Umgebung könnte dieses Skript auf hunderten Servern gleichzeitig laufen und Log-Daten zentral in den MongoDB-Cluster schreiben.

JSON-Integration: MongoDB speichert Daten im BSON-Format (Binary JSON). Da PowerShell exzellent mit Objekten umgeht, ist die Übersetzung nahezu nahtlos.

Was ist der nächste logische Schritt?
Möchten Sie, dass ich ein Cheat-Sheet mit den wichtigsten Mdbc-Befehlen (Finden, Update, Löschen) erstelle, das Sie den Studierenden als PDF-Vorlage abgeben können?



Befehl,Beschreibung,Beispiel
Connect-Mdbc,Verbindung zu DB & Collection herstellen,"$coll = Connect-Mdbc -ConnectionString ""mongodb://localhost"" -DatabaseName ""HF_DB"" -CollectionName ""Logs"""
Send-MdbcData,Objekte in die DB schreiben (Insert),$meinObjekt | Send-MdbcData -Collection $coll
Get-MdbcData,Daten aus der DB abrufen (Find),$alleDaten = Get-MdbcData -Collection $coll
Get-MdbcData -Filter,Gefilterte Abfrage (Query),"Get-MdbcData -Collection $coll -Filter '{ ""Status"": ""Error"" }'"
Update-MdbcData,Bestehende Dokumente ändern,"Update-MdbcData -Collection $coll -Filter '{ ""ID"": 1 }' -Update '{ ""$set"": { ""Status"": ""Fixed"" } }'"
Remove-MdbcData,Dokumente löschen,"Remove-MdbcData -Collection $coll -Filter '{ ""Expired"": true }'"


Praxisauftrag 1: "System-Health Monitor"
Szenario: Sie sollen ein Monitoring-Tool schreiben, das den freien Festplattenspeicher aller Laufwerke prüft und das Ergebnis in einer MongoDB speichert.

Aufgabe:

Ermitteln Sie den freien Speicherplatz (in GB) aller lokalen Laufwerke.

Erstellen Sie für jedes Laufwerk ein Objekt mit Zeitstempel, Servername, Laufwerkbuchstabe und FreierSpeicherGB.

Speichern Sie diese Objekte in der Collection SystemHealth.

Musterlösung Auftrag 1:

PowerShell
```powershell
Import-Module Mdbc
$coll = Connect-Mdbc -ConnectionString "mongodb://localhost:27017" -DatabaseName "Monitoring" -CollectionName "SystemHealth"

# 1. Daten sammeln
$drives = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }

$data = $drives | ForEach-Object {
    [PSCustomObject]@{
        Timestamp   = Get-Date
        Server      = $env:COMPUTERNAME
        Drive       = $_.DeviceID
        FreeSpaceGB = [math]::Round($_.FreeSpace / 1GB, 2)
    }
}

# 2. In MongoDB schreiben
$data | Send-MdbcData -Collection $coll
Write-Host "Monitoring-Daten erfolgreich gespeichert." -ForegroundColor Green
```


Praxisauftrag 2: "Big Data Querying"
Szenario: Die Datenbank enthält nun viele Einträge. Das Management möchte einen Bericht über kritische Zustände.

Aufgabe:

Fragen Sie die Collection SystemHealth ab.

Filtern Sie direkt über die MongoDB-Query-Syntax alle Einträge heraus, bei denen FreeSpaceGB kleiner als 20 (GB) ist.

Geben Sie die Resultate tabellarisch in der Konsole aus.

Musterlösung Auftrag 2:

PowerShell
```powershell
Import-Module Mdbc
$coll = Connect-Mdbc -ConnectionString "mongodb://localhost:27017" -DatabaseName "Monitoring" -CollectionName "SystemHealth"

# Filter definieren: Suche Dokumente, wo FreeSpaceGB kleiner als ($lt) 20 ist
$filter = '{ "FreeSpaceGB": { "$lt": 20 } }'

# Abfrage ausführen
$criticalDrives = Get-MdbcData -Collection $coll -Filter $filter

if ($criticalDrives) {
    Write-Host "WARNUNG: Kritischer Speicherplatz gefunden!" -ForegroundColor Red
    $criticalDrives | Select-Object Timestamp, Drive, FreeSpaceGB | Format-Table
} else {
    Write-Host "Alle Laufwerke im grünen Bereich." -ForegroundColor Green
}
```


Empfohlene Datenquellen für das Projekt
1. Finanz- & Kryptodaten (Hohe Velocity)
Perfekt, um das Thema "Echtzeit-Daten" und Transformation zu üben.

CoinGecko API: Liefert aktuelle Kurse von tausenden Kryptowährungen. Keine Registrierung für Basis-Abfragen nötig.

URL: https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd

ExchangeRate-API: Aktuelle Wechselkurse für über 160 Währungen.

Nutzen: Umrechnung von Werten in der Pipeline (z.B. USD in CHF).

2. Open Data Schweiz (Lokaler Bezug)
Für eine Schweizer HF-Klasse ist der Bezug zu lokalen Daten oft sehr motivierend.

Opendata.swiss: Das zentrale Portal für Schweizer Behördendaten.

Beispiele: Aktuelle Standorte von Mobility-Fahrzeugen, Postleitzahlen-Verzeichnisse oder Wetterdaten von MeteoSchweiz.

OpenTransportData.swiss: Echtzeit-Fahrplandaten des öffentlichen Verkehrs (SBB/ZVV etc.).

Nutzen: Komplexere JSON-Strukturen, ideal für Fortgeschrittene.

3. Wissenschaft & Umwelt
NASA APIs: Riesige Auswahl an Daten zu Asteroiden, Mars-Fotos oder Erdbeobachtung.

URL: https://api.nasa.gov (Erfordert kostenlosen API-Key).

OpenWeatherMap: Der Klassiker für Wetterdaten weltweit.

Nutzen: Gut geeignet, um Vergleiche zwischen verschiedenen Städten zu skripten.



Praxis-Tipp für den Unterricht
Geben Sie den Studierenden dieses kleine Code-Snippet als "Starter-Kit", um die Datenquelle zu testen:

PowerShell
```powershell
# Test-Abfrage für CoinGecko (Top 5 Coins)
$uri = "https://api.coingecko.com/api/v3/coins/markets?vs_currency=eur&order=market_cap_desc&per_page=5&page=1"
$data = Invoke-RestMethod -Uri $uri

# Daten in der Konsole visualisieren
$data | Select-Object name, symbol, current_price | Format-Table
```


1. https://www.kaggle.com/
2. https://datasetsearch.research.google...
3. https://data.fivethirtyeight.com/
4. https://data.gov/
5. https://github.com/search?q=dataset
6. https://data.nasa.gov/
