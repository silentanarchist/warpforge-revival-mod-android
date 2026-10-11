@echo off
setlocal
cd /d "%~dp0"
title Warpforge for Android - graphics trace

echo.
echo  Warpforge for Android - graphics trace
echo  --------------------------------------
echo  Records what the phone does while the game starts: CPU and GPU speeds, which
echo  core ran what, every frame the screen showed (late or dropped ones), phone
echo  temperature and slow-downs from heat, and memory, until you press a key.
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
set "TPID="
for /f %%P in ('powershell -NoProfile -Command "((Get-Content -Raw '!OUT!\trace-start.txt') -replace '\D','')"') do set "TPID=%%P"
if not defined TPID echo  ^(Could not read the trace's number; it will stop by itself after 5 minutes.^)
echo.
echo  RECORDING NOW. Open the game on the phone and do what you want to look at.
echo  When it has happened, press any key here: the recording goes on for
echo  10 more seconds and then stops. ^(It stops by itself after 5 minutes.^)
echo.
pause >nul
echo  Recording 10 more seconds ...
powershell -NoProfile -Command "for ($i = 10; $i -gt 0; $i -= 1) { Write-Host -NoNewline ('  ' + $i); Start-Sleep 1 }; Write-Host ''"
if defined TPID "%ADB%" -s !DEV! shell "kill -TERM !TPID!" >nul 2>&1
echo  Waiting for the phone to finish writing the trace ...
for /l %%W in (1,1,30) do (
    "%ADB%" -s !DEV! shell "kill -0 !TPID! 2>/dev/null && echo running" 2>nul | find "running" >nul && powershell -NoProfile -Command "Start-Sleep 1"
)

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
