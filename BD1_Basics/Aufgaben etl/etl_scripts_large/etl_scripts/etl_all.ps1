param(
  [string]$BasePath = ".\teaching_datasets_large",
  [string]$MongoUri = "mongodb://localhost:27017",
  [string]$DbName   = "hf_class",
  [switch]$Truncate
)

$root = $PSScriptRoot
. "$root/common.ps1"

Write-Log "== Gesamte ETL startet =="

& "$root/etl_orders.ps1" -BasePath $BasePath -MongoUri $MongoUri -DbName $DbName -Truncate:$Truncate
& "$root/etl_iot.ps1"    -BasePath $BasePath -MongoUri $MongoUri -DbName $DbName -Truncate:$Truncate
& "$root/etl_logs.ps1"   -BasePath $BasePath -MongoUri $MongoUri -DbName $DbName -Truncate:$Truncate
& "$root/etl_kpi.ps1"    -BasePath $BasePath -MongoUri $MongoUri -DbName $DbName

Write-Log "== Gesamte ETL abgeschlossen =="
