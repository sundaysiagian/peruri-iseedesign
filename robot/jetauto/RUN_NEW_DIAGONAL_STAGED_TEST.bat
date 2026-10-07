@echo off
call "%~dp0RUN_ALL_MOTOR_TESTS.bat" diagonal-staged "%~1"
exit /B %ERRORLEVEL%
