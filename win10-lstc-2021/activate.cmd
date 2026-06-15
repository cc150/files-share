@echo off
chcp 65001 >nul
rem ---激活 win10 lstc 2021 ---
rem ---需要管理员身份运行 ---
rem ---将 kms.03k.org替换为自己信任的kms服务器---
slmgr /skms kms.03k.org
slmgr /ato
pause