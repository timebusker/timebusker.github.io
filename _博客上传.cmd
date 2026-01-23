color 0a
@echo off & setlocal
:: cd img/top-photo/
:: call 0-rename-jpg.bat
:: cd ..

set var="submit_blog_document"
set d=%date:~0,10%
set t=%time:~0,8%
git add .
git commit -am "更新博客"

:: git push origin master
git push -u --force origin master