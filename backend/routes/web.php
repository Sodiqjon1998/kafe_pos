<?php

use Illuminate\Support\Facades\Route;

// API-only ilovada named 'login' route yo'q — auth:sanctum redirect qilmasligi uchun
Route::get('/login-check', fn() => response()->json(['message' => 'Unauthenticated.'], 401))->name('login');

// SPA (React) — /api, /assets, /storage, /uploads, /up, /build dan tashqari barcha yo'llar
// frontend'ning app.html fayliga yo'naltiriladi (client-side routing).
Route::get('/{any?}', function () {
    return response()->file(public_path('app.html'));
})->where('any', '^(?!api|assets|storage|uploads|up|build).*$');
