@echo off
echo Ma'lumotlar bazasini to'ldirish...
cd /d %~dp0
php artisan db:seed
echo.
echo Tayyor! Endi ilovani ishlatishingiz mumkin.
pause
