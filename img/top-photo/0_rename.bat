@echo off
setlocal enabledelayedexpansion
set /a count=1
for %%i in (*.jpg) do (
    :: 带0补位
    :: set "filename=000!count!"
    :: ren "%%i" "!filename~-3!.jpg"
	:: 不带0补位
	set "filename=!count!"
    ren "%%i" "!filename!.jpg"
    set /a count+=1
)
pause