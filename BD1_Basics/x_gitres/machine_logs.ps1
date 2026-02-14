
# Musterlösung HF – PowerShell Big Data

$csv = Import-Csv "machine_logs.csv"

$errors = $csv | Where-Object { $_.status -eq "ERROR" }

$report = $errors | Group-Object machine | Select-Object Name, Count

$report | Export-Csv "error_report.csv" -NoTypeInformation

Write-Host "Analyse abgeschlossen"
