@echo off
cd /d "%~dp0"
IF EXIST D2Stats.exe (
	Del D2Stats.exe /Q
)
"vendor\Aut2Exe.exe" /in D2Stats.au3 /out D2Stats.exe /icon "Assets\icon.ico" /x86
