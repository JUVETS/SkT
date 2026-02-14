param(
  [string]$BasePath = ".\teaching_datasets_large",
  [string]$MongoUri = "mongodb://localhost:27017",
  [string]$DbName   = "hf_class",
  [switch]$Truncate
)

. "$PSScriptRoot/common.ps1"

Write-Log "Starte Orders-ETL"
Ensure-Mdbc

$srcGood  = Join-Path $BasePath 'shop_orders.json'
$srcBad   = Join-Path $BasePath 'shop_orders_faulty.json'
$outClean = Join-Path $BasePath 'orders_clean.json'
$outFail  = Join-Path $BasePath 'orders_failed.json'

function Test-Order($o){
  $ok = $true
  if (-not $o.orderId -or -not ($o.orderId -is [int] -or $o.orderId -as [int])) { $ok=$false }
  if (-not $o.customerId) { $ok=$false }
  if (-not $o.total -or -not ($o.total -is [double] -or $o.total -as [double])) { $ok=$false }
  if (-not $o.ts) { $ok=$false } else { try { [datetime]::Parse($o.ts) | Out-Null } catch { $ok=$false } }
  if (-not $o.items -or -not ($o.items -is [System.Collections.IEnumerable])) { $ok=$false } else {
    foreach($it in $o.items){ if (-not $it.sku -or -not ($it.qty -as [int]) -or -not ($it.price -as [double])) { $ok=$false; break } }
  }
  return $ok
}

$all = @()
try { $all += (Read-JsonArray $srcGood) } catch { Write-Log "Warnung: $srcGood nicht lesbar: $($_.Exception.Message)" 'WARN' }
try { $all += (Read-JsonArray $srcBad)  } catch { Write-Log "Warnung: $srcBad nicht lesbar: $($_.Exception.Message)" 'WARN' }

$clean = New-Object System.Collections.Generic.List[object]
$fail  = New-Object System.Collections.Generic.List[object]

foreach($o in $all){
  if (Test-Order $o){
    # _id setzen für Idempotenz
    if (-not $o._id) { $o | Add-Member -NotePropertyName _id -NotePropertyValue $o.orderId }
    $clean.Add($o)
  } else {
    $fail.Add($o)
  }
}

Save-Json $clean $outClean
Save-Json $fail  $outFail
Write-Log "Orders valid: $($clean.Count), failed: $($fail.Count)"

# Import
Connect-Mdbc -ConnectionString $MongoUri -Database $DbName -Collection orders
if ($Truncate) { Write-Log "Leere Collection orders"; Remove-MdbcData -All }
if ($clean.Count -gt 0) { Add-MdbcData $clean }
Write-Log "Orders-ETL abgeschlossen"
