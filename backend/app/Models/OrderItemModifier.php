<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OrderItemModifier extends Model
{
    protected $fillable = [
        'order_item_id', 'modifier_id', 'modifier_name', 'price_change',
    ];

    protected $casts = [
        'price_change' => 'decimal:2',
    ];

    public function orderItem() { return $this->belongsTo(OrderItem::class); }
}
