@echo off
call "%~dp0RUN_ALL_MOTOR_TESTS.bat" staged
exit /B %ERRORLEVEL%
