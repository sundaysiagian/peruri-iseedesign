param([Parameter(Mandatory=$true)][string]$QuartusBin)
$ErrorActionPreference='Stop'
$projectPath=Join-Path $PSScriptRoot 'quartus/stm_uart'
foreach($stage in @('map','fit','asm','sta')) {
    $toolPath=Join-Path $QuartusBin "quartus_$stage.exe"
    if(!(Test-Path -LiteralPath $toolPath)) { throw "Missing executable: $toolPath" }
    & $toolPath $projectPath
    if($LASTEXITCODE -ne 0) { throw "Quartus $stage failed with exit $LASTEXITCODE" }
}
Write-Output 'Build complete. Inspect timing reports before programming.'
