@ECHO OFF

REM ===========================================================
REM @file
REM
REM @brief Set up environment for VC toolchain.
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

IF "%1"=="/?" (
  CALL :ShowHelp "%~nx0"
  EXIT /B
)

:: State check
cl.exe >NUL 2>NUL
IF %ERRORLEVEL% EQU 0 (
    ECHO MSVC environment has already been set.
    EXIT /B
)

:: VCREL: the relative path of VC build tools.
SET "VCREL=VC"
:: VCVER: the VC version (not VS version).
SET "VCVER="

:: Check VS Version
  SET "VSVER=%~1"
       IF "%~1"=="10" (
  SET "VS_VER_YEAR=2010"
  SET "VCVER=10.0"
  ECHO.
) ELSE IF "%~1"=="11" (
  SET "VS_VER_YEAR=2012"
  SET "VCVER=11.0"
  ECHO.
) ELSE IF "%~1"=="12" (
  SET "VS_VER_YEAR=2013"
  SET "VCVER=12.0"
  ECHO.
) ELSE IF "%~1"=="14" (
  SET "VS_VER_YEAR=2015"
  SET "VCVER=14.0"
  ECHO.
) ELSE IF "%~1"=="15" (
  SET "VS_VER_YEAR=2017"
  SET "VCVER=14.1"
  SET "VCREL=VC\Auxiliary\Build"
  ECHO.
) ELSE IF "%~1"=="16" (
  SET "VS_VER_YEAR=2019"
  SET "VCVER=14.2"
  SET "VCREL=VC\Auxiliary\Build"
  ECHO.
) ELSE IF "%~1"=="17" (
  SET "VS_VER_YEAR=2022"
  SET "VCVER=14.3"
  SET "VCREL=VC\Auxiliary\Build"
  ECHO.
)

:: Call vcvarsall.bat to obtain %VCVARSPATH%.
SET VSVER=%VSVER%
SET /A VSVERNEXT=VSVER+1
SET "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
SET "USEVCVER=0"
SET "VSPATH="
SET "VCVARSPATH="
IF "%VSVER%"=="" (
  CALL :GuessVcVarsPath
) ELSE (
  CALL :GetVcVarsPath
)
IF "%VCVARSPATH%"=="" (
  ECHO Cannot locate VC!
  CALL :Clean
  EXIT /B
)

:: Check Platform
:: Defaults to x64
  SET "PLATFORM=%~2"
       IF "%~2"=="" (
  SET PLATFORM=x64
  SET TARGET=x64
) ELSE IF "%~2"=="x86" (
  SET TARGET=x86
  ECHO.
) ELSE IF "%~2"=="x86_amd64" (
  SET PLATFORM=x86_x64
  SET TARGET=x64
  ECHO.
) ELSE IF "%~2"=="x86_x64" (
  SET TARGET=x64
  ECHO.
) ELSE IF "%~2"=="x86_arm" (
  SET TARGET=arm
  ECHO.
) ELSE IF "%~2"=="x86_arm64" (
  SET TARGET=arm64
  ECHO.
) ELSE IF "%~2"=="amd64" (
  SET PLATFORM=x64
  SET TARGET=x64
  ECHO.
) ELSE IF "%~2"=="amd64_x86" (
  SET PLATFORM=x64_x86
  SET TARGET=x86
  ECHO.
) ELSE IF "%~2"=="amd64_arm" (
  SET PLATFORM=x64_arm
  SET TARGET=arm
  ECHO.
) ELSE IF "%~2"=="amd64_arm64" (
  SET PLATFORM=x64_arm64
  SET TARGET=arm64
  ECHO.
) ELSE IF "%~2"=="x64" (
  SET TARGET=x64
  ECHO.
) ELSE IF "%~2"=="x64_x86" (
  SET TARGET=x86
  ECHO.
) ELSE IF "%~2"=="x64_arm" (
  SET TARGET=arm
  ECHO.
) ELSE IF "%~2"=="x64_arm64" (
  SET TARGET=arm64
  ECHO.
) ELSE (
  ECHO Invalid platform!
  CALL :ShowHelp "%~nx0"
  CALL :Clean
  EXIT /B
)


