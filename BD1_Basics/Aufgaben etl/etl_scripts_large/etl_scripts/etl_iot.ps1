param(
  [string]$BasePath = ".\teaching_datasets_large",
  [string]$MongoUri = "mongodb://localhost:27017",
  [string]$DbName   = "hf_class",
  [switch]$Truncate,
  [int]$TtlDays = 30
)

. "$PSScriptRoot/common.ps1"

Write-Log "Starte IoT-ETL"
Ensure-Mdbc

$srcGood = Join-Path $BasePath 'iot_metrics.json'
$srcBad  = Join-Path $BasePath 'iot_metrics_faulty.json'
$outClean = Join-Path $BasePath 'iot_clean.json'
$outFail  = Join-Path $BasePath 'iot_failed.json'

$allowedTypes = @('temp','humidity','pressure')

function Test-Iot($x){
  if (-not ($x -is [hashtable] -or $x.PSObject)) { return $false }
  if (-not $x.deviceId) { return $false }
  if (-not $x.type -or $x.type -notin $allowedTypes) { return $false }
  if (-not $x.ts) { return $false } else { try { [datetime]::Parse($x.ts) | Out-Null } catch { return $false } }
  if ($x.battery -and (-not ($x.battery -as [int]))) { return $false }
  if ($x.value -and (-not ($x.value -as [double] -or $x.value -as [int]))) { return $false }
  return $true
}

$good = @(); $bad = @()
try { $good = Read-JsonArray $srcGood } catch { Write-Log "Warnung: $srcGood nicht lesbar" 'WARN' }
try { $bad  = Read-JsonArray $srcBad  } catch { Write-Log "Warnung: $srcBad nicht lesbar" 'WARN' }
$all = @($good + $bad)

$clean = New-Object System.Collections.Generic.List[object]
$fail  = New-Object System.Collections.Generic.List[object]
foreach($x in $all){ if (Test-Iot $x) { $clean.Add($x) } else { $fail.Add($x) } }

Save-Json $clean $outClean
Save-Json $fail  $outFail
Write-Log "IoT valid: $($clean.Count), failed: $($fail.Count)"

# Import & Indexe
Connect-Mdbc -ConnectionString $MongoUri -Database $DbName -Collection iot
if ($Truncate) { Write-Log "Leere Collection iot"; Remove-MdbcData -All }
if ($clean.Count -gt 0) { Add-MdbcData $clean }

$seconds = 60*60*24*$TtlDays
try { Add-MdbcIndex @{ ts = 1 } -ExpireAfterSeconds $seconds } catch { Write-Log "TTL-Index bereits vorhanden oder Fehler: $($_.Exception.Message)" 'WARN' }
try { Add-MdbcIndex @{ deviceId = 1; ts = -1 } } catch { Write-Log "Index bereits vorhanden oder Fehler: $($_.Exception.Message)" 'WARN' }

Write-Log "IoT-ETL abgeschlossen"
