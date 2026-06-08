<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Shift extends Model
{
    protected $connection = 'mysql';

    protected $fillable = [
        'opened_by', 'closed_by', 'opening_cash', 'closing_cash',
        'opened_at', 'closed_at',
    ];

    protected $casts = [
        'opening_cash' => 'decimal:2',
        'closing_cash' => 'decimal:2',
        'opened_at'    => 'datetime',
        'closed_at'    => 'datetime',
    ];

    public function opener()  { return $this->belongsTo(User::class, 'opened_by'); }
    public function closer()  { return $this->belongsTo(User::class, 'closed_by'); }
    public function orders()  { return $this->hasMany(Order::class); }

    public function isOpen(): bool { return is_null($this->closed_at); }

    public static function current(): ?self
    {
        return static::whereNull('closed_at')->orderBy('id', 'desc')->first();
    }
}
