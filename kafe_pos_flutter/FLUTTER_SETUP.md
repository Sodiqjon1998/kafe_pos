# Kafe POS Flutter — O'rnatish yo'riqnomasi

## 1. Birinchi marta o'rnatish

**Terminalni oching** va `kafe_pos_flutter` papkasiga kiring:

```bash
cd D:\OSPanel\home\possystem.loc\kafe_pos_flutter
setup.bat
```

Yoki qo'lda:
```bash
flutter create . --project-name kafe_pos --org uz.kafe --platforms android
flutter pub get
```

---

## 2. INTERNET ruxsatini qo'shish (MUHIM!)

`android\app\src\main\AndroidManifest.xml` faylini oching va `<manifest>` tagidan keyin qo'shing:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Bu qatorni qo'shing: -->
    <uses-permission android:name="android.permission.INTERNET" />

    <application ...>
```

---

## 3. HTTP (http://) ruxsatini qo'shish (LAN uchun)

LAN IP `http://` bilan boshlanadi, shuning uchun `android:usesCleartextTraffic="true"` kerak.

`<application` tagiga qo'shing:

```xml
<application
    android:label="Kafe POS"
    android:usesCleartextTraffic="true"
    ...>
```

---

## 4. Android Studio da ochish

1. Android Studio → **Open**
2. `D:\OSPanel\home\possystem.loc\kafe_pos_flutter` papkasini tanlang
3. Emulator yoki telefon ulang
4. **Run** (Shift+F10)

---

## 5. Ilova ishga tushganda

1. **Sozlamalar** ekrani ochiladi (birinchi marta)
2. Server IP ni kiriting: `http://192.168.X.X`
   - Kompyuterda `cmd` → `ipconfig` → IPv4 Address
3. **Ulanishni tekshirish** tugmasini bosing
4. **Saqlash** → Login ekrani
5. PIN yoki parol bilan kiring

---

## Loyiha tuzilmasi

```
lib/
├── main.dart              ← Ilova kirish nuqtasi
├── router.dart            ← Marshrutlar
├── core/
│   ├── api/
│   │   └── api_client.dart   ← Dio HTTP klienti
│   ├── constants/
│   │   └── app_colors.dart   ← Rang palitasi
│   ├── models/
│   │   ├── user.dart         ← Foydalanuvchi modeli
│   │   ├── table_model.dart  ← Zal/stol modeli
│   │   ├── menu_model.dart   ← Kategoriya/mahsulot
│   │   └── order_model.dart  ← Buyurtma/element
│   └── providers/
│       ├── auth_provider.dart    ← Autentifikatsiya
│       ├── tables_provider.dart  ← Zallar va stollar
│       ├── menu_provider.dart    ← Menyu
│       └── orders_provider.dart  ← Buyurtmalar
└── features/
    ├── splash/         ← Yuklash ekrani
    ├── settings/       ← API URL sozlamalari
    ├── auth/           ← Login (PIN + parol)
    ├── waiter/         ← Ofitsiant (zal xaritasi, buyurtma)
    └── admin/          ← Admin (dashboard, menyu, xodimlar)
```

---

## Ekranlar va navigatsiya

```
/               → Splash (token tekshirish)
/settings       → API URL sozlamalari
/login          → Login (PIN yoki parol)
/waiter         → Zal xaritasi
/waiter/order/X → Buyurtma ekrani (mavjud)
/waiter/new-order → Yangi buyurtma
/admin          → Admin panel (Dashboard / Menyu / Xodimlar)
```

---

## Rollar

| Rol       | Yo'nalish |
|-----------|-----------|
| admin     | /admin    |
| manager   | /admin    |
| waiter    | /waiter   |
| cashier   | /waiter   |
| kitchen   | /waiter   |

---

## API ulanish

Backend: `http://[SERVER_IP]/api`

Barcha so'rovlar `Bearer {token}` bilan yuboriladi (Sanctum).
