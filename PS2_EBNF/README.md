|                             |                          |                                 |
| --------------------------- | ------------------------ | ------------------------------- |
| **Techniker HF Informatik** | **Scripting / Big data** | ![Logo](./../x_gitres/logo.png) |

- [1. EBNF — Syntaxnotation verstehen](#1-ebnf--syntaxnotation-verstehen)
  - [1.1. Lernziele](#11-lernziele)
  - [1.2. Warum braucht es EBNF überhaupt?](#12-warum-braucht-es-ebnf-überhaupt)
  - [1.3. Die wichtigsten Symbole](#13-die-wichtigsten-symbole)
  - [1.4. Konkretes Beispiel: Cmdlet-Syntax in EBNF](#14-konkretes-beispiel-cmdlet-syntax-in-ebnf)
  - [1.5. Von EBNF zur offiziellen PowerShell-Syntaxdarstellung](#15-von-ebnf-zur-offiziellen-powershell-syntaxdarstellung)
  - [1.6. Brücke zu Get-Help](#16-brücke-zu-get-help)
- [2. Aufgaben](#2-aufgaben)
  - [2.1. EBNF lesen und auf PowerShell-Cmdlets anwenden](#21-ebnf-lesen-und-auf-powershell-cmdlets-anwenden)

---

</br>

# 1. EBNF — Syntaxnotation verstehen

## 1.1. Lernziele

Nach diesem Kapitel können Sie:

- [ ] erklären, wozu EBNF (Extended Backus-Naur Form) dient
- [ ] die wichtigsten EBNF-Symbole (`::=`, `|`, `[ ]`, `{ }`, `( )`, Anführungszeichen) korrekt deuten
- [ ] zwischen Terminal- und Nichtterminalsymbolen unterscheiden
- [ ] anhand einer gegebenen EBNF-Regel selbstständig beurteilen, ob ein konkreter PowerShell-Befehl syntaktisch gültig ist
- [ ] den Zusammenhang zwischen EBNF und der offiziellen PowerShell-Syntaxdarstellung in `Get-Help` herstellen

## 1.2. Warum braucht es EBNF überhaupt?

`Get-Process -Name "pwsh" -ComputerName "Server01"` — diese Anweisung ist syntaktisch korrekt. Aber woher weiss man das? Woher weiss man, dass `-Name` optional ist, `Get-Process` aber Pflicht, oder dass man mehrere Prozessnamen per Komma angeben darf?

**EBNF** ist eine formale Notation, um die **Grammatik** (also die erlaubte Syntax) einer Sprache **eindeutig und vollständig** zu beschreiben — egal ob Programmiersprache, SQL oder eben PowerShell-Befehle. Statt „meistens schreibt man das so ungefähr" gibt es damit eine exakte Regel ohne Interpretationsspielräume.

Genau deshalb beschreibt die offizielle PowerShell-Dokumentation (`Get-Help`) jeden Befehl mit einer formalen Syntaxdarstellung — wer diese Notation lesen kann, kann sich jede Cmdlet-Syntax **selbst** aus der Originalquelle erschliessen, ohne auf ein Tutorial angewiesen zu sein.

[WIKI – Erweiterte Backus-Naur-Form](https://de.wikipedia.org/wiki/Erweiterte_Backus-Naur-Form)

## 1.3. Die wichtigsten Symbole

| **Symbol**                  | **Bedeutung**                                                            | **Beispiel**               | **Heisst**                                                       |
| --------------------------- | ------------------------------------------------------------------------ | -------------------------- | ---------------------------------------------------------------- |
| `::=` (oder `=`)            | „ist definiert als"                                                      | `cmdlet ::= verb '-' noun` | Ein `cmdlet` besteht aus Verb, Bindestrich und Noun              |
| `\|`                        | Alternative (entweder/oder)                                              | `'ASC' \| 'DESC'`          | ASC **oder** DESC                                                |
| `[ ... ]`                   | optional (0 oder 1×)                                                     | `[ '-Verbose' ]`           | `-Verbose` darf weggelassen werden                               |
| `{ ... }`                   | Wiederholung (0 bis beliebig oft)                                        | `{ ',' prozessname }`      | beliebig viele weitere Prozessnamen, per Komma getrennt          |
| `( ... )`                   | Gruppierung                                                              | `( '-Asc' \| '-Desc' )`    | fasst die Alternative zu einer Einheit zusammen                  |
| `'...'` (Anführungszeichen) | **Terminal** = wörtlich genau so zu schreiben                            | `'Get-Process'`            | das Cmdlet muss exakt so geschrieben werden                      |
| *kursiv/Kleinbuchstaben*    | **Nichtterminal** = Platzhalter, wird an anderer Stelle weiter definiert | *prozessname*              | steht stellvertretend für einen beliebigen gültigen Prozessnamen |

**Merkregel:** Grossschrift/Anführungszeichen = das musst du **genau so abschreiben**. Kleinschrift = das ist ein **Platzhalter**, den du durch etwas Eigenes ersetzt.

## 1.4. Konkretes Beispiel: Cmdlet-Syntax in EBNF

Die Grundstruktur eines PowerShell-Befehls lässt sich so beschreiben:

```ebnf
befehl       ::= cmdlet { parameter }

cmdlet       ::= verb '-' noun

parameter    ::= '-' parametername [ argument ]

argument     ::= wert | { ',' wert }
```

Ein konkretes Cmdlet — `Get-Process` — lässt sich dann so formal beschreiben:

```ebnf
get_process  ::= 'Get-Process'
                 [ '-Name' prozessliste ]
                 [ '-Id' id { ',' id } ]
                 [ '-ComputerName' rechnerliste ]
                 [ '-Verbose' ]

prozessliste ::= prozessname { ',' prozessname }

rechnerliste ::= rechnername { ',' rechnername }
```

**Wie liest man das laut?**

- `'Get-Process'` → muss wörtlich dastehen
- `[ '-Name' prozessliste ]` → `-Name` ist optional (eckige Klammern); falls angegeben, folgt eine `prozessliste`
- `prozessliste ::= prozessname { ',' prozessname }` → mindestens ein Prozessname, danach beliebig viele weitere per Komma
- `[ '-ComputerName' rechnerliste ]` → ebenfalls optional; ohne Angabe läuft der Befehl lokal
- `[ '-Verbose' ]` → Schalter, kein Argument, einfach weglassbar

Damit lässt sich sofort ablesen:

```powershell
Get-Process                              # gültig – alles optional
Get-Process -Name "pwsh"                 # gültig
Get-Process -Name "pwsh", "explorer"     # gültig – prozessliste mit 2 Einträgen
Get-Process -Verbose                     # gültig
Get-Process pwsh -Name "explorer"        # ungültig – -Name doppelt belegt
```

Genau solche Fragen lassen sich mit EBNF **selbst beantworten**, statt sie einfach auszuprobieren.

## 1.5. Von EBNF zur offiziellen PowerShell-Syntaxdarstellung

`Get-Help` zeigt jeden Befehl in einer formalisierten Syntax, die direkt aus EBNF-Konzepten abgeleitet ist:

```powershell
Get-Help Get-Process -Full
```

```console
SYNTAX
    Get-Process [[-Name] <String[]>] [-ComputerName <String[]>]
                [-Module] [-FileVersionInfo] [-Verbose] [<CommonParameters>]

    Get-Process [-Id] <Int32[]> [-ComputerName <String[]>]
                [-Module] [-FileVersionInfo] [<CommonParameters>]
```

**Übersetzung der Darstellung:**

| **Get-Help-Schreibweise** | **EBNF-Entsprechung**  | **Bedeutung**                            |
| ------------------------- | ---------------------- | ---------------------------------------- |
| `[[-Name] <String[]>]`    | `[ '-Name' wert ]`     | Parameter und Argument beide optional    |
| `<String[]>`              | `wert { ',' wert }`    | Ein oder mehrere Strings (Array)         |
| `[-Verbose]`              | `[ '-Verbose' ]`       | Optionaler Schalter ohne Argument        |
| `[-Name] <String[]>`      | `'-Name' prozessliste` | Parametername optional, Wert ist Pflicht |
| Mehrere `SYNTAX`-Blöcke   | Alternativen mit `\|`  | Verschiedene Parametersets               |

## 1.6. Brücke zu Get-Help

Die Syntaxzeilen in `Get-Help` sind **dieselbe Information wie EBNF, nur in der PowerShell-eigenen Kurzschreibweise**. Wer EBNF lesen kann, kann auch `Get-Help -Full` direkt auswerten — und umgekehrt. Für jedes Cmdlet steht damit eine vollständige, offizielle Syntaxbeschreibung zur Verfügung:

```powershell
Get-Help Get-ChildItem  -Full      # Datei-/Verzeichnisbefehle
Get-Help Copy-Item      -Full      # Kopieren
Get-Help Where-Object   -Full      # Filtern in der Pipeline
Get-Help Get-Help       -Examples  # Hilfe zur Hilfe
```

---

# 2. Aufgaben

## 2.1. EBNF lesen und auf PowerShell-Cmdlets anwenden

| **Vorgabe**             | **Beschreibung**                                                                   |
| :---------------------- | :--------------------------------------------------------------------------------- |
| **Lernziele**           | EBNF-Notation lesen und auf konkrete PowerShell-Befehle anwenden                   |
| **Sozialform**          | Einzelarbeit                                                                       |
| **Auftrag**             | siehe unten                                                                        |
| **Hilfsmittel**         | `Get-Help`, offizielle Dokumentation (learn.microsoft.com)                         |
| **Erwartete Resultate** | Für jeden Befehl: «gültig»/«ungültig» mit Begründung anhand der EBNF-Regel         |
| **Zeitbedarf**          | 25 Minuten                                                                         |
| **Lösungselemente**     | Beurteilung aller 7 Befehle inkl. Begründung, plus eigene EBNF-Regel für Aufgabe 3 |

---

**Teil A – EBNF lesen:**

Gegeben ist folgende EBNF-Grammatik für `Get-ChildItem`:

```ebnf
get_childitem ::= 'Get-ChildItem'
                  [ '-Path' pfadliste ]
                  [ '-Filter' muster ]
                  [ '-Recurse' ]
                  [ '-File' | '-Directory' ]
                  [ '-Depth' zahl ]

pfadliste     ::= pfad { ',' pfad }
```

Beurteilen Sie für jeden der folgenden Befehle, ob er gemäss dieser Grammatik **gültig** oder **ungültig** ist, und begründen Sie Ihre Antwort mit Bezug auf die jeweilige EBNF-Regel:

1. `Get-ChildItem`
2. `Get-ChildItem -Path "C:\Logs" -Recurse`
3. `Get-ChildItem -Path "C:\Logs" -Filter "*.log" -Recurse`
4. `Get-ChildItem -File -Directory`
5. `Get-ChildItem -Recurse -Path`
6. `Get-ChildItem -Path "C:\Logs", "D:\Backup" -Filter "*.log"`
7. `Get-ChildItem -Path "C:\Logs" -Depth 2 -Recurse -File`

---

**Teil B – Get-Help auswerten:**

Rufen Sie die vollständige Hilfe zu `Get-Process` auf:

```powershell
Get-Help Get-Process -Full
```

Beantworten Sie anhand der `SYNTAX`-Sektion:

1. Welche Parameter sind Pflicht, welche optional?
2. Was bedeutet `<String[]>` in der Syntaxdarstellung?
3. Wieviele verschiedene Parametersets gibt es, und worin unterscheiden sie sich?
4. Welcher Parameter akzeptiert Eingabe aus der Pipeline (`ValueFromPipeline`)?

---

**Teil C (Bonus) – Eigene EBNF-Regel formulieren:**

Formulieren Sie selbst eine EBNF-Regel für das Cmdlet `Copy-Item` mit folgenden Anforderungen:

- Pflichtparameter: `-Path` und `-Destination`
- Optional: `-Recurse`, `-Force`, `-Verbose`
- `-Path` soll eine Liste von Pfaden akzeptieren (mindestens einer)

Vergleichen Sie anschliessend Ihre Regel mit der offiziellen Syntax:

```powershell
Get-Help Copy-Item -Full
```

---

© 2026 Lukas Müller – Licensed under CC BY-NC-ND 4.0
See [LICENSE](../license.md) file for details.
