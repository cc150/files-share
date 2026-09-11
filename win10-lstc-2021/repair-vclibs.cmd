@echo off
REM 适用于x64位系统 32位系统将对应的包替换为x86即可

setlocal EnableDelayedExpansion

set "URL=http://files.istudy.cc.cd//win10-lstc-2021/Microsoft.VCLibs.140.00_14.0.30704.0_x64__8wekyb3d8bbwe.Appx"
set "FILE_NAME=Microsoft.VCLibs.140.00_14.0.30704.0_x64__8wekyb3d8bbwe.Appx"
set "FILE=%~dp0%FILE_NAME%"
set "EXPECTED_HASH=009f7db134c6061fe8f260e075374a28abbbc44e6cf23de107f93ec8b8c59816"

echo =====================================
echo  下载并安装 VCLibs x64
echo  来源: %URL%
echo =====================================
echo.

rem --- 1. 先检查是否已安装（已安装则无需下载）---
echo [*] 检查是否已安装...
set installed=0
for /f "delims=" %%i in ('powershell -NoLogo -NoProfile -NonInteractive "try { $p = Get-AppxPackage *VCLibs* | Where { $_.Architecture -eq 'x64' }; if ($p) { Write-Output 'yes' } } catch {}"') do (
    if /i "%%i"=="yes" set installed=1
)

if !installed! equ 1 (
    echo [OK] VCLibs x64 已安装，跳过下载与安装！
    goto :END
)

rem --- 2. 执行下载 ---
echo 正在下载依赖包...
curl -sLf -o "%FILE%" "%URL%"

rem --- 3. 基础下载校验 ---
if %errorlevel% neq 0 (
    echo [失败] 下载网络出错，错误码：%errorlevel%
    goto :FAIL
)

if not exist "%FILE%" (
    echo [失败] 下载文件未生成！
    goto :FAIL
)

for %%A in ("%FILE%") do set "FILE_SIZE=%%~zA"
if !FILE_SIZE! equ 0 (
    echo [失败] 下载的文件为空文件 (0 字节)！
    del /f /q "%FILE%" >nul 2>&1
    goto :FAIL
)

echo [成功] 文件已成功下载，大小为 !FILE_SIZE! 字节。

rem --- 4. SHA256 完整性校验 ---
echo [*] 正在校验 SHA256 哈希值...
set "ACTUAL_HASH="
for /f "delims=" %%h in ('powershell -NoLogo -NoProfile -NonInteractive "(Get-FileHash -Path '%FILE%' -Algorithm SHA256).Hash"') do (
    set "ACTUAL_HASH=%%h"
)

if /i "!ACTUAL_HASH!"=="%EXPECTED_HASH%" (
    echo [成功] SHA256 校验匹配成功！
) else (
    echo [失败] SHA256 校验不匹配，文件可能损坏或被篡改！
    echo        预期: %EXPECTED_HASH%
    echo        实际: !ACTUAL_HASH!
    del /f /q "%FILE%" >nul 2>&1
    goto :FAIL
)
echo.

rem --- 5. 开始安装 ---
echo [*] 正在安装...
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass "Add-AppxPackage -Path '%FILE%' -Verbose"

if !errorlevel! equ 0 (
    echo [OK] 安装成功！
) else (
    echo [FAIL] 安装失败！
)
goto :END

:FAIL
echo.
echo [错误] 因文件未完整下载或校验失败，已终止安装流程。

:END
echo.
echo =====================================
echo  完成！
echo =====================================
echo.

pause
