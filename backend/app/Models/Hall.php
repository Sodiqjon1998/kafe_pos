<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Hall extends Model
{
    protected $fillable = ['name_uz', 'name_ru', 'sort_order', 'is_active'];

    protected $casts = ['is_active' => 'boolean'];

    public function tables()
    {
        return $this->hasMany(Table::class);
    }

    public function getName(string $lang = 'uz'): string
    {
        return $lang === 'ru' ? $this->name_ru : $this->name_uz;
    }
}
