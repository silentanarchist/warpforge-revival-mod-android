@echo off
setlocal
cd /d "%~dp0"
title Warpforge for Android - choose how the game draws (OpenGL or Vulkan)

echo.
echo  Warpforge for Android - choose how the game draws
echo  --------------------------------------------------
echo.
echo  1  OpenGL ES  - try this if the screen sometimes goes black (or shows coloured
echo                  blocks) after signing in. Fixed it on a Pixel 6 Pro.
echo  2  Vulkan     - the game's own choice. Use this if OpenGL ES runs worse for you.
echo.
echo  The choice stays until you run this again, and works when the game is started
echo  from its icon.
echo.
choice /c 12 /n /m "  Press 1 or 2: "
set "PICK=%errorlevel%"

if "%PICK%"=="1" if not exist "mods\WarpforgeRevival.AndroidGraphics.dll" (
    echo  WarpforgeRevival.AndroidGraphics.dll is missing from the "mods" folder.
    goto :end
)

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
echo.
echo  Using device: !DEV!
set "P=/sdcard/MelonLoader/com.Everguild.WarhammerWarpforge"

if "%PICK%"=="1" (
    "%ADB%" -s !DEV! shell mkdir -p %P%/Plugins
    "%ADB%" -s !DEV! push "mods\WarpforgeRevival.AndroidGraphics.dll" %P%/Plugins/WarpforgeRevival.AndroidGraphics.dll
    if errorlevel 1 (
        echo  Copying failed. Has the patched game been started at least once on this phone?
        goto :end
    )
    echo.
    echo  OpenGL ES chosen. Close the game completely and start it again.
) else (
    rem moved aside, not deleted
    "%ADB%" -s !DEV! shell "mkdir -p %P%/Plugins-disabled; if [ -f %P%/Plugins/WarpforgeRevival.AndroidGraphics.dll ]; then mv %P%/Plugins/WarpforgeRevival.AndroidGraphics.dll %P%/Plugins-disabled/; fi"
    echo.
    echo  Vulkan chosen. Close the game completely and start it again.
)

:end
echo.
pause
