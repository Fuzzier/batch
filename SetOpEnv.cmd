@ECHO OFF

REM ===========================================================
REM 20191226
REM ===========================================================

SET SCRIPT_NAME=%0

CD /D "%~dp0"

IF "%1"=="/?" (
  CALL :ShowHelp
  EXIT /B
)

:: Parse command-line options
SET OPNET_VCVER=17
SET OPNET_PLATFORM=x64
SET OPNET_RELEASE=14.5.A
SET OPNET_USER_HOME=
SET OPNET_GUI=
CALL :ParseOptions %*
IF %ERRORLEVEL% GEQ 1 (
  EXIT /B
)

:: Set OPNET platform (intel_win32 or amd_win64)
SET OPNET_PC=intel_win32
CALL :GetPc

:: ECHO.%OPNET_VCVER%
:: ECHO.%OPNET_PLATFORM%
:: ECHO.%OPNET_RELEASE%
:: ECHO.%OPNET_USER_HOME%
:: ECHO.%OPNET_GUI%
:: ECHO.%OPNET_PC%

:: Call the external batch file
CALL SetVcEnv %OPNET_VCVER% %OPNET_PLATFORM%

:: Setup environment for other tools
CALL SetUserEnv.cmd %OPNET_PLATFORM%

:: Setup OPNET environment
SET ProgramFiles64=%ProgramFiles%
IF "%ProgramW6432%" NEQ "" (
  SET ProgramFiles64=%ProgramW6432%
)

:: C:\Program Files\OPNET
SET OPNET_ROOT_DIR=%ProgramFiles64%\OPNET

:: C:\Program Files\OPNET\14.5.A
SET OPNET_INSTALL_DIR=%OPNET_ROOT_DIR%\%OPNET_RELEASE%

:: C:\Program Files\OPNET\14.5.A\sys
SET OPNET_SYS_DIR=%OPNET_INSTALL_DIR%\sys

:: C:\Program Files\OPNET\14.5.A\sys\pc_intel_win32
:: C:\Program Files\OPNET\14.5.A\sys\pc_amd_win64
SET OPNET_PC_DIR=%OPNET_SYS_DIR%\pc_%OPNET_PC%

:: C:\Program Files\OPNET\14.5.A\models\std
SET OPNET_MODEL_DIR=%OPNET_INSTALL_DIR%\models\std

CALL Envvar :EnvvarAddPath "PATH"    "%OPNET_PC_DIR%\bin"
CALL Envvar :EnvvarAddPath "PATH"    "%OPNET_USER_HOME%\op_models\lib"

CALL Envvar :EnvvarAddPath "INCLUDE" "%OPNET_SYS_DIR%\include"
CALL Envvar :EnvvarAddPath "INCLUDE" "%OPNET_MODEL_DIR%\include"
CALL Envvar :EnvvarAddPath "INCLUDE" "%OPNET_USER_HOME%\op_models"

CALL Envvar :EnvvarAddPath "LIB"     "%OPNET_PC_DIR%\lib"
CALL Envvar :EnvvarAddPath "LIB"     "%OPNET_USER_HOME%\op_models\lib"

IF "%OPNET_GUI%"=="1" (
  :: Set current driver
  FOR /D %%d IN ("%OPNET_ROOT_DIR%") DO (CD /D %%~dd)

  :: Start OPNET modeler
  START "" "%OPNET_PC_DIR%\bin\opnet.exe" -mem_shred
)

EXIT /B

:: ============ ShowHelp Begin ============
:ShowHelp
ECHO Usage: %SCRIPT_NAME% [-option value] ...
ECHO   -vc:    Microsoft Visual C++ version, defaults to "17"
ECHO   -p:     Platform architecture,        defaults to "x64"
ECHO   -op:    OPNET Modeler version,        defaults to "14.5.A"
ECHO   -home:  OPNET Modeler User Home.
ECHO   -gui:   Launch OPNET Modeler GUI.
ECHO.
ECHO   For example,
ECHO   %SCRIPT_NAME% -vc 17 -p x64 -op 14.5.A -home "D:\Development\op" -gui
EXIT /B
:: ============ ShowHelp End ============


:: ============ ParseOptions Begin ============
:ParseOptions
IF "%1"=="-vc" (
  IF "%2" NEQ "" (
    SET "OPNET_VCVER=%~2"
  )
  SHIFT /1
  SHIFT /1
) ELSE IF "%1"=="-p" (
  IF "%2" NEQ "" (
    SET "OPNET_PLATFORM=%~2"
  )
  SHIFT /1
  SHIFT /1
) ELSE IF "%1"=="-op" (
  IF "%2" NEQ "" (
    SET "OPNET_RELEASE=%~2"
  )
  SHIFT /1
  SHIFT /1
) ELSE IF "%1"=="-home" (
  IF EXIST "%~2" (
    SET "OPNET_USER_HOME=%~2"
  ) ELSE (
    ECHO '-home' specifies a non-existing directory!
    EXIT /B 1
  )
  SHIFT /1
  SHIFT /1
) ELSE IF "%1"=="-gui" (
  SET OPNET_GUI=1
  SHIFT /1
) ELSE (
  EXIT /B
)
GOTO :ParseOptions
:: ============ ParseOptions End ============


:: ============ GetPc End ============
:GetPc
IF "%OPNET_PLATFORM%"=="x64" (
  SET OPNET_PC=amd_win64
) ELSE IF "%OPNET_PLATFORM%"=="amd64" (
  SET OPNET_PC=amd_win64
) ELSE IF "%OPNET_PLATFORM%"=="x86_x64" (
  SET OPNET_PC=amd_win64
) ELSE IF "%OPNET_PLATFORM%"=="x86_amd64" (
  SET OPNET_PC=amd_win64
)
EXIT /B
:: ============ GetPc End ============
