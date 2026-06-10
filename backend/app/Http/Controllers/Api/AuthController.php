<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    /**
     * PIN orqali kirish (kassir/ofitsiant uchun tez kirish)
     */
    public function loginByPin(Request $request)
    {
        $request->validate(['pin' => 'required|digits:4,6']);

        $user = User::where('pin', $request->pin)
            ->where('is_active', true)
            ->first();

        if (!$user) {
            return response()->json([
                'message' => __('auth.pin_invalid'),
            ], 401);
        }

        $token = $user->createToken('pos-device', ['*'], now()->addHours(12))->plainTextToken;

        return response()->json([
            'user'  => $this->userResource($user),
            'token' => $token,
        ]);
    }

    /**
     * Login/parol orqali kirish (admin/menejer uchun)
     */
    public function loginByPassword(Request $request)
    {
        $request->validate([
            'email'    => 'required|email',
            'password' => 'required',
        ]);

        $user = User::where('email', $request->email)
            ->where('is_active', true)
            ->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'message' => __('auth.failed'),
            ], 401);
        }

        $token = $user->createToken('pos-device')->plainTextToken;

        return response()->json([
            'user'  => $this->userResource($user),
            'token' => $token,
        ]);
    }

    /**
     * Chiqish
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'ok']);
    }

    /**
     * Joriy foydalanuvchi ma'lumotlari
     */
    public function me(Request $request)
    {
        return response()->json($this->userResource($request->user()));
    }

    /**
     * Login ekrani uchun faol xodimlar ro'yxati (faqat ism va rol — PIN yo'q)
     */
    public function activeStaff()
    {
        return response()->json(
            User::where('is_active', true)
                ->select('id', 'name', 'role')
                ->orderByRaw("FIELD(role,'admin','manager','cashier','waiter','kitchen')")
                ->get()
        );
    }

    private function userResource(User $user): array
    {
        return [
            'id'   => $user->id,
            'name' => $user->name,
            'role' => $user->role,
            'lang' => $user->lang,
        ];
    }
}
