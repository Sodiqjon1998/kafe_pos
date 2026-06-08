<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Expense extends Model
{
    protected $fillable = [
        'type', 'amount', 'note', 'user_id', 'ingredient_id',
    ];

    protected $casts = [
        'amount' => 'float',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function ingredient()
    {
        return $this->belongsTo(Ingredient::class);
    }

    public static function typeLabels(): array
    {
        return [
            'stock_in'  => 'Ombor kirim',
            'salary'    => 'Maosh',
            'rent'      => 'Ijara',
            'utility'   => 'Kommunal',
            'equipment' => 'Jihozlar',
            'other'     => 'Boshqa',
        ];
    }
}
