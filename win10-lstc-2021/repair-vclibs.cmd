@echo off
:: 强制将当前 CMD 窗口切换为 UTF-8 编码
REM 适用于x64位系统 32位系统将对应的包替换为x86即可
chcp 65001 >nul
setlocal EnableDelayedExpansion

set "URL=https://istudy.cc.cd/win10-lstc-2021/Microsoft.VCLibs.140.00_14.0.30704.0_x64__8wekyb3d8bbwe.Appx"
set "FILE_NAME=Microsoft.VCLibs.140.00_14.0.30704.0_x64__8wekyb3d8bbwe.Appx"
set "FILE=%~dp0%FILE_NAME%"
echo =====================================
echo  下载并安装 VCLibs x64
echo  来源: %URL%
echo =====================================
echo.



rem --- 下载文件 ---

echo 正在下载依赖包...
curl -sL -o "%~dp0%FILE_NAME%" "%URL%"

if %errorlevel% equ 0 (
    echo [成功] 文件已下载到脚本同级目录下！
) else (
    echo [失败] 下载出错，错误码：%errorlevel%
)

rem --- 检查是否已安装 ---
echo [*] 检查是否已安装...
set installed=0
for /f "delims=" %%i in ('powershell -NoLogo -NoProfile -NonInteractive "try { $p = Get-AppxPackage *VCLibs* | Where { $_.Architecture -eq 'x64' }; if ($p) { Write-Output 'yes' } } catch {}"') do (
    if /i "%%i"=="yes" set installed=1
)
if !installed! equ 1 (
    echo [OK] VCLibs x64 已安装，跳过
) else (
    echo [*] 正在安装...
    powershell -NoLogo -NoProfile -ExecutionPolicy Bypass "Add-AppxPackage -Path '%FILE%' -Verbose"
    if !errorlevel! equ 0 (
        echo [OK] 安装成功！
    ) else (
        echo [FAIL] 安装失败！
    )
)
echo.

echo =====================================
echo  完成！
echo =====================================
echo.



pause

