<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SalaryPayment extends Model
{
    protected $fillable = [
        'user_id', 'paid_by', 'amount', 'type', 'month', 'note',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function paidByUser()
    {
        return $this->belongsTo(User::class, 'paid_by');
    }
}
