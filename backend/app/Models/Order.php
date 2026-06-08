<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Builder;

class Order extends Model
{
    protected $fillable = [
        'order_number', 'table_id', 'waiter_id', 'cashier_id', 'shift_id',
        'type', 'status', 'guests_count', 'note',
        'subtotal', 'discount', 'tax', 'total',
        'opened_at', 'closed_at',
    ];

    protected $casts = [
        'subtotal'   => 'decimal:2',
        'discount'   => 'decimal:2',
        'tax'        => 'decimal:2',
        'total'      => 'decimal:2',
        'opened_at'  => 'datetime',
        'closed_at'  => 'datetime',
    ];

    // ───── Relationships ─────

    public function table()    { return $this->belongsTo(Table::class); }
    public function waiter()   { return $this->belongsTo(User::class, 'waiter_id'); }
    public function cashier()  { return $this->belongsTo(User::class, 'cashier_id'); }
    public function shift()    { return $this->belongsTo(Shift::class); }
    public function items()    { return $this->hasMany(OrderItem::class); }
    public function payment()  { return $this->hasOne(Payment::class); }

    // ───── Scopes ─────

    public function scopeActive(Builder $query): Builder
    {
        return $query->whereNotIn('status', ['paid', 'cancelled']);
    }

    // ───── Helpers ─────

    public function recalculate(): void
    {
        $subtotal = $this->items()
            ->where('status', '!=', 'cancelled')
            ->sum('total');

        $this->update([
            'subtotal' => $subtotal,
            'total'    => $subtotal - $this->discount + $this->tax,
        ]);
    }

    // Order raqamini generatsiya qilish: #000001
    public static function generateNumber(): string
    {
        $last = static::max('id') ?? 0;
        return '#' . str_pad($last + 1, 6, '0', STR_PAD_LEFT);
    }
}
