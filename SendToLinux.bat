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
rem    3. Set Linux line endings on all files (dos2unix *)
rem    4. Make all scripts executable (chmod +x *)
rem    4. Execute the build script (. ./build)
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
echo open %LINUX_IP_ADDRESS% %LINUX_FTP_PORT%> ftp.tmp
echo %LINUX_USERNAME%>> ftp.tmp
echo %LINUX_PASSWORD%>> ftp.tmp
echo ascii>> ftp.tmp
echo prompt>> ftp.tmp
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
echo put DAT\ReplicatorConfig.json>> ftp.tmp
echo bin>> ftp.tmp
echo put DAT\DEPARTMENT.ISM>> ftp.tmp
echo put DAT\DEPARTMENT.IS1>> ftp.tmp
echo put DAT\EMPLOYEE.ISM>> ftp.tmp
echo put DAT\EMPLOYEE.IS1>> ftp.tmp
echo ascii>> ftp.tmp
echo cd ../XDL>> ftp.tmp
echo mput XDL\*.XDL>> ftp.tmp
echo cd ../RPS>> ftp.tmp
echo put RPS\REPLICATION.SCH>> ftp.tmp
echo bin>> ftp.tmp
echo put RPS\rpsmain.ism>> ftp.tmp
echo put RPS\rpsmain.is1>> ftp.tmp
echo put RPS\rpstext.ism>> ftp.tmp
echo put RPS\rpstext.is1>> ftp.tmp
echo ascii>> ftp.tmp
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
ftp -s:ftp.tmp 1>nul

rem Delete the command script
echo Cleaning up...
del /q ftp.tmp

echo Done!
popd
endlocal