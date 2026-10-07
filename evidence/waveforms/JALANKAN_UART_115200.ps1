param([string]$RtlPackage=(Join-Path $PSScriptRoot '../IGOR_DE10_NANO'))
$ErrorActionPreference='Stop'
$RtlPackage=(Resolve-Path -LiteralPath $RtlPackage).Path
$Rtl=@(Get-ChildItem -LiteralPath (Join-Path $RtlPackage 'rtl') -Filter '*.v' | ForEach-Object FullName)
$Simulation=Join-Path $RtlPackage 'simulation'
$Mem=Join-Path $RtlPackage 'assets/neural_24_64_64_4/bram_unified_weights_padded.mem'
if(!(Test-Path -LiteralPath $Mem)){throw 'ROM asset missing; copy the full IGOR package'}
$Iverilog=(Get-Command iverilog.exe -ErrorAction SilentlyContinue).Source
$Vvp=(Get-Command vvp.exe -ErrorAction SilentlyContinue).Source
if(!$Iverilog){$Iverilog='C:\iverilog\bin\iverilog.exe'}
if(!$Vvp){$Vvp='C:\iverilog\bin\vvp.exe'}
$Executable=Join-Path $PSScriptRoot 'uart115200.out'
& $Iverilog -g2001 -s igor_uart_115200_tb -o $Executable @Rtl (Join-Path $PSScriptRoot 'igor_uart_115200_tb.v')
if($LASTEXITCODE -ne 0){throw 'Icarus compilation failed'}
Push-Location -LiteralPath $Simulation
try {
 $Log=Join-Path $PSScriptRoot 'uart115200.log'
 & $Vvp $Executable *> $Log
 $Code=$LASTEXITCODE
 $Text=Get-Content -LiteralPath $Log -Raw
 if($Code -ne 0 -or $Text -match 'TEST FAILED|ERROR:' -or $Text -notmatch 'CHECKS=5 ERRORS=0 RECEIVED=8'){throw 'UART release baud simulation failed'}
 Copy-Item -LiteralPath 'igor_uart_115200.vcd' -Destination (Join-Path $PSScriptRoot 'igor_uart_115200.vcd') -Force
 Get-Content -LiteralPath $Log
} finally {Pop-Location}
