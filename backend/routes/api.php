<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\MenuController;
use App\Http\Controllers\Api\TableController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\KitchenController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\ShiftController;
use App\Http\Controllers\Api\IngredientController;
use App\Http\Controllers\Api\ExpenseController;

// Auth (ochiq)
Route::prefix('auth')->group(function () {
    Route::post('pin',   [AuthController::class, 'loginByPin']);
    Route::post('login', [AuthController::class, 'loginByPassword']);
});

// Himoyalangan
Route::middleware('auth:sanctum')->group(function () {

    // Auth
    Route::post('auth/logout', [AuthController::class, 'logout']);
    Route::get('auth/me',      [AuthController::class, 'me']);

    // Menyu (o'qish — barcha rollar)
    Route::get('menu',       [MenuController::class, 'index']);
    Route::get('categories', [MenuController::class, 'categories']);
    Route::get('products',   [MenuController::class, 'products']);

    // Zal va stollar
    Route::get('halls',                   [TableController::class, 'halls']);
    Route::get('tables',                  [TableController::class, 'index']);
    Route::patch('tables/{table}/status', [TableController::class, 'updateStatus']);

    // Buyurtmalar
    Route::get('orders',                        [OrderController::class, 'index']);
    Route::post('orders',                       [OrderController::class, 'store']);
    Route::get('orders/{order}',                [OrderController::class, 'show']);
    Route::post('orders/{order}/items',              [OrderController::class, 'addItem']);
    Route::patch('orders/{order}/items/{item}',      [OrderController::class, 'updateItem']);
    Route::delete('orders/{order}/items/{item}',     [OrderController::class, 'removeItem']);
    Route::post('orders/{order}/send',               [OrderController::class, 'sendToKitchen']);
    Route::patch('orders/{order}/status',            [OrderController::class, 'updateStatus']);

    // To'lov (kassir)
    Route::get('payments/orders',   [PaymentController::class, 'orders']);
    Route::get('payments/summary',  [PaymentController::class, 'summary']);
    Route::post('payments',         [PaymentController::class, 'store']);

    // Oshpaz
    Route::get('kitchen/tickets',                   [KitchenController::class, 'tickets']);
    Route::patch('kitchen/items/{item}/status',     [KitchenController::class, 'updateItemStatus']);
    Route::patch('kitchen/orders/{order}/status',   [KitchenController::class, 'updateOrderStatus']);

    // Smena
    Route::get('shifts',          [ShiftController::class, 'index']);
    Route::get('shifts/current',  [ShiftController::class, 'current']);
    Route::post('shifts/open',    [ShiftController::class, 'open']);
    Route::post('shifts/close',   [ShiftController::class, 'close']);

    // Admin: xodimlar
    Route::get('users',           [UserController::class, 'index']);
    Route::post('users',          [UserController::class, 'store']);
    Route::get('users/{user}',    [UserController::class, 'show']);
    Route::put('users/{user}',    [UserController::class, 'update']);
    Route::delete('users/{user}', [UserController::class, 'destroy']);

    // Admin: menyu boshqarish
    Route::post('categories',              [MenuController::class, 'storeCategory']);
    Route::put('categories/{category}',    [MenuController::class, 'updateCategory']);
    Route::delete('categories/{category}', [MenuController::class, 'destroyCategory']);
    Route::post('products',                    [MenuController::class, 'storeProduct']);
    Route::put('products/{product}',           [MenuController::class, 'updateProduct']);
    Route::post('products/{product}/image',    [MenuController::class, 'uploadImage']);
    Route::delete('products/{product}/image',  [MenuController::class, 'deleteImage']);
    Route::delete('products/{product}',        [MenuController::class, 'destroyProduct']);

    // Sklad (admin) — static routelar wildcard'dan OLDIN turishi shart
    Route::get('ingredients/low-stock',                    [IngredientController::class, 'lowStock']);
    Route::get('ingredients',                              [IngredientController::class, 'index']);
    Route::post('ingredients',                             [IngredientController::class, 'store']);
    Route::put('ingredients/{ingredient}',                 [IngredientController::class, 'update']);
    Route::delete('ingredients/{ingredient}',              [IngredientController::class, 'destroy']);
    Route::post('ingredients/{ingredient}/stock',          [IngredientController::class, 'addStock']);
    Route::get('ingredients/{ingredient}/movements',       [IngredientController::class, 'movements']);
    Route::get('products/recipe-costs',                    [IngredientController::class, 'allRecipeCosts']);
    Route::get('products/{product}/recipe',                [IngredientController::class, 'getRecipe']);
    Route::post('products/{product}/recipe',               [IngredientController::class, 'saveRecipe']);

    // Xarajatlar
    Route::get('expenses/summary',  [ExpenseController::class, 'summary']);
    Route::get('expenses',          [ExpenseController::class, 'index']);
    Route::post('expenses',         [ExpenseController::class, 'store']);
    Route::delete('expenses/{expense}', [ExpenseController::class, 'destroy']);

    // Admin: zallar va stollar
    Route::post('halls',           [TableController::class, 'storeHall']);
    Route::post('tables',          [TableController::class, 'storeTable']);
    Route::put('tables/{table}',   [TableController::class, 'updateTable']);
    Route::delete('tables/{table}',[TableController::class, 'destroyTable']);
});
