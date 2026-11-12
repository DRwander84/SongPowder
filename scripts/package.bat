@echo off
rem One-command packaging: portable folder + portable zip + installer. Extra arguments are passed to package.ps1.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0package.ps1" %*
exit /b %errorlevel%
