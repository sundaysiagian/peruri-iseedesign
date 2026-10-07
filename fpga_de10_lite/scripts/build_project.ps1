param([string]$QuartusRoot='D:\Quartus-Program\quartus')
$ErrorActionPreference='Stop'
$Root=Split-Path $PSScriptRoot -Parent
$OldRoot=$env:QUARTUS_ROOTDIR
$env:QUARTUS_ROOTDIR=$QuartusRoot
Push-Location (Join-Path $Root 'quartus')
try {
 foreach($Stage in @('map','fit','asm','sta')) {
  $Tool=Join-Path $QuartusRoot "bin64\quartus_$Stage.exe"
  if(!(Test-Path $Tool)){throw "Missing $Tool"}
  $Process=Start-Process -FilePath $Tool -ArgumentList @('igor_max10') -NoNewWindow -Wait -PassThru -RedirectStandardOutput "../evidence/quartus_$Stage.log" -RedirectStandardError "../evidence/quartus_$Stage.stderr.log"
  $Code=$Process.ExitCode
  Get-Content "../evidence/quartus_$Stage.log" -Tail 12
  if($Code -ne 0){throw "Quartus $Stage failed: $Code"}
 }
 $Process=Start-Process -FilePath (Join-Path $QuartusRoot 'bin64\quartus_sta.exe') -ArgumentList @('-t','report_timing.tcl') -NoNewWindow -Wait -PassThru -RedirectStandardOutput ../evidence/timing_command_log.txt -RedirectStandardError ../evidence/timing_command_stderr.txt
 if($Process.ExitCode -ne 0){throw 'Timing report generation failed'}
 if(!(Test-Path output_files/igor_max10.sof)){throw 'SOF missing'}
 $StaSummary=Get-Content output_files/igor_max10.sta.summary -Raw
 if($StaSummary -match 'Slack\s*:\s*-'){throw 'Timing failed: negative slack in STA summary; do not release SOF'}
 $StaLog=Get-Content ../evidence/quartus_sta.log -Raw
 if($StaLog -match 'Critical Warning|Timing requirements not met'){throw 'Timing critical warning; do not release SOF'}
 Get-FileHash output_files/igor_max10.sof -Algorithm SHA256
} finally {Pop-Location; $env:QUARTUS_ROOTDIR=$OldRoot}

