@ECHO OFF

REM ===========================================================
REM @file
REM
REM @brief Make symbolic link.
REM
REM @version 1.0
REM @author  Wei Tang <gauchyler@uestc.edu.cn>
REM @date    2021-08-29
REM
REM @copyright Copyright (c) 2021.
REM   National Key Laboratory of Science and Technology on Communications,
REM   University of Electronic Science and Technology of China.
REM   All rights reserved.
REM ===========================================================

SET USER_PLATFORM=%~1

:: Setup environment for other tools
IF "%USER_PLATFORM%"=="x64" (
  ECHO Set environment for MATLAB x64.
  CALL Envvar :EnvvarPathAppend "PATH"    "%ProgramFiles%\MATLAB\R2021b\bin\win64"
  CALL Envvar :EnvvarPathAppend "PATH"    "%ProgramFiles%\MATLAB\R2021b\extern\bin\win64"
  CALL Envvar :EnvvarPathAppend "INCLUDE" "%ProgramFiles%\MATLAB\R2021b\extern\include"
  CALL Envvar :EnvvarPathAppend "LIB"     "%ProgramFiles%\MATLAB\R2021b\extern\lib\win64\microsoft"
)

SET USER_PLATFORM=

EXIT /B 0
