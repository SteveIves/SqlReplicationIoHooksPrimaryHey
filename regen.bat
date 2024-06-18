@echo off
setlocal

rem ---------------------------------------------------------------------------
rem set code generation options

set STRUCTURES=DEPARTMENT EMPLOYEE

set DBLV11=-define DBLV11
set ENABLE_CLEAN_DATA=-define CLEAN_DATA
rem set USE_STRUCTURE_ALIASES=-a %STRUCTURES%
rem set USE_ALTERNATE_FIELD_NAMES=-af
rem set ENABLE_EXCLUDE_KEYS= -rpsoverride ExcludeKeyTest.json
rem set ASA_TIREMAX=-define ASA_TIREMAX

rem ---------------------------------------------------------------------------
rem Configure the CodeGen environment

set ROOT=%~dp0
set STDOPTS=-i "%ROOT%SRC\TEMPLATES" -rps "%RPSMFIL%" "%RPSTFIL%" -e -r -lf %USE_STRUCTURE_ALIASES% %USE_ALTERNATE_FIELD_NAMES% %ENABLE_CLEAN_DATA% %ENABLE_EXCLUDE_KEYS% %DBLV11% %ASA_TIREMAX%

rem ---------------------------------------------------------------------------
rem Generate code

rem Generate SQL I/O routines for the structures being replicated
codegen -s %STRUCTURES% -t SqlIO MscIO SynIO -o "%ROOT%SRC\LIBRARY" %STDOPTS%

endlocal
