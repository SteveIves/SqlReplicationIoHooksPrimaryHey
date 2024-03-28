@echo off

rem To specify server and login details for the target Linux system, create a
rem file named SendToLinux.Settings.bat in the same directory as this script and
rem use it to specify connection settings, like this:
rem
rem    @echo off
rem    set LINUX_IP_ADDRESS=1.2.3.4
rem    set LINUX_FTP_PORT=21
rem    set LINUX_USERNAME=myusername
rem    set LINUX_PASSWORD=mypassword
rem
rem After this script completes:
rem
rem    1. Log in to the Linux account
rem    2. Go to the LINUX directory
rem    3. Execute the build script (. ./build)
rem 

pushd %~dp0
setlocal enabledelayedexpansion

if exist SendToLinux.Settings.bat (
  call SendToLinux.Settings.bat
) else (
  echo ERROR: SendToLinux.Settings.bat not found!
  goto done
)

rem Create an FTP command script to transfer the files
echo Creating FTP script...
rem echo open %LINUX_IP_ADDRESS% %LINUX_FTP_PORT%> ftp.tmp
rem echo %LINUX_USERNAME%>> ftp.tmp
rem echo %LINUX_PASSWORD%>> ftp.tmp
echo ascii> ftp.tmp
rem echo prompt>> ftp.tmp
echo mkdir replication>> ftp.tmp
echo cd replication>> ftp.tmp
echo mkdir DAT>> ftp.tmp
echo mkdir EXE>> ftp.tmp
echo mkdir XDL>> ftp.tmp
echo mkdir OBJ>> ftp.tmp
echo mkdir PROTO>> ftp.tmp
echo mkdir LOGS>> ftp.tmp
echo mkdir RPS>> ftp.tmp
echo mkdir SRC>> ftp.tmp
echo mkdir SRC/LIBRARY>> ftp.tmp
echo mkdir SRC/REPLICATOR>> ftp.tmp
echo mkdir SRC/TOOLS>> ftp.tmp
echo mkdir LINUX>> ftp.tmp
echo cd DAT>> ftp.tmp
echo mput DAT\*.SEQ>> ftp.tmp
echo cd ../XDL>> ftp.tmp
echo mput XDL\*.XDL>> ftp.tmp
echo cd ../RPS>> ftp.tmp
echo put RPS\REPLICATION.SCH>> ftp.tmp
echo cd ../SRC/LIBRARY>> ftp.tmp
echo mput SRC\LIBRARY\*.dbl>> ftp.tmp
echo mput SRC\LIBRARY\*.def>> ftp.tmp
echo cd ../REPLICATOR>> ftp.tmp
echo mput SRC\REPLICATOR\*.dbl>> ftp.tmp
echo cd ../TOOLS>> ftp.tmp
echo mput SRC\TOOLS\*.dbl>> ftp.tmp
echo cd ../../LINUX>> ftp.tmp
echo put LINUX\build>> ftp.tmp
echo put LINUX\replicator_count>> ftp.tmp
echo put LINUX\replicator_detach>> ftp.tmp
echo put LINUX\replicator_instructions>> ftp.tmp
echo put LINUX\replicator_menu>> ftp.tmp
echo put LINUX\replicator_run>> ftp.tmp
echo put LINUX\replicator_setup>> ftp.tmp
echo put LINUX\replicator_status>> ftp.tmp
echo put LINUX\replicator_stop>> ftp.tmp
echo put LINUX\setup>> ftp.tmp
echo bye>> ftp.tmp

rem Transfer the files
echo Transferring files...
rem ftp -s:ftp.tmp 1>nul

sftp -a -B ftp.tmp -P %LINUX_FTP_PORT% -q -Q %LINUX_USERNAME%@%LINUX_IP_ADDRESS%

rem Delete the command script
echo Cleaning up...
rem del /q ftp.tmp

echo Done!
popd
endlocal