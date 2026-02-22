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
- [3. Aufgaben](#3-aufgaben)
  - [3.1. Testplan für Skript erstellen](#31-testplan-für-skript-erstellen)
  - [3.2. Debugging in VS Code – Breakpoints \& Watch](#32-debugging-in-vscode--breakpoints--watch)
  - [3.3. Logger mit Debug-Level implementieren](#33-logger-mit-debug-level-implementieren)

---

</br>

# 1. Testing und Debugging

## 1.1. Lernziele

- Geeignete **Teststrategien** (Positiv/Negativ, Randwerte, Sonderfälle) entwerfen und Testpläne erstellen.
- Skripte **gezielt testen** – manuell und (bei Bedarf) automatisiert mit Pester v4.
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
- Windows-Build, PowerShell 5.1.x
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
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\CleanUpLogs.ps1" `
  -Source "C:\Logs" -Destination "D:\Archive" -Verbose
echo $LastExitCode  # 0 erwartet

# Fehlerfall (Pfad existiert nicht)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\CleanUpLogs.ps1" `
  -Source "C:\Nope" -Destination "D:\Archive"
echo $LastExitCode  # != 0 erwartet
```

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
function New-Logger {
  param([string]$Path = ".\script.log",[switch]$DebugMode)
  return 
  {
    param([string]$Message,[ValidateSet('INFO','WARN','ERROR','DEBUG')][string]$Level='INFO')
    if ($Level -eq 'DEBUG' -and -not $DebugMode) { return }

    $line = "[{0}] {1} {2}" -f $Level,(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),$Message
    $line | Out-File -FilePath $Path -Append -Encoding utf8

    if     ($Level -eq 'ERROR') { Write-Error   $Message }
    elseif ($Level -eq 'WARN')  { Write-Warning $Message }
    elseif ($Level -eq 'DEBUG') { Write-Debug   $Message }
    else                        { Write-Verbose $Message }
  }
}
```

## 2.3. Testdokumentation (README.md)

Testdurchführung muss detailliert dokumentiert sein:

- Zweck, Voraussetzungen, Installation
- Verwendung/Parameter mit Beispielen
- Betrieb (z. B. Task Scheduler), Logpfade/Rotation
- Troubleshooting/Exitcodes/typische Fehler
- Konten/Rechte, Freigaben/ACLs, Monitoring (LastTaskResult, Eventlog), Update‑/Rollback‑Vorgehen

---

</br>

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

Erstelle eine `launch.json` (s. oben), setze Breakpoints in Eingabevalidierung und Archiv‑Erstellung, inspiziere Variablen, ändere args (ungültiger Pfad) und beobachte Call Stack.

Lösungselemente:

- Screenshot Breakpoint‑Treffer, Variablen‑Watch.
- Notiere 2–3 Beobachtungen (z. B. falscher Pfad, leere Dateiliste).

**Optional:**
Aktiviere `Set-PSDebug -Step` in einem kleinen Teilskript und dokumentiere kurz, wie sich die Schritt‑Ausführung auf das Verständnis des Codes auswirkt.

---

## 3.3. Logger mit Debug-Level implementieren

| **Vorgabe**             | **Beschreibung**                                            |
| :---------------------- | :---------------------------------------------------------- |
| **Lernziele**           | Testplan (Positiv/Negativ/Rand/Unicode) + Evidenz erstellen |
|                         | VS-Code, Write-Verbose, Write-Debug, Set-PSDebug verwenden  |
|                         | README/Admin‑Guide/Comment‑Help                             |
| **Sozialform**          | Einzelarbeit                                                |
| **Auftrag**             | siehe unten                                                 |
| **Hilfsmittel**         |                                                             |
| **Erwartete Resultate** |                                                             |
| **Zeitbedarf**          | 30 min                                                      |
| **Lösungselemente**     | siehe unten                                                 |

Erweitere dein Test-Skript (z.B. Aufgabe Log-Aufräumprozess) mit einer Logger-Funktion und protokolliere die Ausführung mit mehreren Log-Meldungen.

**Beispiel (Vorlage):**

```powershell
function New-Logger {
  param([string]$Path = ".\script.log",[switch]$DebugMode)
  return {
    param([string]$Message,[ValidateSet('INFO','WARN','ERROR','DEBUG')][string]$Level='INFO')
    if ($Level -eq 'DEBUG' -and -not $DebugMode) { return }
    $line = "[{0}] {1} {2}" -f $Level,(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),$Message
    $line | Out-File -FilePath $Path -Append -Encoding utf8
    if     ($Level -eq 'ERROR') { Write-Error   $Message }
    elseif ($Level -eq 'WARN')  { Write-Warning $Message }
    elseif ($Level -eq 'DEBUG') { Write-Debug   $Message }
    else                        { Write-Verbose $Message }
  }
}
```
