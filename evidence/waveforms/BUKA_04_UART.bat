@echo off
cd /d "%~dp0\..\.."
python scripts\unpack_waveforms.py
echo Use docs\QUICKSTART.md for the portable GTKWave commands.
pause
