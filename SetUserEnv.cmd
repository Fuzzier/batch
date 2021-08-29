@ECHO OFF

REM %TARGET%
REM * x86, x64, arm, arm64

REM %ProgramFile%
REM %ProgramFile(x86)%

:: Setup environment for other tools
IF "%TARGET%"=="x64" (
  CALL Envvar :EnvvarAddPath "PATH"    "%ProgramFiles%\Polyspace\R2020b\bin\win64"
  CALL Envvar :EnvvarAddPath "PATH"    "%ProgramFiles%\Polyspace\R2020b\extern\bin\win64"

  CALL Envvar :EnvvarAddPath "INCLUDE" "%ProgramFiles%\Polyspace\R2020b\extern\include"

  CALL Envvar :EnvvarAddPath "LIB"     "%ProgramFiles%\Polyspace\R2020b\extern\lib\win64\microsoft"
)

EXIT /B 0
