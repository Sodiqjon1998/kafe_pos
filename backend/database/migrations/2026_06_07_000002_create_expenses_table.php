<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('expenses', function (Blueprint $table) {
            $table->id();
            $table->enum('type', [
                'stock_in',   // Ombor kirim
                'salary',     // Maosh
                'rent',       // Ijara
                'utility',    // Kommunal
                'equipment',  // Jihozlar
                'other',      // Boshqa
            ])->default('other');
            $table->decimal('amount', 12, 2);           // Summa (so'm)
            $table->string('note')->nullable();          // Izoh
            $table->foreignId('user_id')->nullable()->constrained()->onDelete('set null');
            $table->foreignId('ingredient_id')->nullable()->constrained()->onDelete('set null'); // stock_in uchun
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('expenses');
    }
};