PUSHD .
:: Setup VC build environment
CALL :SetVcVars
POPD

:: Execute cl.exe to obtain the major and minor version.
:: VC_VER_STRING   (e.g., 16.00.40219.01)
:: VC_VER_MAJOR    (e.g., 16)
:: VC_VER_MINOR    (e.g., 00)
:: VC_VER_BUILD    (e.g., 40219)
:: VC_VER_REVISION (e.g., 01)        same as the predefined macro _MSC_BUILD
:: VC_VER_STD      (e.g., 1600)      same as the predefined macro _MSC_VER
:: VC_VER_FULL     (e.g., 160040219) same as the predefined macro _MSC_FULL_VER
CALL :QueryVcVersion

: Execute wmic.exe to obtain the operating system information.
:: OS_CAPTION (e.g., Microsoft Windows 10 Professional)
:: OS_VER     (e.g., 10.0.18363)
:: OS_BUILD   (e.g., 18363)
:: OS_ARCH    (e.g., 64-bit)
CALL :QueryOsInfo

CALL :Clean
EXIT /B 0


:: ============ Clean Begin ============
:Clean
SET VSVER=
SET VSVERNEXT=
SET VS_VER_YEAR=
SET VCREL=
SET VCVER=
SET USEVCVER=
SET VSWHERE=
SET VSPATH=
SET VCVARSPATH=
SET PLATFORM=
SET TARGET=
EXIT /B
:: ============ Clean End ============


:: ============ ShowHelp Begin ============
:ShowHelp
ECHO Usage: %~1 ^<VSVER^> ^[platform^]
ECHO   VSVER:
ECHO     10        Visual C++ 2010
ECHO     11        Visual C++ 2012
ECHO     12        Visual C++ 2013
ECHO     14        Visual C++ 2015
ECHO     15        Visual C++ 2017
ECHO     16        Visual C++ 2019
ECHO     17        Visual C++ 2022
ECHO   platform:
ECHO     x86
ECHO     x86_amd64
ECHO     x86_x64
ECHO     x86_arm
ECHO     x86_arm64
ECHO     amd64
ECHO     amd64_x86
ECHO     amd64_arm
ECHO     amd64_arm64
ECHO     x64         (default)
ECHO     x64_x86
ECHO     x64_arm
ECHO     x64_arm64
EXIT /B
:: ============ ShowHelp End ============


:: ============ GetProgramFile Begin ============
:: @brief Set WOW6432Node and ProgramFiles(x86) for 32-bit OS.
:: @param[out]  %WOW6432Node%, %ProgramFiles(x86)%
:GetProgramFile
REG QUERY "HKLM\HARDWARE\DESCRIPTION\System\CentralProcessor\0" /v "Identifier" | FIND /I "x86" > NUL
IF ERRORLEVEL 1 (
  SET "WOW6432Node=WOW6432Node\"
) ELSE (
  SET "ProgramFiles(x86)=%ProgramFiles%"
  SET "WOW6432Node="
)
EXIT /B
:: ============ GetProgramFile End ============


:: ============ GuessVcVarsPath Begin ============
:: @param[in]  %VSWHERE%    The path to "vswhere.exe".
:: @param[out] %VSPATH%     The installation path of VS.
:: @param[out] %VCVARSPATH% The path to "vcvarsall.bat".
:GuessVcVarsPath
  CALL :GetProgramFile
  CALL :GuessVcVarsPathVsWhere
  IF "%VSPATH%"=="" (
    CALL :GuessVcVarsPathReg
  )
  IF NOT "%VSPATH%"=="" (
    SET "VCVARSPATH=%VSPATH%%VCREL%"
  )
EXIT /B
:: ============ GuessVcVarsPath End ============


