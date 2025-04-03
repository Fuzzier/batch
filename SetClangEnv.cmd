@ECHO OFF

REM ===========================================================
REM @file
REM
REM @brief Set up environment for LLVM/Clang toolchain.
REM
REM @author  Wei Tang <gauchyler@uestc.edu.cn>
REM @date    20250403
REM
REM @copyright Copyright (c) 2025.
REM   National Key Laboratory of Science and Technology on Communications,
REM   University of Electronic Science and Technology of China.
REM   All rights reserved.
REM ===========================================================

SET __clang_root__=D:\Development\Tools\pub\LLVM
SET __cmake_root__=D:\Documents\CMake

FOR %%i IN (clang.exe) DO (
    SET __found_clang__=%%~$PATH:i
)

FOR %%i IN (clang_rt.asan_dynamic-x86_64.dll) DO (
    SET __found_clang_lib__=%%~$PATH:i
)

IF DEFINED __found_clang__ (
    IF DEFINED __found_clang_lib__ (
        ECHO LLVM/Clang environment has already been set.
        GOTO :Exit
    )
)

IF NOT DEFINED __found_clang__ (
    ECHO Add path:  %__clang_root__%\bin
    CALL Envvar :EnvvarPathAppend "PATH"    "%__clang_root__%\bin"
)

FOR /F "delims=." %%i IN ('llvm-config.exe --version') DO (
    SET __clang_ver__=%%i
)
IF NOT DEFINED __found_clang_lib__ (
    ECHO Add path: %__clang_root__%\lib\clang\%__clang_ver__%\lib\windows
    CALL Envvar :EnvvarPathAppend "PATH"    "%__clang_root__%\lib\clang\%__clang_ver__%\lib\windows"
)

FOR %%i IN (cmake.exe) DO (
    SET __found_cmake__=%%~$PATH:i
)
IF NOT DEFINED __found_cmake__ (
    ECHO Add path: %__cmake_root__%\bin
    CALL Envvar :EnvvarPathAppend "PATH"    "%__cmake_root__%\bin"
)

:Exit
SET __found_clang__=
SET __found_clang_lib__=
SET __clang_ver__=
SET __found_cmake__=

EXIT /B
