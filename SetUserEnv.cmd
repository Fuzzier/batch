@ECHO OFF

SET USER_PLATFORM=%~1

:: Setup environment for other tools
IF "%USER_PLATFORM%"=="x64" (
  ECHO Set environment for MATLAB x64.
  CALL Envvar :EnvvarAddPath "PATH"    "%ProgramFiles%\Polyspace\R2020b\bin\win64"
  CALL Envvar :EnvvarAddPath "PATH"    "%ProgramFiles%\Polyspace\R2020b\extern\bin\win64"
  CALL Envvar :EnvvarAddPath "INCLUDE" "%ProgramFiles%\Polyspace\R2020b\extern\include"
  CALL Envvar :EnvvarAddPath "LIB"     "%ProgramFiles%\Polyspace\R2020b\extern\lib\win64\microsoft"
)

SET USER_PLATFORM=

EXIT /B 0
