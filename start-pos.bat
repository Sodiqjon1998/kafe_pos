@echo off
title Kafe POS - Ishga tushirish
color 0A
echo.
echo  ==============================
echo    KAFE POS - Ishga tushmoqda
echo  ==============================
echo.

:: Frontend papkasiga o'tish
cd /d "%~dp0frontend"

:: Node va npm bor-yo'qligini tekshirish
where npm >nul 2>&1
if errorlevel 1 (
    color 0C
    echo  [XATO] Node.js o'rnatilmagan!
    echo  https://nodejs.org dan yuklab o'rnating.
    pause
    exit /b 1
)

:: Electron o'rnatilgan-o'rnatilmaganligini tekshirish
if not exist "node_modules\electron" (
    echo  [!] Paketlar o'rnatilmayapti, kutib turing...
    npm install
    echo.
)

echo  [OK] Vite serveri + Electron ishga tushmoqda...
echo  [!]  Oshpaz/Ofitsiant qurilmalarda: http://KOMPYUTER_IP:5173
echo.

:: Vite va Electron-ni parallel ishga tushirish
npm run electron:dev

pause
