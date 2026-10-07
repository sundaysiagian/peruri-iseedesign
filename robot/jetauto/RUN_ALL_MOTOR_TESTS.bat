@echo off
setlocal
pushd "%~dp0"
set "JETAUTO_PY=%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
if exist "%JETAUTO_PY%" goto python_ready
where py >nul 2>&1
if not errorlevel 1 (
    set "JETAUTO_PY=py"
    goto python_ready
)
where python >nul 2>&1
if not errorlevel 1 (
    set "JETAUTO_PY=python"
    goto python_ready
)
echo Python 3 is required. Pyserial is already included in vendor.
set "JETAUTO_RESULT=1"
goto finish
:python_ready
set "JETAUTO_PROFILE=all"
if /I "%~1"=="verify" goto verify
if /I "%~1"=="diagonals" set "JETAUTO_PROFILE=diagonals"
if /I "%~1"=="staged" set "JETAUTO_PROFILE=staged"
if /I "%~1"=="diagonal-staged" set "JETAUTO_PROFILE=diagonal-staged"
if /I "%~1"=="round-robin" set "JETAUTO_PROFILE=round-robin"
if not "%~1"=="" goto motion
echo V = verify files and run available Verilog tests, without motor commands
echo M = run every motor suite, including diagonals, staggered start and one-ID packets
choice /C VM /N /M "Choose V or M: "
if errorlevel 2 goto motion
goto verify
:motion
echo.
echo COM9 must be the tested CH9102 bridge. Other COM ports will not be used.
echo All wheels must be lifted and free to turn. Motor power must be ON.
if /I "%JETAUTO_PROFILE%"=="all" (
    echo Full suite runs up to 90 RPM and takes about 3 minutes.
) else (
    echo Selected profile: %JETAUTO_PROFILE%. Maximum command is 60 RPM.
)
echo Ctrl+C interrupts the current test.
set "JETAUTO_CONFIRM="
set /P "JETAUTO_CONFIRM=Type RUN to begin motion, or anything else to cancel: "
if /I not "%JETAUTO_CONFIRM%"=="RUN" (
    echo Cancelled. No motor command sent.
    set "JETAUTO_RESULT=0"
    goto finish
)
"%JETAUTO_PY%" run_all_tests.py --run --wheels-raised --supply-on --profile "%JETAUTO_PROFILE%"
set "JETAUTO_RESULT=%ERRORLEVEL%"
goto finish
:verify
"%JETAUTO_PY%" run_all_tests.py
set "JETAUTO_RESULT=%ERRORLEVEL%"
:finish
echo.
echo Logs are in the logs folder. Physical motion is not inferred from serial writes.
if /I not "%~2"=="--no-pause" pause
popd
exit /B %JETAUTO_RESULT%
