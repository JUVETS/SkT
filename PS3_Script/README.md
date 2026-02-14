|                             |                               |                                 |
| --------------------------- | ----------------------------- | ------------------------------- |
| **Techniker HF Informatik** | **Kurs Scripting / Big data** | ![Logo](./../x_gitres/logo.png) |

- [1. PowerShell Scripting](#1-powershell-scripting)
  - [1.1. Lernziele](#11-lernziele)
  - [1.2. Was ist ein PowerShell-Skript?](#12-was-ist-ein-powershell-skript)
  - [1.3. Skripterstellung – vom ersten Befehl zum strukturierten Script](#13-skripterstellung--vom-ersten-befehl-zum-strukturierten-script)
    - [1.3.1. Editoren](#131-editoren)
  - [1.4. Grundaufbau eines PowerShell-Skripts](#14-grundaufbau-eines-powershell-skripts)
    - [1.4.1. Header / Kommentarblock](#141-header--kommentarblock)
    - [1.4.2. Parameterblock](#142-parameterblock)
    - [1.4.3. Funktionsbereich](#143-funktionsbereich)
    - [1.4.4. Skriptlogik / Ablauf](#144-skriptlogik--ablauf)
  - [1.5. Mehrzeiliger Befehl](#15-mehrzeiliger-befehl)
    - [1.5.1. Fehlermanagement](#151-fehlermanagement)
    - [1.5.2. PowerShell-Skripte speichern](#152-powershell-skripte-speichern)
  - [1.6. Skriptaufruf – wie starte ich ein Script?](#16-skriptaufruf--wie-starte-ich-ein-script)
    - [1.6.1. Direkt aus dem Terminal oder PowerShell Konsole](#161-direkt-aus-dem-terminal-oder-powershell-konsole)
    - [1.6.2. Dot Sourcing - Skripte dauerhaft einbinden](#162-dot-sourcing---skripte-dauerhaft-einbinden)
  - [1.7. Parameter für Skripte](#17-parameter-für-skripte)
    - [1.7.1. Beispiel](#171-beispiel)
  - [1.8. Sicherheit](#18-sicherheit)
  - [Wichtige Skripteinstellungen](#wichtige-skripteinstellungen)
    - [set-psdebug - Debugfingfunktionen](#set-psdebug---debugfingfunktionen)
    - [set-strictmode - Codierungsregeln](#set-strictmode---codierungsregeln)
  - [1.9. Vollständiges Demo-Skript](#19-vollständiges-demo-skript)
- [2. Aufgaben](#2-aufgaben)
  - [2.1. Alter Berechnung](#21-alter-berechnung)
  - [2.2. Systeminformationen](#22-systeminformationen)
  - [2.3. Skript erstellen - Pfad prüfen](#23-skript-erstellen---pfad-prüfen)
  - [2.4. Aufgabe - Log-Aufräumprozess](#24-aufgabe---log-aufräumprozess)

---

</br>

# 1. PowerShell Scripting

## 1.1. Lernziele

Nach dieser Einheit sollen die Teilnehmer*innen:

- den Grundaufbau eines PowerShell-Skripts verstehen,
- eine saubere Struktur (Header, Parameterblöcke, Funktionen, Logik) erstellen können,
- den Unterschied zwischen Befehlen, Funktionen und Cmdlets kennen,
- wissen, wie man Skripte korrekt speichert, ausführt und debuggt,
- grundlegende Sicherheitsmechanismen (Execution Policy, Signierung) einordnen,
- Skripte über Parameter flexibel nutzbar machen.

## 1.2. Was ist ein PowerShell-Skript?

Ein PowerShell-Skript ist eine Textdatei mit der Endung `.ps1`, die eine Folge von PowerShell-Befehlen enthält.
Diese Skripte sind reine Textdateien und haben die Dateinamenerweiterung.

```powershell
## MeinSkript.ps1
#
"Informationen über diesen Computer:"
"Datum: " + (Get-Date).ToShortDateString()
"Zeit: " + (Get-Date).ToLongTimeString()
"Anzahl laufender Prozesse: " + (Get-Process).Count
"Anzahl gestarteter Dienste: " + (Get-Service | 
                                    Where-Object { $_.Status -eq "running"}).Count
```

Skripte sind ideal für:

- Automatisierung wiederkehrender Aufgaben
- Konfiguration von Systemen und Diensten
- Auswertung von Logs, Daten, Dateien
- Integration in Systeme wie Scheduled Tasks

## 1.3. Skripterstellung – vom ersten Befehl zum strukturierten Script

### 1.3.1. Editoren

Für professionelles Arbeiten nutze:

- VS Code + PowerShell Extension (bevorzugte Wahl)
- Syntax-Highlighting, Autovervollständigung, Debugger
- PowerShell ISE (älter, aber in Windows 5.1 noch vorhanden)

## 1.4. Grundaufbau eines PowerShell-Skripts

Ein gut strukturiertes Skript besteht aus folgenden Teilen:

### 1.4.1. Header / Kommentarblock

Ein gutes Skript zeichnet sich dadurch aus, dass es gut lesbar ist, dass der Code also entsprechend kommentiert wurde.
Kommentare werden in der PowerShell-Skriptsprache durch eine Raute `#` bzw. bei mehrzeilen `<# … #>`gekennzeichnet.
Die Raute gilt immer nur für den Rest der Zeile.

Der Kommentarblock ist wichtig:

- dient zur Dokumentation und Verständlichkeit
- erleichtert Wartung
- klarer Überblick
- kann via Get-Help sichtbar werden, wenn korrekt formatiert

Hilfe in Windows PowerShell kann vor Beginn einer Funktion innerhalb des Kommentarblocks: (<# ..#>) hinterlegt werden.

- `.Synopsis`     Kurzbeschreibung
- `.Description`  Lange Beschreibung
- `.Parameter`    Parameter-Beschreibung
- `.Example`      Beispiel: kann auch mehrfach verwendet werden

```powershell
<#
.SYNOPSIS
   Erstellt einen täglichen Log-Report.
.DESCRIPTION
   Sammelt Dateien, komprimiert sie und schreibt einen Statusbericht.
.AUTHOR
   Lukas Müller
.VERSION
   1.0
#>

$services = Get-Service   # holt die gestarteten Dienste 
```

### 1.4.2. Parameterblock

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

### 1.4.3. Funktionsbereich

Mit Funktionen kann ein Skript strukturiert und die Wiederverwendbarkeit und Lesbarkeit erhöht werden.

```powershell
function Write-Log {
    param([string]$Message)

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File ".\script.log" -Append
}
```

### 1.4.4. Skriptlogik / Ablauf

Hier wird das eigentliche Verhalten umgesetzt:

```powershell
Write-Log "Skript gestartet."

$files = Get-ChildItem -Path $SourcePath -File
Write-Log "Gefundene Dateien: $($files.Count)"

foreach ($file in $files) {
    Copy-Item $file.FullName -Destination $DestinationPath
}
```

## 1.5. Mehrzeiliger Befehl

- Ein mehrzeiliger Befehl muss wie folgt getrennt werden
- Die Zeile mit einem Pipe-Symbol beendet
- Die Zeile wird mit einem Gravis [`], ASCI-Code 96 abgeschlossen

```powershell
# Umbruch nach Pipe
Get-Process |
  Sort-Object Workingset

# Umbruch mit Gravis [`]  
Get-Process `
  | Sort-Object Workingset
```

### 1.5.1. Fehlermanagement

PowerShell kann Fehler unterschiedlich behandeln:

- terminating errors -> lösen ein catch aus
- non-terminating errors -> nur Meldung

Standard ist non-terminating.

Für robusten Code:

```powershell
try {
    Copy-Item $file.FullName $DestinationPath -ErrorAction Stop
}
catch {
    Write-Log "Fehler beim Kopieren: $($_.Exception.Message)"
}
```

### 1.5.2. PowerShell-Skripte speichern

Die Datei muss folgende Kriterien erfüllen:

- Dateiendung: .ps1
- UTF‑8 ohne BOM empfohlen (Umlaute!)
- kein verborgener Unicode-Müll von Kopierfehlern

```console
C:\Scripts\BackupLogs.ps1
```

## 1.6. Skriptaufruf – wie starte ich ein Script?

Der Start einer Skriptdatei braucht zwingend immer eine Pfadangabe.

### 1.6.1. Direkt aus dem Terminal oder PowerShell Konsole

```powershell
.\BackupLogs.ps1            # relativer Pfad
C:\Scripts\BackupLogs.ps1   # absoluter Pfad
.\Backup.ps1 -SourcePath "C:\Logs" -DestinationPath "D:\Archive" -VerboseMode   # Aufruf mit Parametern
```

### 1.6.2. Dot Sourcing - Skripte dauerhaft einbinden

- Eine Skriptdatei wird permanent in die aktuelle Instanz der PowerShell eingebunden (Erweiterung der Funktionalität)
- Dot Sourcing wird durch einen vorangestellten Punkt mit Leerzeichen aktiviert
- Skripte können in andere eingebunden (include) werden.

```powershell
C:\Scripts> . .\BackupLogs.ps1
```

## 1.7. Parameter für Skripte

Beim Aufruf eines Skripts kann man Parameter genauso übergeben wie beim Aufruf von Commandlets, d.h. ohne Klammern und getrennt durch Leerzeichen:

```console
.\Skriptname.ps1 Parameter1 Parameter2 Parameter3 
```

Ein Skript kann Parameter auf zwei Weisen verarbeiten:

- Über die Variable `$args`, die ein Array (Liste) der Parameter enthält.
- Die Zählung beginnt bei **0**.
- Der erste Parameter steht in `$args[0]`, der zweite in `$args[1]`, der dritte in `$args[2]` usw.

Durch eine explizite Deklaration einer Parameterliste mit Zuweisung von Variablennamen und optional Datentypen.
`param($name1, $name2, $name3, usw.)`

### 1.7.1. Beispiel

Skript Aufruf:  `.\Get-ComputerInfo.ps1 E21`

```powershell
# Variante $args:

# Get-ComputerInfo
# Skript mit Parametern
"Informationen über den Computer: " + $args[0]


# Variante Parameterliste:

# Get-ComputerInfo
# Skript mit Parametern
param([string] $Computer)
"Informationen über den Computer: " + $Computer
```

---

## 1.8. Sicherheit

> PowerShell blockiert standardmässig Skripte, um Sicherheit zu gewährleisten.

```powershell
Set-ExecutionPolicy AllSigned       # Nur signierte Scripts werden ausgeführt
Set-ExecutionPolicy RemoteSigned    # Aus dem Internet heruntergeladene Scripts müssen signiert sein
Set-ExecutionPolicy Unrestricted    # Bevorzugt! Alle Scripts werden ausgeführt. Unsignierten Scripts aus dem Internet müssen bestätigt werden
Set-ExecutionPolicy Bypass          # Keinerlei Einschränkungen, Warnungen oder Prompts
Set-ExecutionPolicy Undefined       # Entfernt eine zugewiesene Richtlinie
```

**Beispiel:**

```powershell
Get-ExecutionPolicy   # Status prüfen
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass  # temporär erlauben (empfohlen für Schulungen!)
```

## Wichtige Skripteinstellungen

### set-psdebug - Debugfingfunktionen

```powershell
# set-psdebug aktiviert/deaktiviert Debuggingfunktionen
set-psdebug -off                  # Deaktiviert alle Skript-Debuggingfunktionen
set-psdebug -strict               # Fehler, wenn auf eine Variable verwiesen wird, bevor ihr ein Wert zugewiesen wurde
```

### set-strictmode - Codierungsregeln

```powershell
# set-strictmode falls Codierungsregeln gebrochen werden bricht der Skript ab
set-strictmode -off               # Deaktiviert Strict-Modus und set-psdebug -strict
set-strictmode -version latest    # Bevorzugt! Verhindert u.a. Verweise auf nicht initialisierte Variablen
#endregion
```

## 1.9. Vollständiges Demo-Skript

```powershell
<#
.SYNOPSIS
   Kopiert Dateien und schreibt ein Log.
#>

param(
    [Parameter(Mandatory)]
    [string]$Source,
    [string]$Destination = "C:\Archive",
    [switch]$Verbose
)

function Write-Log {
    param([string]$Message)

    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$ts - $Message" | Out-File ".\copy.log" -Append
}

Write-Verbose "Skript gestartet."

try {
    Write-Log "Suche Dateien in $Source"
    $files = Get-ChildItem -Path $Source -File -ErrorAction Stop

    foreach ($file in $files) {
        Write-Verbose "Kopiere $($file.Name)"
        Copy-Item $file.FullName -Destination $Destination -ErrorAction Stop
    }

    Write-Log "Fertig. Anzahl: $($files.Count)"
}
catch {
    Write-Log "FEHLER: $($_.Exception.Message)"
    exit 1
}

exit 0
```

---

</br>

# 2. Aufgaben

## 2.1. Alter Berechnung

| **Vorgabe**             | **Beschreibung**                                                                                  |
| :---------------------- | :------------------------------------------------------------------------------------------------ |
| **Lernziele**           | Sie können ein Skript auf Ihrem System ausführen                                                  |
|                         | Sie können ein Skript im Editor analysieren und ggf. bearbeiten                                   |
|                         | Sie sind in der Lage mit den Cmdlets Benutzereingaben einzulesen und berechnete Werte auszulesen. |
| **Sozialform**          | Einzelarbeit                                                                                      |
| **Auftrag**             | siehe unten                                                                                       |
| **Hilfsmittel**         |                                                                                                   |
| **Erwartete Resultate** |                                                                                                   |
| **Zeitbedarf**          | 15min                                                                                             |
| **Lösungselemente**     | Lauffähiger Skript                                                                                |

Schreiben Sie ein Skript welches Sie zur Eingabe des Geburtsdatums auffordert und danach Ihre Alter in Tage, Stunden, Minuten und Sekunden berechnet und in der Konsole ausgibt.
Gehen Sie dabei wie folgt vor:

- Finden und erforschen Sie mithilfe von Get-Help das geeignete Cmdlets um Daten von der Konsole einlesen und ausgeben zu können.
- Suchen Sie das Cmdlets um zwischen zwei Datumswerten die Differenz zu rechnen.

---

## 2.2. Systeminformationen

| **Vorgabe**             | **Beschreibung**                                                |
| :---------------------- | :-------------------------------------------------------------- |
| **Lernziele**           | Sie können ein Skript auf Ihrem System ausführen                |
|                         | Sie können ein Skript im Editor analysieren und ggf. bearbeiten |
|                         | Sie können die Ausführungsrichtlinie korrekt einstellen         |
| **Sozialform**          | Einzelarbeit                                                    |
| **Auftrag**             | siehe unten                                                     |
| **Hilfsmittel**         |                                                                 |
| **Erwartete Resultate** |                                                                 |
| **Zeitbedarf**          | 15min                                                           |
| **Lösungselemente**     | Lauffähiger Skript                                              |

Speichere den Beispielskriptdatei lokal auf der Festplatte und führen den Skript aus.
Prüfe die korrekte Funktionsweise des Skripts und kontrolliere die Skriptausgabe.

[Beispiel Script](./x_gitres/get-systeminformation.ps1)

```powershell
<#
  .SYNOPSIS
  Kurzbeschreibung
  .DESCRIPTION
  Ausführliche Beschreibung
  .PARAMETER <ParameterName-1>
  Beschreibung des ersten Parameters
  .PARAMETER <ParameterName-N>
  Beschreibung des n. Parameters
  .EXAMPLE
  Beispielanwendung und -erläuterung
  .EXAMPLE
  Weitere Beispielanwendung und -erläuterung
  .NOTES
  Weitere Hinweise
  .LINK
  Angabe von URLs oder ähnlichen Cmdlets
#> 
# Set-ExecutionPolicy -ExecutionPolicy Unrestricted
#### HTML Output Formatting #######
$a = "<style>"
$a = $a + "BODY{background-color:Lavender ;}"
$a = $a + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
$a = $a + "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:thistle}"
$a = $a + "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:PaleGoldenrod}"
$a = $a + "</style>"
################################################################################################
###### Global variables ####
$vUserName = (Get-Item env:\username).Value         ## This will get username using environment variable
$vComputerName = (Get-Item env:\Computername).Value     ## this is computer name using environment variable
$filepath = (Get-ChildItem env:\userprofile).value    ## this is user profile  using environment variable

ConvertTo-Html -Title "System Information for $vComputerName" -Body "<h1> Computer Name : $vComputerName </h1>" >  "$filepath\$vComputerName.html" 
################################################
#  Hardware Information
#################################################
ConvertTo-Html -Body "<H1>HARDWARE INFORMATION </H1>" >> "$filepath\$vComputerName.html"

Get-WmiObject win32_bios -ComputerName $vComputerName | 
  Select-Object Status,Version,PrimaryBIOS,Manufacturer,ReleaseDate,SerialNumber | 
  ConvertTo-html -Body "<H2> BIOS Information</H2>" >>  "$filepath\$vComputerName.html"
                      
Get-WmiObject win32_DiskDrive -ComputerName $vComputerName | 
  Select-Object Model,SerialNumber,Description,MediaType,FirmwareRevision |
  ConvertTo-html -Body "<H2> Physical DISK Drives </H2>" >>  "$filepath\$vComputerName.html"
get-WmiObject win32_networkadapter -ComputerName $vComputerName | 
  Select-Object Name,Manufacturer,Description ,AdapterType,Speed,MACAddress,NetConnectionID | 
  ConvertTo-html -Body "<H2> Network Adapters</H2>" >>  "$filepath\$vComputerName.html"
                      
################################################
#  OS Information
#################################################
ConvertTo-Html -Body "<H1>OS INFORMATION </H1>" >> "$filepath\$name.html" 
get-WmiObject win32_operatingsystem -ComputerName $vComputerName | 
  Select-Object Caption,Organization,InstallDate,OSArchitecture,Version,SerialNumber,BootDevice,WindowsDirectory,CountryCode | 
  ConvertTo-html -Body "<H2> Operating System Information</H2>" >>  "$filepath\$vComputerName.html"
                      
Get-WmiObject win32_logicalDisk -ComputerName $vComputerName | 
  Select-Object DeviceID,VolumeName,@{Expression={$_.Size /1Gb -as [int]};Label="Total Size(GB)"}, @{Expression={$_.Freespace / 1Gb -as [int]};Label="Free Size (GB)"} | 
  ConvertTo-html -Body "<H2> Logical DISK Drives </H2>" >>  "$filepath\$vComputerName.html"
                     
Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName $vComputerName |
    Select-Object Description, 
        DHCPServer, 
        @{Name='IpAddress';Expression={$_.IpAddress -join '; '}}, 
        @{Name='IpSubnet';Expression={$_.IpSubnet -join '; '}}, 
        @{Name='DefaultIPgateway';Expression={$_.DefaultIPgateway -join '; '}}, 
        @{Name='DNSServerSearchOrder';Expression={$_.DNSServerSearchOrder -join '; '}}, 
        WinsPrimaryServer, 
        WINSSecondaryServer | 
    ConvertTo-html -Body "<H2>IP Address </H2>" >>  "$filepath\$vComputerName.html"                      


################################################
#  OS Information
#################################################
ConvertTo-Html -Body "<H1>SOFTWARE INFORMATION </H1>" >> "$filepath\$vComputerName.html"
Get-WmiObject win32_startupCommand -ComputerName $vComputerName | 
  Select-Object Name,Location,Command,User,caption | 
  ConvertTo-html  -Body "<H2>Startup Softwares</H2>" >>  "$filepath\$vComputerName.html"
Get-WmiObject win32_process -ComputerName $vComputerName | 
  Select-Object Caption,ProcessId,@{Expression={$_.Vm /1mb -as [Int]};Label="VM (MB)"},@{Expression={$_.Ws /1Mb -as [Int]};Label="WS (MB)"} |
  Sort-Object "Vm (MB)" -Descending | 
  ConvertTo-html -Head $a -Body "<H2> Running Processes</H2>" >>  "$filepath\$vComputerName.html"
                     
Get-WmiObject win32_Service  | 
  Where-Object {$_.StartMode -eq "Auto" -and $_.State -eq "stopped"} |  
  Select-Object Name,StartMode,State | 
  ConvertTo-html  -Head $a -Body "<H2> Services </H2>" >>  "$filepath\$vComputerName.html"                     
                     
$Report = "The Report is generated On  $(get-date) by $((Get-Item env:\username).Value) on computer $((Get-Item env:\Computername).Value)"
$Report  >> "$filepath\$vComputerName.html" 
invoke-Expression "$filepath\$vComputerName.html"  
#################### END of SCRIPT ####################################
```

</br>

---

## 2.3. Skript erstellen - Pfad prüfen

| **Vorgabe**             | **Beschreibung**                                      |
| :---------------------- | :---------------------------------------------------- |
| **Lernziele**           | komplexe Abläufe nachvollziehbar grafisch darstellen. |
|                         | Ablaufdiagramm erstellen (Text und PAP)               |
| **Sozialform**          | Einzelarbeit                                          |
| **Hilfsmittel**         |                                                       |
| **Erwartete Resultate** |                                                       |
| **Zeitbedarf**          | 30 min                                                |
| **Lösungselemente**     | Programmablaufplan als draw.io Datei                  |

Erstelle einen Skript für:

- Eingabe eines Pfades
- Prüfung ob Pfad existiert
- Ausgabe "Pfad existiert" bzw. "Pfad existiert nicht"

---

</br>

## 2.4. Aufgabe - Log-Aufräumprozess

| **Vorgabe**             | **Beschreibung**                                                |
| :---------------------- | :-------------------------------------------------------------- |
| **Lernziele**           | Sie können ein Skript auf Ihrem System ausführen                |
|                         | Sie können ein Skript im Editor analysieren und ggf. bearbeiten |
|                         | Sie können die Ausführungsrichtlinie korrekt einstellen         |
| **Sozialform**          | Einzelarbeit                                                    |
| **Auftrag**             | siehe unten                                                     |
| **Hilfsmittel**         |                                                                 |
| **Erwartete Resultate** |                                                                 |
| **Zeitbedarf**          | 60 min                                                          |
| **Lösungselemente**     | Lauffähiger Skript                                              |

Implementiere den Ablauf aus Modul "Analyse u. Präsentation" als lineares Script:

Ein IT-Administrator möchte einen Log-Aufräumprozess automatisieren:

- Benutzer wählt:
  - Verzeichnis
  - Dateityp (z. B. *.log)
  - Alter der Dateien (in Tagen)

- Script
  - prüft Eingaben
  - listet betroffene Dateien auf
  - fragt nach Bestätigung
  - löscht Dateien
  - schreibt Log

Mindestanforderungen

- Benutzereingaben
- Validierung der Eingaben
- Dateifilter
- Sicherheitsabfrage vor Löschung

> **Noch ohne Funktionen, Fokus auf Ablauf!**
