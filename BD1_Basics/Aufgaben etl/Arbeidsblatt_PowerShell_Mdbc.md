
# Arbeitsblatt – PowerShell & MongoDB mit Mdbc

## Übersicht
Dieses Arbeitsblatt führt dich Schritt für Schritt durch praxisnahe Übungen zum Zusammenspiel von **PowerShell**, **MongoDB** und dem **Mdbc-Modul**. Es beinhaltet Aufgaben, Hinweise und Musterlösungen. Nutze die bereitgestellten Datensätze aus dem Paket `teaching_datasets`.

---

## Voraussetzungen
- PowerShell 7
- MongoDB Community Server + `mongosh`
- Lokale MongoDB-Instanz: `mongodb://localhost:27017`
- Datenbank: `hf_class`
- Mdbc-Modul installiert:
  ```powershell
  Install-Module Mdbc -Scope CurrentUser
  Import-Module Mdbc
  ```
- Entpacktes Datenpaket `teaching_datasets` im aktuellen Arbeitsverzeichnis

---

## Lernziele
- Verbindung zu MongoDB herstellen und Collections binden
- CRUD-Operationen mit Mdbc durchführen
- JSON-Daten validieren und importieren
- Logfiles per Regex parsen und bereinigen
- Aggregationen (KPIs) über Mdbc ausführen
- Indexe inkl. TTL für Zeitreihen anlegen
- Upserts für idempotente Datenläufe erstellen

---

## Aufgabe 0 – Verbindung & Basis-Setup
**Lernziel:** Erste Schritte mit Mdbc – Verbindung, Collection binden, Dokumente zählen.

### Aufgabe
1. Stelle eine Verbindung zur MongoDB her: `mongodb://localhost:27017`.
2. Wähle die Datenbank `hf_class` und die Collection `sandbox`.
3. Zähle die Anzahl der Dokumente.
4. Leere die Collection.

### Musterlösung
```powershell
Import-Module Mdbc

Connect-Mdbc -ConnectionString "mongodb://localhost:27017" `
             -Database hf_class -Collection sandbox

(Get-MdbcData | Measure-Object).Count
Remove-MdbcData -All
```

---

## Aufgabe 1 – CRUD: Kundenverwaltung
**Lernziel:** Insert/Find/Update/Delete mit Mdbc.

### Aufgabe
1. Lege 3 Kunden in der Collection `customers` an: Felder `_id`, `name`, `city`, `tags` (Array).
2. Suche alle Kunden aus **Bern**.
3. Füge dem Kunden **Alice** das Tag `vip` hinzu (ohne Duplikat).
4. Lösche den Kunden **Bob**.

### Musterlösung
```powershell
Connect-Mdbc -ConnectionString "mongodb://localhost:27017" `
             -Database hf_class -Collection customers

Remove-MdbcData -All

Add-MdbcData @(
  @{ _id=1; name="Alice"; city="Bern";   tags=@("newsletter") }
  @{ _id=2; name="Bob";   city="Zürich"; tags=@("newsletter") }
  @{ _id=3; name="Cara";  city="Basel";  tags=@() }
)

Get-MdbcData -Filter @{ city="Bern" }

Update-MdbcData -Filter @{ name="Alice" } `
                -Update @{ '$addToSet' = @{ tags="vip" } }

Remove-MdbcData -Filter @{ name="Bob" }
```

---

## Aufgabe 2 – JSON-Import & Queries (Orders)
**Lernziel:** JSON importieren, filtern, sortieren, projizieren, gruppieren.

### Aufgabe
1. Importiere `teaching_datasets/shop_orders.json` in die Collection `orders`.
2. Finde alle Bestellungen mit `total > 40`.
3. Gib nur `orderId` und `total` aus, sortiert nach `total` absteigend.
4. Gruppiere nach Zahlungsmethode (`payment`) und zähle Bestellungen.

### Musterlösung
```powershell
Connect-Mdbc -ConnectionString "mongodb://localhost:27017" `
             -Database hf_class -Collection orders
Remove-MdbcData -All

$orders = Get-Content ".\teaching_datasets\shop_orders.json" -Raw | ConvertFrom-Json
Add-MdbcData $orders

Get-MdbcData -Filter @{ total = @{ '$gt'=40 } } `
             -Project @{ _id=0; orderId=1; total=1 } `
             -Sort @{ total=-1 }

Invoke-MdbcAggregate @(
  @{ '$group' = @{ _id='$payment'; count=@{ '$sum'=1 } } },
  @{ '$sort'  = @{ count=-1 } }
)
```

