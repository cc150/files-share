@echo off
:: 强制将当前 CMD 窗口切换为 UTF-8 编码
REM 适用于x64位系统 32位系统将对应的包替换为x86即可
chcp 65001 >nul
setlocal EnableDelayedExpansion

set "URL=https://files.istudy.cc.cd//win10-lstc-2021/Microsoft.VCLibs.140.00_14.0.30704.0_x64__8wekyb3d8bbwe.Appx"
set "FILE_NAME=Microsoft.VCLibs.140.00_14.0.30704.0_x64__8wekyb3d8bbwe.Appx"
set "MIN_VERSION=14.0.30704.0"
set "FILE=%~dp0%FILE_NAME%"

echo =====================================
echo  安装 VCLibs x64 依赖包
echo =====================================
echo.

rem --- 第一步：先检测是否已安装满足版本要求 ---
echo [*] 检查是否已安装...
set "installed=0"
for /f "delims=" %%i in ('powershell -NoLogo -NoProfile -NonInteractive -Command ^
    "try { $p = Get-AppxPackage *VCLibs* | Where-Object { $_.Architecture -eq 'x64' -and [version]$_.Version -ge [version]'%MIN_VERSION%' }; if ($p) { Write-Output 'yes' } } catch {}"') do (
    if /i "%%i"=="yes" set "installed=1"
)

if !installed! equ 1 (
    echo [OK] 已安装满足要求的 VCLibs x64（版本 ^>= %MIN_VERSION%），跳过下载与安装。
    goto :end
)

echo [*] 未检测到满足版本要求的 VCLibs，准备下载...
echo.

rem --- 第二步：下载文件（-f 遇到 HTTP 错误码会失败，避免把错误页当成功） ---
echo 正在下载依赖包...
echo 来源: %URL%
curl -fL --connect-timeout 10 --max-time 120 -o "%FILE%" "%URL%"

if not %errorlevel% equ 0 (
    echo [失败] 下载出错，错误码：%errorlevel%
    goto :end
)

rem --- 检查文件是否存在且非空 ---
if not exist "%FILE%" (
    echo [失败] 未找到下载后的文件，安装终止。
    goto :end
)
for %%A in ("%FILE%") do set "FILE_SIZE=%%~zA"
if !FILE_SIZE! lss 1024 (
    echo [失败] 下载的文件过小（%FILE_SIZE% 字节），可能不完整或下载源返回了错误页面，安装终止。
    del /q "%FILE%" >nul 2>&1
    goto :end
)

echo [成功] 文件已下载到脚本同级目录下（大小: !FILE_SIZE! 字节）
echo.

rem --- 第三步：安装 ---
echo [*] 正在安装...
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "Add-AppxPackage -Path '%FILE%' -Verbose"

if !errorlevel! equ 0 (
    echo [OK] 安装成功！

    rem --- 可选：安装成功后清理下载的安装包 ---
    rem 如需自动删除，取消下面两行的注释
    rem del /q "%FILE%" >nul 2>&1
    rem echo [*] 已清理安装包文件。
) else (
    echo [FAIL] 安装失败！错误码：!errorlevel!
    echo 可能原因：系统未启用"开发者模式"或"旁加载应用"权限，或该包与系统架构不匹配。
)

:end
echo.
echo =====================================
echo  完成！
echo =====================================
echo.

pause
