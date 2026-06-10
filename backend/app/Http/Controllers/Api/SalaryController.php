<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SalaryPayment;
use App\Models\User;
use Illuminate\Http\Request;

class SalaryController extends Controller
{
    /**
     * GET /api/salaries
     * Barcha xodimlar + oy bo'yicha to'lov statistikasi
     */
    public function index(Request $request)
    {
        $month = $request->get('month', now()->format('Y-m'));

        $users = User::select('id', 'name', 'role', 'is_active', 'monthly_salary')
            ->where('role', '!=', 'admin')
            ->orderBy('name')
            ->get()
            ->map(function ($user) use ($month) {
                $paid = SalaryPayment::where('user_id', $user->id)
                    ->where('month', $month)
                    ->sum('amount');

                $user->paid_this_month  = $paid;
                $user->debt             = max(0, $user->monthly_salary - $paid);
                return $user;
            });

        return response()->json($users);
    }

    /**
     * PUT /api/users/{user}/salary
     * Xodim oylik maoshini belgilash
     */
    public function setSalary(Request $request, User $user)
    {
        $data = $request->validate([
            'monthly_salary' => 'required|integer|min:0',
        ]);
        $user->update($data);
        return response()->json($user->only(['id', 'name', 'role', 'monthly_salary']));
    }

    /**
     * GET /api/users/{user}/salary-payments
     * Xodimning to'lov tarixi
     */
    public function payments(Request $request, User $user)
    {
        $month = $request->get('month');

        $query = SalaryPayment::where('user_id', $user->id)
            ->with('paidByUser:id,name')
            ->orderByDesc('created_at');

        if ($month) {
            $query->where('month', $month);
        }

        return response()->json($query->paginate(50));
    }

    /**
     * POST /api/salary-payments
     * Maosh to'lash (yozish)
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'user_id' => 'required|exists:users,id',
            'amount'  => 'required|integer|min:1',
            'type'    => 'required|in:monthly,advance,bonus',
            'month'   => 'required|date_format:Y-m',
            'note'    => 'nullable|string|max:500',
        ]);

        $data['paid_by'] = $request->user()->id;

        $payment = SalaryPayment::create($data);
        $payment->load('paidByUser:id,name', 'user:id,name');

        return response()->json($payment, 201);
    }

    /**
     * DELETE /api/salary-payments/{payment}
     * To'lovni o'chirish
     */
    public function destroy(SalaryPayment $salaryPayment)
    {
        $salaryPayment->delete();
        return response()->json(null, 204);
    }

    /**
     * GET /api/salaries/summary
     * Oy bo'yicha maosh xarajati jami
     */
    public function summary(Request $request)
    {
        $from = $request->get('from', now()->subMonths(5)->format('Y-m'));
        $to   = $request->get('to',   now()->format('Y-m'));

        $rows = SalaryPayment::selectRaw('month, SUM(amount) as total, COUNT(*) as count')
            ->where('month', '>=', $from)
            ->where('month', '<=', $to)
            ->groupBy('month')
            ->orderBy('month')
            ->get();

        return response()->json($rows);
    }
}
