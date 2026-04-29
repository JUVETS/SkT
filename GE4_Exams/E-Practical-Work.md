|                             |                          |                                 |
| --------------------------- | ------------------------ | ------------------------------- |
| **Techniker HF Informatik** | **Scripting / Big data** | ![Logo](./../x_gitres/logo.png) |

- [1. Projektarbeit "Skriptingtechnik / BigData"](#1-projektarbeit-skriptingtechnik--bigdata)
  - [1.1. Organisation](#11-organisation)
  - [1.2. Allgemeines](#12-allgemeines)
  - [1.3. Auftrag](#13-auftrag)
  - [1.4. Grundsätzliche Rahmenbedingungen](#14-grundsätzliche-rahmenbedingungen)
  - [1.5. Vorgabe der Applikation](#15-vorgabe-der-applikation)
  - [1.6. Mindestanforderungen](#16-mindestanforderungen)
    - [1.6.1. PowerShell-Skript](#161-powershell-skript)
    - [1.6.2. MongoDB](#162-mongodb)
    - [1.6.3. ETL-Pipeline](#163-etl-pipeline)
    - [1.6.4. KPI / Auswertung](#164-kpi--auswertung)
    - [1.6.5. Credentials](#165-credentials)
  - [1.7. Dokumentationsumfang](#17-dokumentationsumfang)
    - [1.7.1. Konzeptdokumentation (Phase 1)](#171-konzeptdokumentation-phase-1)
    - [1.7.2. Technische Dokumentation (Phase 2)](#172-technische-dokumentation-phase-2)
  - [1.8. Präsentation](#18-präsentation)
  - [1.9. Bewertungen](#19-bewertungen)
  - [1.10. Termine](#110-termine)

</br>

# 1. Projektarbeit "Skriptingtechnik / BigData"

## 1.1. Organisation

|                     |                                                           |
| :------------------ | :-------------------------------------------------------- |
| **Lernziele**       | Skripting / BigData Projekt realisieren                   |
| **Sozialform**      | Partner-/Gruppenarbeit (max. 2-3 Mitglieder)              |
| **Auftrag**         | siehe unten                                               |
| **Hilfsmittel**     | Internet                                                  |
| **Zeitbedarf**      | Total ca. 8-12h                                           |
| **Lösungselemente** | Vollständiges Projekt inkl. Dokumentation u. Präsentation |

---

## 1.2. Allgemeines

In dieser Projektarbeit erarbeiten Sie in Gruppen (2 Personen) einen realistischen Anwendungsfall, in dem PowerShell zur Automatisierung, Systemintegration oder Datenverarbeitung zusammen mit BigData eingesetzt wird.

> **Beispiel: Das Marketing-Team benötigt eine automatisierte Pipeline, die stündlich die neuesten "Trending Products" von einer API abruft, diese bereinigt und für die langfristige Analyse in eine Big-Data-Datenbank speichert.**

---

## 1.3. Auftrag

- Sie entwickeln ein Projekt nach freier Wahl, welches sich aus einem Skript- und BigData (Datenbank) Teil zusammensetzt und als eine vollständige Applikation resultiert.
- Die beiden Techniken Skripting und Datenbanken sind integrierender Bestandteil einer Applikation.
- Im Projekt müssen die aufgeführten Rahmenbedingungen und spezifischen Anforderungen vollständig berücksichtigt und implementiert werden.
- Das Projekt ist in zwei Phasen Aufgabenbeschreibung bzw. Konzeption und Realisierung zu unterteilen und in dieser Reihenfolge abzuarbeiten.

---

## 1.4. Grundsätzliche Rahmenbedingungen

Für die Implementierung dieser Projektarbeit gelten die nachfolgend aufgeführten grundsätzlichen Rahmenbedingungen:

- **Konzeption**
  - Die Konzeption Dokumentation sollte 4 bis max. 6 A4 Seiten umfassen.
  - Kurzbeschreibung der Gesamtaufgabe, unterteilt in Datenbeschaffung, Archivierung und Auswertung (KPI's)
  - Beschreibung der Zielsetzungen, unterteilt in Muss- und Wunschziele
  - Abgrenzung, was gehört zur Lösung und was nicht (Systemgrenze bestimmen)
  - Grobplanung und Aufwandschätzung in Stunden
  - Erforderliche Hilfsmittel (SW-Produkte, Lizenzen usw.)
- **Realisierung**
  - Beide Entwicklungsbereiche Skript (ETL, Analyse) und BigData (Datenbank) müssen Bestandteil einer Applikation sein
  - Die Lösung muss auf einem Windows oder Linux Betriebssystem lauffähig sein
  - Die Skriptprogrammierung muss in PowerShell erfolgen
  - Als Datenbank ist MongoDB einzusetzen
  - Das Projekt muss modular aufgebaut sein
  - Es muss mindestens eine fortgeschrittene Technik enthalten sein
  - Logging muss implementiert sein
  - Fehlerbehandlung muss enthalten
  - Das Projekt und Programmcode muss dokumentiert sein
  - Die Realisierung darf erst nach abgeschlossener und durch den Dozenten genehmigter Konzeptionsphase erfolgen
  - Die Implementierung hat gemäss Vorgaben zur Namenskonventionen und Standards und Guide Lines zu erfolgen
  - Am Schluss muss die Lösung mit einer Live-Demonstration präsentiert werden (inkl. Diskussion, Reflexion)

---

## 1.5. Vorgabe der Applikation

Die Applikation hat sich aus einem Datenbeschaffungs- (Quelle), Archivierung- (persistente Datenhaltung) und einem Auswertungsteil (Analyse, KPI) zusammenzusetzen.

![Projektstruktur](./x_gitres/practical-work.png)

---

## 1.6. Mindestanforderungen

Die nachfolgenden Mindestanforderungen müssen zwingend erfüllt sein, damit die Projektarbeit als bestanden gilt.

### 1.6.1. PowerShell-Skript

- Mindestens 3 eigenständige Funktionen mit sinnvollen Parametern und Rückgabewerten
- Mindestens 1 fortgeschrittene Technik, z.B.:
  - Parallelverarbeitung (ForEach-Object -Parallel)
  - REST-API-Anbindung (Invoke-RestMethod)
  - Scheduled Task / Zeitsteuerung via Windows Task Scheduler oder Cron
  - Pipelining mit eigenen Objekten ([PSCustomObject])
- Fehlerbehandlung mit try/catch/finally in allen kritischen Bereichen (API-Aufruf, DB-Operationen, Dateioperationen)
- Strukturiertes Logging in eine Logdatei (.log oder .csv) mit Timestamp, Level (INFO, WARNING, ERROR) und Meldung

### 1.6.2. MongoDB

- Mindestens 1 Collection mit sinnvoll strukturierten Dokumenten (kein flaches Key-Value-Dumping)
- Mindestens 3 Abfragen/Aggregationen, z.B. Filterung, Gruppierung, Sortierung ($match, $group, $sort)
- Mindestens 1 Index zur Abfrageoptimierung
- Datenqualitätsprüfung vor dem Insert (z.B. Pflichtfelder, Typprüfung, Duplikatserkennung)

### 1.6.3. ETL-Pipeline

- Extract: Daten aus mindestens einer externen Quelle (API, CSV, Web)
- Transform: Mindestens eine Bereinigung oder Anreicherung der Rohdaten
- Load: Persistente Speicherung in MongoDB mit Upsert-Logik (kein blindes Re-Insert)

### 1.6.4. KPI / Auswertung

- Mindestens 3 aussagekräftige KPIs müssen berechnet und im Terminal oder einer Ausgabedatei dargestellt werden.

### 1.6.5. Credentials

- Keine Credentials, API-Keys oder Passwörter im Code bzw. Repository.
- Sensitive Konfiguration erfolgt über Umgebungsvariablen oder eine .env oder json-Datei.
- Falls mit **GIT** gearbeitet wird, müssen diese Dateien in `.gitignore` ausgeschlossen werden.

---

## 1.7. Dokumentationsumfang

### 1.7.1. Konzeptdokumentation (Phase 1)

Umfang: 4–6 A4-Seiten, abzugeben als PDF

**Pflichtinhalte:**

| **Abschnitt**        | **Inhalt**                                                                  |
| -------------------- | --------------------------------------------------------------------------- |
| **Ausgangslage**     | Problembeschreibung und Motivation                                          |
| **Zielsetzung**      | Muss- und Wunschziele tabellarisch                                          |
| **Systemgrenze**     | Was ist Teil der Lösung, was explizit nicht                                 |
| **Datenquellen**     | Quelle, Format, Zugriffsmethode, Lizenz/Nutzungsbedingungen                 |
| **Architektur**      | Skizze der Gesamtarchitektur (ETL-Fluss, Komponenten)                       |
| **Aufwandschätzung** | Tabelle oder Gantt mit Aufgaben, Verantwortlichkeit und geschätzten Stunden |
| **Hilfsmittel**      | Eingesetzte Tools, Libraries, Lizenzen                                      |

### 1.7.2. Technische Dokumentation (Phase 2)

**README.md** muss enthalten:

- Projektbeschreibung (2–4 Sätze)
- Voraussetzungen (PowerShell-Version, MongoDB-Version, benötigte Module)
- Installationsanleitung (Schritt-für-Schritt, reproduzierbar)
- Konfiguration (Umgebungsvariablen, Verbindungsstrings, Parameter)
- Ausführung (wie wird das Skript gestartet, welche Modi gibt es)
- Beschreibung der MongoDB-Collections und wichtigsten Felder
- Beschreibung der KPIs und deren Berechnung
- Bekannte Einschränkungen / offene Punkte

**Inline-Kommentare im Code:**

- Jede Funktion mit Comment-Based Help (`<# .SYNOPSIS / .PARAMETER / .EXAMPLE #>`)
- Komplexe Logikblöcke mit erklärendem Kommentar
- Keine auskommentierten Code-Leichen

---

## 1.8. Präsentation

Sie stellen Ihre Ergebnisse mittels einer Kurzpräsentation der Klasse vor, präsentieren Sie Ihre
Projektarbeit in einer Live Demo und schliessen Sie Ihre Präsentation mit einem kurzen Fazit ab (lessons
learned).

- Dauer ca. 20 min (15 min Präsentation + 5 min Fragen/Diskussion)
- Live-Demo zwingend, Folien optional als Leitfaden

Die Live-Demo muss auf der eigenen Maschine lauffähig sein und folgende Punkte zeigen:

- Skript wird gestartet und durchläuft den ETL-Prozess sichtbar
- Logging-Ausgabe ist nachvollziehbar (Terminal oder Logdatei)
- MongoDB-Daten sind nach dem Lauf einsehbar (z.B. via mongosh oder MongoDB Compass)
- Mindestens 1 Aggregationsabfrage wird live ausgeführt
- KPIs werden ausgegeben

---

## 1.9. Bewertungen

| **Kriterium**                                | **Punkte** |
| -------------------------------------------- | :--------: |
| **Analyse & Konzept**                        |            |
| - Problemstellung klar verstanden            |     3      |
| - Datenquellen korrekt analysiert            |     3      |
| - Ablauf logisch & nachvollziehbar           |     3      |
| - Big-Data-Bezug korrekt eingeordnet         |     3      |
|                                              |            |
| **PowerShell-Skripting**                     |            |
| - Funktionen & Parameter sinnvoll eingesetzt |     3      |
| - Schleifen & Bedingungen korrekt            |     3      |
| - Fehlerbehandlung (try/catch)               |     3      |
| - Lesbarkeit & Stil                          |     3      |
|                                              |            |
| **MongoDB / Big-Data-Integration (ETL)**     |            |
| - Filterung & Transformation                 |     3      |
| - Aggregation (Statistiken)                  |     3      |
| - Datenqualität berücksichtigt               |     3      |
| - Big-Data-Konzepte korrekt angewendet       |     3      |
|                                              |            |
| **Automatisierung & Robustheit**             |            |
| - Automatisierungsidee (z.B. Zeitsteuerung)  |     3      |
| - Logging implementiert                      |     3      |
| - Debug-/Fehlermeldungen sinnvoll            |     3      |
| - Testing                                    |     3      |
|                                              |            |
| **Dokumentation & Präsentation**             |            |
| - Technische Dokumentation (README.md)       |     3      |
| - Verständlichkeit für Dritte                |     3      |
| - Präsentation / Erklärung                   |     3      |
| - Reflexion & Ausblick                       |     3      |
|                                              |            |
| **Total**                                    |   **60**   |

> **Notenskala: Erreichte Punktzahl x 5 / Max. Punktzahl + 1 = Note (auf 1/10 Noten gerundet)**

## 1.10. Termine

Termin für Konzeptabgabe: **21.06.2026, 14:00 Uhr, OpenOLAT (Ordner Studierende)**
Termin für Projektabgabe: **25.06.2026, 23:59 Uhr, OpenOLAT (Ordner Studierende)**

---

© 2026 Lukas Müller – Licensed under CC BY-NC-ND 4.0
See [LICENSE](..\license.md) file for details.
