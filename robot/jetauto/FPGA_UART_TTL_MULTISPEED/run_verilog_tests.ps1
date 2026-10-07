param(
    [string]$Iverilog = 'C:\iverilog\bin\iverilog.exe',
    [string]$Vvp = 'C:\iverilog\bin\vvp.exe'
)
$ErrorActionPreference = 'Stop'
Push-Location -LiteralPath $PSScriptRoot
try {
    New-Item -ItemType Directory -Force -Path 'build', 'evidence' | Out-Null
    & $Iverilog -g2012 -Wall -s tb_multispeed -o 'build\multispeed.vvp' 'rtl\stm_packet_tx_multispeed.v' 'tb\tb_multispeed.v'
    if ($LASTEXITCODE -ne 0) { throw 'Packet testbench compilation failed' }
    & $Vvp 'build\multispeed.vvp' | Tee-Object -FilePath 'evidence\multispeed_test.log'
    if ($LASTEXITCODE -ne 0) { throw 'Packet testbench failed' }
    & $Iverilog -g2012 -Wall -s tb_multispeed_control -o 'build\multispeed_control.vvp' 'rtl\stm_packet_tx_multispeed.v' 'rtl\stm_uart_multispeed_top.v' 'tb\tb_multispeed_control.v'
    if ($LASTEXITCODE -ne 0) { throw 'Controller testbench compilation failed' }
    & $Vvp 'build\multispeed_control.vvp' | Tee-Object -FilePath 'evidence\multispeed_control_test.log'
    if ($LASTEXITCODE -ne 0) { throw 'Controller testbench failed' }
}
finally { Pop-Location }
