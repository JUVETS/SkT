|                             |                          |                                 |
| --------------------------- | ------------------------ | ------------------------------- |
| **Techniker HF Informatik** | **Scripting / Big data** | ![Logo](./../x_gitres/logo.png) |

- [1. Dokumentation](#1-dokumentation)
  - [1.1. Lernziele](#11-lernziele)
  - [1.2. Warum dokumentieren?](#12-warum-dokumentieren)
  - [1.3. Dokumentation (Überblick)](#13-dokumentation-überblick)
  - [1.4. README.md – Pflichtinhalte \& Vorlage](#14-readmemd--pflichtinhalte--vorlage)
  - [1.5. Beispiel‑Skeleton (README.md)](#15-beispielskeleton-readmemd)
  - [1.6. Parameter](#16-parameter)
  - [1.7. Betrieb (Task Scheduler)](#17-betrieb-task-scheduler)
  - [1.8. Exitcodes](#18-exitcodes)
  - [1.9. Troubleshooting](#19-troubleshooting)
  - [1.10. Version / Changelog](#110-version--changelog)
  - [1.11. Lizenz](#111-lizenz)
  - [1.12. Versionierung mit SemVer \& Changelog](#112-versionierung-mit-semver--changelog)
- [2. Aufgaben](#2-aufgaben)
  - [2.1. README.md erstellen/verbessern](#21-readmemd-erstellenverbessern)
  - [2.2. Comment‑based help ergänzen](#22-commentbased-help-ergänzen)

---

# 1. Dokumentation

## 1.1. Lernziele

- Den Zweck von Dokumentation (für User, Admins, Entwickler) begründen und die passenden Artefakte auswählen.
- Aussagekräftige README.md, Admin‑Guides und Entwicklernotizen erstellen.
- comment‑based help in Skripten schreiben und mit Get-Help nutzbar machen.
- Parameter, Beispiele, Exitcodes, Logpfade, Betrieb (Scheduled Tasks) und Troubleshooting eindeutig beschreiben.
- Versionierung (SemVer), Changelog, Lizenz und Contributing‑Hinweise sinnvoll pflegen.
- Konsistente Code‑Kommentare, Namenskonventionen und Struktur nutzen, um Lesbarkeit/Wartbarkeit zu erhöhen.

## 1.2. Warum dokumentieren?

- **Nutzbarkeit**: Andere können das Skript finden, korrekt aufrufen und richtig konfigurieren.
- **Betriebssicherheit**: Admins wissen, wo Logs liegen, wie Tasks konfiguriert werden und wie Fehler zu diagnostizieren sind.
- **Wartbarkeit**: Devs verstehen Architektur, Parameter, Abhängigkeiten und Teststrategie.
- **Compliance/Übergaben**: Nachweise (Versionen/Änderungen) und klare Zuständigkeiten.

> **Merksatz: „Wenn es nicht dokumentiert ist, ist es nicht fertig.“**

## 1.3. Dokumentation (Überblick)

- **README.md (Nutzerfokus)** – Zweck, Voraussetzungen, Installation, Verwendung (mit Beispielen), Betrieb (Task Scheduler), Logs, Troubleshooting, Exitcodes, Lizenz.
- **Admin‑Guide** – Betrieb im System: Service‑Konten/Rechte, Pfade/UNC‑Shares, Monitoring (LastTaskResult/Eventlog), Update/Rollback, Logrotation.
- **Developer Notes** – Architektur/Flow (PAP), Parameter/Typen, Modulstruktur, Teststrategie (Pester), Coding‑Guidelines, Release‑Prozess.
- **Comment‑based help** – Inline‑Hilfe im Skript; per Get-Help .\Script.ps1 -Full.
- **Changelog** – Was hat sich wann und warum geändert (SemVer).
- **LICENSE + NOTICE (falls relevant)** – Nutzungsrechte/Klarheit bei Weitergabe.
- **Contributing (optional)** – Pull‑Request‑Abläufe, Code‑Style, Testpflichten.

## 1.4. README.md – Pflichtinhalte & Vorlage

**Mindestinhalte:**

- **Zweck**: 1–3 Sätze („Was automatisiert wird und warum“).
- **Voraussetzungen**: PowerShell‑Version, Rechte (Admin?), Module, Speicher/Netz.
- **Installation**: Ablagepfade (z. B. C:\ProgramData\Company\Automation\), Policies/Signierung.
- **Verwendung**: Parameter mit Typen/Defaults, Beispiele (Happy/Negativ), Exitcodes.
- **Betrieb**: Geplanter Task (Trigger, Konto, RunLevel), Logpfade & Rotation.
- **Troubleshooting**: Häufige Fehler, Diagnose‑Schritte, Eventlog‑IDs.
- **Version/Changelog**: Welche Version ist das? Link zur Historie.
- **Lizenz** (falls erforderlich).

## 1.5. Beispiel‑Skeleton (README.md)

```markdown
# Compress-LogFiles

## Zweck
Archiviert Log-Dateien seit X Tagen in ein ZIP, schreibt Logfile und liefert aussagekräftige Exitcodes.

## Voraussetzungen
- PowerShell 7.x
- Schreibrechte auf Zielpfad
- Freier Speicher für Archivierung

## Installation
1. `CompressLogs.ps1` nach `C:\ProgramData\Company\Automation\` kopieren
2. (Optional) Signierung prüfen
3. Execution Policy für den Prozess lockern (Kursbetrieb):
   `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force`

## Verwendung

```powershell
# Happy Path
pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "C:\ProgramData\Company\Automation\CompressLogs.ps1" \
  -Source "C:\Logs" -Destination "D:\Archive" -Verbose

# Fehlerfall – ungültiger Quellpfad (Exitcode 1 erwartet)
pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "C:\ProgramData\Company\Automation\CompressLogs.ps1" \
  -Source "C:\Nope" -Destination "D:\Archive"
$LASTEXITCODE   # sollte 1 sein
```

## 1.6. Parameter

| Parameter      | Typ      | Pflicht | Default      | Beschreibung              |
| -------------- | -------- | ------- | ------------ | ------------------------- |
| `-Source`      | `string` | Ja      | –            | Quellpfad mit Log-Dateien |
| `-Destination` | `string` | Nein    | `D:\Archive` | Zielpfad für ZIP-Archiv   |
| `-Since`       | `int`    | Nein    | `7`          | Dateialter in Tagen       |
| `-Verbose`     | `switch` | Nein    | –            | Detailausgabe aktivieren  |

## 1.7. Betrieb (Task Scheduler)

- **Trigger**: täglich 02:00 Uhr
- **Konto**: `DOMAIN\svc_automation` (Least Privilege)
- **Programm**: `C:\Program Files\PowerShell\7\pwsh.exe`
- **Argumente**: `-NoProfile -ExecutionPolicy Bypass -File "C:\ProgramData\Company\Automation\CompressLogs.ps1" -Source "C:\Logs" -Destination "D:\Archive"`
- **Logpfad**: `C:\ProgramData\Company\Automation\Logs\compress.log`

## 1.8. Exitcodes

| Code | Bedeutung                             |
| ---- | ------------------------------------- |
| `0`  | Erfolgreich abgeschlossen             |
| `1`  | Unerwarteter Fehler                   |
| `2`  | Quellpfad nicht gefunden              |
| `3`  | Zielpfad konnte nicht erstellt werden |

## 1.9. Troubleshooting

| Problem                        | Mögliche Ursache              | Massnahme                          |
| ------------------------------ | ----------------------------- | ---------------------------------- |
| Exitcode 2, Log: „Source leer" | Pfad falsch oder kein Zugriff | Pfad und Rechte prüfen (`icacls`)  |
| Task startet nicht             | Konto ohne Anmeldungsrecht    | `Log on as batch job` Recht prüfen |
| ZIP leer                       | Keine Dateien im Alter-Filter | `-Since`-Parameter anpassen        |

## 1.10. Version / Changelog

Siehe [CHANGELOG.md](./CHANGELOG.md)

## 1.11. Lizenz

CC BY-NC-ND 4.0 – Lukas Müller

```powershell

## 1.6. Beispiel - Comment‑based help – Inline‑Hilfe

Mit einem standardisierten Block im Skript wird die Hilfe per `Get-Help` verfügbar.

```powershell
<#
.SYNOPSIS
  Aufräumen von Logdateien.

.DESCRIPTION
  Filtert Dateien seit -Since, schreibt Logfile, setzt Exitcodes und (optional) Eventlog-Einträge.
  Setzt voraus: PowerShell 7.x, Schreibrechte auf Source und Destination.

.PARAMETER Source
  Quellpfad (Ordner mit Log-Dateien). Pflicht.

.PARAMETER Destination
  Zielpfad (Ordner für ZIP-Archive). Wird bei Bedarf angelegt.

.PARAMETER Since
  Datum/Zeitgrenze – nur Dateien älter als dieser Wert werden verarbeitet.
  Standard: 7 Tage zurück (Get-Date).AddDays(-7).

.PARAMETER Verbose
  Aktiviert detaillierte Konsolenausgabe.

.EXAMPLE
  .\CleanUpLogs.ps1 -Source 'C:\Logs' -Destination 'D:\Archive' -Verbose
  Verarbeitet alle Dateien aus C:\Logs und archiviert sie nach D:\Archive.

.EXAMPLE
  .\CleanUpLogs.ps1 -Source 'C:\Logs' -Destination 'D:\Archive' -Since (Get-Date).AddDays(-30)
  Nur Dateien, die älter als 30 Tage sind, werden archiviert.

.NOTES
  Autor  : <Name>
  Version: 1.3.0
  Lizenz : CC BY-NC-ND 4.0
#>
```

Hilfe aufrufen:

```powershell
Get-Help .\CleanUpLogs.ps1 -Full
Get-Help .\CleanUpLogs.ps1 -Examples   # nur Beispiele anzeigen
Get-Help .\CleanUpLogs.ps1 -Parameter Source   # einzelnen Parameter erklären
```

## 1.12. Versionierung mit SemVer & Changelog

**Semantic Versioning (SemVer)** ist das Standardformat für Versionsnummern: `MAJOR.MINOR.PATCH`

| **Teil** | **Erhöhen wenn…**                                                    | **Beispiel**      |
| -------- | -------------------------------------------------------------------- | ----------------- |
| `MAJOR`  | Inkompatible Änderung (Breaking Change) – bestehende Aufrufe brechen | `1.3.0` → `2.0.0` |
| `MINOR`  | Neue Funktion, rückwärtskompatibel                                   | `1.3.0` → `1.4.0` |
| `PATCH`  | Bugfix, rückwärtskompatibel                                          | `1.3.0` → `1.3.1` |

**Empfehlung für Skripte:** Die aktuelle Version im `.NOTES`-Block und im README pflegen. Bei grösseren Projekten eine separate `CHANGELOG.md` führen.

**Changelog-Format (Keep a Changelog):**

```markdown
# Changelog

## [1.4.0] – 2026-09-01
### Hinzugefügt
- Parameter `-Since` für Datumsfilterung
- Exitcode 2 für fehlenden Quellpfad

## [1.3.1] – 2026-08-15
### Behoben
- Encoding-Fehler bei Umlauten im Logfile

## [1.3.0] – 2026-07-01
### Hinzugefügt
- Erste stabile Version mit Logging und Exitcodes
```

> **Tipp:** Das Format `## [Version] – Datum` mit Abschnitten `Hinzugefügt`, `Geändert`, `Behoben`, `Entfernt` ist etabliert und für alle Beteiligten sofort lesbar. Mehr: [keepachangelog.com](https://keepachangelog.com)

---

</br>

# 2. Aufgaben

## 2.1. README.md erstellen/verbessern

| **Vorgabe**             | **Beschreibung**                                                          |
| :---------------------- | :------------------------------------------------------------------------ |
| **Lernziele**           | aussagekräftige README.md, Admin‑Guides und Entwicklernotizen erstellen   |
|                         | comment‑based help in Skripten schreiben und mit Get-Help nutzbar machen. |
|                         | konsistente Code‑Kommentare, Namenskonventionen und Struktur nutzen       |
| **Sozialform**          | Einzelarbeit                                                              |
| **Auftrag**             | siehe unten                                                               |
| **Hilfsmittel**         |                                                                           |
| **Erwartete Resultate** |                                                                           |
| **Zeitbedarf**          | 30 min                                                                    |
| **Lösungselemente**     | siehe unten                                                               |

Erstelle für dein Skript (z.B. Aufgabe Log-Aufräumprozess) eine `README.md`, die Zweck, Voraussetzungen, Installation, Verwendung (mit mindestens 2 Beispielen), Exitcodes, Betrieb (Task Scheduler), Logs und Troubleshooting dokumentiert.

- Nutze das README‑Skeleton oben.
- Füge reale Pfade/Parameter und eine Fehlerfall‑Ausführung (ungültiger Source) als Beispiel ein.

**Vorlage:**

```markdown
# <Projektname>

## Zweck
<Kurzbeschreibung>

## Voraussetzungen
- PowerShell 7.x
- <weitere Abhängigkeiten>

## Installation
1) Skript nach `C:\ProgramData\<Company>\Automation\` kopieren
2) (Optional) Signatur/Policy prüfen

## Verwendung (Beispiele)
```powershell
pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "C:\ProgramData\<Company>\Automation\<Script>.ps1" `
  -ParamA ... -ParamB ... -Verbose
```

---

## 2.2. Comment‑based help ergänzen

| **Vorgabe**             | **Beschreibung**                                      |
| :---------------------- | :---------------------------------------------------- |
| **Lernziele**           | Comment-Based Help vollständig und korrekt schreiben  |
|                         | `Get-Help` zur Validierung der Inline-Hilfe einsetzen |
|                         | Alle Parameter, Beispiele und Notizen dokumentieren   |
| **Sozialform**          | Einzelarbeit                                          |
| **Auftrag**             | siehe unten                                           |
| **Hilfsmittel**         |                                                       |
| **Erwartete Resultate** |                                                       |
| **Zeitbedarf**          | 30 min                                                |
| **Lösungselemente**     | siehe unten                                           |

Füge deinem Skript eine vollständige Inline‑Hilfe hinzu, inkl. **.SYNOPSIS**, **.DESCRIPTION**, **.PARAMETER (alle)**, **.EXAMPLE** (mind. 2) und **.NOTES** (Autor/Version).

- Übernehme den Hilfe‑Block aus Abschnitt 6 und passe Parameter/Beispiele an.
- Teste mit: `Get-Help .\DeinScript.ps1 -Full`

**Vorlage:**

```powershell
<#
.SYNOPSIS
  <Kurzbeschreibung>

.DESCRIPTION
  <Langbeschreibung: Was, wie, warum; Eingaben/Outputs>

.PARAMETER ParamA
  Beschreibung inkl. Typ/Erwartung

.PARAMETER ParamB
  Beschreibung inkl. Typ/Erwartung

.EXAMPLE
  .\<Script>.ps1 -ParamA '...' -ParamB 123 -Verbose

.NOTES
  Autor: <Name> | Version: <vX.Y.Z> | Lizenz: <Lizenz>
#>
```

---

© 2026 Lukas Müller – Licensed under CC BY-NC-ND 4.0
See [LICENSE](../license.md) file for details.
