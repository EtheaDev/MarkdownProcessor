@echo off
rem ---------------------------------------------------------------------------
rem MarkdownProcessor test suite: builds the DUnitX project for Win32 and Win64,
rem runs both, and regenerates Tests\CONFORMANCE.md.
rem
rem   RunTests.cmd            build + run (exit code 0 only if every test passes)
rem   RunTests.cmd /record    re-record the legacy snapshots (Tests\snapshots)
rem                           of mdDaringFireball / mdTxtMark, then run
rem
rem Requires Delphi 13. Set STUDIO_ROOT / MDP_STUDIO to use another install
rem (default C:\BDS\Studio\37.0).
rem ---------------------------------------------------------------------------
setlocal

set "ROOT=%~dp0"
if not defined STUDIO_ROOT set "STUDIO_ROOT=C:\BDS\Studio"
if not defined MDP_STUDIO set "MDP_STUDIO=37.0"
set "RSVARS=%STUDIO_ROOT%\%MDP_STUDIO%\bin\rsvars.bat"
set "PROJECT=%ROOT%MarkdownProcessor.Tests.dproj"
set "RESULTS=%ROOT%results"

if /i "%~1"=="/record" (
    set "MDP_RECORD_SNAPSHOTS=1"
    echo [tests] Recording legacy snapshots
)

if not exist "%RSVARS%" (
    echo [tests] rsvars.bat not found at "%RSVARS%".
    exit /b 2
)
call "%RSVARS%"

for %%P in (Win32 Win64) do (
    echo.
    echo === Building %%P ===
    msbuild "%PROJECT%" /t:Build /p:Config=Debug /p:Platform=%%P /v:m /nologo
    if errorlevel 1 (
        echo === BUILD FAILED ^(%%P^) ===
        exit /b 2
    )
)

if not exist "%RESULTS%" mkdir "%RESULTS%"

echo.
echo === Running Win32 ===
"%ROOT%Win32\Debug\MarkdownProcessor.Tests.exe" -exit:continue
set "EXIT32=%ERRORLEVEL%"

rem Snapshots are recorded once (Win32): Win64 then verifies them.
set "MDP_RECORD_SNAPSHOTS="

echo.
echo === Running Win64 ===
"%ROOT%Win64\Debug\MarkdownProcessor.Tests.exe" -exit:continue
set "EXIT64=%ERRORLEVEL%"

echo.
copy /y "%RESULTS%\conformance-Win64.md" "%ROOT%CONFORMANCE.md" >nul
fc /b "%RESULTS%\conformance-Win32.md" "%RESULTS%\conformance-Win64.md" >nul
if errorlevel 1 (
    echo === WARNING: Win32 and Win64 conformance results differ ===
    set "EXIT64=1"
)
echo Conformance dashboard: %ROOT%CONFORMANCE.md

echo.
echo Win32 exit code: %EXIT32%
echo Win64 exit code: %EXIT64%
if not "%EXIT32%"=="0" exit /b 1
if not "%EXIT64%"=="0" exit /b 1
echo === All tests passed ===
exit /b 0
