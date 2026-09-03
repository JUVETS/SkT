|                             |                          |                                 |
| --------------------------- | ------------------------ | ------------------------------- |
| **Techniker HF Informatik** | **Scripting / Big data** | ![Logo](./../x_gitres/logo.png) |

- [1. Error Handling in PowerShell‑Skripten](#1-error-handling-in-powershellskripten)
  - [1.1. Lernziele](#11-lernziele)
  - [1.2. Begriffsklärung: Fehlertypen in PowerShell](#12-begriffsklärung-fehlertypen-in-powershell)
  - [1.3. $ErrorActionPreference \& -ErrorAction](#13-erroractionpreference---erroraction)
  - [1.4. Fehler abfangen: try/catch/finally](#14-fehler-abfangen-trycatchfinally)
  - [1.5. Prozess-/Exit‑Signale: $?, $LASTEXITCODE, Exitcodes](#15-prozess-exitsignale--lastexitcode-exitcodes)
  - [1.5b. Die `$Error`-Variable](#15b-die-error-variable)
  - [1.5c. Fehler selbst auslösen: throw \& Write-Error](#15c-fehler-selbst-auslösen-throw--write-error)
  - [1.6. Error Handling + Logging = Beobachtbarkeit](#16-error-handling--logging--beobachtbarkeit)
- [2. Aufgaben](#2-aufgaben)
  - [2.1. PowerShell Fehler erkennen und behandeln](#21-powershell-fehler-erkennen-und-behandeln)

---

</br>

# 1. Error Handling in PowerShell‑Skripten

## 1.1. Lernziele

- den Unterschied zwischen **terminierenden** und **nicht‑terminierenden** Fehlern erklären,
- `$ErrorActionPreference`, `-ErrorAction`, `try/catch/finally` und `throw` gezielt einsetzen,
- mit `$Error`, `$LASTEXITCODE` und `$?` arbeiten,
- Exitcodes definieren und an aufrufende Prozesse zurückgeben,
- eigene Exception‑Flüsse (inkl. throw/Write-Error) entwerfen,
- Logging/Tracing sinnvoll mit Error Handling kombinieren,
- Robustheitsmuster (Retry, Timeout, Idempotenz) umsetzen.

## 1.2. Begriffsklärung: Fehlertypen in PowerShell

- **Nicht‑terminierende Fehler:**
  - Cmdlet meldet einen Fehler, **bricht aber nicht** den gesamten Befehl/Skriptblock ab.
  - Das Skript läuft weiter. Beispiele: Get-ChildItem auf einen nicht zugreifbaren Pfad ohne -ErrorAction Stop.
- **Terminierende Fehler:**
  - Werfen eine **Ausnahme (Exception)** und können per try/catch abgefangen werden.
  - Beispiele: `throw`, `-ErrorAction Stop`, bestimmte Exceptions (z. B. `New-Item` mit ungültigem Pfad und `-ErrorAction Stop`).

> **Grundidee: In Automationsszenarien wollen wir bei echten Fehlern gezielt abbrechen und diese sauber behandeln – also terminierende Fehler forcieren und abfangen.**

## 1.3. $ErrorActionPreference & -ErrorAction

`$ErrorActionPreference`

- **Globale Voreinstellung**, wie mit nicht‑terminierenden Fehlern umgegangen wird.
- Wichtige Werte:
  - `Continue` (Standard) – Fehler werden gemeldet, Ausführung geht weiter.
  - `Stop` – Fehler werden terminierend (**lösen catch aus**).
  - `SilentlyContinue` – Fehler werden unterdrückt (vorsichtig nutzen).
  - `Inquire` – interaktive Nachfrage.

Beispiel (Skriptweit **strict** schalten):

```powershell
$ErrorActionPreference = 'Stop'    # Empfohlen in produktiven Skripten
```

`-ErrorAction (pro Cmdlet)`
Lokale Überschreibung für einen einzelnen Aufruf.

```powershell
Copy-Item C:\Quelle\*.log D:\Ziel -ErrorAction Stop
```

**Daumenregel:**

- In Automationsskripten `$ErrorActionPreference = 'Stop'` setzen.
- Für einzelne, erwartbar fragile Stellen wahlweise lokal feinsteuern (`-ErrorAction Stop` oder `SilentlyContinue` + eigene Reaktion).

---

## 1.4. Fehler abfangen: try/catch/finally

Die Fehlerbehandlung findet im `catch`-Block statt. Der Programmcode im `finally`-Block wird **immer** (Fehlerfall und bei erfolgreicher Ausführung) ausgeführt.

```powershell
$ErrorActionPreference = 'Stop'   # Wichtig
try {
    # riskanter Code
    $content = Get-Content -Path 'C:\nicht_da.txt'  # löst terminierenden Fehler aus
    "Zeilen: $($content.Count)"
}
catch {
    # Fehler behandeln
    Write-Error "Fehler beim Einlesen: $($_.Exception.Message)"
    # optional: exit 1
}
finally {
    # Aufräumen – läuft IMMER (Fehler oder nicht)
    # z. B. Handles schliessen, Tempdateien löschen
}
```

## 1.5. Prozess-/Exit‑Signale: $?, $LASTEXITCODE, Exitcodes

- `$?`: Wahr, wenn letzter Befehl erfolgreich war (nicht zuverlässig für komplexe Sequenzen).
- `$LASTEXITCODE`: Exitcode externer Prozesse (z. B. robocopy, 7z.exe).
- `exit <code>`: Exitcode des Skripts zurückgeben (für Task Scheduler wichtig).

```powershell
try {
    # Arbeit …
    exit 0
}
catch {
    Write-Error "Fehler: $($_.Exception.Message)"
    exit 1
}
```

## 1.5b. Die `$Error`-Variable

PowerShell speichert alle aufgetretenen Fehler der laufenden Sitzung im automatischen Array `$Error`.

```powershell
$Error[0]           # letzter Fehler
$Error[0].Exception # die eigentliche .NET-Exception
$Error.Count        # Anzahl gesammelter Fehler
$Error.Clear()      # Liste leeren
```

> **Hinweis:** `$Error` sammelt sitzungsweit – nicht nur aus dem aktuellen Skript. Im `catch`-Block ist `$_` (das aktuelle Exception-Objekt) zuverlässiger als `$Error[0]`.

---

## 1.5c. Fehler selbst auslösen: throw & Write-Error

Manchmal muss ein Skript selbst einen Fehler signalisieren:

```powershell
# throw – löst terminierenden Fehler aus, landet im catch-Block
function Get-Config {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        throw "Konfigurationsdatei nicht gefunden: $Path"
    }
    Get-Content $Path
}

# Write-Error – nicht-terminierend (wie ein Cmdlet-Fehler)
function Test-Value {
    param([int]$Value)
    if ($Value -lt 0) {
        Write-Error "Wert darf nicht negativ sein: $Value"
        return
    }
    "Wert OK: $Value"
}
```

> **Faustregel:** `throw` in Funktionen, die von `try/catch` umschlossen werden sollen. `Write-Error` für Warnungen, bei denen der Aufrufer selbst entscheidet, ob er abbricht.

---

## 1.6. Error Handling + Logging = Beobachtbarkeit

Ein einfacher Logger mit Level hilft beim Debuggen.

> **PS7-Stil:** Statt `New-Object PSObject` + `Add-Member` (PS2-Muster) wird eine einfache Funktion mit `script:`-Scope-Variable für den Log-Pfad verwendet – lesbarer und wartbarer.

```powershell
# Logger initialisieren
$script:LogPath = ".\script.log"

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO','WARN','ERROR','DEBUG')]
        [string]$Level = 'INFO',
        [switch]$DebugMode
    )

    # DEBUG-Meldungen nur ausgeben wenn explizit aktiviert
    if ($Level -eq 'DEBUG' -and -not $DebugMode) { return }

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line      = "[$Level] $timestamp $Message"

    # In Datei schreiben
    $line | Out-File -FilePath $script:LogPath -Append -Encoding UTF8

    # Passende PS-Ausgabefunktion wählen
    switch ($Level) {
        'ERROR' { Write-Error   $Message }
        'WARN'  { Write-Warning $Message }
        'DEBUG' { Write-Debug   $Message }
        default { Write-Verbose $Message }
    }
}

# Verwendung:
$script:LogPath = "C:\Logs\backup.log"

Write-Log "Skript gestartet"                     # INFO
Write-Log "Datei fehlt: x.txt" -Level WARN
Write-Log "DB nicht erreichbar" -Level ERROR
Write-Log "Schleife i=3" -Level DEBUG -DebugMode  # nur mit -DebugMode sichtbar
```

**Vollständiges Beispiel mit try/catch + Logging:**

```powershell
$ErrorActionPreference = 'Stop'
$script:LogPath = ".\cleanup.log"

try {
    Write-Log "Starte Aufräumprozess"
    $files = Get-ChildItem -Path "C:\Logs\*.log" -ErrorAction Stop
    Write-Log "Gefundene Dateien: $($files.Count)"

    foreach ($file in $files) {
        Remove-Item $file.FullName -ErrorAction Stop
        Write-Log "Gelöscht: $($file.Name)"
    }

    Write-Log "Fertig."
    exit 0
}
catch {
    Write-Log "FEHLER: $($_.Exception.Message)" -Level ERROR
    exit 1
}
```

</br>

---

# 2. Aufgaben

## 2.1. PowerShell Fehler erkennen und behandeln

| **Vorgabe**             | **Beschreibung**                                                     |
| :---------------------- | :------------------------------------------------------------------- |
| **Lernziele**           | Unterschied zwischen terminierenden und nicht‑terminierenden kennen. |
|                         | Fehlerbehandlungen einbauen und protokollieren                       |
| **Sozialform**          | Einzelarbeit                                                         |
| **Hilfsmittel**         |                                                                      |
| **Erwartete Resultate** |                                                                      |
| **Zeitbedarf**          | 40 min                                                               |
| **Lösungselemente**     | PowerShell Datei mit sämtlichen Lösungen                             |

**A1:**

Über die globale eingebaute Variable `$ErrorActionPreference` kann man das Standardverhalten für `-ErrorAction` für alle Commandlets setzen.
Der Wert muss als Zeichenkette übergeben werden.
Die Standardeinstellung ist `Continue`.

Untersuchen Sie die Programmausführung und Fehlermeldung (Standardverhalten) bei folgenden Einstellungen.

- Verhalten bei `$ErrorActionPreference=Continue`
- Verhalten bei `$ErrorActionPreference=SilentlyContinue`
- Verhalten bei `$ErrorActionPreference=Stop`

**Tipp:**

```powershell
# Stabiles Beispiel: Zugriff auf nicht vorhandene Datei
Get-Item "C:\existiert_nicht.txt"
```

> **Hinweis:** `1 / $null` ist kein verlässlicher Fehlerauslöser – in PS7 ergibt `$null` den Wert 0 und löst eine DivisionByZeroException aus, in manchen Kontexten aber keinen Fehler. `Get-Item` auf einen nicht vorhandenen Pfad ist stabiler und praxisnäher.

**A2:**

Um nicht jeden Fehler separat überprüfen zu müssen, lässt die Powershell abschnittweise Fehlerüberprüfungen mit `try catch` zu.
Im `catch`-Block kann an zentraler Stelle eine Fehlerbehandlung hinterlegen werden.

- Programmiere eine Skript Datei, in welcher Sie mehrere Cmdlet in den try-Block einfügen und im catch-Block eine Fehlerbehandlung vornehmen.
- Geben Sie im `catch`-Block auch die Fehlermeldung aus.

> **Achten Sie, dass vor dem `try`-Block die Variable `$ErrorActionPreference = "Stop"` gesetzt werden muss, da ansonsten der `catch`-Block nicht ausgeführt wird.**

```powershell
$ErrorActionPreference = "Stop"
try 
{
    # Fehler auslösen
    # ...
}
catch
{
    "Fehler: " + $error[0]
} 
```

---

**A3:**

Schreibe ein Skript `Read-ImportantFile.ps1`, das eine Textdatei einliest (Pfad über -Path), die Zeilen zählt und das Ergebnis ausgibt.

- Bei fehlendem Pfad: terminierend abbrechen (sinnvolle Meldung).
- Bei Erfolg: Exitcode 0, bei Fehler: Exitcode 1.

---

© 2026 Lukas Müller – Licensed under CC BY-NC-ND 4.0
See [LICENSE](../license.md) file for details.
