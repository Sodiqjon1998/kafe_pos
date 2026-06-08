<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Table extends Model
{
    protected $fillable = [
        'hall_id', 'name', 'capacity', 'pos_x', 'pos_y',
        'shape', 'status', 'is_active',
    ];

    protected $casts = ['is_active' => 'boolean'];

    public function hall()
    {
        return $this->belongsTo(Hall::class);
    }

    public function activeOrder()
    {
        return $this->hasOne(Order::class)
            ->whereNotIn('status', ['paid', 'cancelled'])
            ->latest();
    }

    public function isFree(): bool
    {
        return $this->status === 'free';
    }
}
