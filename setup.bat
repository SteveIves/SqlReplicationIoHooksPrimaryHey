@echo off

rem This batch file can be used to configure the environment after an initial
rem download of the environment. It will load the repository from the schema
rem file, and load the ISAM files ready for use.

if exist "%SYNERGYDE64%dbl\dblvars64.bat" (
  call "%SYNERGYDE64%dbl\dblvars64.bat"
  echo Using 64-bit Synergy
) else (
  if exist "%SYNERGYDE32%dbl\dblvars32.bat" (
    call "%SYNERGYDE32%dbl\dblvars32.bat"
    echo Using 32-bit Synergy
  ) else (
    echo "Synergy/DE not found!"
    exit /b
  )
)

set ROOT=%~dp0
set INC=%ROOT%SRC\LIBRARY
set OBJ=%ROOT%OBJ
set REPLICATOR_EXE=%ROOT%EXE
set REPLICATOR_DATA=%ROOT%DAT
set REPLICATOR_SAMPLE_DATA=%ROOT%DAT
set REPLICATOR_XDL=%ROOT%XDL
set RPSMFIL=%ROOT%RPS\rpsmain.ism
set RPSTFIL=%ROOT%RPS\rpstext.ism
set SYNEXPDIR=%ROOT%PROTO
set SYNIMPDIR=%ROOT%PROTO

rem If no repository load it from the schema
if not exist "%RPSMFIL%" (
  call RpsImport.bat
)

if not exist "%DAT%\DEPARTMENT.ISM" (
  fconvert -it REPLICATOR_SAMPLE_DATA:DEPARTMENT.SEQ -oi REPLICATOR_SAMPLE_DATA:DEPARTMENT.ISM -d REPLICATOR_XDL:DEPARTMENT.XDL
)

if not exist "%DAT%\EMPLOYEE.ISM" (
  fconvert -it REPLICATOR_SAMPLE_DATA:EMPLOYEE.SEQ   -oi REPLICATOR_SAMPLE_DATA:EMPLOYEE.ISM   -d REPLICATOR_XDL:EMPLOYEE.XDL
)

if not exist "%DAT%\REPLICATION_DEFAULT.ISM" (
  dbs DBLDIR:bldism -k REPLICATOR_XDL:REPLICATION.XDL
)
