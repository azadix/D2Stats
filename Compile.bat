@echo off
cd /d "%~dp0"

set "IMGUI_DIR=native\d2stats_ui\third_party\imgui"
if not exist "%IMGUI_DIR%\imgui.cpp" (
	echo Cloning Dear ImGui...
	git clone --depth 1 --branch v1.91.9b https://github.com/ocornut/imgui.git "%IMGUI_DIR%"
	if errorlevel 1 (
		echo Failed to clone imgui. Install git or place imgui sources in %IMGUI_DIR%.
		exit /b 1
	)
)

set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
set "MSBUILD="
if exist "%VSWHERE%" (
	for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe`) do set "MSBUILD=%%i"
)
if not defined MSBUILD (
	if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" set "MSBUILD=%ProgramFiles%\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"
)

if not defined MSBUILD (
	echo MSBuild not found. Install Visual Studio with the C++ x86 toolset, or use cmake -A Win32.
	exit /b 1
)

"%MSBUILD%" "native\d2stats_ui\d2stats_ui.vcxproj" /p:Configuration=Release /p:Platform=Win32 /m
if errorlevel 1 (
	echo Failed to build d2stats_ui.dll
	exit /b 1
)

if not exist d2stats_ui.dll (
	echo d2stats_ui.dll was not produced. A 32-bit MSVC toolset is required.
	exit /b 1
)

IF EXIST D2Stats.exe (
	Del D2Stats.exe /Q
)
"vendor\Aut2Exe.exe" /in D2Stats.au3 /out D2Stats.exe /icon "Assets\icon.ico" /x86
