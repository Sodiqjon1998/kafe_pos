@echo off
echo ================================================
echo   Kafe POS - Avtomatik o'rnatish
echo ================================================
echo.

set "THISDIR=%~dp0"
set "BACKEND=%~dp0backend"
set "FRONTEND=%~dp0frontend"
set "OS_FOLDER=%~dp0..\.os"

echo BACKEND: %BACKEND%
echo FRONTEND: %FRONTEND%
echo.

REM --- 1. .os papkasi (OSPanel virtual host) ---
echo [1/6] OSPanel virtual host sozlanmoqda...
if not exist "%OS_FOLDER%" mkdir "%OS_FOLDER%"
echo [php] > "%OS_FOLDER%\host.ini"
echo version = 8.2 >> "%OS_FOLDER%\host.ini"
echo. >> "%OS_FOLDER%\host.ini"
echo [apache] >> "%OS_FOLDER%\host.ini"
echo DocumentRoot = www/backend/public >> "%OS_FOLDER%\host.ini"
echo OK: .os\host.ini yaratildi

REM --- 2. Composer ---
echo.
echo [2/6] Composer tekshirilmoqda...
where composer >nul 2>&1
if %errorlevel% neq 0 (
    echo XATO: Composer topilmadi!
    echo https://getcomposer.org/download/ dan yuklab o'rnating
    pause
    exit /b 1
)
echo OK: Composer mavjud

REM --- 3. Laravel paketlari ---
echo.
echo [3/6] Laravel paketlari o'rnatilmoqda...
cd /d "%BACKEND%"
if not exist "vendor" (
    composer install --no-interaction --prefer-dist
) else (
    echo Allaqachon o'rnatilgan
)

REM --- 4. .env ---
echo.
echo [4/6] .env sozlanmoqda...
cd /d "%BACKEND%"
if not exist ".env" (
    copy ".env.example" ".env" >nul
    php artisan key:generate --ansi
    echo OK: .env yaratildi
) else (
    echo .env allaqachon mavjud
)

REM --- 5. Database ---
echo.
echo [5/6] Database migratsiyasi...
echo.
echo   phpMyAdmin da "pos_kafe" nomli DB yarating, keyin Enter bosing...
pause >nul
cd /d "%BACKEND%"
php artisan migrate --force

REM --- 6. Frontend ---
echo.
echo [6/6] Frontend paketlari o'rnatilmoqda...
where npm >nul 2>&1
if %errorlevel% neq 0 (
    echo XATO: Node.js topilmadi! https://nodejs.org
    pause
    exit /b 1
)
cd /d "%FRONTEND%"
if not exist "node_modules" (
    npm install
) else (
    echo Allaqachon o'rnatilgan
)

REM --- Tayyor ---
echo.
echo ================================================
echo   MUVAFFAQIYATLI O'RNATILDI!
echo ================================================
echo.
echo   1. OSPanel - RESTART bosing
echo   2. Yangi terminal oching va quyidagini yozing:
echo      cd /d "%FRONTEND%"
echo      npm run dev
echo.
echo   Backend:  http://possystem.loc
echo   Frontend: http://localhost:5173
echo.
pause