---

## Aufgabe 3 – Fehlerhafte Orders validieren (ETL)
**Lernziel:** Datenvalidierung in PowerShell: gültig/ungültig trennen.

### Aufgabe
1. Lade `shop_orders.json` **und** `shop_orders_faulty.json`.
2. Validiere pro Order:
   - `orderId` ist Zahl
   - `total` ist Zahl
   - `ts` ist gültiges Datum
3. Schreibe gültige Datensätze → `orders_clean.json`, fehlerhafte → `orders_failed.json`.
4. Importiere **nur** `orders_clean.json` in die Collection `orders`.

### Musterlösung
```powershell
function Test-Order {
    param($o)
    $ok = $true
    if (-not ($o.orderId -as [int]))   { $ok = $false }
    if (-not ($o.total   -as [double])){ $ok = $false }
    try { [void][datetime]$o.ts } catch { $ok = $false }
    return $ok
}

$all = @()
$all += (Get-Content ".\teaching_datasets\shop_orders.json" -Raw | ConvertFrom-Json)
$all += (Get-Content ".\teaching_datasets\shop_orders_faulty.json" -Raw | ConvertFrom-Json)

$clean  = New-Object System.Collections.Generic.List[object]
$failed = New-Object System.Collections.Generic.List[object]

foreach($o in $all){ if(Test-Order $o){ $clean.Add($o) } else { $failed.Add($o) } }

$clean  | ConvertTo-Json -Depth 10 | Set-Content ".\teaching_datasets\orders_clean.json"
$failed | ConvertTo-Json -Depth 10 | Set-Content ".\teaching_datasets\orders_failed.json"

Connect-Mdbc -ConnectionString "mongodb://localhost:27017" `
             -Database hf_class -Collection orders
Remove-MdbcData -All
Add-MdbcData $clean
```

---

## Aufgabe 4 – IoT: Zeitreihen & Indexe
**Lernziel:** TTL-Index & Compound-Index; Zeit-Queries.

### Aufgabe
1. Lade `iot_metrics.jsonl` und `iot_metrics_faulty.jsonl`.
2. Validiere minimal: `deviceId` vorhanden, `ts` ist gültiger Zeitstempel.
3. Schreibe validierte Daten in `iot_clean.json` und importiere in Collection `iot`.
4. Erzeuge Indexe:
   - TTL `{ ts: 1 }` mit 30 Tagen
   - Compound `{ deviceId: 1, ts: -1 }`
5. Frage die letzten 5 Messungen von `SEN-1001` ab.

### Musterlösung (Kernausschnitt)
```powershell
# Validierung (analog Aufgabe 3), Ergebnisdatei: .\teaching_datasets\iot_clean.json

Connect-Mdbc -ConnectionString "mongodb://localhost:27017" `
             -Database hf_class -Collection iot
Remove-MdbcData -All

# Import der validierten JSON (Array)
Add-MdbcData (Get-Content ".\teaching_datasets\iot_clean.json" -Raw | ConvertFrom-Json)

# Indexe
Add-MdbcIndex @{ ts=1 } -ExpireAfterSeconds (60*60*24*30)
Add-MdbcIndex @{ deviceId=1; ts=-1 }

# Abfrage
Get-MdbcData -Filter @{ deviceId="SEN-1001" } -Sort @{ ts=-1 } -Limit 5
```

---

## Aufgabe 5 – Logfiles parsen & speichern
**Lernziel:** Regex-Parsing, Fehlertrennung, Insert in `logs`.

### Aufgabe
1. Parse `access.log` und `access_faulty.log`.
2. Zielstruktur: `ip`, `ts (UTC)`, `method`, `path`, `status`, `bytes`.
3. Schreibe fehlerhafte Zeilen in `logs_failed.log`.
4. Speichere gültige Zeilen in Collection `logs`.

