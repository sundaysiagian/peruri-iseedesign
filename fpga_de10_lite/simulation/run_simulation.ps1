$ErrorActionPreference='Stop'
$Root=Split-Path $PSScriptRoot -Parent
$Rtl=@(Get-ChildItem (Join-Path $Root 'rtl/*.v') | ForEach-Object FullName)
Push-Location $PSScriptRoot
try {
 foreach ($Top in @('igor_units_tb','igor_top_tb','igor_neural_tb','igor_uart_tb','igor_uart_full_map_tb')) {
  & iverilog -g2001 -Wall -s $Top -o "$Top.out" @Rtl (Join-Path $Root "tb/$Top.v") *> "logs/$Top.compile.log"
  if ($LASTEXITCODE -ne 0) { throw "Compile failed: $Top" }
  & vvp "$Top.out" *> "logs/$Top.log"
  $SimExit=$LASTEXITCODE
  $Log=Get-Content "logs/$Top.log" -Raw
  if ($SimExit -ne 0 -or $Log -match 'TEST FAILED|FAIL time' -or $Log -notmatch 'TEST PASSED') { throw "Simulation failed: $Top" }
  Write-Output "$Top PASS"
 }
 Get-Content logs/igor_units_tb.log,logs/igor_top_tb.log,logs/igor_neural_tb.log,logs/igor_uart_tb.log,logs/igor_uart_full_map_tb.log | Set-Content ../evidence/simulation_log.txt
} finally { Pop-Location }