:: ============ GuessVcVarsPathVsWhere Begin ============
:: @param[in]  %VSWHERE%    The path to "vswhere.exe".
:: @param[out] %VSPATH%     The installation path of VS.
:: @param[out] %VCVARSPATH% The path to "vcvarsall.bat".
:GuessVcVarsPathVsWhere
  REM Query 'vswhere.exe' for the lastest version.
  SET "VSVER=15"
  SET "VCREL=VC\Auxiliary\Build"
  CALL :GetVcVarsPathVswhereLatest
EXIT /B
:: ============ GuessVcVarsPathVsWhere End ============


:: ============ GuessVcVarsPathReg Begin ============
:: @param[out] %VSPATH%     The installation path of VS.
:: @param[out] %VCVARSPATH% The path to "vcvarsall.bat".
:GuessVcVarsPathReg
  SET "VCREL=VC"
  FOR /L %%i IN (14,-1,10) DO (
    SET "VSVER=%%i"
    CALL :GuessVcVarsPathReg1
  )
EXIT /B
:: ============ GuessVcVarsPathReg End ============


:: ============ GuessVcVarsPathReg1 Begin ============
:: @param[in]  %VSVER%      The VS major version.
:: @param[in]  %VCREL%      The relative path to VC build tools.
:: @param[out] %VSPATH%     The installation path of VS.
:: @param[out] %VCVARSPATH% The path to "vcvarsall.bat".
:GuessVcVarsPathReg1
  IF "%VSPATH%"=="" (
    CALL :GetVcVarsPathReg
  )
EXIT /B
:: ============ GuessVcVarsPathReg1 End ============


:: ============ GetVcVarsPath Begin ============
:: @param[in]  %VSVER%      The VS major version.
:: @param[in]  %VSVERNEXT%  The next VS major version.
:: @param[in]  %VSWHERE%    The path to "vswhere.exe".
:: @param[in]  %VCREL%      The relative path to VC build tools.
:: @param[out] %VSPATH%     The installation path of VS.
:: @param[out] %VCVARSPATH% The path to "vcvarsall.bat".
:: @param[out] %USEVCVER%   Use "-vcvars_ver=%VCVER%"?
:GetVcVarsPath
  CALL :GetProgramFile
  REM For VS2017+, query via 'vswhere.exe'.
  CALL :GetVcVarsPathVswhere
IF %ERRORLEVEL% EQU 1 (
  REM If not found, try to call the newest vcvarsall.bat with -vcvars_ver=%VCVER%.
  REM For example, users may install vc141 (VC 2017) toolset in VS2019,
  REM so a call to "vcvarsall.bat -vcvars_ver=14.1" will work.
  CALL :GetVcVarsPathVswhereLatest
)
IF %ERRORLEVEL% EQU 0 (
  SET "USEVCVER=1"
) ELSE (
  REM For VS2015-, qeury via the registry.
  CALL :GetVcVarsPathReg
)
IF %ERRORLEVEL% EQU 0 (
  SET "VCVARSPATH=%VSPATH%%VCREL%"
)
EXIT /B
:: ============ GetVcVarsPath End ============


:: ============ GetVcVarsPathVswhere End ============
:: @brief For VS2017+, query via 'vswhere.exe'.
:: @param[in]  %VSVER%     The VS major version.
:: @param[in]  %VSVERNEXT% The next VS major version.
:: @param[in]  %VSWHERE%   The path to "vswhere.exe".
:: @param[in]  %VCREL%     The relative path to VC build tools.
:: @param[out] %VSPATH%    The installation path of VS.
:: @return If found, return 0; otherwise, return 1.
:GetVcVarsPathVswhere
IF %VSVER% GEQ 15 (
  IF EXIST "%VSWHERE%" (
    FOR /F "delims=" %%i IN ('"%VSWHERE%" -version ^[%VSVER%^,%VSVERNEXT%^) -property installationPath') DO (
      IF EXIST "%%~i\%VCREL%\vcvarsall.bat" (
        SET "VSPATH=%%~i\"
        EXIT /B 0
      )
    )
  )
)
EXIT /B 1
:: ============ GetVcVarsPathVswhere End ============


