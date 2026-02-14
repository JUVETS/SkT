# Common helper functions for ETL scripts
param()

function Write-Log {
  param([string]$Message,[string]$Level='INFO')
  $ts = (Get-Date).ToString('s')
  Write-Host "[$ts][$Level] $Message"
}

function Ensure-Mdbc {
  if (-not (Get-Module -ListAvailable -Name Mdbc)) {
    throw "Mdbc-Modul nicht gefunden. Bitte ausführen: Install-Module Mdbc -Scope CurrentUser; Import-Module Mdbc"
  }
  Import-Module Mdbc -ErrorAction Stop
}

function Save-Json {
  param($Object,[string]$Path)
  $Object | ConvertTo-Json -Depth 20 | Set-Content -Path $Path -Encoding UTF8
}

function Read-JsonArray {
  param([string]$Path)
  if (-not (Test-Path $Path)) { throw "Datei nicht gefunden: $Path" }
  return (Get-Content $Path -Raw | ConvertFrom-Json)
}
