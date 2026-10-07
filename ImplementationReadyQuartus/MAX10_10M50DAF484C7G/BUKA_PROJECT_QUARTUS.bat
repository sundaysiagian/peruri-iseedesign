@echo off
setlocal
cd /d "%~dp0quartus"
set "QEXE=D:\Quartus-Program\quartus\bin64\quartus.exe"
if exist "%QEXE%" (
 start "" "%QEXE%" "igor_max10.qpf"
) else (
 start "" "igor_max10.qpf"
)
endlocal
