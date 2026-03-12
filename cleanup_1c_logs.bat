@echo off
setlocal enabledelayedexpansion

rem === Настройки ===
set "REG_PATH=C:\Program Files\1cv8\srvinfo\reg_1541"
set "DEL_PATH=%REG_PATH%\_del"
set "LOG_FILE=%REG_PATH%\cleanup_reg.log"

echo ========================================== >> "%LOG_FILE%"
echo Запуск очистки журналов регистрации: %date% %time% >> "%LOG_FILE%"
echo ========================================== >> "%LOG_FILE%"

rem === Проверяем наличие папки журналов ===
if not exist "%REG_PATH%" (
    echo Ошибка: каталог %REG_PATH% не найден. >> "%LOG_FILE%"
    echo Каталог %REG_PATH% не найден.
    exit /b 1
)

rem === Создаём папку для удалённых журналов ===
if not exist "%DEL_PATH%" (
    mkdir "%DEL_PATH%"
    echo Создан каталог: %DEL_PATH% >> "%LOG_FILE%"
)

rem === Формируем список актуальных GUID ===
set "ACTIVE_GUIDS_FILE=%REG_PATH%\active_guids.txt"
del "%ACTIVE_GUIDS_FILE%" 2>nul

rem Ищем GUIDы в файлах srvinfo.lst и 1CV8Clst.lst
for %%F in ("%REG_PATH%\srvinfo.lst" "%REG_PATH%\1CV8Clst.lst") do (
    if exist "%%~F" (
        findstr /r /i "[0-9A-Fa-f-][0-9A-Fa-f-][0-9A-Fa-f-][0-9A-Fa-f-]-[0-9A-Fa-f-]" "%%~F" >> "%ACTIVE_GUIDS_FILE%"
    )
)

rem Очищаем от лишнего - оставляем только GUID
for /f "tokens=1 delims= " %%A in ('type "%ACTIVE_GUIDS_FILE%" ^| findstr /r /i "[0-9a-fA-F-][0-9a-fA-F-]"') do (
    echo %%A>>"%ACTIVE_GUIDS_FILE%.tmp"
)
move /y "%ACTIVE_GUIDS_FILE%.tmp" "%ACTIVE_GUIDS_FILE%" >nul

rem === Формируем список всех каталогов журналов ===
set "ALL_GUIDS_FILE=%REG_PATH%\all_guids.txt"
dir /b /ad "%REG_PATH%" | findstr /r "^[0-9a-f-][0-9a-f-]" > "%ALL_GUIDS_FILE%"

rem === Перебираем каталоги и переносим неактуальные ===
for /f %%G in ('type "%ALL_GUIDS_FILE%"') do (
    findstr /i "%%G" "%ACTIVE_GUIDS_FILE%" >nul
    if errorlevel 1 (
        echo Перемещение неактуального журнала %%G ... >> "%LOG_FILE%"
        move "%REG_PATH%\%%G" "%DEL_PATH%\%%G" >nul
    ) else (
        echo Актуальный журнал: %%G >> "%LOG_FILE%"
    )
)

echo Очистка завершена: %date% %time% >> "%LOG_FILE%"
echo ------------------------------------------ >> "%LOG_FILE%"

echo Готово. Результаты в %LOG_FILE%.
endlocal
pause