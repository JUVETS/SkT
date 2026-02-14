param(
  [string]$MongoUri = "mongodb://localhost:27017",
  [string]$DbName   = "hf_class",
  [string]$BasePath = ".\teaching_datasets_large"
)

. "$PSScriptRoot/common.ps1"
Ensure-Mdbc

Connect-Mdbc -ConnectionString $MongoUri -Database $DbName -Collection logs | Out-Null

Write-Log "Berechne KPIs (logs)"
$topUrls = Invoke-MdbcAggregate @(
  @{ '$group' = @{ _id='$path'; hits=@{ '$sum'=1 } } },
  @{ '$sort'  = @{ hits=-1 } },
  @{ '$limit' = 10 }
)
Save-Json $topUrls (Join-Path $BasePath 'kpi_top_urls.json')

$errorRate = Invoke-MdbcAggregate @(
  @{ '$group' = @{
        _id=@{ '$dateTrunc'=@{ date='$ts'; unit='minute' } }
        total=@{ '$sum'=1 }
        errors=@{ '$sum'=@{ '$cond'=@(@{ '$gte'=@('$status',500) },1,0) } }
  }},
  @{ '$project' = @{
        time='$_id'; total=1; errors=1
        errorRatePct=@{ '$round'=@(@{ '$multiply'=@(@{ '$divide'=@('$errors','$total') },100) },2) }
        _id=0
  }},
  @{ '$sort' = @{ time=1 } }
)
Save-Json $errorRate (Join-Path $BasePath 'kpi_error_rate_by_minute.json')

# KPIs IoT
Connect-Mdbc -ConnectionString $MongoUri -Database $DbName -Collection iot | Out-Null
Write-Log "Berechne KPIs (iot)"
$warnings = Invoke-MdbcAggregate @(
  @{ '$match' = @{ status = 'warning' } },
  @{ '$group' = @{ _id='$deviceId'; warnings=@{ '$sum'=1 } } },
  @{ '$sort'  = @{ warnings=-1 } }
)
Save-Json $warnings (Join-Path $BasePath 'kpi_iot_warnings.json')

# KPIs Orders
Connect-Mdbc -ConnectionString $MongoUri -Database $DbName -Collection orders | Out-Null
Write-Log "Berechne KPIs (orders)"
$byPay = Invoke-MdbcAggregate @(
  @{ '$group' = @{ _id='$payment'; count=@{ '$sum'=1 } } },
  @{ '$sort'  = @{ count=-1 } }
)
Save-Json $byPay (Join-Path $BasePath 'kpi_orders_by_payment.json')

Write-Log "KPI-Berechnung abgeschlossen"
