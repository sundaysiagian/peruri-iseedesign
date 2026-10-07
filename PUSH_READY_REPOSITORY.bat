@echo off
setlocal
cd /d "%~dp0"
git config user.name "wlmoi"
if errorlevel 1 goto failed
git config user.email "16523109@std.stei.itb.ac.id"
if errorlevel 1 goto failed
git config http.sslBackend openssl
if errorlevel 1 goto failed
py -3.11 scripts\create_manifest.py
if errorlevel 1 goto failed
py -3.11 scripts\validate_repository.py
if errorlevel 1 goto failed
git add .
if errorlevel 1 goto failed
git diff --cached --quiet
if errorlevel 1 (
  git commit -m "Complete IGOR documentation and verified Quartus ready projects"
  if errorlevel 1 goto failed
)
git push origin main
if errorlevel 1 goto failed
echo Repository updated successfully.
pause
exit /b 0
:failed
echo Update stopped. Review the error above. No force push was used.
pause
exit /b 1
