<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Zallar (masalan: Asosiy zal, Veranda, VIP xona)
        Schema::create('halls', function (Blueprint $table) {
            $table->id();
            $table->string('name_uz');
            $table->string('name_ru');
            $table->integer('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // Stollar
        Schema::create('tables', function (Blueprint $table) {
            $table->id();
            $table->foreignId('hall_id')->constrained()->onDelete('cascade');
            $table->string('name'); // "Stol 1", "VIP 3" kabi
            $table->integer('capacity')->default(4); // nechta odam sig'adi
            $table->integer('pos_x')->default(0); // zal xaritasidagi X pozitsiyasi
            $table->integer('pos_y')->default(0); // zal xaritasidagi Y pozitsiyasi
            $table->enum('shape', ['square', 'round', 'rectangle'])->default('square');
            $table->enum('status', ['free', 'occupied', 'reserved', 'bill_requested'])->default('free');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tables');
        Schema::dropIfExists('halls');
    }
};
