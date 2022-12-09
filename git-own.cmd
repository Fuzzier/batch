@ECHO OFF

NET FILE 2>NUL 1>NUL
IF ERRORLEVEL 1 (
  CALL sudow %*
  EXIT /B
)

CALL :Takeown %CD%
PAUSE
EXIT /B

:Scan
FOR /F "delims=" %%d in ('DIR /B /AD') DO (
  CALL :Takeown "%%~d"
)
EXIT /B

:Takeown
CALL Envvar :EnvvarPathWin CDIR "%~1"
IF EXIST "%CDIR%\HEAD" (
  TAKEOWN /F "%CDIR%"
  EXIT /B
) ELSE IF EXIST "%CDIR%\.git" (
  TAKEOWN /F "%CDIR%" & TAKEOWN /F "%CDIR%\.git"
  EXIT /B
) ELSE (
  PUSHD "%CDIR%"
  CALL :Scan
  POPD
)
EXIT /B
