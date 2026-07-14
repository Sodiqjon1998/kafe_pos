<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Hall;
use App\Models\Ingredient;
use App\Models\Product;
use App\Models\Table;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        // ── Foydalanuvchilar ──────────────────────────────────────────────────
        $users = [
            ['name' => 'Admin',            'email' => 'admin@pos.uz',   'password' => Hash::make('admin123'),   'pin' => '1111', 'role' => 'admin'],
            ['name' => 'Menejer',          'email' => 'manager@pos.uz', 'password' => Hash::make('manager123'), 'pin' => '2222', 'role' => 'manager'],
            ['name' => 'Kassir',           'email' => 'cashier@pos.uz', 'password' => Hash::make('cashier123'), 'pin' => '3333', 'role' => 'cashier'],
            ['name' => 'Jasur',            'email' => null,             'password' => null,                     'pin' => '4444', 'role' => 'waiter'],
            ['name' => 'Malika',           'email' => null,             'password' => null,                     'pin' => '5555', 'role' => 'waiter'],
            ['name' => 'Oshpaz Akbar',     'email' => null,             'password' => null,                     'pin' => '6666', 'role' => 'kitchen'],
        ];
        foreach ($users as $data) {
            User::updateOrCreate(['pin' => $data['pin']], $data);
        }

        // ── Zallar ────────────────────────────────────────────────────────────
        $halls = [
            ['name_uz' => 'Asosiy zal', 'name_ru' => 'Основной зал', 'sort_order' => 1],
            ['name_uz' => 'VIP xona',   'name_ru' => 'VIP зал',       'sort_order' => 2],
            ['name_uz' => "Bog'",        'name_ru' => 'Сад',           'sort_order' => 3],
        ];
        foreach ($halls as $h) {
            Hall::firstOrCreate(['name_uz' => $h['name_uz']], $h);
        }

        // ── Stollar ───────────────────────────────────────────────────────────
        $asosiy = Hall::where('name_uz', 'Asosiy zal')->first();
        $vip    = Hall::where('name_uz', 'VIP xona')->first();
        $bog    = Hall::where('name_uz', "Bog'")->first();

        for ($i = 1; $i <= 12; $i++) {
            Table::firstOrCreate(
                ['hall_id' => $asosiy->id, 'name' => "$i-stol"],
                ['capacity' => 4, 'pos_x' => ($i - 1) % 4 * 2, 'pos_y' => (int)(($i - 1) / 4) * 2]
            );
        }
        for ($i = 1; $i <= 4; $i++) {
            Table::firstOrCreate(
                ['hall_id' => $vip->id, 'name' => "VIP $i"],
                ['capacity' => 8, 'shape' => 'round']
            );
        }
        for ($i = 1; $i <= 6; $i++) {
            Table::firstOrCreate(
                ['hall_id' => $bog->id, 'name' => "B-$i"],
                ['capacity' => 6]
            );
        }

        // ── Kategoriyalar va mahsulotlar ──────────────────────────────────────
        $menu = [
            [
                'category' => ['name_uz' => 'Asosiy taomlar', 'name_ru' => 'Основные блюда', 'sort_order' => 1],
                'products'  => [
                    ['name_uz' => 'Osh (Plov)',      'name_ru' => 'Плов',             'price' => 35000, 'cook_time' => 20],
                    ['name_uz' => 'Shashlik (mol)',   'name_ru' => 'Шашлык (говядина)', 'price' => 45000, 'cook_time' => 25],
                    ['name_uz' => "Lag'mon",          'name_ru' => 'Лагман',           'price' => 28000, 'cook_time' => 15],
                    ['name_uz' => 'Manti',            'name_ru' => 'Манты',            'price' => 30000, 'cook_time' => 30],
                    ['name_uz' => 'Qozon kabob',      'name_ru' => 'Казан-кебаб',      'price' => 48000, 'cook_time' => 35],
                    ['name_uz' => 'Dimlama',          'name_ru' => 'Димляма',          'price' => 55000, 'cook_time' => 40],
                ],
            ],
            [
                'category' => ['name_uz' => "Sho'rvalar", 'name_ru' => 'Супы', 'sort_order' => 2],
                'products'  => [
                    ['name_uz' => 'Mastava',     'name_ru' => 'Мастава',    'price' => 22000, 'cook_time' => 15],
                    ['name_uz' => "Sho'rva",     'name_ru' => 'Шурпа',      'price' => 25000, 'cook_time' => 15],
                    ['name_uz' => 'Dum sho\'rva','name_ru' => 'Думшурпа',   'price' => 28000, 'cook_time' => 20],
                ],
            ],
            [
                'category' => ['name_uz' => 'Salatlar', 'name_ru' => 'Салаты', 'sort_order' => 3],
                'products'  => [
                    ['name_uz' => 'Achchiq-chuchuk', 'name_ru' => 'Ачичук',     'price' => 12000, 'cook_time' => 5],
                    ['name_uz' => 'Salyot',          'name_ru' => 'Салат',       'price' => 18000, 'cook_time' => 5],
                    ['name_uz' => 'Toshkent salati', 'name_ru' => 'Ташкентский', 'price' => 22000, 'cook_time' => 10],
                ],
            ],
            [
                'category' => ['name_uz' => 'Ichimliklar', 'name_ru' => 'Напитки', 'sort_order' => 4],
                'products'  => [
                    ['name_uz' => 'Choy (ko\'k)',  'name_ru' => 'Чай (зелёный)', 'price' => 8000,  'cook_time' => 3],
                    ['name_uz' => 'Choy (qora)',   'name_ru' => 'Чай (чёрный)',  'price' => 8000,  'cook_time' => 3],
                    ['name_uz' => 'Pepsi 0.5L',    'name_ru' => 'Pepsi 0.5L',   'price' => 12000, 'cook_time' => 0],
                    ['name_uz' => 'Coca-Cola 0.5L','name_ru' => 'Coca-Cola',     'price' => 12000, 'cook_time' => 0],
                    ['name_uz' => 'Limonad',       'name_ru' => 'Лимонад',       'price' => 15000, 'cook_time' => 5],
                    ['name_uz' => 'Kompot',        'name_ru' => 'Компот',        'price' => 10000, 'cook_time' => 0],
                ],
            ],
            [
                'category' => ['name_uz' => 'Non-tandir', 'name_ru' => 'Хлеб', 'sort_order' => 5],
                'products'  => [
                    ['name_uz' => 'Non (katta)',   'name_ru' => 'Лепёшка',   'price' => 5000, 'cook_time' => 10],
                    ['name_uz' => 'Samsa (3 ta)',  'name_ru' => 'Самса (3)',  'price' => 12000,'cook_time' => 15],
                ],
            ],
        ];

        foreach ($menu as $section) {
            $cat = Category::firstOrCreate(
                ['name_uz' => $section['category']['name_uz']],
                $section['category']
            );
            foreach ($section['products'] as $i => $p) {
                Product::firstOrCreate(
                    ['category_id' => $cat->id, 'name_uz' => $p['name_uz']],
                    array_merge($p, ['name_ru' => $p['name_ru'], 'sort_order' => $i])
                );
            }
        }

        // ── Sklad ingredientlari ──────────────────────────────────────────────
        $ingredients = [
            // Go'sht mahsulotlar
            ['name' => 'Mol go\'shtı',       'unit' => 'kg',   'quantity' => 15.0,  'min_quantity' => 3.0,  'cost_per_unit' => 85000],
            ['name' => 'Qo\'y go\'shtı',     'unit' => 'kg',   'quantity' => 10.0,  'min_quantity' => 2.0,  'cost_per_unit' => 95000],
            ['name' => 'Tovuq',              'unit' => 'kg',   'quantity' => 8.0,   'min_quantity' => 2.0,  'cost_per_unit' => 45000],
            // Sabzavotlar
            ['name' => 'Piyoz',              'unit' => 'kg',   'quantity' => 20.0,  'min_quantity' => 5.0,  'cost_per_unit' => 3000],
            ['name' => 'Sabzi',              'unit' => 'kg',   'quantity' => 15.0,  'min_quantity' => 3.0,  'cost_per_unit' => 4000],
            ['name' => 'Pomidor',            'unit' => 'kg',   'quantity' => 12.0,  'min_quantity' => 3.0,  'cost_per_unit' => 5000],
            ['name' => 'Bodring',            'unit' => 'kg',   'quantity' => 6.0,   'min_quantity' => 2.0,  'cost_per_unit' => 6000],
            ['name' => 'Kartoshka',          'unit' => 'kg',   'quantity' => 25.0,  'min_quantity' => 5.0,  'cost_per_unit' => 3500],
            ['name' => 'Karam',              'unit' => 'kg',   'quantity' => 8.0,   'min_quantity' => 2.0,  'cost_per_unit' => 2500],
            // Don mahsulotlar
            ['name' => 'Guruch',             'unit' => 'kg',   'quantity' => 30.0,  'min_quantity' => 5.0,  'cost_per_unit' => 12000],
            ['name' => 'Un',                 'unit' => 'kg',   'quantity' => 20.0,  'min_quantity' => 5.0,  'cost_per_unit' => 8000],
            ['name' => 'Makkajo\'xori uni',  'unit' => 'kg',   'quantity' => 5.0,   'min_quantity' => 1.0,  'cost_per_unit' => 10000],
            // Moyliq
            ['name' => 'O\'simlik yog\'i',   'unit' => 'litr', 'quantity' => 8.0,   'min_quantity' => 2.0,  'cost_per_unit' => 22000],
            ['name' => 'Sariyog\'',          'unit' => 'kg',   'quantity' => 3.0,   'min_quantity' => 0.5,  'cost_per_unit' => 75000],
            // Ziravorlar
            ['name' => 'Tuz',               'unit' => 'kg',   'quantity' => 5.0,   'min_quantity' => 1.0,  'cost_per_unit' => 2000],
            ['name' => 'Qalampir',          'unit' => 'gr',   'quantity' => 500.0, 'min_quantity' => 100.0,'cost_per_unit' => 80],
            ['name' => 'Zira',              'unit' => 'gr',   'quantity' => 300.0, 'min_quantity' => 50.0, 'cost_per_unit' => 120],
            ['name' => 'Koriander',         'unit' => 'gr',   'quantity' => 200.0, 'min_quantity' => 50.0, 'cost_per_unit' => 100],
            // Ichimliklar
            ['name' => 'Choy (ko\'k)',       'unit' => 'gr',   'quantity' => 1000.0,'min_quantity' => 200.0,'cost_per_unit' => 150],
            ['name' => 'Choy (qora)',        'unit' => 'gr',   'quantity' => 800.0, 'min_quantity' => 200.0,'cost_per_unit' => 100],
            ['name' => 'Shakar',            'unit' => 'kg',   'quantity' => 10.0,  'min_quantity' => 2.0,  'cost_per_unit' => 9000],
            ['name' => 'Limon',             'unit' => 'dona', 'quantity' => 30.0,  'min_quantity' => 10.0, 'cost_per_unit' => 3000],
            // Boshqa
            ['name' => 'Tuxum',             'unit' => 'dona', 'quantity' => 60.0,  'min_quantity' => 12.0, 'cost_per_unit' => 2000],
            ['name' => 'Sut',               'unit' => 'litr', 'quantity' => 5.0,   'min_quantity' => 1.0,  'cost_per_unit' => 9000],
            ['name' => 'Qatiq',             'unit' => 'litr', 'quantity' => 3.0,   'min_quantity' => 0.5,  'cost_per_unit' => 12000],
        ];

        foreach ($ingredients as $ing) {
            Ingredient::firstOrCreate(['name' => $ing['name']], $ing);
        }
    }
}