:: ============ GetVcVarsPathVswhereLatest End ============
:: @brief For VS2017+, query the latest version via 'vswhere.exe'.
:: @param[in]  %VSWHERE%  The path to "vswhere.exe".
:: @param[in]  %VCREL%    The relative path to VC build tools.
:: @param[out] %VSPATH%   The installation path of VS.
:: @return If found, return 0; otherwise, return 1.
:GetVcVarsPathVswhereLatest
IF %VSVER% GEQ 15 (
  IF EXIST "%VSWHERE%" (
    FOR /F "delims=" %%i IN ('"%VSWHERE%" -latest -property installationPath') DO (
      IF EXIST "%%~i\%VCREL%\vcvarsall.bat" (
        SET "VSPATH=%%~i\"
        FOR /F "delims=" %%j IN ('"%VSWHERE%" -latest -property catalog_productLineVersion') DO (
            SET "VS_VER_YEAR=%%j"
        )
        EXIT /B 0
      )
    )
  )
)
EXIT /B 1
:: ============ GetVcVarsPathVswhereLatest End ============


:: ============ GetVcVarsPathReg End ============
:: @brief For VS2015-, query via registry.
:: @param[in]  %VSVER%  The VS major version.
:: @param[in]  %VCREL%  The relative path to VC build tools.
:: @param[out] %VSPATH% The installation path of VS.
:: @return If found, return 0; otherwise, return 1.
:GetVcVarsPathReg
IF %VSVER% LEQ 14 (
  FOR /F "tokens=1,2*" %%i IN ('REG QUERY "HKLM\SOFTWARE\%WOW6432Node%Microsoft\VisualStudio\SxS\VS7" /v "%VSVER%.0" 2^>NUL') DO (
    IF "%%i"=="%VSVER%.0" (
      IF EXIST "%%~k%VCREL%\vcvarsall.bat" (
        SET "VSPATH=%%~k"
        EXIT /B 0
      )
    )
  )
)
EXIT /B 1
:: ============ GetVcVarsPathReg End ============


:: ============ SetVcVars Begin ============
:: @brief Call "vcvarsall.bat".
:: @param[in] %VCVARSPATH% The path to "vcvarsall.bat".
:: @param[in] %PLATFORM%   The platform.
:: @param[in] %USEVCVER%   Use "-vcvars_ver=%VCVER%"?
:: @param[in] %VCVER%      The VC version.
:SetVcVars
PUSHD "%VCVARSPATH%"
SET "VCVARSARGS=%PLATFORM%
IF %USEVCVER% EQU 1 (
  SET "VCVARSARGS=%VCVARSARGS% -vcvars_ver=%VCVER%"
)
ECHO.%VCVARSPATH%\
ECHO.call vcvarsall.bat %VCVARSARGS%
:: Prevent sending telemetry, and preserve the console font
:: by not invoking powershell.
SET "VSCMD_SKIP_SENDTELEMETRY=1"
CALL vcvarsall.bat %VCVARSARGS%
SET "VCVARSARGS="
POPD

IF "%VSVER%"=="10" (
  IF EXIST "%ProgramFiles(x86)%\Microsoft SDKs\Windows\v7.1A\Include\Win32.Mak" (
    SET "SDK_INCLUDE_DIR=%ProgramFiles(x86)%\Microsoft SDKs\Windows\v7.1A\Include"
  ) ELSE IF EXIST "%ProgramFiles(x86)%\Microsoft SDKs\Windows\v7.0A\Include\Win32.Mak" (
    SET "SDK_INCLUDE_DIR=%ProgramFiles(x86)%\Microsoft SDKs\Windows\v7.0A\Include"
  )
)
EXIT /B
:: ============ SetVcVars End ============


