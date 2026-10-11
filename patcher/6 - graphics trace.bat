@echo off
setlocal
cd /d "%~dp0"
title Warpforge for Android - graphics trace

echo.
echo  Warpforge for Android - graphics trace
echo  --------------------------------------
echo  Records what the phone does while the game starts: CPU and GPU speeds, which
echo  core ran what, every frame the screen showed (late or dropped ones), phone
echo  temperature and slow-downs from heat, and memory. About 90 seconds.
echo  Nothing on the phone is changed, and the game itself is not touched.
echo.
set "ADB="
if exist "tool\platform-tools\adb.exe" set "ADB=%~dp0tool\platform-tools\adb.exe"
if not defined ADB for /f "delims=" %%A in ('where adb 2^>nul') do if not defined ADB set "ADB=%%A"
if not defined ADB (
    echo  This needs Google's "platform-tools" ^(the adb program^) in tool\platform-tools.
    goto :end
)
if not exist "tool\graphics-trace.cfg" (
    echo  tool\graphics-trace.cfg is missing.
    goto :end
)
echo  Devices found:
"%ADB%" devices
echo.
setlocal enabledelayedexpansion
set "DEV="
for /f "skip=1 tokens=1,2" %%A in ('""%ADB%" devices"') do (
    set "N=%%A"
    if "%%B"=="device" if /i not "!N:~0,9!"=="emulator-" if not defined DEV set "DEV=%%A"
)
if not defined DEV for /f "skip=1 tokens=1,2" %%A in ('""%ADB%" devices"') do if "%%B"=="device" if not defined DEV set "DEV=%%A"
if not defined DEV (
    echo  No phone is ready. Check the cable, that USB debugging is on, and that the
    echo  "Allow USB debugging?" prompt on the phone was accepted.
    goto :end
)
echo  Using device: !DEV!
echo.
echo  IMPORTANT: close the game first ^(swipe it away^), then press a key here.
pause >nul

set "PKG=com.Everguild.WarhammerWarpforge"
set "STAMP=run"
for /f %%T in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss"') do set "STAMP=%%T"
set "OUT=graphics-traces\!STAMP!"
if not exist "!OUT!" mkdir "!OUT!"

echo  Getting ready ...
"%ADB%" -s !DEV! logcat -G 16M >nul 2>&1
"%ADB%" -s !DEV! logcat -c >nul 2>&1
"%ADB%" -s !DEV! shell "dumpsys SurfaceFlinger --timestats -clear -enable" >nul 2>&1
"%ADB%" -s !DEV! shell "rm -f /data/misc/perfetto-traces/warpforge.pftrace" >nul 2>&1
"%ADB%" -s !DEV! push "tool\graphics-trace.cfg" /data/misc/perfetto-configs/warpforge.cfg >nul
if errorlevel 1 (
    echo  Could not copy the trace settings to the phone.
    goto :end
)
"%ADB%" -s !DEV! shell "perfetto --background --txt -c /data/misc/perfetto-configs/warpforge.cfg -o /data/misc/perfetto-traces/warpforge.pftrace" > "!OUT!\trace-start.txt" 2>&1
if errorlevel 1 (
    echo  The phone would not start the trace. Details:
    type "!OUT!\trace-start.txt"
    goto :end
)
echo.
echo  RECORDING NOW. Open the game on the phone, and let it load to the menu.
echo  Touch nothing else on the phone. The recording stops by itself after
echo  90 seconds; wait for this window to say it is done.
echo.
powershell -NoProfile -Command "for ($i = 90; $i -gt 0; $i -= 5) { Write-Host ('   ' + $i + ' s left'); Start-Sleep 5 }"
echo.
echo  Waiting for the phone to finish writing the trace ...
powershell -NoProfile -Command "Start-Sleep 8"

echo  Saving ...
"%ADB%" -s !DEV! pull /data/misc/perfetto-traces/warpforge.pftrace "!OUT!\warpforge.pftrace" > "!OUT!\pull-result.txt" 2>&1
"%ADB%" -s !DEV! logcat -d -v threadtime > "!OUT!\logcat.txt" 2>&1
"%ADB%" -s !DEV! shell "dumpsys SurfaceFlinger --timestats -dump" > "!OUT!\frame-stats.txt" 2>&1
"%ADB%" -s !DEV! shell "dumpsys SurfaceFlinger --timestats -disable" >nul 2>&1
"%ADB%" -s !DEV! shell "dumpsys gfxinfo !PKG!" > "!OUT!\gfxinfo.txt" 2>&1
"%ADB%" -s !DEV! shell "dumpsys meminfo !PKG!" > "!OUT!\meminfo.txt" 2>&1
"%ADB%" -s !DEV! shell "dumpsys gpu" > "!OUT!\gpu.txt" 2>&1
"%ADB%" -s !DEV! shell "dumpsys thermalservice" > "!OUT!\thermal.txt" 2>&1
"%ADB%" -s !DEV! shell "getprop | grep -i -E 'egl|gles|vulkan|gfx|graphics|hwui|ro.product.model|ro.build.version|ro.build.fingerprint|ro.board|ro.hardware|angle'" > "!OUT!\phone-graphics-settings.txt" 2>&1
"%ADB%" -s !DEV! shell "cat /sdcard/MelonLoader/!PKG!/MelonLoader/Latest.log" > "!OUT!\Latest.log" 2>&1
echo.
if exist "!OUT!\warpforge.pftrace" (
    echo  Done. Everything is in the "!OUT!" folder.
    echo  The trace ^(warpforge.pftrace^) can also be opened at https://ui.perfetto.dev
) else (
    echo  The trace file did not arrive; the other files are in "!OUT!". Details:
    type "!OUT!\pull-result.txt"
)
:end
echo.
pause
