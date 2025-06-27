@echo off
setlocal enabledelayedexpansion

:: Configurable build mode
IF NOT [%~1]==[] (
    set "BUILD_CONFIGURATION=%~1"
) ELSE (
    set "BUILD_CONFIGURATION=Release"
)

echo Building in '%BUILD_CONFIGURATION%' mode

:: Create output dir
mkdir "..\%BUILD_CONFIGURATION%" 2>nul

:: Use vswhere to locate latest VS installation
for /f "usebackq tokens=*" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do (
    set "VSINSTALL=%%i"
)

if not defined VSINSTALL (
    echo Visual Studio with C++ tools not found. Aborting.
    exit /b 1
)

:: Setup environment using vcvarsall
call "%VSINSTALL%\VC\Auxiliary\Build\vcvarsall.bat" x86

:: Windows SDK version and include path
for /f "delims=" %%v in ('reg query "HKLM\SOFTWARE\Microsoft\Microsoft SDKs\Windows\v10.0" /v ProductVersion 2^>nul ^| find "REG_SZ"') do (
    for /f "tokens=3" %%x in ("%%v") do set "SDKVER=%%x"
)

if not defined SDKVER (
    set "SDKVER=10.0.26100.0"
)

:: Compile resource file
"%WindowsSdkDir%bin\%SDKVER%\x86\rc.exe" ^
    /I "%WindowsSdkDir%Include\%SDKVER%\um" ^
    /I "%WindowsSdkDir%Include\%SDKVER%\shared" Config.rc

:: Include paths
set INCLUDE_PATHS=/I "%VCToolsInstallDir%include" ^
 /I "%WindowsSdkDir%Include\%SDKVER%\ucrt" ^
 /I "%WindowsSdkDir%Include\%SDKVER%\um" ^
 /I "%WindowsSdkDir%Include\%SDKVER%\shared" ^
 /I "C:\Program Files (x86)\Winamp SDK\Winamp" ^
 /I "C:\Users\bezal\OneDrive\Documents\discord-rpc\win32-dynamic\include"


:: Set build flags
IF /I "%BUILD_CONFIGURATION%"=="Release" (
    set "CLFLAGS=/O2 /Gy /W3"
) ELSE (
    set "CLFLAGS=/Od /Yc /Gy /Oi /W3"
)

set "COMMONFLAGS=/nologo !CLFLAGS! /DUNICODE /DWIN32 /DDEBUG /DDISCORDRICHPRESENCE_EXPORTS /D_WINDOWS /D_USRDLL /D_WINDLL /EHsc /std:c++14 !INCLUDE_PATHS!"
set "LINKFLAGS=/DLL /OUT:..\%BUILD_CONFIGURATION%\gen_DiscordRichPresence.dll User32.lib Config.res"

echo Using compiler flags: !CLFLAGS!

:: Compile
cl.exe !COMMONFLAGS! *.cpp /link !LINKFLAGS!

:: Cleanup
del /q *.ilk *.obj *.pdb *.lib *.pch *.exp Config.res 2>nul
endlocal
