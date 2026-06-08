<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Ingredientlar (xom ashyo)
        Schema::create('ingredients', function (Blueprint $table) {
            $table->id();
            $table->string('name');                          // "Un", "Go'sht", "Yog'"
            $table->string('unit')->default('kg');           // kg, litr, dona, gr
            $table->decimal('quantity', 10, 3)->default(0); // joriy qoldiq
            $table->decimal('min_quantity', 10, 3)->default(0); // ogohlantirish chegarasi
            $table->decimal('cost_per_unit', 10, 2)->default(0); // 1 birlik narxi (so'm)
            $table->timestamps();
        });

        // 2. Mahsulot retsepti (qaysi taomda nechta ingredient)
        Schema::create('product_ingredients', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')->constrained()->onDelete('cascade');
            $table->foreignId('ingredient_id')->constrained()->onDelete('cascade');
            $table->decimal('quantity', 10, 3); // 1 porsiya uchun miqdor
            $table->unique(['product_id', 'ingredient_id']);
            $table->timestamps();
        });

        // 3. Sklad harakatlari (kirim / chiqim tarixi)
        Schema::create('stock_movements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ingredient_id')->constrained()->onDelete('cascade');
            $table->enum('type', ['in', 'out']);             // kirim / chiqim
            $table->decimal('quantity', 10, 3);
            $table->decimal('cost_per_unit', 10, 2)->default(0); // kirim narxi
            $table->string('reason')->nullable();            // "Yangi partiya", "Buyurtma #12"
            $table->foreignId('user_id')->nullable()->constrained()->onDelete('set null');
            $table->foreignId('order_id')->nullable()->constrained()->onDelete('set null');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('stock_movements');
        Schema::dropIfExists('product_ingredients');
        Schema::dropIfExists('ingredients');
    }
};
