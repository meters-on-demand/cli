@ECHO OFF

SET PSScript=%~dp0MetersOnDemand.ps1

Powershell -ExecutionPolicy Bypass -Command "& '%PSScript%' %*"
