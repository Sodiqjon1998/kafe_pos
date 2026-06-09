<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

// API-only ilovada named 'login' route yo'q — auth:sanctum redirect qilmasligi uchun
Route::get('/login', fn() => response()->json(['message' => 'Unauthenticated.'], 401))->name('login');
