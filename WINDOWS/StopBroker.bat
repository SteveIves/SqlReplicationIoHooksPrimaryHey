@echo off
setlocal enabledelayedexpansion
pushd %~dp0

set process_name=dbl_replicator.exe

tasklist /FI "IMAGENAME eq %process_name%" 2>NUL | find /I "%process_name%" >NUL
if errorlevel 1 (
    rem Not running
    goto done
) else (
    taskkill /F /IM %process_name% >NUL
    tasklist /FI "IMAGENAME eq %process_name%" 2>NUL | find /I "%process_name%" >NUL
    if errorlevel 1 (
        rem Stopped
        goto done
    ) else (
        echo ERROR: Failed to stop the broker
        goto fail
    )
)

:done
popd
endlocal
exit /b 0

:fail
popd
endlocal
exit /b 1
