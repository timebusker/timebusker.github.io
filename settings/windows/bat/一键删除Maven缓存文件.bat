@echo off 
color 0a
title 删除当前文件(含子文件夹)里类型文件
echo 正在搜索...
for /f "delims=" %%i in ('dir /b /a-d /s "*.pom.md5"') do del /s %%i
for /f "delims=" %%i in ('dir /b /a-d /s "*.pom.sha1"') do del /s %%i
for /f "delims=" %%i in ('dir /b /a-d /s "*.jar.md5"') do del /s %%i
for /f "delims=" %%i in ('dir /b /a-d /s "*.jar.sha1"') do del /s %%i
for /f "delims=" %%i in ('dir /b /a-d /s "*.pom.lastUpdated"') do del /s %%i
for /f "delims=" %%i in ('dir /b /a-d /s "*.jar.lastUpdated"') do del /s %%i
echo ...
echo ......
echo ..........
:: pause