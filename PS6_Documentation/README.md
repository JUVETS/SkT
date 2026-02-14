|                             |                               |                                 |
| --------------------------- | ----------------------------- | ------------------------------- |
| **Techniker HF Informatik** | **Kurs Scripting / Big data** | ![Logo](./../x_gitres/logo.png) |

- [1. Dokumentation](#1-dokumentation)
  - [1.1. Lernziele](#11-lernziele)
  - [1.2. Warum dokumentieren?](#12-warum-dokumentieren)
  - [1.3. Dokumentation (Überblick)](#13-dokumentation-überblick)
  - [1.4. README.md – Pflichtinhalte \& Vorlage](#14-readmemd--pflichtinhalte--vorlage)
  - [1.5. Beispiel‑Skeleton (README.md)](#15-beispielskeleton-readmemd)
  - [1.6. Beispiel - Comment‑based help – Inline‑Hilfe](#16-beispiel---commentbased-help--inlinehilfe)
- [2. Aufgaben](#2-aufgaben)
  - [2.1. README.md erstellen/verbessern](#21-readmemd-erstellenverbessern)
  - [2.2. 3.1.Comment‑based help ergänzen](#22-31commentbased-help-ergänzen)

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
- PowerShell 5.1
- Schreibrechte auf Zielpfad
- Freier Speicher für Archivierung

## Installation
1. `CompressLogs.ps1` nach `C:\ProgramData\Company\Automation\` kopieren
2. (Optional) Signierung prüfen
3. (Kursbetrieb) Execution Policy pro Prozess lockern:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
```

## 1.6. Beispiel - Comment‑based help – Inline‑Hilfe

Mit einem standardisierten Block im Skript wird die Hilfe per `Get-Help` verfügbar.

```powershell
<#
.SYNOPSIS
  Aufräumen von Logdateien.

.DESCRIPTION
  Filtert Dateien seit -Since, schreibt Logfile, setzt Exitcodes und (optional) Eventlog-Einträge.

.PARAMETER Source
  Quellpfad (Ordner). Pflicht.

.PARAMETER Destination
  Zielpfad (Ordner). Wird bei Bedarf angelegt.

.PARAMETER Since
  Datum/Zeitgrenze. Standard: 7 Tage zurück.

.EXAMPLE
  .\CleanUpLogs.ps1 -Source 'C:\Logs' -Destination 'D:\Archive' -Since (Get-Date).AddDays(-7) -Verbose

.NOTES
  Autor: <Name> | Version: 1.3.0 | Lizenz: <Lizenz>
#>

```powershell
Get-Help .\CleanUpLogs.ps1 -Full
```

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
- PowerShell 5.1
- <weitere Abhängigkeiten>

## Installation
1) Skript nach `C:\ProgramData\<Company>\Automation\` kopieren
2) (Optional) Signatur/Policy prüfen

## Verwendung (Beispiele)
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\ProgramData\<Company>\Automation\<Script>.ps1" `
  -ParamA ... -ParamB ... -Verbose
```

---

## 2.2. 3.1.Comment‑based help ergänzen

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
