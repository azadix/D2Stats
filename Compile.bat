@echo off
REM Rebuild Core only when it is missing. After changing core/, run core\build.bat
IF NOT EXIST D2Stats.Core.exe (
	call core\build.bat
	IF ERRORLEVEL 1 EXIT /B 1
)

IF EXIST D2Stats.exe (
	Del D2Stats.exe /Q
)
"Assets/Aut2Exe.exe" /in D2Stats.au3 /out D2Stats.exe /icon "Assets/icon.ico" /x86