@echo off
cd /d "%~dp0"
py -m pip install -r host\requirements.txt
if errorlevel 1 (echo Install Python 3 with pip first. & pause & exit /b 1)
echo UART dependencies ready. Run BUKA_UART.bat
pause
