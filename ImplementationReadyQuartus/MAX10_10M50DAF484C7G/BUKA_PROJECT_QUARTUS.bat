@echo off
setlocal
cd /d "%~dp0quartus"
if defined QUARTUS_ROOTDIR (
  start "" "%QUARTUS_ROOTDIR%\bin64\quartus.exe" "igor_max10.qpf"
) else if exist "D:\Quartus-Program\quartus\bin64\quartus.exe" (
  start "" "D:\Quartus-Program\quartus\bin64\quartus.exe" "igor_max10.qpf"
) else (
  start "" "igor_max10.qpf"
)
endlocal
