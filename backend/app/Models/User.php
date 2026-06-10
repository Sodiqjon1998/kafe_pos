<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens;

    protected $fillable = [
        'name', 'pin', 'email', 'password', 'role', 'lang', 'is_active', 'monthly_salary',
    ];

    protected $hidden = ['password', 'remember_token'];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    // Rollarga tekshirish
    public function isAdmin(): bool    { return $this->role === 'admin'; }
    public function isManager(): bool  { return in_array($this->role, ['admin', 'manager']); }
    public function isCashier(): bool  { return in_array($this->role, ['admin', 'manager', 'cashier']); }
    public function isKitchen(): bool  { return in_array($this->role, ['admin', 'manager', 'kitchen']); }

    public function orders()
    {
        return $this->hasMany(Order::class, 'waiter_id');
    }

    public function shifts()
    {
        return $this->hasMany(Shift::class, 'opened_by');
    }
}
