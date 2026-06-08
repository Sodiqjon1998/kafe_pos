<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Smenalar
        Schema::create('shifts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('opened_by')->constrained('users');
            $table->foreignId('closed_by')->nullable()->constrained('users');
            $table->decimal('opening_cash', 10, 2)->default(0); // boshlang'ich kassa
            $table->decimal('closing_cash', 10, 2)->nullable();
            $table->timestamp('opened_at');
            $table->timestamp('closed_at')->nullable();
            $table->timestamps();
        });

        // Buyurtmalar
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->string('order_number')->unique(); // #0001, #0002...
            $table->foreignId('table_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('waiter_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('cashier_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('shift_id')->nullable()->constrained()->nullOnDelete();
            $table->enum('type', ['dine_in', 'takeaway'])->default('dine_in');
            $table->enum('status', [
                'open',         // ochiq
                'sent',         // oshpazga yuborildi
                'ready',        // tayyor
                'bill',         // hisob so'raldi
                'paid',         // to'landi
                'cancelled'     // bekor qilindi
            ])->default('open');
            $table->integer('guests_count')->default(1);
            $table->text('note')->nullable(); // umumiy izoh
            $table->decimal('subtotal', 10, 2)->default(0);
            $table->decimal('discount', 10, 2)->default(0);
            $table->decimal('tax', 10, 2)->default(0);
            $table->decimal('total', 10, 2)->default(0);
            $table->timestamp('opened_at')->nullable();
            $table->timestamp('closed_at')->nullable();
            $table->timestamps();
        });

        // Buyurtma elementlari
        Schema::create('order_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->onDelete('cascade');
            $table->foreignId('product_id')->constrained();
            $table->string('product_name'); // snapshot - mahsulot nomi o'zgarib ketmasin
            $table->decimal('product_price', 10, 2); // snapshot
            $table->integer('quantity')->default(1);
            $table->decimal('total', 10, 2);
            $table->text('note')->nullable(); // oshpazga izoh
            $table->enum('status', ['pending', 'cooking', 'ready', 'served', 'cancelled'])->default('pending');
            $table->foreignId('sent_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('sent_at')->nullable();
            $table->timestamps();
        });

        // Buyurtma elementi modifikatorlari
        Schema::create('order_item_modifiers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_item_id')->constrained()->onDelete('cascade');
            $table->foreignId('modifier_id')->constrained();
            $table->string('modifier_name'); // snapshot
            $table->decimal('price_change', 10, 2)->default(0);
            $table->timestamps();
        });

        // To'lovlar
        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->onDelete('cascade');
            $table->foreignId('cashier_id')->constrained('users');
            $table->decimal('amount', 10, 2);
            $table->enum('method', ['cash', 'card', 'click', 'payme', 'transfer', 'debt'])->default('cash');
            $table->decimal('cash_received', 10, 2)->nullable(); // qabul qilingan naqd
            $table->decimal('change_given', 10, 2)->nullable(); // qaytim
            $table->string('reference')->nullable(); // karta/transfer ref raqam
            $table->text('note')->nullable();
            $table->timestamp('paid_at');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
        Schema::dropIfExists('order_item_modifiers');
        Schema::dropIfExists('order_items');
        Schema::dropIfExists('orders');
        Schema::dropIfExists('shifts');
    }
};
