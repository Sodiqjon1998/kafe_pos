<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StockMovement extends Model
{
    protected $fillable = [
        'ingredient_id', 'type', 'quantity',
        'cost_per_unit', 'reason', 'user_id', 'order_id',
    ];

    protected $casts = [
        'quantity'      => 'float',
        'cost_per_unit' => 'float',
    ];

    public function ingredient()
    {
        return $this->belongsTo(Ingredient::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function order()
    {
        return $this->belongsTo(Order::class);
    }
}