:: ============ SetupPIL Begin ============
:SetupPIL
@ECHO Setup Environment for library: "%~1"

IF NOT EXIST "%~1" EXIT /B -1
CALL Envvar :EnvvarAddPath "PATH"    "%~1\bin"
CALL Envvar :EnvvarAddPath "INCLUDE" "%~1\include"
CALL Envvar :EnvvarAddPath "LIB"     "%~1\lib"

EXIT /B
:: ============ SetupPIL End ============


:: ============ SetupBoost Begin ============
:SetupBoost
@ECHO Setup Environment for Boost Library: "%~1"

IF NOT EXIST "%~1" EXIT /B -1
CALL Envvar :EnvvarAddPath "PATH"    "%~1\stage\lib"
CALL Envvar :EnvvarAddPath "INCLUDE" "%~1"
CALL Envvar :EnvvarAddPath "LIB"     "%~1\stage\lib"

EXIT /B
:: ============ SetupBoost End ============


:: ============ QueryVcVersion Begin ============
:: Capture and process the command line output of cl.exe.
:: e.g., "Microsoft (R) C/C++ Optimizing Compiler Version ww.xx.yy.zz for x64".
:QueryVcVersion
FOR /F "delims=" %%v IN ('cl.exe 2^>^&1 1^>NUL ^| FINDSTR /C:"Version"') DO (
  CALL :ParseVersionLine "%%~v"
  EXIT /B
)
EXIT /B
:: ============ QueryVcVersion End ============


:: ============ QueryVcVersion Begin ============
:: @param[in] %1 The command line output of cl.exe that contains "Version ww.xx.yy.zz".
:ParseVersionLine
FOR /F "tokens=1*" %%i IN ("%~1") DO (
  CALL :IsVcVersion "%%~i"
  IF ERRORLEVEL 1 (
    IF "%%j" NEQ "" (
      CALL :ParseVersionLine "%%j"
    )
  )
)
EXIT /B
:: ============ QueryVcVersion End ============


:: ============ IsVcVersion Begin ============
:: @param[in] %1 The string that should looks like "ww.xx.yy.zz".
:IsVcVersion
ECHO %~1| FINDSTR /R /C:"^[0-9.]*$" >NUL
IF %ERRORLEVEL% EQU 0 (
  CALL :ParseVcVersion "%~1"
)
EXIT /B
:: ============ IsVcVersion End ============


:: ============ ParseVcVersion Begin ============
:: @param[in] %1 The version string "ww.xx.yy.zz".
:ParseVcVersion
SET VC_VER_STRING=%~1
FOR /F "tokens=1,2,3,4 delims=." %%w IN ("%~1") DO (
  SET VC_VER_MAJOR=%%w
  SET VC_VER_MINOR=%%x
  SET VC_VER_BUILD=%%y
  SET VC_VER_REVISION=%%z
  SET VC_VER_FULL=%%w%%x%%y
  SET VC_VER_STD=%%w%%x
)
EXIT /B
:: ============ ParseVcVersion End ============


:: ============ QueryOsInfo Begin ============
:QueryOsInfo
FOR /F "skip=1 tokens=1,2,3" %%i IN ('WMIC OS GET Caption        ^| FINDSTR /R /C:[0-9A-Za-z.]') DO ( SET "OS_CAPTION=%%i %%j %%k" )
FOR /F "skip=1"              %%i IN ('WMIC OS GET Version        ^| FINDSTR /R /C:[0-9A-Za-z.]') DO ( SET "OS_VER=%%i" )
FOR /F "skip=1"              %%i IN ('WMIC OS GET BuildNumber    ^| FINDSTR /R /C:[0-9A-Za-z.]') DO ( SET "OS_BUILD=%%i" )
FOR /F "skip=1"              %%i IN ('WMIC OS GET OSArchitecture ^| FINDSTR /R /C:[0-9A-Za-z.]') DO ( SET "OS_ARCH=%%i" )
EXIT /B
:: ============ QueryOsInfo End ============
