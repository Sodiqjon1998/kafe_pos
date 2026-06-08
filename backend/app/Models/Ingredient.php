<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Ingredient extends Model
{
    protected $fillable = ['name', 'unit', 'quantity', 'min_quantity', 'cost_per_unit'];

    protected $casts = [
        'quantity'      => 'float',
        'min_quantity'  => 'float',
        'cost_per_unit' => 'float',
    ];

    public function products()
    {
        return $this->belongsToMany(Product::class, 'product_ingredients')
                    ->withPivot('quantity')
                    ->withTimestamps();
    }

    public function movements()
    {
        return $this->hasMany(StockMovement::class);
    }

    // Qoldiq kam qolganmi?
    public function getLowStockAttribute(): bool
    {
        return $this->min_quantity > 0 && $this->quantity <= $this->min_quantity;
    }
}
