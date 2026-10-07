param([string]$QuartusBin = 'D:\Quartus-Program\quartus\bin64')
$ErrorActionPreference = 'Stop'
Push-Location -LiteralPath $PSScriptRoot
try {
    New-Item -ItemType Directory -Force -Path 'evidence' | Out-Null
    foreach ($phase in @('map', 'fit', 'asm', 'sta')) {
        $tool = Join-Path -Path $QuartusBin -ChildPath ('quartus_' + $phase + '.exe')
        & $tool 'quartus\stm_uart_multispeed' *> ('evidence\quartus_' + $phase + '.log')
        if ($LASTEXITCODE -ne 0) { throw ('Quartus failed in ' + $phase + '. Read evidence log.') }
        Write-Output ('PASS: Quartus ' + $phase)
    }
}
finally { Pop-Location }
