@echo off
cd /d "%~dp0"
py host\uart_monitor.py
if errorlevel 1 pause
