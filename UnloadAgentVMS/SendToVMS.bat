@echo off

rem To specify server and login details for the target VMS system, create account
rem file named SendToVMS.Settings.bat in the same directory as this script and
rem use it to specify connection settings, like this:
rem
rem    @echo off
rem    set VMS_IP_ADDRESS=1.2.3.4
rem    set VMS_FTP_PORT=21
rem    set VMS_USERNAME=myusername
rem    set VMS_PASSWORD=mypassword
rem    set VMS_DIRECTORY=UNLOAD_AGENT
rem
rem After this script completes:
rem 
rem    1. Log in to the VMS account
rem    2. Go to the directory
rem    3. Execute BUILD.COM to build the software
rem 

pushd %~dp0
setlocal enabledelayedexpansion

if exist SendToVMS.Settings.bat (
  call SendToVMS.Settings.bat
) else (
  echo ERROR: SendToVMS.Settings.bat not found!
  goto done
)

rem Create an FTP command script to transfer the files
echo Creating FTP script...
echo open %VMS_IP_ADDRESS% %VMS_FTP_PORT% > ftp.tmp
echo %VMS_USERNAME% >> ftp.tmp
echo %VMS_PASSWORD% >> ftp.tmp
echo ascii >> ftp.tmp
echo prompt >> ftp.tmp

rem Put us in a REPLICATION subdirectory
echo mkdir [.%VMS_DIRECTORY%] >> ftp.tmp
echo cd [.%VMS_DIRECTORY%] >> ftp.tmp

rem Upload new files
echo put AGENT.OPT >> ftp.tmp
echo put BUILD.COM >> ftp.tmp
echo put KafkaAPI.dbl >> ftp.tmp
echo put SETUP.COM >> ftp.tmp
echo put UnloadAgent.dbl >> ftp.tmp

rem Make subdirectories
echo mkdir [.EXPORT] >> ftp.tmp
echo mkdir [.ZIP] >> ftp.tmp

echo bye >> ftp.tmp

rem Do it all
echo Transferring files...
ftp -s:ftp.tmp 1>nul

rem Delete the command script
echo Cleaning up...
del /q ftp.tmp

echo Done!

:done
endlocal
popd
