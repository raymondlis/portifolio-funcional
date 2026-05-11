param(
  [string]$Output = "data/prices_2025_h2_real.csv",
  [string]$StartDate = "2025-07-01",
  [string]$EndDate = "2025-12-31"
)

$ErrorActionPreference = "Stop"

$tickers = @(
  "AAPL", "AMGN", "AMZN", "AXP", "BA", "CAT", "CRM", "CSCO", "CVX", "DIS",
  "GS", "HD", "HON", "IBM", "JNJ", "JPM", "KO", "MCD", "MMM", "MRK",
  "MSFT", "NKE", "NVDA", "PG", "SHW", "TRV", "UNH", "V", "VZ", "WMT"
)

$start = [datetime]::ParseExact($StartDate, "yyyy-MM-dd", $null)
$end = [datetime]::ParseExact($EndDate, "yyyy-MM-dd", $null)
$pricesByTicker = @{}

foreach ($ticker in $tickers) {
  $uri = "https://www.pocketportfolio.app/api/tickers/$ticker/json"
  Write-Host "Fetching $ticker from $uri"
  $response = Invoke-RestMethod -Uri $uri

  $byDate = @{}
  foreach ($row in $response.data) {
    $date = [datetime]::ParseExact($row.date, "yyyy-MM-dd", $null)
    if ($date -ge $start -and $date -le $end -and $null -ne $row.close) {
      $byDate[$row.date] = [double]$row.close
    }
  }

  if ($byDate.Count -eq 0) {
    throw "No rows returned for $ticker between $StartDate and $EndDate"
  }

  $pricesByTicker[$ticker] = $byDate
}

$commonDates = @($pricesByTicker[$tickers[0]].Keys)
foreach ($ticker in $tickers[1..($tickers.Count - 1)]) {
  $dates = $pricesByTicker[$ticker].Keys
  $commonDates = @($commonDates | Where-Object { $dates -contains $_ })
}
$commonDates = @($commonDates | Sort-Object)

if ($commonDates.Count -eq 0) {
  throw "No common dates found for all tickers"
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add(("Date," + ($tickers -join ",")))

foreach ($date in $commonDates) {
  $values = foreach ($ticker in $tickers) {
    $pricesByTicker[$ticker][$date].ToString("0.########", [Globalization.CultureInfo]::InvariantCulture)
  }
  $lines.Add(($date + "," + ($values -join ",")))
}

$outputPath = Join-Path (Get-Location) $Output
$outputDir = Split-Path -Parent $outputPath
if ($outputDir -and -not (Test-Path $outputDir)) {
  New-Item -ItemType Directory -Force $outputDir | Out-Null
}

$utf8NoBom = New-Object Text.UTF8Encoding $false
[IO.File]::WriteAllLines($outputPath, $lines, $utf8NoBom)
Write-Host "Wrote $($commonDates.Count) rows to $Output"
