nhalt des ZIP (Ordner teaching_datasets_large/):

shop_orders.json (~1000 Orders, sauber)
shop_orders_faulty.json (~100 fehlerhafte Orders, diverse Fehlerklassen)
iot_metrics.json (~2000 Messpunkte, sauber)
iot_metrics_faulty.json (~200 fehlerhafte Messpunkte)
iot_clean.json (aus den sauberen IoT‑Daten validiert)
access.log (~3000 Logzeilen, Apache‑ähnlich)
access_faulty.log (~300 absichtlich fehlerhafte Logzeilen)

Was ist enthalten (technische Details)
shop_orders.json

Felder: orderId, customerId, items[] (sku, qty, price), total, payment, ts
Zeitraum: 1 Woche simuliert
Zahlungen: creditcard, invoice, twint, paypal

shop_orders_faulty.json (Fehlerklassen)

Fehlende Pflichtfelder (orderId, total, ts)
Falsche Typen (orderId als String, total = "NaN")
Unplausible Werte (total negativ)
Falsche Datumsformate

iot_metrics.json

Felder: deviceId, type (temp|humidity|pressure), value, unit, battery, status, ts
Zeitreihe im Minutentakt, mehrere Geräte

iot_metrics_faulty.json (Fehlerklassen)

Fehlende Felder (deviceId, ts)
Ungültige Datums-/Zahlenformate
Unplausible Werte (z. B. pressure negativ)

iot_clean.json

Ergebnis einer grundsätzlichen Validierung (Pflichtfelder + ISO‑Timestamp)

access.log

Apache‑ähnliches Format:
192.168.1.10 - - [14/Sep/2025:10:21:15 +0200] "GET /index.html HTTP/1.1" 200 1043


Methoden: GET, POST; Pfade: /, /index.html, /products, /api/order, …
Statusmix: 2xx/3xx/4xx/5xx

access_faulty.log (Fehlerklassen)

Komplett invalide Zeilen
Falsche IPs
Unbekannte Methoden / Statuscodes
Ungültige Größenangaben


Nächste Schritte (optional)
Wenn du möchtest, kann ich dir gleich dazu bereitstellen:

PowerShell‑ETL‑Skripte (angepasst an die großen Dateien), inklusive:

Validierung + Zusammenfassung (Counts clean/failed)
mongoimport/Mdbc‑Import
KPI‑Aggregation & Export (JSON/CSV)


Index‑Playbook für logs, orders, iot (inkl. Mess‑Skript für Laufzeiten).
Auto‑Runner (Task Scheduler Vorlage) für wiederkehrende Läufe.
Zusätzliche „Stress“-Datensätze (z. B. 10k–50k Zeilen) für Performance‑Sessions.

Sag mir einfach, ob ich die ETL‑Skripte für diese großen Dateien direkt miterzeugen soll (ich passe sie auf die Dateinamen in teaching_datasets_large/ an).


ETL-Skripte

Inhalt der ETL‑Skripte
Im ZIP findest du den Ordner etl_scripts/ mit:

common.ps1 – gemeinsame Helfer (Logging, JSON lesen/schreiben, Mdbc‑Check)
etl_orders.ps1 – Validierung & Import für shop_orders.json + shop_orders_faulty.json
→ erzeugt orders_clean.json / orders_failed.json und importiert in orders (mit _id = orderId für Idempotenz)
etl_iot.ps1 – Validierung & Import für iot_metrics.json + iot_metrics_faulty.json
→ erzeugt/überschreibt iot_clean.json, legt Indexe { ts:1 } mit TTL (30 Tage) und { deviceId:1, ts:-1 } an
etl_logs.ps1 – Parsing & Import für access.log + access_faulty.log
→ Regex‑Parsing, IPv4‑Prüfung, Timezone‑Parsing, erzeugt logs_clean.json / logs_failed.log, legt Indexe { ts:1 }, { path:1 }, { status:1, ts:-1 } an
etl_kpi.ps1 – KPIs exportieren (JSON)

kpi_top_urls.json (Top 10 URLs)
kpi_error_rate_by_minute.json (Fehlerrate)
kpi_iot_warnings.json (Warnungen pro Sensor)
kpi_orders_by_payment.json (Bestellungen pro Zahlungsmethode)


etl_all.ps1 – Orchestriert die vier Schritte in Folge

Alle Skripte basieren auf Mdbc (PowerShell‑Modul für MongoDB) und prüfen dessen Verfügbarkeit.

Schnellstart

ZIPs entpacken (am besten in denselben Ordner):

teaching_datasets_large/
etl_scripts/

PowerShell öffnen und in den Ordner der Skripte wechseln:

cd .\etl_scripts

Gesamte ETL ausführen (inkl. Leeren der Collections):

.\etl_all.ps1 -BasePath ..\teaching_datasets_large `
              -MongoUri "mongodb://localhost:27017" `
              -DbName hf_class `
              -Truncate

Ergebnisdateien findest du im BasePath (teaching_datasets_large/):

orders_clean.json, orders_failed.json
iot_clean.json, iot_failed.json
logs_clean.json, logs_failed.log
KPIs: kpi_top_urls.json, kpi_error_rate_by_minute.json, kpi_iot_warnings.json, kpi_orders_by_payment.json

Was die Skripte genau machen (Kurzüberblick)

Orders: Prüfen Pflichtfelder & Typen (orderId, total, ts, items[]), _id = orderId für idempotenten Import.
IoT: Validieren deviceId, type, ts, numerische Felder, erzeugen iot_clean.json, TTL‑Index für zeitbasierte Datenhaltung.
Logs: Regex‑Parsing des Apache‑ähnlichen Formats, IPv4‑Check, Status‑Range, Bytes≥0, Trennung in clean/failed.
KPIs: Aggregationen via Invoke-MdbcAggregate, Export als JSON.


Einzelne Pipelines:

.\etl_logs.ps1   -BasePath ..\teaching_datasets_large -MongoUri "mongodb://localhost:27017" -DbName hf_class -Truncate
.\etl_orders.ps1 -BasePath ..\teaching_datasets_large -MongoUri "mongodb://localhost:27017" -DbName hf_class -Truncate
.\etl_iot.ps1    -BasePath ..\teaching_datasets_large -MongoUri "mongodb://localhost:27017" -DbName hf_class -Truncate
.\etl_kpi.ps1    -BasePath ..\teaching_datasets_large -MongoUri "mongodb://localhost:27017" -DbName hf_class
