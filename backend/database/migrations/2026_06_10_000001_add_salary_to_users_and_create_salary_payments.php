<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Users jadvaliga oylik maosh maydoni
        Schema::table('users', function (Blueprint $table) {
            $table->unsignedBigInteger('monthly_salary')->default(0)->after('is_active');
        });

        // Maosh to'lovlari jadvali
        Schema::create('salary_payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('paid_by')->constrained('users')->onDelete('cascade');
            $table->unsignedBigInteger('amount');
            $table->enum('type', ['monthly', 'advance', 'bonus'])->default('monthly');
            $table->string('month', 7);   // "2026-06" formatida
            $table->text('note')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('salary_payments');
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('monthly_salary');
        });
    }
};
