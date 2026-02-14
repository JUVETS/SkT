
# Analyze sensor big data
$data = Import-Csv sensordaten.csv

$errors = $data | Where-Object { $_.Status -eq 'ERROR' }

$stats = $errors | Group-Object Machine | Select-Object Name, Count

$stats | Export-Csv error_stats.csv -NoTypeInformation
