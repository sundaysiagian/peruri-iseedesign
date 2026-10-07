$ErrorActionPreference = 'Stop'
$taskDriverRoot = $PSScriptRoot
$taskPython = 'C:\Users\William Anthony\AppData\Local\Programs\Python\Python311\python.exe'
if (-not (Test-Path -LiteralPath $taskPython)) {
    throw 'Python 3.11 not found. Run raw_serial_test.py manually with your Python interpreter.'
}
Write-Host 'Live UART packets. The single beep is intentional, not an error code.' -ForegroundColor Cyan
Write-Host 'Forward/backward 1 RPS for 2 seconds each. Wheels must remain raised.' -ForegroundColor Yellow
& $taskPython (Join-Path $taskDriverRoot 'raw_serial_test.py') --run --wheels-raised --supply-on 2>&1 | Tee-Object -FilePath (Join-Path $taskDriverRoot 'logs\uart_live_console.log')
Write-Host 'Test finished. STOP sent. This window stays open for inspection.' -ForegroundColor Cyan
