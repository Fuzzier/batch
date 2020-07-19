:: :::::::::::::::::::::::::::
:: @brief     Automatically check & obtain admin rights
:: @see <a href="http://stackoverflow.com/users/1016343/matt">Matt</a>
:: @see <a href="http://stackoverflow.com/questions/7044985/how-can-i-auto-elevate-my-batch-file-so-that-it-requests-from-uac-admin-rights">link</a>
:: :::::::::::::::::::::::::::

@ECHO OFF

:: This script use `NET FILE` to check administrator rights.
:: If the administrator rights is not obtained, then
:: * The command line to execute is stored in `_ELEV_CMD_`.
:: * Create a temporary VBS script, the path is stored in `_ELEV_VBS_`.
::   This script uses Windows `Shell` to invoke this script with a single
::   argument `_ELEV_`, with administrator rights.
:: * When administrator rights are obtained, the current environment variables
::   are lost, in order to recall `_ELEV_CMD_`, the environment variables are
::   stored in a temporary batch file `_ELEV_ENV_`.
::   When this script is invoked with administrator rights, and the command line
::   argument is `_ELEV_`, it invokes `_ELEV_CMD_` to recall the environment
::   variables.
::   Then `_ELEV_CMD_` is invoked appropriately.

CALL :TestPriviledges
IF "%~1"=="_TEST_" (
  EXIT /B ERRORLEVEL
)

IF ERRORLEVEL 1 (
  REM Try to run this script as administrator.
  CALL :GetPrivileges %*
) ELSE (
  REM Run this script as administrator.
  CALL :RunAsAdmin %*
)

REM PAUSE
EXIT /B


:: ========= Test Access Right Begin =========
:TestPriviledges
NET FILE 1>NUL 2>NUL
EXIT /B %ERRORLEVEL%
:: ========= Test Access Right End =========


:: ========= Elevate Access Right Begin =========
:GetPrivileges
ECHO Require administrator privileges, try to obtain...

SET "_ELEV_VBS_=%TEMP%\_Elev_.vbs"
SET "_ELEV_ENV_=%TEMP%\_Elev_.cmd"

REM Save current directory.
FOR /F "delims=" %%d IN ('CD') DO (
  ECHO SET "_ELEV_DIR_=%%~d" >  "%_ELEV_ENV_%"
)

CALL :SaveCommand %*

:: Create a temporary script.
ECHO Set UAC=CreateObject^("Shell.Application"^) > "%_ELEV_VBS_%"
:: ShellExecute
:: @param[in] sFile
:: @param[in] vArguments
:: @param[in] vDirectory
:: @param[in] vOperation  "runas": run as administrator.
:: @param[in] vShow       1: run in a normal window.
ECHO UAC.ShellExecute "%~nx0", "_ELEV_", "%_ELEV_DIR_%", "runas", 1 >> "%_ELEV_VBS_%"

:: Invoke the script.
"%_ELEV_VBS_%"

CALL :Clean

EXIT /B
:: ========= Elevate Access Right End =========


:: ========= SaveCommand Begin =========
:SaveCommand
SHIFT /0
REM Save command line arguments (double quotes are preserved:).
IF "%~0"=="" (
  REM If this script is run without arguments, start a console by default.
  ECHO SET _ELEV_CMD_=cmd >> "%_ELEV_ENV_%"
) ELSE (
  CALL :IsBatch %0
  IF ERRORLEVEL 1 (
    REM `CALL` is required to invoke a batch file.
    ECHO SET _ELEV_CMD_=CALL %* >> "%_ELEV_ENV_%"
  ) ELSE (
    ECHO SET _ELEV_CMD_=%* >> "%_ELEV_ENV_%"
  )
)
EXIT /B
:: ========= SaveCommand End =========


:: ========= RunAsAdmin Begin =========
:RunAsAdmin
IF "%~1"=="_ELEV_" (
  CALL :Delegate
) ELSE (
  %*
)
EXIT /B
:: ========= RunAsAdmin End =========


:: ========= IsBatch Begin =========
:IsBatch
IF "%~x1"==".cmd" ( EXIT /B 1 )
IF "%~x1"==".bat" ( EXIT /B 1 )
EXIT /B 0
:: ========= IsBatch End =========


:: ========= Do work Begin =========
:Delegate
SET "_ELEV_VBS_=%TEMP%\_Elev_.vbs"
SET "_ELEV_ENV_=%TEMP%\_Elev_.cmd"
REM Restore environment variables.
CALL "%_ELEV_ENV_%"
REM Restore current directory.
CD /D "%_ELEV_DIR_%"
REM Delete temporary files.
DEL /Q "%_ELEV_ENV_%"
DEL /Q "%_ELEV_VBS_%"
REM Invoke command.
%_ELEV_CMD_%
CALL :Clean
EXIT /B
:: ========= Do work End =========


:: ========= Clean Start =========
:Clean
REM Clear environment variables.
SET "_ELEV_VBS_="
SET "_ELEV_ENV_="
SET "_ELEV_DIR_="
SET "_ELEV_CMD_="
EXIT /B
:: ========= Clean End =========

