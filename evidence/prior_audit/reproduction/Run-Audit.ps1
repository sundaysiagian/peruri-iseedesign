param([string]$IcarusBin = 'C:/iverilog/bin')
$ErrorActionPreference='Stop'
$auditRtl=@(Get-ChildItem (Join-Path $PSScriptRoot 'rtl/*.v') | ForEach-Object FullName)
Push-Location (Join-Path $PSScriptRoot 'simulation')
try {
 foreach ($auditTop in @('igor_top_tb','igor_uart_full_map_tb')) {
  & (Join-Path $IcarusBin 'iverilog.exe') -g2012 -s $auditTop -o "$auditTop.out" @auditRtl (Join-Path $PSScriptRoot "tb/$auditTop.v")
  if ($LASTEXITCODE -ne 0) { throw "Compile failed $auditTop" }
  & (Join-Path $IcarusBin 'vvp.exe') "$auditTop.out" *> "$auditTop.log"
  $auditText=Get-Content "$auditTop.log" -Raw
  if ($LASTEXITCODE -ne 0 -or $auditText -match 'FAIL|ERRORS=[1-9]' -or $auditText -notmatch 'TEST PASSED') { throw "Test failed $auditTop" }
  Write-Output "$auditTop PASS"
 }
} finally { Pop-Location }
