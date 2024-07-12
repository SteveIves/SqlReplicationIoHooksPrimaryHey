@echo off

rem To specify server and login details for the target VMS system, create account
rem file named UpdateCCode.Settings.bat in the same directory as this script and
rem use it to specify connection settings, like this:
rem
rem    @echo off
rem    set VMS_IP_ADDRESS=1.2.3.4
rem    set VMS_FTP_PORT=21
rem    set VMS_USERNAME=myusername
rem    set VMS_PASSWORD=mypassword
rem    set VMS_DIRECTORY=DISK:[DIRECTORY]
rem

pushd %~dp0
setlocal enabledelayedexpansion

if exist UpdateCCode.Settings.bat (
  call UpdateCCode.Settings.bat
) else (
  echo ERROR: UpdateCCode.Settings.bat not found!
  goto done
)

rem Create an FTP command script to transfer the files
echo Creating FTP script...
echo open %VMS_IP_ADDRESS% %VMS_FTP_PORT% > getccode.tmp
echo %VMS_USERNAME% >> getccode.tmp
echo %VMS_PASSWORD% >> getccode.tmp
echo ascii >> getccode.tmp
echo prompt >> getccode.tmp

rem Put us in the directory containing the C code
echo cd %VMS_DIRECTORY% >> getccode.tmp
echo lcd SRC\VMSC  >> getccode.tmp
rem Download the files
echo get DBL_KAFKA.C >> getccode.tmp
echo get DBL_UTILS.C >> getccode.tmp
echo get DBL_UTILS.H >> getccode.tmp
echo get KAFKA_UTILS.C >> getccode.tmp
echo get KAFKA_UTILS.H >> getccode.tmp
echo get MESSAGE_UTILS.C >> getccode.tmp
echo get MESSAGE_UTILS.H >> getccode.tmp
echo get PACKET_UTILS.C >> getccode.tmp
echo get PACKET_UTILS.H >> getccode.tmp
echo get ZMQ_HOOKS.C >> getccode.tmp

echo bye >> getccode.tmp

rem Do it all
echo Transferring files...
ftp -s:getccode.tmp
rem  1>nul

rem Delete the command script
echo Cleaning up...
del /q getccode.tmp

echo Done!

:done
endlocal
popd
