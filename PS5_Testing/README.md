|                             |                          |                                 |
| --------------------------- | ------------------------ | ------------------------------- |
| **Techniker HF Informatik** | **Scripting / Big data** | ![Logo](./../x_gitres/logo.png) |

- [1. Testing und Debugging](#1-testing-und-debugging)
  - [1.1. Lernziele](#11-lernziele)
  - [1.2. Warum Testing \& Debugging?](#12-warum-testing--debugging)
  - [1.3. Arten von Tests](#13-arten-von-tests)
  - [1.4. Testplan (Template)](#14-testplan-template)
  - [1.5. Manuelles Testing (schnell \& effektiv)](#15-manuelles-testing-schnell--effektiv)
  - [1.6. Fehlerbehandlung für testbares Verhalten](#16-fehlerbehandlung-für-testbares-verhalten)
- [2. Debugging – Werkzeuge \& Techniken](#2-debugging--werkzeuge--techniken)
  - [2.1. VS Code Debugger (empfohlen)](#21-vscode-debugger-empfohlen)
  - [2.2. PowerShell‑eigene Hilfen](#22-powershelleigene-hilfen)
  - [2.3. Testdokumentation (README.md)](#23-testdokumentation-readmemd)
  - [2.4. Automatisiertes Testen mit Pester v5](#24-automatisiertes-testen-mit-pester-v5)
    - [2.4.1. Installation \& Voraussetzungen](#241-installation--voraussetzungen)
    - [2.4.2. Aufbau einer Pester-Testdatei](#242-aufbau-einer-pester-testdatei)
    - [2.4.3. Wichtige Should-Assertions](#243-wichtige-should-assertions)
    - [2.4.4. Vollständiges Beispiel: Get-RentalCost testen](#244-vollständiges-beispiel-get-rentalcost-testen)
    - [2.4.5. Projektstruktur mit Pester](#245-projektstruktur-mit-pester)
- [3. Aufgaben](#3-aufgaben)
  - [3.1. Testplan für Skript erstellen](#31-testplan-für-skript-erstellen)
  - [3.2. Debugging in VS Code – Breakpoints \& Watch](#32-debugging-in-vscode--breakpoints--watch)
  - [3.3. Logger mit Debug-Level implementieren](#33-logger-mit-debug-level-implementieren)
  - [3.4. Pester-Tests implementieren](#34-pester-tests-implementieren)

---

</br>

# 1. Testing und Debugging

## 1.1. Lernziele

- Geeignete **Teststrategien** (Positiv/Negativ, Randwerte, Sonderfälle) entwerfen und Testpläne erstellen.
- Skripte **gezielt testen** – manuell und (bei Bedarf) automatisiert mit Pester v5.
- **Fehlerbehandlung** strukturiert aufbauen und Exitcodes/Logs verifizieren.
- **Debugging‑Techniken** (VS Code Debugger, Breakpoints, Set-PSDebug, Write-Debug, eigene Debug‑Schalter) sicher anwenden.
- reproduzierbare **Nachweise** (Logs, Testergebnisse) erstellen.

## 1.2. Warum Testing & Debugging?

- Testing prüft Korrektheit, Robustheit, Reproduzierbarkeit – besonders wichtig, wenn Skripte geplant (Task Scheduler) oder ereignisgesteuert laufen.
- Debugging reduziert Zeit bei der Fehlersuche, macht Ursachen sichtbar (Stack, Variablenzustände) und verhindert Trial‑and‑Error.

> **Merksatz: „Testen zeigt, dass Fehler da sind. Debugging zeigt, warum sie da sind.“**

## 1.3. Arten von Tests

- **Funktionale Tests (Happy Path)** – z. B. korrektes Erstellen eines ZIP‑Archivs.
- **Negativtests** – ungültige Pfade/Dateien, fehlende Rechte, Platte voll, Netzwerkfehler.
- **Randwerttests** – keine Dateien, sehr viele Dateien (>10k), sehr grosse Dateien (>1 GB), sehr lange Pfade, Sonderzeichen/Unicode.
- **Idempotenz** – mehrfaches Ausführen verändert das System nicht ungewollt.
- **Performance/Robustheit (Basis)** – Zeitverhalten/Retry‑Muster, $ProgressPreference='SilentlyContinue' für Massenoperationen.

## 1.4. Testplan (Template)

Ein Testplan definiert Ziel/Umfang, Umgebung, Fälle (Schritte/Erwartung), Ergebnis, Massnahmen.

```powershell
# Testplan – <Projektname>

## Umgebung
- Windows-Build, PowerShell 7.x (pwsh.exe)
- Rechte/Konto, Pfade, Testdaten

## Testfälle
TC-01 Positiv – Normale Dateien
- Schritte: ...
- Erwartung: Exitcode 0; ZIP erzeugt; Log enthält "Archiv erstellt"
- Ergebnis: PASS/FAIL

TC-02 Negativ – Pfad fehlt
- Erwartung: Exitcode != 0; Log enthält "Source-Pfad ungültig"

TC-03 Sonderzeichen – äöü ss 空白
- Erwartung: ZIP enthält Dateien korrekt; keine Encoding-Probleme

TC-04 Grenzwert – >1 GB
- Erwartung: Erfolg oder sauberer Fehler; Log dokumentiert Grund
```
  
## 1.5. Manuelles Testing (schnell & effektiv)

Aufruf mit Parametern + Exitcode prüfen

```powershell
# Erfolgspfad
pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\CleanUpLogs.ps1" `
  -Source "C:\Logs" -Destination "D:\Archive" -Verbose
$LASTEXITCODE   # 0 erwartet

# Fehlerfall (Pfad existiert nicht)
pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\CleanUpLogs.ps1" `
  -Source "C:\Nope" -Destination "D:\Archive"
$LASTEXITCODE   # != 0 erwartet
```

> **Hinweis:** `$LASTEXITCODE` (grossgeschrieben) ist die automatische PS-Variable für den Exitcode des zuletzt gestarteten externen Prozesses. `$LastExitCode` (gemischt) funktioniert dank case-insensitivity ebenfalls – `echo $LASTEXITCODE` ist jedoch zu vermeiden, da `echo` ein Alias für `Write-Output` ist und nichts mit dem Exitcode-Wert macht.

## 1.6. Fehlerbehandlung für testbares Verhalten

**Das Grundmuster:**

```powershell
$ErrorActionPreference = 'Stop'   # non-terminating => terminating
try {
  # ... Arbeit
  exit 0
}
catch {
  Write-Error "Fehler: $($_.Exception.Message)"
  exit 1
}
```

Erwartbare Fehler gezielt erzeugen/prüfen

- Ungültige Eingabe/Datei: throw "Pfad ungültig: $Source"
- Fehlertexte konkret halten (erleichtert Log‑Suche & Pester‑Asserts).

---

</br>

# 2. Debugging – Werkzeuge & Techniken

## 2.1. VS Code Debugger (empfohlen)

- Breakpoints setzen (F9)
- Step Over / Into / Out
- Variablen/Watch & Call Stack
- Launch‑Konfiguration für Skript mit Parametern

Minimal‑launch.json (Beispiel):

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "PowerShell",
      "request": "launch",
      "name": "Script debuggen",
      "script": "C:\\Scripts\\CleanUpLogs.ps1",
      "args": ["-Source","C:\\Logs","-Destination","D:\\Archive","-Verbose"],
      "cwd": "C:\\Scripts"
    }
  ]
}
```

## 2.2. PowerShell‑eigene Hilfen

- Set-PSDebug -Step – **Schrittweises** Abarbeiten (PS 5.1 vorhanden).
- Write-Debug – gezielte Debug‑Ausgabe; sichtbar mit -Debug.
- Write-Verbose – Laufzeitinfos; sichtbar mit -Verbose.
- **Eigener Debug‑Modus** (z.B. -DebugMode), um **zusätzliche** Logs zu aktivieren.
- Start-Transcript/Stop-Transcript – vollständige Sitzung mitschreiben.

Beispiel – eigener Logger inkl. Debug:

```powershell
# Logger-Konfiguration (script:-Scope, sichtbar im ganzen Skript)
$script:LogPath  = ".\script.log"
$script:LogDebug = $false   # auf $true setzen für DEBUG-Ausgaben

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO','WARN','ERROR','DEBUG')]
        [string]$Level = 'INFO'
    )
    # Guard: DEBUG nur ausgeben wenn aktiviert
    if ($Level -eq 'DEBUG' -and -not $script:LogDebug) { return }

    $line = "[{0}] {1} {2}" -f $Level, (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    $line | Out-File -FilePath $script:LogPath -Append -Encoding utf8

    switch ($Level) {
        'ERROR' { Write-Error   $Message }
        'WARN'  { Write-Warning $Message }
        'DEBUG' { Write-Debug   $Message }
        default { Write-Verbose $Message }
    }
}

# Verwendung:
Write-Log "Skript gestartet"
Write-Log "Warnung aufgetreten"           -Level WARN
Write-Log "Kritischer Fehler"             -Level ERROR
Write-Log "Zwischenwert i=3"              -Level DEBUG   # nur wenn $script:LogDebug = $true
```

> **Warum nicht `New-Logger` mit ScriptBlock-Rückgabe?** Das ursprüngliche Muster (`return` gefolgt von `{ ... }` auf der nächsten Zeile) gibt in PowerShell keinen ScriptBlock zurück – `return` ohne Argument auf einer eigenen Zeile beendet die Funktion sofort. Der nachfolgende Block wird als selbstständige Anweisung interpretiert und nie zurückgegeben. Die `Write-Log`-Funktion mit `$script:`-Scope ist idiomatischer und zuverlässiger.

## 2.3. Testdokumentation (README.md)

Testdurchführung muss detailliert dokumentiert sein:

- Zweck, Voraussetzungen, Installation
- Verwendung/Parameter mit Beispielen
- Betrieb (z. B. Task Scheduler), Logpfade/Rotation
- Troubleshooting/Exitcodes/typische Fehler
- Konten/Rechte, Freigaben/ACLs, Monitoring (LastTaskResult, Eventlog), Update‑/Rollback‑Vorgehen

---

</br>

## 2.4. Automatisiertes Testen mit Pester v5

**Pester** ist das offizielle Test-Framework für PowerShell. Es ermöglicht automatisierte Unit- und Integrationstests, die wiederholbar, versionierbar und in CI/CD-Pipelines integrierbar sind.

### 2.4.1. Installation & Voraussetzungen

```powershell
# Aktuelle Version installieren (als Administrator)
Install-Module -Name Pester -Force -Scope AllUsers

# Version prüfen (mindestens 5.x)
Get-Module -Name Pester -ListAvailable | Select-Object Name, Version
```

> **Hinweis:** Windows 10/11 enthält noch Pester v3 als Systemodul. Ohne `-Force` wird das alte Modul nicht überschrieben. Im Zweifel explizit importieren: `Import-Module Pester -MinimumVersion 5.0`.

---

### 2.4.2. Aufbau einer Pester-Testdatei

Pester-Tests werden in Dateien mit der Endung `.Tests.ps1` gespeichert.
Die Struktur folgt drei Ebenen:

| **Schlüsselwort** | **Bedeutung**                                           |
| ----------------- | ------------------------------------------------------- |
| `Describe`        | Testgruppe – beschreibt eine Funktion oder ein Szenario |
| `Context`         | Untergruppe – z. B. Happy Path / Fehlerfall             |
| `It`              | Einzelner Testfall mit konkreter Erwartung              |
| `Should`          | Assertion – prüft den erwarteten Wert/Zustand           |
| `BeforeAll`       | Setup-Code, der einmal vor allen Tests läuft            |
| `BeforeEach`      | Setup-Code, der vor jedem `It`-Block läuft              |
| `AfterAll`        | Teardown-Code nach allen Tests                          |

---

### 2.4.3. Wichtige Should-Assertions

```powershell
$result | Should -Be 42                      # Wert exakt gleich
$result | Should -BeExactly "Hallo"          # case-sensitiv
$result | Should -BeGreaterThan 0            # grösser als
$result | Should -BeLessThan 100             # kleiner als
$result | Should -BeNullOrEmpty              # null oder leer
$result | Should -Not -BeNullOrEmpty         # nicht null/leer
$result | Should -Contain "Wert"             # Array enthält Element
$result | Should -BeOfType [int]             # Typ prüfen
{ Get-Item "C:
ope" } | Should -Throw       # Exception erwartet
{ Remove-Item $file } | Should -Not -Throw   # keine Exception erwartet
```

---

### 2.4.4. Vollständiges Beispiel: Get-RentalCost testen

Das folgende Beispiel testet die Funktion `Get-RentalCost` aus der Autovermietungs-Aufgabe (README-functions.md).

**Zu testende Funktion** (`RentalCost.ps1`):

```powershell
function Get-RentalCost {
    param(
        [Parameter(Mandatory)]
        [int]$KmStart,
        [Parameter(Mandatory)]
        [int]$KmEnd
    )
    if ($KmStart -ge $KmEnd) {
        throw "KM-Stand Start muss kleiner sein als KM-Stand Ende"
    }

    $driven = $KmEnd - $KmStart
    $cost   = 0.0

    if ($driven -le 200) {
        $cost = 0.0
    } elseif ($driven -le 1000) {
        $cost = ($driven - 200) * 0.80
    } else {
        $cost = (800 * 0.80) + (($driven - 1000) * 0.50)
    }
    return [math]::Round($cost, 2)
}
```

**Testdatei** (`RentalCost.Tests.ps1`):

```powershell
BeforeAll {
    # Funktion per Dot-Sourcing laden
    . "$PSScriptRoot\RentalCost.ps1"
}

Describe "Get-RentalCost" {

    Context "Freikilometer – erste 200 km gratis" {
        It "genau 200 km ergibt 0 CHF" {
            Get-RentalCost -KmStart 0 -KmEnd 200 | Should -Be 0
        }
        It "199 km ergibt 0 CHF" {
            Get-RentalCost -KmStart 100 -KmEnd 299 | Should -Be 0
        }
    }

    Context "Mitteltarif – 200 bis 1000 km (0.80 CHF/km)" {
        It "201 km ergibt 0.80 CHF" {
            Get-RentalCost -KmStart 0 -KmEnd 201 | Should -Be 0.80
        }
        It "700 km ergibt 400 CHF (500 km * 0.80)" {
            Get-RentalCost -KmStart 0 -KmEnd 700 | Should -Be 400.00
        }
        It "genau 1000 km ergibt 640 CHF (800 km * 0.80)" {
            Get-RentalCost -KmStart 0 -KmEnd 1000 | Should -Be 640.00
        }
    }

    Context "Hochtarif – über 1000 km (0.50 CHF/km)" {
        It "1100 km ergibt 690 CHF (640 + 100 * 0.50)" {
            Get-RentalCost -KmStart 0 -KmEnd 1100 | Should -Be 690.00
        }
        It "1500 km ergibt 890 CHF (640 + 500 * 0.50)" {
            Get-RentalCost -KmStart 0 -KmEnd 1500 | Should -Be 890.00
        }
    }

    Context "Fehlerbehandlung" {
        It "KmStart gleich KmEnd wirft Exception" {
            { Get-RentalCost -KmStart 500 -KmEnd 500 } | Should -Throw
        }
        It "KmStart grösser als KmEnd wirft Exception" {
            { Get-RentalCost -KmStart 800 -KmEnd 200 } | Should -Throw
        }
        It "Fehlermeldung enthält erklärenden Text" {
            { Get-RentalCost -KmStart 800 -KmEnd 200 } |
                Should -Throw -ExpectedMessage "*kleiner sein*"
        }
    }
}
```

**Tests ausführen:**

```powershell
# Alle Tests ausführen
Invoke-Pester -Path ".\RentalCost.Tests.ps1" -Output Detailed

# Mit Code-Coverage-Report
Invoke-Pester -Path ".\RentalCost.Tests.ps1" `
    -CodeCoverage ".\RentalCost.ps1" `
    -CodeCoverageOutputFile ".\coverage.xml"
```

**Erwartete Ausgabe:**

```console
Starting discovery in 1 files.
Discovery finished in 52ms.

Describing Get-RentalCost
  Context Freikilometer – erste 200 km gratis
    [+] genau 200 km ergibt 0 CHF 12ms
    [+] 199 km ergibt 0 CHF 2ms
  Context Mitteltarif – 200 bis 1000 km (0.80 CHF/km)
    [+] 201 km ergibt 0.80 CHF 2ms
    [+] 700 km ergibt 400 CHF 1ms
    [+] genau 1000 km ergibt 640 CHF 1ms
  Context Hochtarif – über 1000 km (0.50 CHF/km)
    [+] 1100 km ergibt 690 CHF 1ms
    [+] 1500 km ergibt 890 CHF 1ms
  Context Fehlerbehandlung
    [+] KmStart gleich KmEnd wirft Exception 5ms
    [+] KmStart grösser als KmEnd wirft Exception 2ms
    [+] Fehlermeldung enthält erklärenden Text 2ms

Tests completed in 331ms
Tests Passed: 10, Failed: 0, Skipped: 0
```

---

### 2.4.5. Projektstruktur mit Pester

```console
MeinProjekt/
├── src/
│   └── RentalCost.ps1           # Produktions-Code
├── tests/
│   └── RentalCost.Tests.ps1     # Pester-Tests
├── logs/
│   └── backup.log
└── README.md
```

> **Best Practice:** Tests und Produktions-Code trennen. Testdateien nie in dieselbe Datei wie die Funktion schreiben – das erschwert Dot-Sourcing und spätere Modularisierung.

---

# 3. Aufgaben

## 3.1. Testplan für Skript erstellen

| **Vorgabe**             | **Beschreibung**                                            |
| :---------------------- | :---------------------------------------------------------- |
| **Lernziele**           | Testplan (Positiv/Negativ/Rand/Unicode) + Evidenz erstellen |
|                         | VS-Code, Write-Verbose, Write-Debug, Set-PSDebug verwenden  |
|                         | README/Admin‑Guide/Comment‑Help                             |
| **Sozialform**          | Einzelarbeit                                                |
| **Auftrag**             | siehe unten                                                 |
| **Hilfsmittel**         |                                                             |
| **Erwartete Resultate** |                                                             |
| **Zeitbedarf**          | 40 min                                                      |
| **Lösungselemente**     | siehe unten                                                 |

Erstelle für dein Skript (oder das Muster CompressLogs.ps1) einen Testplan (mind. 6 Fälle) und führe die Tests manuell aus.
Dokumentiere Exitcodes, Logauszüge, Artefakte.

Lösungselemente:

- Testplan.md gemäss Template.
- Befehle (Happy/Negativ) inkl. echo $LastExitCode.
- „Massnahmen“ (z.B. genauere Fehlertexte, früheres Filtern).

---

## 3.2. Debugging in VS Code – Breakpoints & Watch

| **Vorgabe**             | **Beschreibung**                                              |
| :---------------------- | :------------------------------------------------------------ |
| **Lernziele**           | VS Code Debugger (Breakpoints, Step, Watch) gezielt einsetzen |
|                         | Variablenzustände und Call Stack zur Fehleranalyse nutzen     |
|                         | launch.json für parametrisierte Skripte konfigurieren         |
| **Sozialform**          | Einzelarbeit                                                  |
| **Auftrag**             | siehe unten                                                   |
| **Hilfsmittel**         | VS Code, PowerShell Extension                                 |
| **Erwartete Resultate** |                                                               |
| **Zeitbedarf**          | 40 min                                                        |
| **Lösungselemente**     | siehe unten                                                   |

Erstelle eine `launch.json` (s. oben), setze Breakpoints in Eingabevalidierung und Archiv‑Erstellung, inspiziere Variablen, ändere args (ungültiger Pfad) und beobachte Call Stack.

Lösungselemente:

- Screenshot Breakpoint‑Treffer, Variablen‑Watch.
- Notiere 2–3 Beobachtungen (z. B. falscher Pfad, leere Dateiliste).

**Optional:**
Aktiviere `Set-PSDebug -Step` in einem kleinen Teilskript und dokumentiere kurz, wie sich die Schritt‑Ausführung auf das Verständnis des Codes auswirkt.

---

## 3.3. Logger mit Debug-Level implementieren

| **Vorgabe**             | **Beschreibung**                                      |
| :---------------------- | :---------------------------------------------------- |
| **Lernziele**           | Write-Log-Funktion mit Level-Steuerung implementieren |
|                         | DEBUG/INFO/WARN/ERROR korrekt einsetzen               |
|                         | Logdatei strukturiert aufbauen und auswerten          |
| **Sozialform**          | Einzelarbeit                                          |
| **Auftrag**             | siehe unten                                           |
| **Hilfsmittel**         |                                                       |
| **Erwartete Resultate** |                                                       |
| **Zeitbedarf**          | 30 min                                                |
| **Lösungselemente**     | siehe unten                                           |

Erweitere dein Test-Skript (z.B. Aufgabe Log-Aufräumprozess) mit einer Logger-Funktion und protokolliere die Ausführung mit mehreren Log-Meldungen.

**Beispiel (Vorlage):**

```powershell
$script:LogPath  = ".\script.log"
$script:LogDebug = $false

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO','WARN','ERROR','DEBUG')]
        [string]$Level = 'INFO'
    )
    if ($Level -eq 'DEBUG' -and -not $script:LogDebug) { return }

    $line = "[{0}] {1} {2}" -f $Level, (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    $line | Out-File -FilePath $script:LogPath -Append -Encoding utf8

    switch ($Level) {
        'ERROR' { Write-Error   $Message }
        'WARN'  { Write-Warning $Message }
        'DEBUG' { Write-Debug   $Message }
        default { Write-Verbose $Message }
    }
}

# Aufruf-Beispiele:
$script:LogDebug = $true   # DEBUG-Modus aktivieren

Write-Log "Aufräumprozess gestartet"
Write-Log "Verzeichnis nicht gefunden"  -Level WARN
Write-Log "Datei gesperrt, skip"        -Level DEBUG
Write-Log "Kritischer Fehler"           -Level ERROR
```

---

## 3.4. Pester-Tests implementieren

| **Vorgabe**             | **Beschreibung**                                                   |
| :---------------------- | :----------------------------------------------------------------- |
| **Lernziele**           | Pester-Testdatei nach v5-Standard erstellen                        |
|                         | Describe/Context/It/Should korrekt einsetzen                       |
|                         | Positive, negative und Randwert-Fälle abdecken                     |
| **Sozialform**          | Einzelarbeit                                                       |
| **Auftrag**             | siehe unten                                                        |
| **Hilfsmittel**         | Pester Dokumentation: **<https://pester.dev>**                     |
| **Erwartete Resultate** |                                                                    |
| **Zeitbedarf**          | 45 min                                                             |
| **Lösungselemente**     | `.Tests.ps1`-Datei, alle Tests grün (`Tests Passed: N, Failed: 0`) |

**Aufgabe:**

Schreibe Pester-Tests für deine `Get-RentalCost`-Funktion (oder eine eigene Funktion aus früheren Aufgaben).

**A1 – Grundstruktur:**

Erstelle `RentalCost.Tests.ps1` mit:

- `BeforeAll` zum Laden der Funktion via Dot-Sourcing
- Mindestens zwei `Describe`/`Context`-Blöcke (Happy Path + Fehlerfall)
- Mindestens 5 `It`-Testfälle

**A2 – Assertions erweitern:**

Ergänze Tests für:

- Randwerte (genau 200 km, genau 1000 km)
- Exception-Prüfung mit `-ExpectedMessage`
- Rückgabetyp mit `Should -BeOfType [double]`

**A3 – Tests ausführen und auswerten:**

```powershell
Invoke-Pester -Path ".\RentalCost.Tests.ps1" -Output Detailed
```

- Provoziere absichtlich einen fehlgeschlagenen Test (falscher Erwartungswert)
- Lies die Fehlerausgabe und verstehe die Differenz zwischen `Expected` und `But was`
- Korrigiere den Test und führe erneut aus

**A4 (optional) – Code-Coverage:**

```powershell
Invoke-Pester -Path ".\RentalCost.Tests.ps1" `
    -CodeCoverage ".\RentalCost.ps1" `
    -CodeCoverageOutputFile ".\coverage.xml"
```

Prüfe, welche Zeilen noch nicht durch Tests abgedeckt sind, und ergänze fehlende Testfälle.

---

© 2026 Lukas Müller – Licensed under CC BY-NC-ND 4.0
See [LICENSE](../license.md) file for details.
