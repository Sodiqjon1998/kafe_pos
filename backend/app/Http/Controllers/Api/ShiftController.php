<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ShiftController extends Controller
{
    private function db()
    {
        return DB::connection('mysql');
    }

    // GET /api/shifts/current
    public function current()
    {
        $row = $this->db()->table('shifts')
            ->whereNull('closed_at')
            ->orderByDesc('id')
            ->first();

        if (!$row) {
            return response()->json(null);
        }

        return response()->json($this->withStats((array) $row));
    }

    // POST /api/shifts/open
    public function open(Request $request)
    {

        $existing = $this->db()->table('shifts')
            ->whereNull('closed_at')
            ->orderByDesc('id')
            ->first();

        if ($existing) {
            return response()->json(
                ['message' => 'Hozir ochiq smena mavjud', 'shift_id' => $existing->id],
                422
            );
        }

        $request->validate([
            'opening_cash' => 'nullable|numeric|min:0',
        ]);

        $id = $this->db()->table('shifts')->insertGetId([
            'opened_by'    => auth()->id(),
            'opening_cash' => $request->opening_cash ?? 0,
            'closing_cash' => null,
            'opened_at'    => now(),
            'closed_at'    => null,
            'created_at'   => now(),
            'updated_at'   => now(),
        ]);

        $row = $this->db()->table('shifts')->find($id);

        return response()->json($this->withStats((array) $row), 201);
    }

    // POST /api/shifts/close
    public function close(Request $request)
    {
        $row = $this->db()->table('shifts')
            ->whereNull('closed_at')
            ->when($request->shift_id, fn($q) => $q->where('id', $request->shift_id))
            ->orderByDesc('id')
            ->first();

        if (!$row) {
            return response()->json(['message' => 'Ochiq smena topilmadi'], 422);
        }

        $request->validate([
            'closing_cash' => 'nullable|numeric|min:0',
        ]);

        $this->db()->table('shifts')->where('id', $row->id)->update([
            'closed_by'    => auth()->id(),
            'closing_cash' => $request->closing_cash ?? 0,
            'closed_at'    => now(),
            'updated_at'   => now(),
        ]);

        $updated = $this->db()->table('shifts')->find($row->id);

        return response()->json($this->withStats((array) $updated));
    }

    // GET /api/shifts
    public function index()
    {
        $shifts = $this->db()->table('shifts')
            ->orderByDesc('id')
            ->limit(30)
            ->get()
            ->map(fn($s) => $this->withStats((array) $s));

        return response()->json($shifts);
    }

    // Smena statistikasi
    private function withStats(array $shift): array
    {
        $orders = $this->db()->table('orders')
            ->where('shift_id', $shift['id'])
            ->get();

        $paid    = $orders->where('status', 'paid');
        $revenue = $paid->sum(fn($o) => (float) ($o->total ?? 0));

        // To'lov usuli bo'yicha breakdown
        $byMethod = collect();
        if ($paid->count() > 0) {
            $paidIds = $paid->pluck('id')->toArray();
            $payments = $this->db()->table('payments')
                ->whereIn('order_id', $paidIds)
                ->get();
            $byMethod = $payments->groupBy('method')->map(fn($g) => [
                'count'  => $g->count(),
                'amount' => $g->sum(fn($p) => (float) ($p->amount ?? 0)),
            ]);
        }

        // Opener/closer nomlarini olish
        $opener = $shift['opened_by']
            ? $this->db()->table('users')->select('id','name')->find($shift['opened_by'])
            : null;
        $closer = $shift['closed_by']
            ? $this->db()->table('users')->select('id','name')->find($shift['closed_by'])
            : null;

        return [
            'id'           => $shift['id'],
            'opened_at'    => $shift['opened_at'],
            'closed_at'    => $shift['closed_at'],
            'is_open'      => is_null($shift['closed_at']),
            'opening_cash' => (float) ($shift['opening_cash'] ?? 0),
            'closing_cash' => (float) ($shift['closing_cash'] ?? 0),
            'opener'       => $opener,
            'closer'       => $closer,
            'stats'        => [
                'orders_total' => $orders->count(),
                'orders_paid'  => $paid->count(),
                'revenue'      => $revenue,
                'by_method'    => $byMethod,
            ],
        ];
    }
}
