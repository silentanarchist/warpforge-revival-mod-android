@echo off
setlocal
cd /d "%~dp0"
title Warpforge for Android - start the game with OpenGL instead of Vulkan

echo.
echo  Warpforge for Android - start the game with OpenGL instead of Vulkan
echo  ---------------------------------------------------------------------
echo.
echo  A test for the black screen after signing in. The game normally draws with Vulkan;
echo  this starts it once with the older OpenGL ES instead. If the black screen never
echo  comes back when started this way, Vulkan on this phone is the cause.
echo  (Starting the game from its icon goes back to Vulkan.)
echo.

set "ADB="
if exist "tool\platform-tools\adb.exe" set "ADB=%~dp0tool\platform-tools\adb.exe"
if not defined ADB for /f "delims=" %%A in ('where adb 2^>nul') do if not defined ADB set "ADB=%%A"
if not defined ADB (
    echo  This needs Google's "platform-tools" ^(the adb program^) in tool\platform-tools.
    goto :end
)

setlocal enabledelayedexpansion
set "DEV="
for /f "skip=1 tokens=1,2" %%A in ('""%ADB%" devices"') do (
    set "N=%%A"
    if "%%B"=="device" if /i not "!N:~0,9!"=="emulator-" if not defined DEV set "DEV=%%A"
)
if not defined DEV for /f "skip=1 tokens=1,2" %%A in ('""%ADB%" devices"') do if "%%B"=="device" if not defined DEV set "DEV=%%A"
if not defined DEV (
    echo  No phone is ready. Check the cable and that USB debugging is on and allowed.
    goto :end
)
echo  Using device: !DEV!

set "PKG=com.Everguild.WarhammerWarpforge"
set "ACT="
rem the last line of the answer is the start screen, as package/activity
for /f "delims=" %%L in ('""%ADB%" -s !DEV! shell cmd package resolve-activity --brief %PKG%"') do set "ACT=%%L"
if defined ACT if "!ACT:/=!"=="!ACT!" set "ACT="
if not defined ACT (
    echo  Could not find the game's start screen on the phone. Is the patched game installed?
    goto :end
)
echo  Closing the game if it is running ...
"%ADB%" -s !DEV! shell am force-stop %PKG%
echo  Starting %ACT% with OpenGL ES ...
"%ADB%" -s !DEV! shell am start -n %ACT% -e unity "-force-gles"
echo.
echo  Play as usual. Restart it with this file each time while testing. If the black
echo  screen never comes back this way, run "6 - choose OpenGL or Vulkan.bat" and pick 1
echo  so the game always draws with OpenGL ES, even when started from its icon.

:end
echo.
pause
