@echo off
setlocal enabledelayedexpansion
set /a count=1
for %%i in (*.jpg) do (
    echo %%i 
    :: 生产随机命名文件
    :: ren "%%i" "%RANDOM%-!count!.jpg"
    :: 生成顺序连续的文件名
    ren "%%i" "!count!.jpg"
    set /a count+=1
)
pause