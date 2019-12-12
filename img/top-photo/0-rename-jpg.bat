@echo off
setlocal enabledelayedexpansion
d:
set extension=.jpg
set /a sum=100
for %%m in (*.jpg) do (
ren %%m !sum!%extension%
:: echo %%m 
::echo !sum!%extension%
set /a sum=sum+1
)
set /a sum=1
for %%m in (*.jpg*) do (
ren %%m !sum!%extension%
:: echo %%m 
:: echo !sum!%extension%
set /a sum=sum+1
)
set /a sum=sum-1
echo 文件修改完毕，一共修改了%sum%个文件名！