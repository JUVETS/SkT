|                             |                          |                                 |
| --------------------------- | ------------------------ | ------------------------------- |
| **Techniker HF Informatik** | **Scripting / Big data** | ![Logo](./../x_gitres/logo.png) |

- [1. Startup‑Argumente beim PowerShell‑Aufruf](#1-startupargumente-beim-powershellaufruf)
  - [1.1. Lernziele](#11-lernziele)
  - [1.2. Was sind Startup‑Argumente?](#12-was-sind-startupargumente)
  - [1.3. $args – das schnelle, positionsbasierte Array](#13-args--das-schnelle-positionsbasierte-array)
    - [1.3.1. Vor- \& Nachteile](#131-vor---nachteile)
  - [1.4. param() – benannte, typisierte und dokumentierbare Parameter](#14-param--benannte-typisierte-und-dokumentierbare-parameter)
    - [1.4.1. Validierungen](#141-validierungen)
    - [1.4.2. Vorteile](#142-vorteile)
- [2. Aufgaben](#2-aufgaben)
  - [2.1. Skript mit Startup-Argumenten implementieren](#21-skript-mit-startup-argumenten-implementieren)

</br>

# 1. Startup‑Argumente beim PowerShell‑Aufruf

## 1.1. Lernziele

- **Startup‑Argumente** an ein Skript/Befehl übergeben und korrekt auslesen,
- den Unterschied zwischen `$args` (positionsbasiert) und param() (benannt/typisiert) verstehen,
- Quoting/Parsing von Argumenten (Leerzeichen, Sonderzeichen) sicher handhaben,
- Exitcodes und Pass‑Through von Argumenten an nachgelagerte Befehle korrekt nutzen,
- typische Fehlerquellen vermeiden (falsche Anführungszeichen, verborgene Typkonvertierung).

## 1.2. Was sind Startup‑Argumente?

Startup‑Argumente sind Werte, die beim Aufruf eines Skripts oder Befehls über die Kommandozeile mitgegeben werden.
In PowerShell gibt es zwei grundsätzliche Wege, diese im Skript zu empfangen:

- `$args` – ein Array ungemappt übergebener, positionsbasierter Argumente
- `param()` – ein Parameterblock mit benannten, typisierten Parametern (empfohlen)

Beide Verfahren können parallel existieren, aber im professionellen Skripting bevorzugt man `param()`.

## 1.3. $args – das schnelle, positionsbasierte Array

`$args` ist eine automatische Variable und enthält alle Argumente, die nicht an benannte Parameter gebunden wurden.

```powershell
# Script.ps1
"Anzahl Args: $($args.Count)"
"Arg[0]: $($args[0])"
"Arg[1]: $($args[1])"
```

```console
.\Script.ps1 Alpha Beta
```

**Ausgabe:**

```console
Anzahl Args: 2
Arg[0]: Alpha
Arg[1]: Beta
```

### 1.3.1. Vor- & Nachteile

**Vorteile:**

- sehr einfach, keine Deklaration nötig
- schnell für kurze Einweg-Skripte

**Nachteile:**

- keine Typprüfung
- keine Hilfe oder Autovervollständigung
- reihenfolgeabhängig und dadurch fehleranfällig
- nicht kompatibel mit `[CmdletBinding()]`

## 1.4. param() – benannte, typisierte und dokumentierbare Parameter

Die empfohlene Variante für alle produktiven Skripte.
Mit `param()` definierst du benannte Parameter, Default‑Werte, Typen und Validierungen.

**`[CmdletBinding()]`** – direkt über `param()` gesetzt – aktiviert den «Advanced Function»-Modus:

- ermöglicht `-Verbose`, `-Debug`, `-ErrorAction` und andere Common Parameters
- erzwingt sauberere Parameterverarbeitung
- Voraussetzung für Pipeline-Unterstützung in Funktionen

```powershell
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Source,

    [Parameter(Mandatory)]
    [string]$Destination,

    [int]$MaxItems = 100
)

"Quelle: $Source"
"Ziel:   $Destination"
"Max:    $MaxItems"
```

```console
.\Script.ps1 -Source "C:\Logs" -Destination "D:\Archive" -MaxItems 250
```

### 1.4.1. Validierungen

**Validierungen** schützen vor ungültigen Eingaben, bevor der Skriptcode ausgeführt wird:

```powershell
param(
    # Nur erlaubte Werte: ValidateSet
    [ValidateSet("Info", "Warning", "Error")]
    [string]$LogLevel = "Info",

    # Wertebereich: ValidateRange
    [ValidateRange(1, 365)]
    [int]$RetentionDays = 30,

    # Regulärer Ausdruck: ValidatePattern (z.B. IPv4-Adresse)
    [ValidatePattern('^\d{1,3}(\.\d{1,3}){3}$')]
    [string]$IpAddress,

    # Eigene Logik: ValidateScript
    [ValidateScript({ Test-Path $_ })]
    [string]$LogPath
)
```

### 1.4.2. Vorteile

- **benannt & selbstbeschreibend** – Aufruf unabhängig von der Reihenfolge
- **Typprüfung** – PS konvertiert oder bricht mit klarer Fehlermeldung ab
- **Validierungen** – `[ValidateSet()]`, `[ValidateRange()]`, `[ValidatePattern()]`, `[ValidateScript()]`
- **Hilfe & Autovervollständigung** – funktioniert mit `Get-Help` und IntelliSense in VS Code
- **Mandatory-Parameter** – PS fragt automatisch nach, wenn ein Pflichtparameter fehlt

> **Wichtig:** Pfade mit Leerzeichen immer in Anführungszeichen setzen:
> `.\Script.ps1 -Source "C:\Program Files\My App\logs"`

</br>

---

# 2. Aufgaben

## 2.1. Skript mit Startup-Argumenten implementieren

| **Vorgabe**             | **Beschreibung**                                                          |
| :---------------------- | :------------------------------------------------------------------------ |
| **Lernziele**           | Sie sind in der Lage ein Skript mit Kommandozeilenparameter aufzurufen    |
|                         | Sie können in der Skriptdatei Kommandozeilenparameter auslesen und prüfen |
| **Sozialform**          | Einzelarbeit                                                              |
| **Hilfsmittel**         |                                                                           |
| **Erwartete Resultate** |                                                                           |
| **Zeitbedarf**          | 30 min                                                                    |
| **Lösungselemente**     | PowerShell Datei mit sämtlichen Lösungen                                  |

- Erstellen Sie eine neue Skript Datei `StartArgs.ps1`.
- Beim Aufruf dieser Skript Datei müssen drei IP-Adressen übergeben werden, die im Skript eingelesen und ausgegeben werden.
- Prüfen Sie auch die Anzahl der übergebenen Parameter.

**Teil A – `$args`-Variante:**

Implementieren Sie die Lösung mit dem `$args`-Array.
Prüfen Sie manuell, ob genau 3 Argumente übergeben wurden, und geben Sie eine Fehlermeldung aus, falls nicht.

**Teil B – `param()`-Variante:**

Ersetzen Sie `$args` durch eine explizite Parameterdeklaration mit drei benannten Parametern (`$Ip1`, `$Ip2`, `$Ip3`).

**Teil C – Validierung (Erweiterung):**

Ergänzen Sie die `param()`-Variante um eine `[ValidatePattern()]`-Validierung, die sicherstellt, dass jeder Parameter eine gültige IPv4-Adresse enthält (Muster: `^\d{1,3}(\.\d{1,3}){3}$`).

**Beispielaufruf:**

```console
.\StartArgs.ps1 -Ip1 "192.168.1.1" -Ip2 "10.0.0.1" -Ip3 "172.16.0.1"
```

---

© 2026 Lukas Müller – Licensed under CC BY-NC-ND 4.0
See [LICENSE](../license.md) file for details.
