<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OrderItem extends Model
{
    protected $fillable = [
        'order_id', 'product_id', 'product_name', 'product_price',
        'quantity', 'total', 'note', 'status', 'sent_by', 'sent_at',
    ];

    protected $casts = [
        'product_price' => 'decimal:2',
        'total'         => 'decimal:2',
        'sent_at'       => 'datetime',
    ];

    public function order()     { return $this->belongsTo(Order::class); }
    public function product()   { return $this->belongsTo(Product::class); }
    public function sentBy()    { return $this->belongsTo(User::class, 'sent_by'); }
    public function modifiers() { return $this->hasMany(OrderItemModifier::class); }

    public function recalculate(): void
    {
        $modifiersTotal = $this->modifiers()->sum('price_change');
        $this->update([
            'total' => ($this->product_price + $modifiersTotal) * $this->quantity,
        ]);
    }
}
