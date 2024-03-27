@echo off
setlocal enabledelayedexpansion

set process_name=dbl_replicator.exe

tasklist /FI "IMAGENAME eq %process_name%" 2>NUL | find /I "%process_name%" >NUL
if errorlevel 1 (
    echo The broker is NOT running
    goto done
) else (
    echo The broker is running
    goto fail
)

:done
endlocal
exit /b 0

:fail
endlocal
exit /b 1
