|                             |                          |                                 |
| --------------------------- | ------------------------ | ------------------------------- |
| **Techniker HF Informatik** | **Scripting / Big data** | ![Logo](./../x_gitres/logo.png) |

- [1. PowerShell Module (.psm1)](#1-powershell-module-psm1)
  - [1.1. Lernziele](#11-lernziele)
  - [1.2. Warum Module?](#12-warum-module)
  - [1.3. Aufbau und Dateistruktur](#13-aufbau-und-dateistruktur)
  - [1.4. Funktionen exportieren mit Export-ModuleMember](#14-funktionen-exportieren-mit-export-modulemember)
  - [1.5. Modul laden und verwenden](#15-modul-laden-und-verwenden)
  - [1.6. Modul-Manifest (.psd1)](#16-modul-manifest-psd1)
  - [1.7. Modul installieren und verteilen](#17-modul-installieren-und-verteilen)
  - [1.8. Vollständiges Beispiel: MathTools](#18-vollständiges-beispiel-mathtools)
  - [1.9. Vergleich: .ps1 vs. .psm1 vs. .psd1](#19-vergleich-ps1-vs-psm1-vs-psd1)
- [2. Aufgaben](#2-aufgaben)
  - [2.1. Modul StringTools erstellen](#21-modul-stringtools-erstellen)
  - [2.2. Log-Aufräumprozess als Modul](#22-log-aufräumprozess-als-modul)

---

</br>

# 1. PowerShell Module (.psm1)

## 1.1. Lernziele

Nach dieser Einheit können die Teilnehmer*innen:

- erklären, wozu PowerShell-Module dienen und wann sie gegenüber einfachen Skripten sinnvoll sind,
- ein eigenes Modul als `.psm1`-Datei erstellen und strukturieren,
- Funktionen gezielt mit `Export-ModuleMember` nach aussen sichtbar machen,
- ein Modul mit `Import-Module` laden und dessen Funktionen verwenden,
- den Unterschied zwischen `.ps1`, `.psm1` und `.psd1` erklären,
- ein einfaches Modul-Manifest mit `New-ModuleManifest` erstellen.

---

## 1.2. Warum Module?

Wenn Funktionen in mehreren Skripten gebraucht werden, ist Copy-Paste die schlechteste Lösung: eine Korrektur muss überall gleichzeitig gemacht werden. **Module** lösen dieses Problem.

Ein PowerShell-Modul ist eine **wiederverwendbare Bibliothek von Funktionen**, die:

- einmal geschrieben und in beliebig vielen Skripten verwendet werden kann,
- klare **öffentliche und private** Bereiche trennt (was nach aussen sichtbar ist, was nicht),
- versioniert, dokumentiert und verteilt werden kann,
- von PowerShell **automatisch gefunden** wird, wenn sie am richtigen Ort abgelegt ist.

**Typische Einsatzgebiete:**

| **Einsatzgebiet**             | **Beispiel**                                        |
| :---------------------------- | :-------------------------------------------------- |
| Shared Utilities              | Logging, Datumsformatierung, Validierungsfunktionen |
| Unternehmensstandards         | Firmeninterne Namenskonventionen, AD-Funktionen     |
| Wiederverwendbare Komponenten | Datenbankzugriff, REST-API-Wrapper                  |
| Kursmodule / Lernumgebungen   | Lehrmaterial als fertiges Cmdlet-Set                |

---

## 1.3. Aufbau und Dateistruktur

Ein Modul besteht mindestens aus einer `.psm1`-Datei. Professionelle Module haben zusätzlich ein Manifest (`.psd1`).

**Minimalstruktur:**

```console
MathTools\
└── MathTools.psm1        ← Modul-Code
```

**Empfohlene Vollstruktur:**

```console
MathTools\
├── MathTools.psm1        ← alle Funktionen
├── MathTools.psd1        ← Manifest (Metadaten, Versionierung)
└── README.md             ← Dokumentation
```

> **Wichtig:** Der **Ordnername** und der **Dateiname** (ohne Erweiterung) müssen identisch sein – PowerShell erkennt das Modul anhand dieser Konvention.

---

## 1.4. Funktionen exportieren mit Export-ModuleMember

Standardmässig sind alle Funktionen in einer `.psm1`-Datei **privat** – von aussen nicht aufrufbar. Mit `Export-ModuleMember` wird festgelegt, welche Funktionen **öffentlich** zugänglich sind.

```powershell
# MathTools.psm1

# ── Öffentliche Funktionen ──────────────────────────────────────────────────

function Get-Factorial {
    <#
    .SYNOPSIS
    Berechnet die Fakultät einer ganzen Zahl.
    #>
    param(
        [Parameter(Mandatory)]
        [ValidateRange(0, 20)]
        [int]$Number
    )
    if ($Number -le 1) { return 1 }
    return $Number * (Get-Factorial -Number ($Number - 1))
}

function Get-IsPrime {
    <#
    .SYNOPSIS
    Prüft, ob eine Zahl eine Primzahl ist.
    #>
    param(
        [Parameter(Mandatory)]
        [int]$Number
    )
    if ($Number -lt 2)  { return $false }
    if ($Number -eq 2)  { return $true  }
    if ($Number % 2 -eq 0) { return $false }

    for ($i = 3; $i * $i -le $Number; $i += 2) {
        if ($Number % $i -eq 0) { return $false }
    }
    return $true
}

# ── Private Hilfsfunktion (NICHT exportiert) ────────────────────────────────

function Invoke-ValidatePositive {
    param([int]$Value)
    if ($Value -le 0) { throw "Wert muss positiv sein: $Value" }
}

# ── Export: nur diese Funktionen sind von aussen sichtbar ───────────────────

Export-ModuleMember -Function Get-Factorial, Get-IsPrime
```

**Was passiert mit nicht exportierten Funktionen?**

`Invoke-ValidatePositive` ist nach dem Import **nicht** aufrufbar – sie existiert nur intern und kann von `Get-Factorial` und `Get-IsPrime` genutzt werden. Das entspricht dem Prinzip der **Kapselung** aus der objektorientierten Programmierung.

---

## 1.5. Modul laden und verwenden

```powershell
# Modul aus einem bestimmten Pfad laden
Import-Module "C:\Scripts\MathTools\MathTools.psm1"

# Geladene Module anzeigen
Get-Module

# Verfügbare Cmdlets des Moduls anzeigen
Get-Command -Module MathTools

# Funktionen verwenden
Get-Factorial -Number 5          # → 120
Get-IsPrime -Number 17           # → True
Get-IsPrime -Number 10           # → False

# Modul aus der Sitzung entfernen
Remove-Module MathTools

# Modul neu laden (nach Änderungen)
Import-Module ".\MathTools\MathTools.psm1" -Force
```

> **Tipp: `-Force`** beim Import ist nützlich während der Entwicklung – es lädt das Modul neu, auch wenn es bereits importiert ist.

**Automatisches Laden** funktioniert, wenn das Modul im Standard-Modulpfad liegt:

```powershell
# Modulpfade anzeigen (PowerShell sucht hier automatisch)
$env:PSModulePath -split ';'

# Modul in Benutzer-Modulpfad ablegen (kein Admin nötig):
# C:\Users\<Name>\Documents\PowerShell\Modules\MathTools\

# Danach reicht:
Import-Module MathTools    # PowerShell findet es automatisch
```

---

## 1.6. Modul-Manifest (.psd1)

Ein **Manifest** ist eine **Metadaten-Datei**, die PowerShell über das Modul informiert: Version, Autor, Abhängigkeiten, welche Dateien dazugehören und welche Funktionen exportiert werden.

```powershell
# Manifest automatisch erstellen
New-ModuleManifest -Path ".\MathTools\MathTools.psd1" `
    -RootModule        "MathTools.psm1" `
    -ModuleVersion     "1.2.0" `
    -Author            "Lukas Müller" `
    -Description       "Mathematische Hilfsfunktionen für PowerShell" `
    -FunctionsToExport "Get-Factorial", "Get-IsPrime" `
    -PowerShellVersion "7.0"
```

Ausschnitt aus der erzeugten `MathTools.psd1`:

```powershell
@{
    RootModule        = 'MathTools.psm1'
    ModuleVersion     = '1.2.0'
    Author            = 'Lukas Müller'
    Description       = 'Mathematische Hilfsfunktionen für PowerShell'
    PowerShellVersion = '7.0'
    FunctionsToExport = @('Get-Factorial', 'Get-IsPrime')
}
```

Vorteile eines Manifests:

- **Versionsverwaltung** – mehrere Versionen nebeneinander möglich
- **Abhängigkeiten** deklarieren (`RequiredModules`)
- **Sichtbarkeit** zentral steuern (`FunctionsToExport`, `CmdletsToExport`)
- Voraussetzung für Veröffentlichung im **PowerShell Gallery**

---

## 1.7. Modul installieren und verteilen

**Option A – Lokal, manuell:**

Modul-Ordner in einen der `$PSModulePath`-Pfade kopieren:

```powershell
# Für aktuellen Benutzer (kein Admin nötig)
$ziel = "$HOME\Documents\PowerShell\Modules\MathTools"
Copy-Item -Path ".\MathTools" -Destination $ziel -Recurse
```

**Option B – PowerShell Gallery (öffentlich/intern):**

```powershell
# Modul aus der offiziellen Gallery installieren (Beispiel: Pester)
Install-Module -Name Pester -Scope CurrentUser

# Eigenes Modul in eine interne Gallery (z.B. Nexus, Artifactory) veröffentlichen
Publish-Module -Name MathTools -Repository "FirmenGallery"
```

**Option C – Dot Sourcing (nur für die aktuelle Sitzung):**

```powershell
# Nur Funktionen einlesen, kein vollständiges Modul
. "C:\Scripts\MathTools\MathTools.psm1"
```

---

## 1.8. Vollständiges Beispiel: MathTools

Komplette Projektstruktur zum Nachbauen:

**`MathTools\MathTools.psm1`:**

```powershell
<#
.SYNOPSIS
    Modul mit mathematischen Hilfsfunktionen.
.NOTES
    Autor  : Lukas Müller
    Version: 1.2.0
#>

function Get-Factorial {
    param(
        [Parameter(Mandatory)]
        [ValidateRange(0, 20)]
        [int]$Number
    )
    if ($Number -le 1) { return 1 }
    return $Number * (Get-Factorial -Number ($Number - 1))
}

function Get-IsPrime {
    param(
        [Parameter(Mandatory)]
        [int]$Number
    )
    if ($Number -lt 2)     { return $false }
    if ($Number -eq 2)     { return $true  }
    if ($Number % 2 -eq 0) { return $false }
    for ($i = 3; $i * $i -le $Number; $i += 2) {
        if ($Number % $i -eq 0) { return $false }
    }
    return $true
}

function Get-PrimesUpTo {
    param(
        [Parameter(Mandatory)]
        [ValidateRange(2, 10000)]
        [int]$Limit
    )
    2..$Limit | Where-Object { Get-IsPrime -Number $_ }
}

# Private Hilfsfunktion – nicht exportiert
function Invoke-ValidatePositive {
    param([int]$Value)
    if ($Value -le 0) { throw "Wert muss positiv sein: $Value" }
}

Export-ModuleMember -Function Get-Factorial, Get-IsPrime, Get-PrimesUpTo
```

**Verwendung:**

```powershell
Import-Module ".\MathTools\MathTools.psm1"

Get-Factorial -Number 10           # → 3628800
Get-IsPrime -Number 97             # → True
Get-PrimesUpTo -Limit 50           # → 2 3 5 7 11 13 17 19 23 29 31 37 41 43 47

# Hilfe aus Comment-Based Help
Get-Help Get-Factorial

# Private Funktion ist nicht aufrufbar:
Invoke-ValidatePositive -Value -1  # Fehler: "Invoke-ValidatePositive" nicht gefunden
```

---

## 1.9. Vergleich: .ps1 vs. .psm1 vs. .psd1

| Merkmal                  | `.ps1` (Skript)                     | `.psm1` (Modul)                    | `.psd1` (Manifest)                   |
| :----------------------- | :---------------------------------- | :--------------------------------- | :----------------------------------- |
| **Zweck**                | Einmaliger Ablauf / Automatisierung | Bibliothek mit Funktionen          | Metadaten für ein Modul              |
| **Inhalt**               | Befehle, Logik, Funktionen          | Nur Funktionen (+ Export)          | Nur Konfiguration (keine Logik)      |
| **Aufruf**               | `.\Script.ps1`                      | `Import-Module .\Modul.psm1`       | Wird automatisch mit `.psm1` geladen |
| **Wiederverwendbarkeit** | Gering – läuft von oben nach unten  | Hoch – Funktionen beliebig nutzbar | Nur Metadaten, kein Code             |
| **Private Funktionen**   | Nein (alle sichtbar)                | Ja – durch `Export-ModuleMember`   | Nicht anwendbar                      |
| **Versionierung**        | Nur über Dateiname                  | Über `.psd1` (ModuleVersion)       | `ModuleVersion` zentral pflegen      |
| **Automatisches Laden**  | Nein                                | Ja – wenn in `$PSModulePath`       | Ja – zusammen mit `.psm1`            |

---

# 2. Aufgaben

## 2.1. Modul StringTools erstellen

| **Vorgabe**             | **Beschreibung**                                         |
| :---------------------- | :------------------------------------------------------- |
| **Lernziele**           | Ein eigenes PowerShell-Modul als `.psm1`-Datei erstellen |
|                         | Funktionen mit `Export-ModuleMember` gezielt exportieren |
|                         | Modul laden, testen und in einem Skript verwenden        |
| **Sozialform**          | Einzelarbeit                                             |
| **Auftrag**             | siehe unten                                              |
| **Hilfsmittel**         | `Get-Help`, VS Code                                      |
| **Erwartete Resultate** |                                                          |
| **Zeitbedarf**          | 45 min                                                   |
| **Lösungselemente**     | `StringTools.psm1`, Testskript `Test-StringTools.ps1`    |

---

Erstelle ein Modul `StringTools`, das nützliche String-Hilfsfunktionen enthält.

**Teil A – Modul erstellen (`StringTools\StringTools.psm1`)**

Implementiere folgende **öffentliche** Funktionen:

**1. `Get-WordCount`** – zählt die Wörter in einem Text

```powershell
# Erwartetes Verhalten:
Get-WordCount -Text "Hallo schöne Welt"    # → 3
Get-WordCount -Text "PowerShell ist toll"  # → 3
```

**2. `ConvertTo-TitleCase`** – wandelt einen Text in Titelschreibweise um (jedes Wort gross)

```powershell
# Erwartetes Verhalten:
ConvertTo-TitleCase -Text "hallo schöne welt"  # → "Hallo Schöne Welt"
```

**3. `Test-IsPalindrome`** – prüft, ob ein Wort/Satz ein Palindrom ist (Gross/Kleinschreibung ignorieren)

```powershell
# Erwartetes Verhalten:
Test-IsPalindrome -Text "Racecar"   # → True
Test-IsPalindrome -Text "PowerShell" # → False
```

Erstelle zusätzlich eine **private** Hilfsfunktion `Remove-Whitespace`, die Text von führenden/nachgestellten Leerzeichen bereinigt – diese soll **nicht** exportiert werden.

**Anforderungen an das Modul:**

- Korrekte `Export-ModuleMember`-Angabe (nur die drei öffentlichen Funktionen)
- Comment-Based Help (`.SYNOPSIS`) für jede öffentliche Funktion
- Parametervalidierung: `-Text` darf nicht leer sein (`[ValidateNotNullOrEmpty()]`)

---

**Teil B – Modul verwenden (`Test-StringTools.ps1`)**

Erstelle ein Testskript, das:

1. Das Modul per `Import-Module` lädt
2. Alle drei Funktionen mit je zwei verschiedenen Eingaben aufruft und die Ergebnisse ausgibt
3. Versucht, die private Funktion `Remove-Whitespace` aufzurufen, und den resultierenden Fehler sauber abfängt

```powershell
# Erwartete Ausgabe (Beispiel):
# --- Get-WordCount ---
# "Hallo schöne Welt"      → 3
# "PowerShell Scripting"   → 2
#
# --- ConvertTo-TitleCase ---
# "hallo welt"             → "Hallo Welt"
# "powershell ist cool"    → "Powershell Ist Cool"
#
# --- Test-IsPalindrome ---
# "Racecar"                → True
# "PowerShell"             → False
#
# --- Private Funktion ---
# Fehler erwartet: Remove-Whitespace ist nicht verfügbar.
```

---

**Teil C (optional) – Manifest erstellen:**

Erstelle mit `New-ModuleManifest` eine `StringTools.psd1` für dein Modul:

- Version: `1.0.0`
- Autor: dein Name
- PowerShell-Mindestversion: `7.0`
- Exportierte Funktionen: die drei öffentlichen

Prüfe mit `Test-ModuleManifest .\StringTools\StringTools.psd1`, ob das Manifest gültig ist.

---

## 2.2. Log-Aufräumprozess als Modul

| **Vorgabe**             | **Beschreibung**                                                             |
| :---------------------- | :--------------------------------------------------------------------------- |
| **Lernziele**           | Bestehende Funktionen in ein Modul auslagern und wiederverwenden             |
|                         | Öffentliche und private Funktionen gezielt trennen (`Export-ModuleMember`)   |
|                         | Hauptskript sauber von Modul-Logik trennen                                   |
| **Sozialform**          | Einzelarbeit                                                                 |
| **Voraussetzung**       | Aufgabe «Log-Aufräumprozess erweitert» aus README-functions.md abgeschlossen |
| **Auftrag**             | siehe unten                                                                  |
| **Hilfsmittel**         | VS Code, eigenes Funktions-Skript aus der Funktionen-Aufgabe                 |
| **Erwartete Resultate** |                                                                              |
| **Zeitbedarf**          | 45 min                                                                       |
| **Lösungselemente**     | `LogCleanup\LogCleanup.psm1` · `Start-LogCleanup.ps1`                        |

---

**Ausgangslage:**

Im Funktionen-Kapitel (README-functions.md, Aufgabe 2.2) wurde der Log-Aufräumprozess mit vier Funktionen strukturiert:

| Funktion            | Aufgabe                                            |
| :------------------ | :------------------------------------------------- |
| `Get-UserInput`     | Verzeichnis, Dateityp und Alter vom Benutzer lesen |
| `Get-FilesToDelete` | Dateien filtern, die den Kriterien entsprechen     |
| `Remove-Files`      | Dateien löschen mit Sicherheitsabfrage             |
| `Write-Log`         | Aktionen in eine Log-Datei schreiben               |

Bisher waren alle Funktionen direkt im Hauptskript enthalten. Das Ziel dieser Aufgabe ist es, diese Logik in ein **eigenständiges Modul** auszulagern, damit sie in verschiedenen Skripten wiederverwendet werden kann.

---

**Teil A – Modul erstellen (`LogCleanup\LogCleanup.psm1`)**

Lagere die vier Funktionen in ein Modul aus. Beachte dabei:

- **`Write-Log`** soll **privat** bleiben (interne Hilfsfunktion des Moduls, nicht direkt von aussen aufrufbar)
- Die drei anderen Funktionen sind **öffentlich** und werden exportiert
- Jede öffentliche Funktion erhält einen `.SYNOPSIS`-Kommentarblock
- Parametervalidierungen (`[ValidateNotNullOrEmpty()]`, `[ValidateRange()]`) bleiben erhalten

**Gewünschte Ordnerstruktur:**

```console
LogCleanup\
└── LogCleanup.psm1      ← Modul mit allen vier Funktionen

Start-LogCleanup.ps1     ← Hauptskript (ruft nur noch Modul-Funktionen auf)
```

**Was ins Modul gehört:**

```powershell
# LogCleanup.psm1

# Private Funktion (NICHT exportieren):
function Write-Log { ... }

# Öffentliche Funktionen (exportieren):
function Get-UserInput { ... }
function Get-FilesToDelete { ... }
function Remove-Files { ... }

Export-ModuleMember -Function Get-UserInput, Get-FilesToDelete, Remove-Files
```

> **Warum ist `Write-Log` privat?**
> Logging ist eine interne Infrastrukturfunktion des Moduls. Die aufrufenden Funktionen (`Get-FilesToDelete`, `Remove-Files`) nutzen sie intern – nach aussen wird nur das Ergebnis sichtbar. Das verhindert, dass Aufrufer die Log-Datei direkt beschreiben, ohne den vorgesehenen Weg zu gehen.

---

**Teil B – Hauptskript (`Start-LogCleanup.ps1`)**

Das Hauptskript soll so schlank wie möglich sein – die gesamte Logik liegt im Modul:

```powershell
# Start-LogCleanup.ps1

# 1. Modul laden
Import-Module ".\LogCleanup\LogCleanup.psm1" -Force

# 2. Ablauf steuern – NUR Orchestrierung, keine eigene Logik
$params     = Get-UserInput
$files      = Get-FilesToDelete @params
Remove-Files -Files $files -LogPath $params.LogPath
```

Anforderungen an das Hauptskript:

- Kein eigener Ablauf-Code ausser dem Aufruf der drei Modul-Funktionen
- `$ErrorActionPreference = 'Stop'` am Anfang
- Comment-Based Help (`.SYNOPSIS`) für das Skript selbst
- Exitcode 0 bei Erfolg, 1 bei Fehler

---

**Teil C – Testen:**

Verifiziere nach der Umstellung:

```powershell
# Modul laden und verfügbare Funktionen prüfen
Import-Module ".\LogCleanup\LogCleanup.psm1" -Force
Get-Command -Module LogCleanup
```

Erwartete Ausgabe – nur die drei öffentlichen Funktionen:

```console
CommandType  Name                Module
-----------  ----                ------
Function     Get-FilesToDelete   LogCleanup
Function     Get-UserInput       LogCleanup
Function     Remove-Files        LogCleanup
```

Prüfe auch, dass `Write-Log` nicht sichtbar ist:

```powershell
# Dieser Befehl soll einen Fehler liefern:
Write-Log -Message "Test"   # → Fehler: 'Write-Log' nicht gefunden
```

---

**Reflexionsfragen** *(schriftlich, je 2–3 Sätze)*

1. Welchen konkreten Vorteil hat es, dass `Write-Log` privat ist – in welchem Szenario würde eine öffentliche `Write-Log`-Funktion zu Problemen führen?
2. Was müsste am Modul geändert werden, wenn der Log-Aufräumprozess auch auf Netzlaufwerken funktionieren soll – und wie würde das die Modul-Schnittstelle beeinflussen?

---

© 2026 Lukas Müller – Licensed under CC BY-NC-ND 4.0
See [LICENSE](../license.md) file for details.
