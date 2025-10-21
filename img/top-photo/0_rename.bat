@echo off
setlocal enabledelayedexpansion
set /a count=1
for %%i in (*.jpg) do (
    echo %%i 
    :: 带0补位
    :: ren "%%i" "0!count!.jpg"
    :: 不带0补位
    ren "%%i" "!count!.jpg"
    set /a count+=1
)
pause