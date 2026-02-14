param(
  [string]$BasePath = ".\teaching_datasets_large",
  [string]$MongoUri = "mongodb://localhost:27017",
  [string]$DbName   = "hf_class",
  [switch]$Truncate
)

. "$PSScriptRoot/common.ps1"

Write-Log "Starte Logs-ETL"
Ensure-Mdbc

$srcLogs  = Join-Path $BasePath 'access.log'
$srcBad   = Join-Path $BasePath 'access_faulty.log'
$outClean = Join-Path $BasePath 'logs_clean.json'
$outFail  = Join-Path $BasePath 'logs_failed.log'

$pattern = '^(?<ip>\S+) \S+ \S+ \[(?<ts>[^\]]+)\] "(?<method>\S+) (?<path>\S+) \S+" (?<status>\d{3}) (?<bytes>\d+|-)'

function Test-IPv4($ip){
  try {
    $addr=[System.Net.IPAddress]::Parse($ip)
    return $addr.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork
  } catch { return $false }
}

$clean = New-Object System.Collections.Generic.List[object]
$fail  = New-Object System.Collections.Generic.List[string]

Get-Content $srcLogs, $srcBad | ForEach-Object {
  $line = $_
  if ($line -match $pattern) {
    $ip=$Matches.ip; $rawts=$Matches.ts; $method=$Matches.method; $path=$Matches.path; $status=[int]$Matches.status; $bytes=$Matches.bytes
    if ($bytes -eq '-') { $bytes = 0 } else { $bytes = [int]$bytes }
    try { $ts=[datetime]::ParseExact($rawts,'dd/MMM/yyyy:HH:mm:ss zzz',[Globalization.CultureInfo]::InvariantCulture) } catch { $ts=$null }
    $ok = ($ts -ne $null) -and (Test-IPv4 $ip) -and ($method -in @('GET','POST')) -and ($status -ge 100 -and $status -le 599) -and ($bytes -ge 0)
    if ($ok) {
      $clean.Add([pscustomobject]@{ ip=$ip; ts=$ts.ToUniversalTime(); method=$method; path=$path; status=$status; bytes=$bytes })
    } else { $fail.Add($line) }
  } else { $fail.Add($line) }
}

Save-Json $clean $outClean
$fail | Set-Content -Path $outFail -Encoding UTF8
Write-Log "Logs valid: $($clean.Count), failed lines: $($fail.Count)"

Connect-Mdbc -ConnectionString $MongoUri -Database $DbName -Collection logs
if ($Truncate) { Write-Log "Leere Collection logs"; Remove-MdbcData -All }
if ($clean.Count -gt 0) { Add-MdbcData $clean }

# Indexe
try { Add-MdbcIndex @{ ts = 1 } } catch { }
try { Add-MdbcIndex @{ path = 1 } } catch { }
try { Add-MdbcIndex @{ status = 1; ts = -1 } } catch { }

Write-Log "Logs-ETL abgeschlossen"
