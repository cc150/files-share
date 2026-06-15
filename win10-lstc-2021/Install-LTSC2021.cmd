@echo off
setlocal EnableDelayedExpansion

rem ============================================
rem One-click installer for Windows 10 LTSC 2021
rem Downloads VCLibs Appx from static site (Cloudflare Pages) and installs automatically
rem
rem Usage: Right-click ^> "Run as administrator"
rem Download source: https://istudy.cc.cd/win10-lstc-2021/
rem ============================================

set "SITE_URL=https://istudy.cc.cd/win10-lstc-2021/"
set "SCRIPT_DIR=%~dp0"

echo.
echo ============================================================
echo   Windows 10 LTSC 2021 一键安装包
echo   Source: %SITE_URL%
echo ============================================================
echo.

rem --- Check admin rights ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] 请以管理员身份运行！
    echo.
    echo 右键此脚本 -> "以管理员身份运行"
    echo.
    pause
    exit /b 1
)

rem --- Detect architecture ---
if /i "%PROCESSOR_ARCHITECTURE%" equ "AMD64" (set "arch=x64") else (set "arch=x86")
echo [+] 检测到系统架构: %arch%
echo.

rem --- Appx file names ---
set "FILE_X64=Microsoft.VCLibs.140.00_14.0.30704.0_x64__8wekyb3d8bbwe.Appx"
set "FILE_X86=Microsoft.VCLibs.140.00_14.0.30704.0_x86__8wekyb3d8bbwe.Appx"
set "URL_X64=%SITE_URL%%FILE_X64%"
set "URL_X86=%SITE_URL%%FILE_X86%"

rem --- Download with fallback chain: BITS -> PowerShell -> manual ---
call :download "%URL_X64%" "%FILE_X64%" "x64" || goto :download_x86_failed
call :download "%URL_X86%" "%FILE_X86%" "x86" || goto :download_x86_failed

echo.
echo [+] 下载完成，开始安装...
echo.

rem --- Check if already installed ---
set "need_x64=1"
set "need_x86=1"

set "arch_lower=%arch%"
set "arch_lower=%arch_lower:X64=x64%"
set "arch_lower=%arch_lower:X86=x86%"

for /f "delims=" %%i in ('powershell -NoLogo -NoProfile -NonInteractive ^
    "try { $p = (Get-AppxPackage *VCLibs* | Where {$_.Architecture -eq '%arch_lower%'}); if($p) { Write-Output 'installed' } } catch {}"') do (
    if /i "%%i"=="installed" (
        set "need_x64=0"
        set "need_x86=0"
    )
)

if !need_x64! equ 0 (
    echo [*] VCLibs %arch% 已安装，跳过。
)
echo.

rem --- Install x64 ---
if exist "%SCRIPT_DIR%%FILE_X64%" (
    if !need_x64! equ 1 (
        echo [+] 正在安装 x64 包...
        add-appxpackage "%SCRIPT_DIR%%FILE_X64%" 2>&1 | findstr /i "install" || echo     (安装过程可能有警告，属正常现象)
    ) else (
        echo [*] 跳过 x64 安装。
    )
) else (
    echo [WARN] x64 Appx 文件未找到: %SCRIPT_DIR%%FILE_X64%
)

rem --- Install x86 ---
if exist "%SCRIPT_DIR%%FILE_X86%" (
    if !need_x86! equ 1 (
        echo [+] 正在安装 x86 包...
        add-appxpackage "%SCRIPT_DIR%%FILE_X86%" 2>&1 | findstr /i "install" || echo     (安装过程可能有警告，属正常现象)
    ) else (
        echo [*] 跳过 x86 安装。
    )
    echo.
)

echo.
echo ============================================================
echo   安装完成！
echo ============================================================
echo.
pause
exit /b 0

rem ============================================
rem Download function: BITS -> PowerShell WebRequest -> curl -> fail
rem Usage: call :download <URL> <FILENAME> <LABEL>
rem ============================================
:download
set "_url=%~1"
set "_file=%~2"
set "_label=%~3"
set "_path=%SCRIPT_DIR%%_file%"
set "_ret=0"

echo [*] 下载 %_label% 包...

rem Try 1: BITS (built-in Windows downloader, supports resume)
bitsadmin /transfer "VCLibs_%_label%" /priority normal "%_url%" "%_path%" >nul 2>&1
if errorlevel 1 set "_ret=1"

if !_ret! equ 0 (
    echo [OK] %_label% 包下载完成 (BITS)
    exit /b 0
)

rem Try 2: PowerShell Invoke-WebRequest
echo     BITS 失败，尝试 PowerShell...
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass ^
    "try { Invoke-WebRequest -Uri '%_url%' -OutFile '%_path%'; exit 0 } catch { exit 1 }" 2>nul
if errorlevel 1 set "_ret=1"

if !_ret! equ 0 (
    echo [OK] %_label% 包下载完成 (PowerShell)
    exit /b 0
)

rem Try 3: curl (Windows 10 17063+)
echo     PowerShell 失败，尝试 curl...
curl -sL --output "%_path%" "%_url%" 2>nul
if not exist "%_path%" set "_ret=1"

if !_ret! equ 0 (
    echo [OK] %_label% 包下载完成 (curl)
    exit /b 0
)

echo [FAIL] %_label% 包下载失败！
echo.
echo  请手动下载:
echo     %_url%
echo     保存到: %_path%
echo.
exit /b 1

:download_x86_failed
echo.
echo [*] 继续尝试安装 x86 包...
if exist "%SCRIPT_DIR%%FILE_X86%" (
    echo [+] 正在安装 x86 包...
    add-appxpackage "%SCRIPT_DIR%%FILE_X86%"
) else (
    echo [FAIL] x86 Appx 文件也未找到。
    echo.
    echo  请手动下载:
    echo     %URL_X86%
    echo.
)
echo.
echo ============================================================
echo   部分安装完成（仅 x64）
echo ============================================================
pause
exit /b 0
