@echo off
setlocal enabledelayedexpansion

set containerName=redpanda-console
set containerRunning=

rem Run the Docker PS command in WSL and capture the output
for /f "usebackq tokens=*" %%i in (`wsl -d RockyLinux8 -- docker ps --format "{{.Names}}" 2^>nul`) do (
    if /I "%%i"=="%containerName%" (
        set "containerRunning=true"
    )
)

rem Check if the container is running
if defined containerRunning (
    rem echo Container %containerName% is running
    goto done
) else (
    rem echo Container %containerName% is NOT running
    goto fail
)
:done
endlocal
exit /b 0

:fail
endlocal
exit /b 1
