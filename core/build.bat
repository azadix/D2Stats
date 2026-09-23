@echo off
setlocal
pushd "%~dp0"

where cl >nul 2>&1
if errorlevel 1 (
	popd
	exit /b 1
)

cl /nologo /O1 /W3 /MT d2stats_core.c /Fe:"..\D2Stats.Core.exe" /link /SUBSYSTEM:WINDOWS /INCREMENTAL:NO /BREPRO user32.lib advapi32.lib
if errorlevel 1 (
	popd
	exit /b 1
)
if exist d2stats_core.obj del /q d2stats_core.obj
popd
exit /b 0
