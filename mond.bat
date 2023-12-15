@echo off
setlocal
set PSScript=%~dp0MetersOnDemand.ps1
Powershell -ExecutionPolicy Bypass -File "%PSScript%" %*
endlocal
