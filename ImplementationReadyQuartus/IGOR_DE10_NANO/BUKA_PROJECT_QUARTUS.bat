@echo off
setlocal
cd /d "%~dp0quartus"
set "QEXE=D:\Quartus-Program\quartus\bin64\quartus.exe"
if exist "%QEXE%" (
 start "" "%QEXE%" "igor.qpf"
) else (
 start "" "igor.qpf"
)
endlocal
