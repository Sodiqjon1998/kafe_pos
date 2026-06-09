<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class UserController extends Controller
{
    // GET /api/users
    public function index()
    {
        return response()->json(
            User::select('id', 'name', 'email', 'pin', 'role', 'is_active', 'created_at')
                ->orderBy('role')
                ->get()
        );
    }

    // GET /api/users/{id}
    public function show(User $user)
    {
        return response()->json(
            $user->only(['id', 'name', 'email', 'pin', 'role', 'is_active', 'created_at'])
        );
    }

    // POST /api/users
    public function store(Request $request)
    {
        $data = $request->validate([
            'name'     => 'required|string',
            'pin'      => 'required|digits_between:4,6|unique:users,pin',
            'email'    => 'nullable|email|unique:users,email',
            'password' => 'nullable|string|min:6',
            'role'     => 'required|in:admin,manager,cashier,waiter,kitchen',
        ]);

        if (!empty($data['password'])) {
            $data['password'] = Hash::make($data['password']);
        }

        return response()->json(User::create($data), 201);
    }

    // PUT /api/users/{id}
    public function update(Request $request, User $user)
    {
        $data = $request->validate([
            'name'      => 'string',
            'pin'       => "digits_between:4,6|unique:users,pin,{$user->id}",
            'email'     => "nullable|email|unique:users,email,{$user->id}",
            'password'  => 'nullable|string|min:6',
            'role'      => 'in:admin,manager,cashier,waiter,kitchen',
            'is_active' => 'boolean',
        ]);

        if (!empty($data['password'])) {
            $data['password'] = Hash::make($data['password']);
        } else {
            unset($data['password']);
        }

        $user->update($data);
        return response()->json($user);
    }

    // DELETE /api/users/{id}
    public function destroy(User $user)
    {
        if ($user->id === auth()->id()) {
            return response()->json(['message' => 'O\'zingizni o\'chira olmaysiz'], 422);
        }
        $user->delete();
        return response()->json(null, 204);
    }
}
