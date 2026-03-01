|                             |                          |                                 |
| --------------------------- | ------------------------ | ------------------------------- |
| **Techniker HF Informatik** | **Scripting / Big data** | ![Logo](./../x_gitres/logo.png) |

- [1. Error Handling in PowerShell‑Skripten](#1-error-handling-in-powershellskripten)
  - [1.1. Lernziele](#11-lernziele)
  - [1.2. Begriffsklärung: Fehlertypen in PowerShell](#12-begriffsklärung-fehlertypen-in-powershell)
  - [1.3. $ErrorActionPreference \& -ErrorAction](#13-erroractionpreference---erroraction)
  - [1.4. Fehler abfangen: try/catch/finally](#14-fehler-abfangen-trycatchfinally)
  - [1.5. Prozess-/Exit‑Signale: $?, $LASTEXITCODE, Exitcodes](#15-prozess-exitsignale--lastexitcode-exitcodes)
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

## 1.6. Error Handling + Logging = Beobachtbarkeit

Ein einfacher Logger mit Level hilft beim Debuggen:

```powershell
function New-Logger {
    param(
        [string]$Path = ".\script.log",
        [switch]$DebugMode
    )

    # Ordner erstellen falls nötig
    $dir = Split-Path -Path $Path -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    # Logger-Objekt definieren
    $logger = New-Object PSObject -Property @{
        Path      = $Path
        DebugMode = $DebugMode.IsPresent
    }

    # Methode Log hinzufügen
    $logger | Add-Member -MemberType ScriptMethod -Name Log -Value {
        param(
            [string]$Message,
            [ValidateSet('INFO','WARN','ERROR','DEBUG')]
            [string]$Level = 'INFO'
        )

        $p = $this.Path
        $debug = $this.DebugMode

        # Debug unterdrücken wenn nicht aktiviert
        if ($Level -eq 'DEBUG' -and -not $debug) { return }

        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $line = "[{0}] {1} {2}" -f $Level, $timestamp, $Message

        $line | Out-File -FilePath $p -Append -Encoding UTF8

        switch ($Level) {
            'ERROR' { Write-Error   $Message }
            'WARN'  { Write-Warning $Message }
            'DEBUG' { Write-Debug   $Message }
            default { Write-Verbose $Message }
        }
    }

    return $logger
}

# Verwendung:
# $log = New-Logger -Path '.\script.log' -DebugMode
# $log.Invoke("Start", "INFO")
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
# Fehler kann mit Division durch $null ausgelöst werden
Write-Host (1 / $null) 
```

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
See [LICENSE](lincense.md) file for details.
