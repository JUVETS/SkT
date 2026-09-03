|                             |                          |                                 |
| --------------------------- | ------------------------ | ------------------------------- |
| **Techniker HF Informatik** | **Scripting / Big data** | ![Logo](./../x_gitres/logo.png) |

- [1. Systemintegration](#1-systemintegration)
  - [1.1. Lernziele](#11-lernziele)
  - [1.2. Grundprinzipien der Systemintegration](#12-grundprinzipien-der-systemintegration)
  - [1.3. Execution Policy, Signierung \& Vertrauensmodell](#13-execution-policy-signierung--vertrauensmodell)
  - [1.4. Skript‑/Modul‑Signierung (Überblick)](#14-skriptmodulsignierung-überblick)
  - [1.5. Startmechanismen: Zeit‑/Boot‑/Event‑gesteuert](#15-startmechanismen-zeitbooteventgesteuert)
  - [1.6. PowerShell Scripts in Scheduled Tasks ausführen](#16-powershell-scripts-in-scheduled-tasks-ausführen)
  - [1.7. Logging, Exitcodes \& Monitoring](#17-logging-exitcodes--monitoring)
  - [1.8. Windows Eventlog (optional)](#18-windows-eventlog-optional)
  - [1.9. Exitcodes](#19-exitcodes)
  - [1.10. Fehlerbehandlung \& Robustheit](#110-fehlerbehandlung--robustheit)
- [2. Aufgaben](#2-aufgaben)
  - [2.1. Backup Task erstellen](#21-backup-task-erstellen)
  - [2.2. Scheduled Task‑Auftrag](#22-scheduled-taskauftrag)

---

</br>

# 1. Systemintegration

## 1.1. Lernziele

- Execution Policy, Signierung und Sicherheitskonzepte korrekt einordnen.
- Skripte zweckmässig ablegen, versionieren und über den Systemstart, Scheduled Tasks oder Ereignisse automatisiert ausführen.
- Parameter, Konfigurationsdateien, Umgebungsvariablen und Benutzer-/Dienst‑Kontexte sicher nutzen.
- Logging/Monitoring (Exitcodes, Protokolle, Eventlog) implementieren.
- Remoting, Rechte, JEA (Übersicht) verstehen und Fehlerquellen vermeiden.

---

## 1.2. Grundprinzipien der Systemintegration

- **Reproduzierbarkeit**: Skripte müssen unabhängig von einem interaktiven Benutzer laufen (keine GUI‑Prompts, keine Read-Host in Automation).
- **Determinismus**: Eindeutige Eingaben (Parameter/Konfiguration) ⇒ klare Outputs (Logfiles/Exitcodes).
- **Sicherheit**: Geringste Rechte, Code‑Signierung, Secrets nie im Klartext.
- **Beobachtbarkeit**: Logging (Datei/Eventlog), Exitcodes, ggf. Metriken.
- **Wartbarkeit**: Versionierung, Doku, Idempotenz (mehrfach ausführbar ohne Schaden).

---

## 1.3. Execution Policy, Signierung & Vertrauensmodell

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
```

> **Hinweis: Nur im Scope Process lockern – kein systemweites Absenken. In produktiven Umgebungen auf signierte Skripte setzen.**

---

## 1.4. Skript‑/Modul‑Signierung (Überblick)

- Signaturzertifikat (Code Signing) im Zertifikatsspeicher.
- Skript signieren (Beispiel mit Set-AuthenticodeSignature).
- Verteilung nur aus vertrauenswürdigen Repositories.
- Prüfen: `Get-AuthenticodeSignature .\Script.ps1`.

---

## 1.5. Startmechanismen: Zeit‑/Boot‑/Event‑gesteuert

**Geplante Aufgaben (Task Scheduler):**

- **Trigger**: Zeit (täglich 08:00), At startup, On event.
- **Kontext**: Ausführen unter Service‑Konto (least privilege), Run with highest privileges nur wenn nötig.

```console
# PowerShell 7 (empfohlen)
pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\Job.ps1" -ParamA X

# Windows PowerShell 5.1 (legacy – nur wenn PS7 nicht verfügbar)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\Job.ps1" -ParamA X
```

---

## 1.6. PowerShell Scripts in Scheduled Tasks ausführen

Im Gegensatz zu Command-/Batch-Scripts sollten PowerShell Scripts in Scheduled Tasks nicht direkt über das Feld **Program/Script** ausgeführt werden, sondern über das optionale **Argument** Feld

1. **Öffnen Sie den Taskplaner**: Drücke `Win + R`, gebe „`taskschd.msc`“ in das Dialogfeld **Ausführen** ein und drücke die Eingabetaste.
   1. ![Task-Scheduler](./x_gitres/task-scheduler.png)
2. Im Aktionsbereich auf der rechten Seite **Aufgabe erstellen** wählen
3. **Namen** und eine **Beschreibung** für Ihre Aufgabe eingeben
   1. ![Task-Erstellen](./x_gitres/create-task.png)
4. Wechsel zur Registerkarte **„Trigger“** und klicke auf **„Neu“**. Wählen im Bereich **„Neuer Trigger“**
   1. Wann die Aufgabe beginnen soll
   2. Die Häufigkeit, mit der sie ausgeführt werden soll, z.B. einmalig, täglich oder wöchentlich
   3. ![Trigger-Erstellen](./x_gitres/create-trigger.png)
5. Wechsele zur Registerkarte **„Aktionen“**. Klicke auf **„Neu“**, um eine neue Aktion zum Ausführen Ihres PowerShell-Skripts einzurichten:
   1. **Action**: Start a program
   2. **Program/Script** (PS7): `%ProgramFiles%\PowerShell\7\pwsh.exe`
      **Program/Script** (PS5.1 legacy): `%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe`
   3. Add Arguments (optional): `-ExecutionPolicy Bypass -NoProfile -NoLogo -NonInteractive -File "<Pfad>\<Script-Name>.ps1"`
   4. ![Task](./x_gitres/new-task.png)

> Der `-ExecutionPolicy Bypass` Parameter sorgt dafür, dass das Script ausgeführt wird, auch wenn die eigentliche Execution Policy des Systems die Ausführung bestimmter Scripts **nicht zulässt**.

[Video](https://www.youtube.com/watch?v=ZtBEQLSRRlc)

**Task mit PowerShell erstellen:**

```powershell
$taskName  = "Daily_Job"
$action    = New-ScheduledTaskAction `
    -Execute  "C:\Program Files\PowerShell\7\pwsh.exe" `
    -Argument '-NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\Job.ps1"'
$trigger   = New-ScheduledTaskTrigger -Daily -At 08:00
$principal = New-ScheduledTaskPrincipal `
    -UserId   "DOMAIN\svc_automation" `
    -RunLevel Limited   # Least Privilege: nie Highest ausser zwingend nötig
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Force
```

> **Hinweis PS7:** `pwsh.exe` liegt standardmässig unter `C:\Program Files\PowerShell\7\pwsh.exe`. Den Pfad einmalig mit `(Get-Command pwsh).Source` ermitteln.

**Start beim Systemstart (Autostart/Startup Trigger):**

- Geplanter Task mit -AtStartup (robuster als Run‑Key/Autostart‑Ordner).
- Dienst‑Kontexte vermeiden interaktive Abhängigkeiten.

**Ereignis‑Trigger (Event‑Log, Datei‑Watcher):**

- Trigger auf bestimmtes Eventlog‑Ereignis oder **FileSystemWatcher** im Dienst/Job.
- Achtung: Debouncing/Throttling gegen Event‑Stürme.

---

## 1.7. Logging, Exitcodes & Monitoring

**Dateilog + Verbose/Debug:**

```powershell
# Logger initialisieren (PS7-Stil: einfache Funktion mit script:-Variable)
$script:LogPath  = "C:\ProgramData\MyApp\Logs\job.log"
$script:LogDebug = $false   # auf $true setzen für DEBUG-Ausgaben

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

# Verwendung:
Write-Log "Job gestartet"
Write-Log "Warnung aufgetreten"  -Level WARN
Write-Log "Kritischer Fehler"    -Level ERROR
Write-Log "Debug-Info"           -Level DEBUG   # nur wenn $script:LogDebug = $true
```

---

## 1.8. Windows Eventlog (optional)

- Eigenes Eventlog/Quelle anlegen und Ereignisse schreiben.
- `Write-EventLog` ist in PS7 als deprecated markiert (nur noch via Windows Compatibility Shim).
- **PS7-Empfehlung:** `New-WinEvent` für strukturierte ETW-Ereignisse, oder einfache Datei-/Structured-Logs für die meisten Automationsszenarien.

```powershell
# Eventlog-Quelle einmalig anlegen (benötigt Admin-Rechte)
New-EventLog -LogName Application -Source "MyApp"

# Eintrag schreiben (funktioniert via Compatibility Shim in PS7)
Write-EventLog -LogName Application -Source "MyApp" `
    -EventId 1000 -EntryType Information -Message "Job erfolgreich abgeschlossen"

# Alternativ: New-WinEvent (nativ PS7, kein Shim)
# Erfordert ein registriertes ETW-Manifest – für einfache Skripte überdimensioniert.
# Für Produktion: strukturiertes Datei-Logging + zentrales SIEM empfohlen.
```

---

## 1.9. Exitcodes

- 0 = Erfolg, ≠0 = Fehler.
- Am Ende des Skripts explizit exit 0/exit 1 setzen.
- Task Scheduler zeigt LastTaskResult.

---

## 1.10. Fehlerbehandlung & Robustheit

- `$ErrorActionPreference = 'Stop'` im Automationskontext, dann **try/catch**.
- Retry‑Muster bei transienten Fehlern (Netz, File Locks).
- Timeouts (z. B. bei externen Tools).
- Idempotenz: Mehrfaches Ausführen hinterlässt konsistenten Zustand.
- Transkription (falls nötig)

```powershell
Start-Transcript -Path "C:\ProgramData\MyApp\Logs\transcript.txt" -Append
# ... Script
Stop-Transcript
```

---

</br>

# 2. Aufgaben

## 2.1. Backup Task erstellen

| **Vorgabe**             | **Beschreibung**                                                   |
| :---------------------- | :----------------------------------------------------------------- |
| **Lernziele**           | Sie können ein Logging + Exitcodes + (optional) Eventlog einsetzen |
|                         | Geplanter Task (Zeit/Boot/Event) mit Monitoring registrieren       |
| **Sozialform**          | Einzelarbeit                                                       |
| **Auftrag**             | siehe unten                                                        |
| **Hilfsmittel**         |                                                                    |
| **Erwartete Resultate** |                                                                    |
| **Zeitbedarf**          | 40 min                                                             |
| **Lösungselemente**     | Lauffähiger Skript                                                 |

Speichere die nachfolgenden Befehle in der `start-backup.ps1` Skript Datei ab und erstelle für automatische Ausführung ein geplante Task (**Name: Backup**)
Die Skriptausführung soll vorerst zu Testzwecken alle **5min** erfolgen (Trigger).

- Prüfe im Logfile die korrekte Ausführung
- Prüfe mit PowerShell die letzte Laufzeit/Ergebnis `Get-ScheduledTask`, `Get-ScheduledTaskInfo`

```powershell
<#
  .SYNOPSIS
  System Backup
  .DESCRIPTION
  Sichert Dateien aus einem Quellpfad in ein Zielverzeichnis.
  Schreibt ein Logfile und gibt Exitcodes zurück.
  .NOTES
  Exitcode 0 = Erfolg, 1 = Fehler
#>

$ErrorActionPreference = 'Stop'    # alle Fehler terminierend → catch greift

# ── Konfiguration ──────────────────────────────────────────────────────────────
$script:LogFile = Join-Path $PSScriptRoot "backup.log"

# ── Funktionen ─────────────────────────────────────────────────────────────────
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO','WARN','ERROR')]
        [string]$Level = 'INFO'
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$Level] $timestamp – $Message" | Out-File $script:LogFile -Append -Encoding utf8
    if ($Level -eq 'ERROR') { Write-Error $Message }
}

# ── Hauptprogramm ──────────────────────────────────────────────────────────────
try {
    Write-Log "Backup gestartet"

    # TODO: Backup-Logik hier implementieren
    # Beispiel:
    # $source = "C:\Daten"
    # $dest   = "D:\Backup\$(Get-Date -Format 'yyyyMMdd')"
    # Copy-Item -Path $source -Destination $dest -Recurse -ErrorAction Stop

    Write-Log "Backup erfolgreich abgeschlossen"
    exit 0
}
catch {
    Write-Log "Backup fehlgeschlagen: $($_.Exception.Message)" -Level ERROR
    exit 1
}
```

---

## 2.2. Scheduled Task‑Auftrag

| **Vorgabe**             | **Beschreibung**                                                   |
| :---------------------- | :----------------------------------------------------------------- |
| **Lernziele**           | Sie können ein Logging + Exitcodes + (optional) Eventlog einsetzen |
|                         | Geplanter Task (Zeit/Boot/Event) mit Monitoring registrieren       |
| **Sozialform**          | Einzelarbeit                                                       |
| **Auftrag**             | siehe unten                                                        |
| **Hilfsmittel**         |                                                                    |
| **Erwartete Resultate** |                                                                    |
| **Zeitbedarf**          | 30 min                                                             |
| **Lösungselemente**     | Lauffähiger Skript                                                 |

Registriere ein PowerShell Skript, das ein Skript stündlich startet und ein Logfile schreibt.

**Weitere Anforderungen:**

- **Konfigurationsdatei**: Lagere Zielpfade in eine JSON‑Datei aus; lade/verwende sie im Skript.
- **Exitcodes testen**: Provoziere einen Fehler (falscher Pfad), verifiziere LastTaskResult und Log‑Eintrag.

---

© 2026 Lukas Müller – Licensed under CC BY-NC-ND 4.0
See [LICENSE](../license.md) file for details.
