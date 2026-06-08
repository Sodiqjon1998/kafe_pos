# Kafe POS — O'rnatish yo'riqnomasi

## 1. Talab qilinadigan muhit
- OpenServer Panel (mavjud ✓)
- PHP 8.2+
- MySQL 8.0+
- Composer
- Node.js 18+

## 2. Backend (Laravel 12) o'rnatish

OSPanel terminalini oching (`D:\OSPanel\home\possystem.loc\kafe-restorant-pos` ichida):

```bash
# Laravel loyihasini yaratish
composer create-project laravel/laravel backend

# Backend papkasiga o'tish
cd backend

# .env faylini sozlash
copy .env.example .env
php artisan key:generate

# Ma'lumotlar bazasini yaratish (phpMyAdmin orqali: pos_kafe)
# Keyin migratsiyalarni ishlatish
php artisan migrate --seed

# Sanctum o'rnatish
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"

# Serverni ishga tushirish (OSPanel orqali avtomatik ishlaydi)
```

## 3. Frontend (React + Vite) o'rnatish

```bash
# Yangi terminal, possystem.loc/kafe-restorant-pos ichida
npm create vite@latest frontend -- --template react
cd frontend
npm install
npm install axios react-router-dom zustand @tanstack/react-query
npm run dev
```

## 4. OSPanel virtual host sozlamalari

- Domain: `possystem.loc`
- Papka: `D:\OSPanel\home\possystem.loc\kafe-restorant-pos\backend\public`
- PHP: 8.2+

## 5. Ma'lumotlar bazasi

phpMyAdmin (`http://localhost/phpmyadmin`) da:
- Yangi DB: `pos_kafe`
- Collation: `utf8mb4_unicode_ci`

## 6. LAN tarmoq sozlamalari

LAN ichidagi boshqa qurilmalar (planshet/telefon) quyidagi manzil orqali kiradi:
```
http://[SERVER_IP]:80
```
Server IP ni aniqlash: `ipconfig` → IPv4 Address
