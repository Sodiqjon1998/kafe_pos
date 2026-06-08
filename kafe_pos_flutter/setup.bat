@echo off
echo =====================================================
echo   Kafe POS Flutter - O'rnatish
echo =====================================================
echo.
echo Bu skript:
echo  1. Flutter android fayllarini yaratadi
echo  2. Paketlarni o'rnatadi
echo.
echo DIQQAT: lib/ va pubspec.yaml mavjud, ular o'zgartirilmaydi.
echo.
pause

cd /d "%~dp0"

echo [1/3] Platform fayllarini yaratish...
flutter create . --project-name kafe_pos --org uz.kafe --platforms android --overwrite
if %errorlevel% neq 0 (
    echo.
    echo [XATO] flutter create ishlamadi.
    echo Qo'lda bajaring: Android Studio -> New Flutter Project
    echo loyiha nomi: kafe_pos
    echo Keyin bu papkadagi lib/ va pubspec.yaml ni yangi loyihaga ko'chiring.
    pause
    exit /b 1
)

echo.
echo [2/3] Paketlarni o'rnatish...
flutter pub get
if %errorlevel% neq 0 (
    echo XATO: flutter pub get ishlamadi. Internet ulanishini tekshiring.
    pause
    exit /b 1
)

echo.
echo [3/3] AndroidManifest.xml ni tahrirlang
echo.
echo Fayl: android\app\src\main\AndroidManifest.xml
echo.
echo  ^<manifest xmlns:android="..."^>
echo      ^<!-- Quyidagi 2 qatorni qo'shing --^>
echo      ^<uses-permission android:name="android.permission.INTERNET" /^>
echo      ^<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" /^>
echo.
echo      ^<application
echo          android:usesCleartextTraffic="true"   ^<-- bu qatorni qo'shing
echo          ...^>
echo.
echo =====================================================
echo   TAYYOR! Android Studio da oching:
echo   File -> Open -> %cd%
echo =====================================================
echo.
pause
