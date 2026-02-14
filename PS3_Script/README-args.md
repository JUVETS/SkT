|                             |                               |                                 |
| --------------------------- | ----------------------------- | ------------------------------- |
| **Techniker HF Informatik** | **Kurs Scripting / Big data** | ![Logo](./../x_gitres/logo.png) |

- [1. Startup‑Argumente beim PowerShell‑Aufruf](#1-startupargumente-beim-powershellaufruf)
  - [1.1. Lernziele](#11-lernziele)
  - [1.2. Was sind Startup‑Argumente?](#12-was-sind-startupargumente)
  - [1.3. $args – das schnelle, positionsbasierte Array](#13-args--das-schnelle-positionsbasierte-array)
    - [1.3.1. Vor- \& Nachteile](#131-vor---nachteile)
  - [1.4. param() – benannte, typisierte und dokumentierbare Parameter](#14-param--benannte-typisierte-und-dokumentierbare-parameter)
    - [1.4.1. Vorteile](#141-vorteile)
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

- sehr einfach, keine Deklaration nötig
- keine Typprüfung, keine Hilfe/Autovervollständigung, Reihenfolge‑abhängig, fehleranfällig

## 1.4. param() – benannte, typisierte und dokumentierbare Parameter

- Die empfohlene Variante
- Mit`param()` (oder `[CmdletBinding()]`) definierst du benannte Parameter, Default‑Werte, Typen, Validierungen und erhältst Get‑Help‑Unterstützung.

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

### 1.4.1. Vorteile

- benannt & selbstbeschreibend
- Typprüfung & Validierungen ([ValidateSet()], [ValidateScript()], …)
- Hilfe & Autovervollständigung
- Reihenfolge egal (sofern eindeutig)

> Wichtig: Beim Aufruf musst du ggf. Anführungszeichen setzen: `.\Script.ps1 -Path "C:\Program Files\My App\logs"`

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
- Prüfen Sie auch die Anzahl die übergebenen Parameter.

- Implementieren Sie die Variante mit $args Array.
- Ändern Sie die Skript Datei durch die Variante mit einer expliziten Parameter Deklaration.
