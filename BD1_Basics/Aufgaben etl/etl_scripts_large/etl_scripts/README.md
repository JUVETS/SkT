# ETL Scripts (PowerShell + Mdbc) for teaching_datasets_large

## Prerequisites
- PowerShell 7
- MongoDB running locally (mongodb://localhost:27017)
- Database: `hf_class`
- Module Mdbc installed
  ```powershell
  Install-Module Mdbc -Scope CurrentUser
  Import-Module Mdbc
  ```

## Files
- `common.ps1` – shared helpers
- `etl_orders.ps1` – validate & import Orders
- `etl_iot.ps1` – validate & import IoT metrics (+ indexes)
- `etl_logs.ps1` – parse & import Web logs (+ indexes)
- `etl_kpi.ps1` – compute KPIs and export JSON reports
- `etl_all.ps1` – orchestrates all steps in sequence

## Usage
Extract `teaching_datasets_large.zip` and place these scripts next to the folder, or pass `-BasePath`.

Run everything (truncate collections first):
```powershell
./etl_scripts/etl_all.ps1 -BasePath ./teaching_datasets_large -MongoUri "mongodb://localhost:27017" -DbName hf_class -Truncate
```

Run single pipeline:
```powershell
./etl_scripts/etl_logs.ps1 -BasePath ./teaching_datasets_large -MongoUri "mongodb://localhost:27017" -DbName hf_class -Truncate
```

Outputs (saved into BasePath):
- `orders_clean.json`, `orders_failed.json`
- `iot_clean.json`, `iot_failed.json`
- `logs_clean.json`, `logs_failed.log`
- KPI JSONs: `kpi_top_urls.json`, `kpi_error_rate_by_minute.json`, `kpi_iot_warnings.json`, `kpi_orders_by_payment.json`
