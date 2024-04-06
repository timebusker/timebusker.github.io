@echo off
setlocal enabledelayedexpansion
set /a count=1
for %%i in (*.jpg) do (
    set "filename=!count!"
    ren "%%i" "!filename!.jpg"
    set /a count+=1
)
pause