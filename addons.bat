@echo off

:: ANSI ESCAPE CHARACTER:  Here for copy/paste use for any of the echo commands

::Probably will replace with a python script instead

echo %1

if "%1"=="init" goto init
if "%1"=="reinit" goto init
if "%1"=="clean" goto clean

goto init

:clean

echo Cleaning files...

del /s /q ".temp"
del /s /q addons

echo Done.

exit /b

:init

:: Dialogic
echo Cloning [96mDialogic[0m...

git clone https://github.com/coppolaemilio/dialogic ".temp\dialogic"

echo Copying files...
xcopy ".temp\dialogic\addons\dialogic\" addons\dialogic /i /s

::insert any others here

echo Done.