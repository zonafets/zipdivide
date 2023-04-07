@rem Created by Stefano Zaglio (Copyright 2023-GPL 3.0)
@echo off
setlocal enabledelayedexpansion
@rem get maxsize from environment
set maxsize=%ZIPMAXSIZEBYTES%
@rem otherwise set the default
if "%maxsize%"=="" set maxsize=32000000
if %maxsize%==0 set maxsize=32000000
set /a maxsizemb=maxsize / 1024 / 1024
set info=true
set zipper="%ProgramFiles%\7-Zip\7z.exe"
set program=%~n0
set program_name=%~nx0
set install="%programfiles%\%program_name%"

set isadmin=0
net session >nul 2>&1
if not %errorlevel% neq 0 set isadmin=1

call :set_msgs

call :setESC
if not exist %install% goto install
if %isadmin%==1 goto install
if "%~1%isadmin%"=="0" goto help
if not exist %zipper% goto err_zipper

@rem remove quotes
set folder="%~dp1%~nx1"
set files="%~dp1%~nx1\*.*"
set file=%~dp1%~nx1
set filenameext=%~nx1
set filename=%~n1
set filepath=%~nf1
set zip="%file%.zip"
set totsize=0
set size=0

if %info%==false goto skip_info
call :msg_yellow "Folder.............: %folder:"=%"
call :msg_yellow "files..............: %files:"=%"
call :msg_yellow "filename...........: %filename:"=%"
call :msg_yellow "filepath...........: %filepath:"=%"
call :msg_yellow "zip................: %zip:"=%"
call :msg_yellow "maxsize............: %maxsize%"
call :msg_yellow "maxsize MB.........: %maxsizemb%MB"

:skip_info
set size=0
call :chk_and_zip %folder%
call :setsize %zip%
if %size% gtr %maxsize% call :divide_zip %zip%
goto end

:chk_and_zip
if exist "%~1\" (call :do_zip "%~1") else set zip="%~1"
goto :eof

:do_zip
echo %msg_delete% "%file%*.zip"
del "%file%*.zip" /q 2>nul
echo %msg_compress% %1
%zipper% a %zip% %1 >nul
if not %errorlevel%==0 goto :err
goto :eof

:setsize
set size=%~z1
goto :eof

:divide_zip
set txt="%temp%\%filename%.txt"
%zipper% l %zip% | findstr /x /r "[0-9][0-9][0-9][0-9].*\....A.*" > %txt%
@rem type %txt%
@rem todo: find a way to sort by size

set volume=1
set vol="%temp%\%filename%-%volume%.txt"
call :msg_yellow "Volume %volume%:"
set totsize=0

for /f "usebackq tokens=1 delims=" %%a in (%txt%) do call :mng_vol "%%a"
call :msg_yellow "%msg_created% %volume% %msg_volumes%"
goto move_files

:mng_vol
@rem non necessary because use of findstr in the caller
set str=%~1
@rem set chk=%str:~10,1%%str:~13,1%%str:~16,1%%str:~24,1%
@rem if not "%chk%"==" ::A" goto exit_mng_itm
set file=%str:~53,255%
set size=%str:~39,12%
if %size% gtr %maxsize% goto err_size
set /a totsize+=size
set inside=false
if %totsize%==%maxsize% set inside=true
if %totsize% lss %maxsize% set inside=true
if %inside%==true echo %file%>>%vol%
if %inside%==true echo %size%:%file%
if %inside%==false call :new_vol
:exit_mng_itm
goto :eof

:new_vol
set /a volsize=totsize-size
echo vol.size:%volsize%KB
set /a volume+=1
set vol="%temp%\%filename%-%volume%.txt"
call :msg_yellow "Volume %volume%:"
echo %file%>%vol%
echo %size%:%file%
set totsize=%size%
goto :eof

:move_files
@rem for /R "%temp%" %%f in ("%filename%-*.txt") do echo %%f
for /L %%g in (1,1,%volume%) do call :remove %%g
del "%temp%\%filename%-*.txt"
del %zip%
goto :eof

:remove
set newzip="%filepath%-%1#%volume%.zip"
call :msg_yellow "%msg_create% %newzip:"=%"
copy /y %zip% %newzip% >nul
%zipper% d %newzip% * -x@"%temp%\%filename%-%1.txt" >nul
if not %errorlevel%==0 goto :err
goto :eof

