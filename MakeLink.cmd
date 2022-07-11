@ECHO OFF

REM ===========================================================
REM @file
REM
REM @brief Make symbolic link.
REM
REM @version 1.0
REM @author  Wei Tang <gauchyler@uestc.edu.cn>
REM @date    2020-06-03
REM
REM @copyright Copyright (c) 2020.
REM   National Key Laboratory of Science and Technology on Communications,
REM   University of Electronic Science and Technology of China.
REM   All rights reserved.
REM ===========================================================

:: @brief Invoke a subroutine in this script.
:: @param %1 The name of the subroutine in this script.
::           For example, :MakeJunction
:: @param %2 The additional argument.
:: @param %3 The additional argument.
:: @param %4 The additional argument.
:: @param %5 The additional argument.
:: @param %6 The additional argument.
:: @param %7 The additional argument.
:: @param %8 The additional argument.
:: @param %9 The additional argument.
IF "%~1" NEQ "" (
  CALL %1 %2 %3 %4 %5 %6 %7 %8 %9
)
EXIT /B

EXIT /B

:MakeJunction
SET DST=%~1
SET SRC=%~2
IF EXIST "%DST%" (
    RD "%DST%" /S /Q
)
MKLINK /J "%DST%" "%SRC%"
EXIT /B

:MakeHardlink
SET DST=%~1
SET SRC=%~2
IF EXIST "%DST%" (
    DEL "%DST%" /F /Q
)
MKLINK /H "%DST%" "%SRC%"
EXIT /B

:MakeSymboliclink
SET DST=%~1
SET SRC=%~2
IF EXIST "%DST%" (
    DEL "%DST%" /F /Q
)
MKLINK "%DST%" "%SRC%"
EXIT /B
