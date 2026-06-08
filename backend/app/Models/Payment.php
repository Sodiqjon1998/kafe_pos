<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Payment extends Model
{
    protected $fillable = [
        'order_id', 'cashier_id', 'amount', 'method',
        'cash_received', 'change_given', 'reference', 'note', 'paid_at',
    ];

    protected $casts = [
        'amount'        => 'decimal:2',
        'cash_received' => 'decimal:2',
        'change_given'  => 'decimal:2',
        'paid_at'       => 'datetime',
    ];

    public function order()   { return $this->belongsTo(Order::class); }
    public function cashier() { return $this->belongsTo(User::class, 'cashier_id'); }
}
