@echo off
setlocal enabledelayedexpansion
pushd %~dp0

set process_name=dbl_replicator.exe
set broker_log=broker.log

rem Check we have the broker executable

if not exist %process_name% (
    echo ERROR: %process_name% not found.
    goto fail
)

rem Check we have the OpenSSL 3 library

if not exist "%SystemRoot%\system32\libssl-3-x64.dll" (
    echo ERROR: OpenSSL 3 is not installed. It can be installed with winget: winget install -e --id ShiningLight.OpenSSL
    goto fail
)

rem If we have a CheckKafka script, run it and check the result

if exist CheckKafka.bat (
    call CheckKafka.bat
    if errorlevel 1 (
        echo ERROR: CheckKafka reports that Kafka is not running
        goto fail
    )
)

rem Check we have the necessary config files

if not exist .\config\config.toml (
    echo ERROR: config\config.toml not found
    goto fail
)

if not exist .\config\iceoryx2.toml (
    echo ERROR: config\iceoryx2.toml not found
    goto fail
)

rem Check we have a C:\TEMP directory

if not exist C:\TEMP\. (
    mkdir C:\TEMP
)

rem Check if the broker is already running

tasklist /FI "IMAGENAME eq %process_name%" 2>NUL | find /I "%process_name%" >NUL
if errorlevel 1 (

    rem Not running. Clean up any temp files from an earlier run
    if exist C:\TEMP\iox2*.dynamic.shm_state del /q C:\TEMP\iox2*.dynamic.shm_state
    if exist C:\TEMP\iceoryx2\. rmdir /s /q C:\TEMP\iceoryx2

    rem Delete the log file from a previous run
    if exist %broker_log% del /q %broker_log%

    rem Start the broker
    start "" /B cmd /c "%process_name% > %broker_log% 2>&1"

    rem Check if the process is running
    tasklist /FI "IMAGENAME eq %process_name%" 2>NUL | find /I "%process_name%" >NUL
    if errorlevel 1 (
        rem Still not running!
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
