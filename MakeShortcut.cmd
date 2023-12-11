@ECHO OFF

IF "%~1"=="" (
  ECHO Drop executable onto the batch script.
  PAUSE
  EXIT /B
)

CALL MakeLink :MakeShortcut "%USERPROFILE%\Desktop\%~nx1" "%~f1"

EXIT /B
