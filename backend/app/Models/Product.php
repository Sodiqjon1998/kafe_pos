<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    protected $fillable = [
        'category_id', 'name_uz', 'name_ru', 'description_uz', 'description_ru',
        'price', 'unit_uz', 'unit_ru', 'image', 'is_available', 'is_active',
        'sort_order', 'cook_time',
    ];

    protected $casts = [
        'price'        => 'decimal:2',
        'is_available' => 'boolean',
        'is_active'    => 'boolean',
    ];

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function modifiers()
    {
        return $this->hasMany(Modifier::class)->where('is_active', true);
    }

    public function getName(string $lang = 'uz'): string
    {
        return $lang === 'ru' ? $this->name_ru : $this->name_uz;
    }

    public function ingredients()
    {
        return $this->belongsToMany(Ingredient::class, 'product_ingredients')
                    ->withPivot('quantity')
                    ->withTimestamps();
    }
}