### Musterlösung
```powershell
$pattern = '^(?<ip>\S+) \S+ \S+ \[(?<ts>[^\]]+)\] "(?<method>\S+) (?<path>\S+) \S+" (?<status>\d{3}) (?<bytes>\d+|-)'

$valid = [System.Collections.Generic.List[object]]::new()
$invalid = [System.Collections.Generic.List[string]]::new()

Get-Content .\teaching_datasets\access.log, .\teaching_datasets\access_faulty.log |
ForEach-Object {
    if ($_ -match $pattern) {
        try {
            $ts = [datetime]::ParseExact(
                $Matches.ts,'dd/MMM/yyyy:HH:mm:ss zzz',
                [Globalization.CultureInfo]::InvariantCulture
            )
            $valid.Add([pscustomobject]@{
                ip=$Matches.ip
                ts=$ts.ToUniversalTime()
                method=$Matches.method
                path=$Matches.path
                status=[int]$Matches.status
                bytes= if($Matches.bytes -eq '-') {0} else {[int]$Matches.bytes}
            })
        } catch { $invalid.Add($_) }
    } else { $invalid.Add($_) }
}

$invalid | Set-Content ".\teaching_datasets\logs_failed.log"

Connect-Mdbc -ConnectionString "mongodb://localhost:27017" `
             -Database hf_class -Collection logs
Remove-MdbcData -All
Add-MdbcData $valid
```

---

## Aufgabe 6 – Aggregationen & KPIs
**Lernziel:** Aggregationspipelines mit `Invoke-MdbcAggregate`.

### Aufgabe
1. **Top 5 URLs** nach Hits (Collection `logs`).
2. **Fehlerrate pro Minute** (HTTP-Status ≥ 500).
3. **Durchschnittliche Antwortgröße (`bytes`)** pro URL.

### Musterlösung
```powershell
Connect-Mdbc -ConnectionString "mongodb://localhost:27017" `
             -Database hf_class -Collection logs

# Top 5 URLs
Invoke-MdbcAggregate @(
  @{ '$group' = @{ _id='$path'; hits=@{ '$sum'=1 } } },
  @{ '$sort'  = @{ hits=-1 } },
  @{ '$limit' = 5 }
)

# Fehlerrate pro Minute
Invoke-MdbcAggregate @(
  @{ '$group' = @{
        _id=@{ '$dateTrunc'=@{ date='$ts'; unit='minute' } }
        total=@{ '$sum'=1 }
        errors=@{ '$sum'=@{ '$cond'=@(@{ '$gte'=@('$status',500) },1,0) } }
  }},
  @{ '$project' = @{
        time='$_id'; total=1; errors=1
        errorRatePct=@{ '$round'=@(@{ '$multiply'=@(@{ '$divide'=@('$errors','$total') },100) },2) }
        _id=0
  }},
  @{ '$sort' = @{ time=1 } }
)

# Durchschnittliche Bytes pro URL
Invoke-MdbcAggregate @(
  @{ '$group' = @{ _id='$path'; avgBytes=@{ '$avg'='$bytes' } } },
  @{ '$sort'  = @{ avgBytes=-1 } }
)
```

---

## Zusatzaufgabe – Upsert & Idempotenz (Orders)
**Lernziel:** Upsert-Muster mit `$set` und `$setOnInsert`.

### Aufgabe
- Erstelle/aktualisiere die Order `_id = 9999` so, dass `createdAt` nur beim ersten Insert gesetzt wird.
- Führe das Skript zweimal aus und überprüfe, dass **kein Duplikat** entsteht.

### Musterlösung
```powershell
Connect-Mdbc -ConnectionString "mongodb://localhost:27017" `
             -Database hf_class -Collection orders

$now = Get-Date
Update-MdbcData `
  -Filter @{ _id = 9999 } `
  -Update @{
    '$set'        = @{ total=42.5; payment='creditcard'; ts=$now }
    '$setOnInsert'= @{ createdAt=$now }
  } `
  -Upsert

Get-MdbcData -Filter @{ _id = 9999 } | Format-List
```

---

## Hinweise & Best Practices
- **Fehlerhandling**: Nutze `try/catch` und schreibe Logs mit Zeitstempel.
- **Validierung**: Trenne Clean/Failed-Daten für Transparenz und Re-Run.
- **Indexe**: Optimiere nach häufigen Abfragen; prüfe Laufzeiten.
- **Idempotenz**: Upserts + deterministische Keys verwenden.
- **Security**: Keine Secrets im Code; nutze Umgebungsvariablen/Secret Vault.

---

Viel Erfolg und viel Spaß beim Üben!
