|                             |                          |                                 |
| --------------------------- | ------------------------ | ------------------------------- |
| **Techniker HF Informatik** | **Scripting / Big data** | ![Logo](./../x_gitres/logo.png) |

- [1. Powershell-Funktionen](#1-powershell-funktionen)
  - [1.1. Lernziele](#11-lernziele)
  - [1.2. Warum Funktionen?](#12-warum-funktionen)
  - [1.3. Funktionsbereich](#13-funktionsbereich)
  - [1.4. Grundaufbau einer Funktion](#14-grundaufbau-einer-funktion)
  - [1.5. Parameterblock param](#15-parameterblock-param)
  - [1.6. Parameter \& Validierungen](#16-parameter--validierungen)
  - [1.7. Advanced Functions („Cmdlet‑ähnlich“)](#17-advanced-functions-cmdletähnlich)
  - [1.8. Rückgabewerte](#18-rückgabewerte)
  - [1.9. Scopes in Funktionen – wichtige Regeln](#19-scopes-in-funktionen--wichtige-regeln)
  - [1.10. Naming Best Practices](#110-naming-best-practices)
- [2. Aufgaben](#2-aufgaben)
  - [2.1. Funktionen implementieren](#21-funktionen-implementieren)
  - [2.2. Aufgabe - Log-Aufräumprozess erweitert](#22-aufgabe---log-aufräumprozess-erweitert)
  - [2.3. Lotto Statistik Generator](#23-lotto-statistik-generator)

---

</br>

# 1. Powershell-Funktionen

## 1.1. Lernziele

- Erklären, warum und wann **Funktionen** eingesetzt werden,
- Den Aufbau einer PowerShell‑Funktion verstehen,
- Parameterblöcke, Rückgabewerte, Scopes und Validierungen nutzen,
- **Funktionen** modularisieren und wiederverwenden,
- saubere Funktionsbibliotheken erstellen,
- Fehlerbehandlung und Logging in **Funktionen** integrieren,
- Best Practices anwenden (Naming, Return‑Werte, Pipeline‑Verhalten).

## 1.2. Warum Funktionen?

**Funktionen** sind wiederverwendbare Bausteine, die …

- Code strukturieren,
- Fehlerquellen reduzieren,
- Lesbarkeit verbessern,
- Wiederverwendung ermöglichen,
- Testbarkeit erleichtern.

## 1.3. Funktionsbereich

Mit Funktionen kann ein Skript strukturiert und die Wiederverwendbarkeit und Lesbarkeit erhöht werden.

```powershell
function Write-Log {
    param([string]$Message)

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File ".\script.log" -Append
}
```

## 1.4. Grundaufbau einer Funktion

```powershell

# Funktion ohne Parameter
function Say-Hello {
    "Hallo Welt"
}

## Funktion mit Parameter Name
function Say-Hello {
    param(
        [string]$Name
    )
    "Hallo $Name"
}

## Hier wird die Funktion aufgerufen
Say-Hello -Name "Max"
```

## 1.5. Parameterblock param

Damit Skripte flexibel werden, nutzt man `param()`:

Vorteile von Skript mit Parametern (`param()`):

- Skript ist anpassbar ohne Codeänderung
- Skript wird wiederverwendbar
- Inputs validierbar

```powershell
param (
    [Parameter(Mandatory)]
    [string]$SourcePath,

    [Parameter()]
    [string]$DestinationPath = "C:\Archive",

    [switch]$VerboseMode
)
```

## 1.6. Parameter & Validierungen

Parameter ermöglichen es, Funktionen flexibel zu gestalten.

```powershell
function Get-Area {
    param(
        [int]$Width,
        [int]$Height
    )
    return $Width * $Height
}

# Parameter mit Validation
function Set-LogLevel {
    param(
        [ValidateSet("INFO","WARN","ERROR")]
        [string]$Level
    )
    "Level gesetzt: $Level"
}

# Parameter Mandatory
function Backup-Folder {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
}
```

## 1.7. Advanced Functions („Cmdlet‑ähnlich“)

Mit `[CmdletBinding()]` wird eine Funktion wie ein echtes Cmdlet behandelt:

- unterstützt -Verbose, -Debug, -ErrorAction, -ErrorVariable
- kann Pipeline‑Input verarbeiten
- besser testbar

```powershell
function Get-UserInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$UserName
    )
    process {
        "User: $UserName"
    }
}

"max","anna" | Get-UserInfo -Verbose
```

## 1.8. Rückgabewerte

`return <wert>` beendet Funktion + gibt Wert zurück

```powershell
function Add-Numbers {
    param($A, $B)

    return ($A + $B)
}
```

## 1.9. Scopes in Funktionen – wichtige Regeln

PowerShell kennt folgende Scopes:

- `local`: – innerhalb der Funktion (Standard)
- `script`: – globale Variable im Skript
- `global`: – systemweit (vorsicht!)
- `private`: – isoliert im aktuellen Scope

```powershell
$global:Counter = 0

function Increase-Counter {
    $script:Counter = $script:Counter + 1
}
```

## 1.10. Naming Best Practices

- CmdletStyle: Verb‑Noun verwenden
- Kein „SetX“ → besser „Set‑Config“, „Add‑User“
- Microsoft approved Verbs nutzen (Get‑Help Verb)

**Beispiele:**

- ✔ Get-LogSummary
- ✔ New-Archive
- ✔ Test-File
- ❌ DoThatThing

</br>

---

# 2. Aufgaben

## 2.1. Funktionen implementieren

| **Vorgabe**             | **Beschreibung**                                                        |
| :---------------------- | :---------------------------------------------------------------------- |
| **Lernziele**           | Sie strukturieren Code und machen ihn testbar                           |
|                         | Parameter, Validierung und Scopes sind für saubere Architektur bekannt. |
| **Sozialform**          | Einzelarbeit                                                            |
| **Hilfsmittel**         |                                                                         |
| **Erwartete Resultate** |                                                                         |
| **Zeitbedarf**          | 50 min                                                                  |
| **Lösungselemente**     | PowerShell Datei mit sämtlichen Lösungen                                |

**A1:**

Erstelle eine Funktion `Get-RectangleArea`, die Breite und Höhe übernimmt und die Fläche berechnet.
Starte die Funktion aus dem Hauptprogramm und zeige das Resultat in der Konsole an.

**A2:**

Schreibe eine Funktion Write-Log (INFO/WARN/ERROR), die Log-Meldungen mit Zeitstempel in eine Logdatei schreibt.
Rufe die Write-Log Funktionen im Hauptprogramm auf.

**Beispiel:**

```powershell
function Write-Log {
    param($Message,[ValidateSet('INFO','WARN','ERROR')]$Level)
    "$Level $(Get-Date): $Message" | Out-File ".\script.log" -Append
}
```

**A3:**

In einer Autovermietung werden – unter anderem – die Mietkosten berechnet.  
Dabei wird wie folgt vorgegangen:

- Die ersten 200 km werden nicht berechnet,
- Für die nächsten 800 km werden 0.8 CHF je km berechnet,
- Darüberhinausgehende km werden mit 0.50 CHF je km berechnet

Schreiben Sie ein Programm, das den km-Stand vor Abfahrt und den nach der Differenz nach den obigen Vorgaben die km-Kosten berechnet.

- Prüfen Sie die Benutzereingabe, sodass KM-Stand Start immer kleiner ist als KM-Stand Ende.
- Fügen Sie der Skriptdatei einen Kommentarheader hinzu.
- Gliedern Sie Ihren Code in mehrere Funktionen:
  - `TitelAusgeben()`: Titel ausgeben
  - `KMStandEinlesen()`: Eine Kilometerstand einlesen
  - `MietkostenBerechnung()`: Aus den gefahrenen KM die Mietkostenberechnung durchführen

---

</br>

## 2.2. Aufgabe - Log-Aufräumprozess erweitert

| **Vorgabe**             | **Beschreibung**                             |
| :---------------------- | :------------------------------------------- |
| **Lernziele**           | Variablen gezielt einsetzen                  |
|                         | Schleifen & verschachtelte Strukturen nutzen |
|                         | Saubere Scriptarchitektur                    |
|                         | Korrekte Dokumention (Header u. Code)        |
| **Sozialform**          | Einzelarbeit                                 |
| **Auftrag**             | siehe unten                                  |
| **Hilfsmittel**         |                                              |
| **Erwartete Resultate** |                                              |
| **Zeitbedarf**          | 60 min                                       |
| **Lösungselemente**     | Lauffähiger Skript                           |

Baue dein Script (Log-Aufräumprozess) um:

- Erstelle Funktionen
  - `Get-UserInput`
  - `Get-FilesToDelete`
  - `Remove-Files`
  - `Write-Log`
- Nutze Schleifen zur Verarbeitung mehrerer Dateien
- Übergabe von Parametern
- Rückgabewerte verwenden

---

## 2.3. Lotto Statistik Generator

| **Vorgabe**             | **Beschreibung**                         |
| :---------------------- | :--------------------------------------- |
| **Lernziele**           | Variablen gezielt einsetzen              |
|                         | HashTables nutzen                        |
|                         | Datenaggregation durchführen             |
|                         | Korrekte Dokumention (Header u. Code)    |
| **Sozialform**          | Einzelarbeit                             |
| **Hilfsmittel**         |                                          |
| **Erwartete Resultate** |                                          |
| **Zeitbedarf**          | 40 min                                   |
| **Lösungselemente**     | PowerShell Datei mit sämtlichen Lösungen |

**Ausgangslage:**

Die Lotteriegesellschaft möchte ein kleines Tool entwickeln lassen, mit dem **zufällige Lottozahlen nach dem Schweizer Lotto-System generiert werden können**.

Beim Schweizer Lotto werden:

- **6 Hauptzahlen aus dem Bereich 1–42**
- **1 Glückszahl aus dem Bereich 1–6**

gezogen.

**A1:**
Erweitere das Programm **"Lottozahlen"** um die nachfolgenden statistischen Auswertungen und strukturiere es mit mehreren Funktionen:

- 1000 Ziehungen simulieren
- Statistik berechnen:
  - Häufigkeit jeder Zahl
  - häufigste Zahl
  - seltenste Zahl
- Resultat ausgeben

**Beispiel:**

Häufigkeit der Zahlen

```console
1  : 145
2  : 132
...
42 : 119

Häufigste Zahl : 17
Seltenste Zahl : 4
```

---

© 2026 Lukas Müller – Licensed under CC BY-NC-ND 4.0
See [LICENSE](..\license.md) file for details.