:install
if %isadmin%==0 goto runasadmin
if exist %install% goto uninstall
@rem installation
echo %msg_coping%
copy /y %0 %install% >nul
if not %errorlevel%==0 goto :err
echo %msg_registry%
reg add "HKCR\Directory\Shell\%program%\command" /d "%install:"=% ""%%1""" /f >nul
if not %errorlevel%==0 goto :err
call :msg_yellow "%msg_installed0%"
call :msg_yellow "%msg_installed1%"
call :msg_yellow "%msg_installed2%"
echo.
call :msg_yellow "%msg_maxsize%"
echo %msg_presskey%
pause >nul
exit

:uninstall
echo %msg_uninstalling%
del /q /f %install% >nul
if not %errorlevel%==0 goto :err
reg delete "HKCR\Directory\Shell\%program%" /f >nul
call :msg_yellow "%msg_uninstalled%"
echo %msg_presskey%
pause >nul
exit

:runasadmin
call :msg_red "%msg_install0%"
call :msg_yellow "%msg_install1%"
call :msg_yellow "%msg_install2%"
call :msg_yellow "%msg_info0%"
call :msg_yellow "%msg_info1%"
call :msg_yellow "%msg_maxsize%"
echo %msg_presskey%
pause >nul
exit

:help
@echo.
call :msg_yellow "%msg_license%"
@echo.
echo %msg_info0%
echo %msg_maxsize%
@echo.
echo %msg_use%
goto :exit

:set_msgs
for /f "tokens=3" %%a in ('reg query "HKCU\Control Panel\International"  /V LocaleName  ^|findstr /ri "REG_SZ"') do set lang=%%a
if %lang%=="" set lang=en-EN
set lang=%lang:~0,2%
if %lang%==it goto :msg_it
set msg_a_problem=There was a problem.
set msg_check=Check and press any key to continue
set msg_add_volume=Adding a volume
set msg_zipper_not_found=Zipper not found
set msg_install0=The program needs to be installed.
set msg_install1=Run it as administrator.
set msg_install2=Rerun as administrator to uninstall.
set msg_presskey=press any key to continue
set msg_installed0=Programm installed.
set msg_installed1=Right click on folders or zip to compress and/or unzip.
set msg_installed2=%msg_install2%
set msg_maxsize=The current separation size is %maxsize% bytes.
set msg_info0=This program allows you to compress a folder into several separate zips.
set msg_info1=You need to have the freeware 7zip installed.
set msg_use=Usage:  %program% (folder or zipfile).
set msg_coping=Copying program to %programfiles% folder
set msg_registry=Setting the system registry.
set msg_uninstalling=I am uninstalling the program and removing the system registry.
set msg_uninstalled=Program uninstalled.
set msg_license=Program created by Stefano Zaglio (Copyright 2023-GPL 3.0)
set msg_err_size=An already compressed archive is too big. Splitting to %maxsizemb% is not possible.
set msg_created=Will be created
set msg_volumes=volumes
set msg_compress=Compressing
set msg_delete=Delete
set msg_create=Create
goto :eof

:msg_it
set msg_a_problem=C'e' stato un problema
set msg_check=Controllare e premere un tasto per continuare
set msg_add_volume=Aggiungo volume
set msg_zipper_not_found=Programma di compressione non trovato
set msg_install0=Il programma deve essere installato.
set msg_install1=Eseguirlo come amministratore.
set msg_install2=Rieseguirlo come amministratore per disinstallarlo.
set msg_presskey=Premere un tasto per proseguire
set msg_installed0=Programma installato.
set msg_installed1=Cliccare con il tasto destro del mouse su cartelle o zip per comprimere e/o separare.
set msg_installed2=%msg_install2%
set msg_maxsize=L'attuale dimensione di separazione e' di %maxsize% bytes.
set msg_info0=Questo programma consente di comprimere una cartella in piu' zip separati.
set msg_info1=E' necessario che sia installato il programma libero 7zip.
set msg_use=Uso:  %program% (cartella o filezip).
set msg_coping=Sto copiando il programma nella cartella %programfiles%
set msg_registry=Sto impostando il registro di sistema.
set msg_uninstalling=Sto cancellando il programma e rimuovendo il registro di sistema.
set msg_uninstalled=Programma disinstallato.
set msg_license=Programma realizzato da Stefano Zaglio (Copyright 2023-GPL 3.0)
set msg_err_size=Un archivio già compresso è troppo grande. La divisione a %maxsizemb% non è possibile.
set msg_created=Saranno creati
set msg_volumes=volumi
set msg_compress=Comprimo
set msg_delete=Cancello
set msg_create=Creo
goto :eof

@rem Errors and utility section ==============================================

:setESC
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (
  set ESC=%%b
  exit /B 0
)
exit /B 0

:msg_red
@echo %ESC%[31m%~1%ESC%[0m
goto :eof

:msg_green
@echo %ESC%[92m%~1%ESC%[0m
goto :eof

:msg_yellow
@echo %ESC%[33m%~1%ESC%[0m
goto :eof

:err_zipper
@call :msg_red "%msg_zipper_not_found%"
@goto :err

:err_subdir
@call :msg_red "%msg_subdir_not_permitted%"
@goto :err

:err_size
@call :msg_red "%msg_errsize%"
@goto :err

:err
@echo.
@call :msg_red "%msg_a_problem%"
@echo %msg_check%
@pause >nul
rem taskkill /im "%~0"
exit

:end
if not %errorlevel%==0 goto :err

:exit