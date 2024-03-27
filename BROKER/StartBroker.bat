@echo off
setlocal enabledelayedexpansion
pushd %~dp0

set process_name=dbl_replicator.exe
set broker_log=broker.log

rem Check pre-requisites

if not exist %process_name% (
    echo ERROR: %process_name% not found.
    goto fail
)

if not exist "%SystemRoot%\system32\libssl-3-x64.dll" (
    echo ERROR: OpenSSL 3 is not installed. It can be installed with winget: winget install -e --id ShiningLight.OpenSSL
    goto fail
)

if not exist .\config\config.toml (
    echo ERROR: config\config.toml not found
    goto fail
)

if not exist .\config\iceoryx2.toml (
    echo ERROR: config\iceoryx2.toml not found
    goto fail
)

if not exist C:\TEMP\. (
    mkdir C:\TEMP
)

tasklist /FI "IMAGENAME eq %process_name%" 2>NUL | find /I "%process_name%" >NUL
if errorlevel 1 (
    if exist C:\TEMP\iox2*.dynamic.shm_state del /q C:\TEMP\iox2*.dynamic.shm_state
    if exist C:\TEMP\iceoryx2\. rmdir /s /q C:\TEMP\iceoryx2
    if exist %broker_log% del /q %broker_log%
    start "" /B cmd /c "%process_name% > %broker_log% 2>&1"
    tasklist /FI "IMAGENAME eq %process_name%" 2>NUL | find /I "%process_name%" >NUL
    if errorlevel 1 (
        echo ERROR: The broker failed to start
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
