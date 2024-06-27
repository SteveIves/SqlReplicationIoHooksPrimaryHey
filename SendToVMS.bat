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
rem    set VMS_DIRECTORY=REPLICATION
rem
rem After this script completes:
rem 
rem    1. Log in to the VMS account
rem    2. Go to the [.REPLICATION] directory
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

rem Make sure the directories are all there
echo mkdir [.DATA] >> ftp.tmp
echo mkdir [.EXE] >> ftp.tmp
echo mkdir [.FDL] >> ftp.tmp
echo mkdir [.OBJ] >> ftp.tmp
echo mkdir [.PROTO] >> ftp.tmp
echo mkdir [.LOGS] >> ftp.tmp
echo mkdir [.REPOSITORY] >> ftp.tmp
echo mkdir [.SRC.LIBRARY] >> ftp.tmp
echo mkdir [.SRC.REPLICATOR] >> ftp.tmp
echo mkdir [.SRC.TOOLS] >> ftp.tmp
echo mkdir [.SRC.VMSC] >> ftp.tmp

rem Delete existing files
echo mdelete [.DATA]*.seq;* >> ftp.tmp
echo mdelete [.FDL]*.*;* >> ftp.tmp
echo mdelete [.OBJ]*.*;* >> ftp.tmp
echo mdelete [.PROTO]*.*;* >> ftp.tmp
echo mdelete [.REPOSITORY]*.*;* >> ftp.tmp
echo mdelete [.SRC.LIBRARY]*.*;* >> ftp.tmp
echo mdelete [.SRC.REPLICATOR]*.*;* >> ftp.tmp
echo mdelete [.SRC.TOOLS]*.*;* >> ftp.tmp
echo mdelete [.SRC.VMSC]*.*;* >> ftp.tmp

rem Upload new files
echo cd [.REPOSITORY] >> ftp.tmp
echo put RPS\REPLICATION.SCH >> ftp.tmp
echo cd [-.DATA] >> ftp.tmp
echo put DAT\department.seq >> ftp.tmp
echo put DAT\employee.seq >> ftp.tmp
echo cd [-.FDL] >> ftp.tmp
echo mput VMS\*.fdl >> ftp.tmp
echo cd [-.SRC.LIBRARY] >> ftp.tmp
echo mput SRC\LIBRARY\*.dbl >> ftp.tmp
echo mput SRC\LIBRARY\*.def >> ftp.tmp
echo cd [-.REPLICATOR] >> ftp.tmp
echo mput SRC\REPLICATOR\*.dbl >> ftp.tmp
echo cd [-.TOOLS] >> ftp.tmp
echo mput SRC\TOOLS\*.dbl >> ftp.tmp
echo cd [-.VMSC] >> ftp.tmp
echo mput SRC\VMSC\*.* >> ftp.tmp
echo cd [-.-] >> ftp.tmp
echo mput VMS\*.COM >> ftp.tmp
echo put VMS\MAKESHARE.DBL >> ftp.tmp
echo put VMS\REPLICATION.FDL >> ftp.tmp
echo put VMS\REPLICATOR.OPT >> ftp.tmp

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
