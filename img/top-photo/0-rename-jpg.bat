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
echo �ļ��޸���ϣ�һ���޸���%sum%���ļ�����