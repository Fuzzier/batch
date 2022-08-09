@ECHO OFF

:GetDateTime
FOR /F "skip=1 tokens=1-6" %%a in ('wmic Path Win32_LocalTime Get Day^,Hour^,Minute^,Month^,Second^,Year /Format:table') DO (
  SET __day__=0%%a
  SET __hour__=0%%b
  SET __minute__=0%%c
  SET __month__=0%%d
  SET __second__=0%%e
  SET __year__=%%f
  GOTO :GetDateTimeEnd
)
:GetDateTimeEnd
SET __day__=%__day__:~-2%
SET __hour__=%__hour__:~-2%
SET __minute__=%__minute__:~-2%
SET __month__=%__month__:~-2%
SET __second__=%__second__:~-2%

EXIT /B
