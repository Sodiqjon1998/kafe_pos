<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Expense;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ExpenseController extends Controller
{
    // GET /api/expenses — xarajatlar ro'yxati (filter: from, to)
    public function index(Request $request)
    {
        $query = Expense::with('user:id,name', 'ingredient:id,name')
            ->latest();

        if ($request->from) $query->whereRaw("DATE(CONVERT_TZ(created_at, '+00:00', '+05:00')) >= ?", [$request->from]);
        if ($request->to)   $query->whereRaw("DATE(CONVERT_TZ(created_at, '+00:00', '+05:00')) <= ?", [$request->to]);
        if ($request->type) $query->where('type', $request->type);

        return response()->json($query->limit(200)->get());
    }

    // POST /api/expenses — qo'lda xarajat kiritish
    public function store(Request $request)
    {
        $data = $request->validate([
            'type'   => 'required|in:stock_in,salary,rent,utility,equipment,other',
            'amount' => 'required|numeric|min:1',
            'note'   => 'nullable|string|max:300',
        ]);

        $expense = Expense::create([
            ...$data,
            'user_id' => auth()->id(),
        ]);

        return response()->json($expense, 201);
    }

    // DELETE /api/expenses/{expense}
    public function destroy(Expense $expense)
    {
        $expense->delete();
        return response()->json(['ok' => true]);
    }

    // GET /api/expenses/summary — daromad va xarajat xulosasi
    public function summary(Request $request)
    {
        $from = $request->from;
        $to   = $request->to;

        // Toshkent UTC+5 — bazada UTC saqlanadi, shuning uchun CONVERT_TZ ishlatiladi
        $tz = '+05:00';

        // Daromad: total=0 bo'lsa order_items dan hisoblaydi (frontend bilan bir xil logika)
        $revenueQuery = DB::table('orders')->where('status', 'paid');
        if ($from) $revenueQuery->whereRaw("DATE(CONVERT_TZ(closed_at, '+00:00', ?)) >= ?", [$tz, $from]);
        if ($to)   $revenueQuery->whereRaw("DATE(CONVERT_TZ(closed_at, '+00:00', ?)) <= ?", [$tz, $to]);
        $revenue = $revenueQuery->selectRaw("
            SUM(CASE
                WHEN total > 0 THEN total
                ELSE (SELECT SUM(oi.product_price * oi.quantity) FROM order_items oi WHERE oi.order_id = orders.id)
            END) as revenue
        ")->value('revenue') ?? 0;

        // Xarajat
        $expenseQuery = DB::table('expenses');
        if ($from) $expenseQuery->whereRaw("DATE(CONVERT_TZ(created_at, '+00:00', ?)) >= ?", [$tz, $from]);
        if ($to)   $expenseQuery->whereRaw("DATE(CONVERT_TZ(created_at, '+00:00', ?)) <= ?", [$tz, $to]);
        $totalExpense = $expenseQuery->sum('amount');

        // Tur bo'yicha xarajat
        $byType = DB::table('expenses')
            ->when($from, fn($q) => $q->whereRaw("DATE(CONVERT_TZ(created_at, '+00:00', '+05:00')) >= ?", [$from]))
            ->when($to,   fn($q) => $q->whereRaw("DATE(CONVERT_TZ(created_at, '+00:00', '+05:00')) <= ?", [$to]))
            ->select('type', DB::raw('SUM(amount) as total'), DB::raw('COUNT(*) as count'))
            ->groupBy('type')
            ->get();

        return response()->json([
            'revenue'       => $revenue,
            'expense'       => $totalExpense,
            'net_profit'    => $revenue - $totalExpense,
            'by_type'       => $byType,
        ]);
    }
}
