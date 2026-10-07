@echo off
setlocal
cd /d "%~dp0quartus"
if defined QUARTUS_ROOTDIR (
  start "" "%QUARTUS_ROOTDIR%\bin64\quartus.exe" "igor.qpf"
) else if exist "D:\Quartus-Program\quartus\bin64\quartus.exe" (
  start "" "D:\Quartus-Program\quartus\bin64\quartus.exe" "igor.qpf"
) else (
  start "" "igor.qpf"
)
endlocal
