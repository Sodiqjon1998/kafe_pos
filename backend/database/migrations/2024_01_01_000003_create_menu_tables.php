<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Menyu kategoriyalari
        Schema::create('categories', function (Blueprint $table) {
            $table->id();
            $table->string('name_uz');
            $table->string('name_ru');
            $table->string('icon')->nullable(); // emoji yoki icon nomi
            $table->string('color', 7)->default('#FF6B35'); // kategoria rangi
            $table->integer('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // Mahsulotlar
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->foreignId('category_id')->constrained()->onDelete('cascade');
            $table->string('name_uz');
            $table->string('name_ru');
            $table->text('description_uz')->nullable();
            $table->text('description_ru')->nullable();
            $table->decimal('price', 10, 2);
            $table->string('unit_uz')->default('dona'); // dona, litr, gram...
            $table->string('unit_ru')->default('шт');
            $table->string('image')->nullable();
            $table->boolean('is_available')->default(true);
            $table->boolean('is_active')->default(true);
            $table->integer('sort_order')->default(0);
            $table->integer('cook_time')->default(0)->comment('Tayyorlash vaqti (daqiqa)');
            $table->timestamps();
        });

        // Mahsulot modifikatorlari (masalan: o'lcham, qo'shimcha)
        Schema::create('modifiers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')->constrained()->onDelete('cascade');
            $table->string('name_uz');
            $table->string('name_ru');
            $table->decimal('price_change', 10, 2)->default(0); // + yoki - narx o'zgarishi
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('modifiers');
        Schema::dropIfExists('products');
        Schema::dropIfExists('categories');
    }
};
