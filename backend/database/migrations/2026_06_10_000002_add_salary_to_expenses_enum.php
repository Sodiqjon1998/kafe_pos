<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Expenses jadvalidagi type enum ga 'salary' qo'shish (agar yo'q bo'lsa)
        DB::statement("ALTER TABLE expenses MODIFY COLUMN type ENUM(
            'stock_in',
            'salary',
            'rent',
            'utility',
            'equipment',
            'other'
        ) NOT NULL DEFAULT 'other'");
    }

    public function down(): void
    {
        DB::statement("ALTER TABLE expenses MODIFY COLUMN type ENUM(
            'stock_in',
            'rent',
            'utility',
            'equipment',
            'other'
        ) NOT NULL DEFAULT 'other'");
    }
};
