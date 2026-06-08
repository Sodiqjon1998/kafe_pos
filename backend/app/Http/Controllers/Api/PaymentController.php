<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Payment;
use App\Models\Table;
use App\Models\StockMovement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PaymentController extends Controller
{
    // GET /api/payments/orders — kassir uchun buyurtmalar
    public function orders()
    {
        $orders = Order::whereNotIn('status', ['paid', 'cancelled'])
            ->with(['table.hall', 'waiter:id,name', 'items'])
            ->latest()
            ->get();

        return response()->json($orders);
    }

    // GET /api/payments/summary — to'lov usuli bo'yicha statistika
    public function summary(Request $request)
    {
        $query = DB::table('payments');
        if ($request->from) $query->whereDate('paid_at', '>=', $request->from);
        if ($request->to)   $query->whereDate('paid_at', '<=', $request->to);

        $data = $query->select('method',
                DB::raw('COUNT(*) as count'),
                DB::raw('SUM(amount) as total')
            )
            ->groupBy('method')
            ->get();

        $grandTotal = $data->sum('total');

        return response()->json([
            'methods'     => $data,
            'grand_total' => $grandTotal,
        ]);
    }

    // POST /api/payments — to'lov qabul qilish
    public function store(Request $request)
    {
        // Ochiq smena (majburiy emas — LAN POS da smena bo'lmasligi mumkin)
        $openShift = DB::connection('mysql')->table('shifts')->whereNull('closed_at')->orderByDesc('id')->first();

        $request->validate([
            'order_id'      => 'required|exists:orders,id',
            'method'        => 'required|in:cash,card,click,payme,transfer,debt',
            'cash_received' => 'nullable|numeric|min:0',
            'discount'      => 'nullable|numeric|min:0',
        ]);

        $order = Order::with('items')->findOrFail($request->order_id);

        if ($order->status === 'paid') {
            return response()->json(['message' => 'Buyurtma allaqachon to\'langan'], 422);
        }

        $payment = DB::transaction(function () use ($request, $order, $openShift) { // $openShift nullable
            // Asosiy summa
            $subtotal = (float) ($order->total ?: $order->subtotal);
            if ($subtotal <= 0) {
                $subtotal = $order->items->sum(fn($i) => (float) $i->product_price * (int) $i->quantity);
            }

            // Chegirma
            $discount = min((float) ($request->discount ?? 0), $subtotal);
            $amount   = max(0, $subtotal - $discount);

            $cashReceived = (float) ($request->cash_received ?? $amount);
            $change       = max(0, $cashReceived - $amount);

            $payment = Payment::create([
                'order_id'      => $order->id,
                'cashier_id'    => auth()->id(),
                'amount'        => $amount,
                'method'        => $request->method,
                'cash_received' => $request->method === 'cash' ? $cashReceived : null,
                'change_given'  => $request->method === 'cash' ? $change : null,
                'paid_at'       => now(),
            ]);

            $order->update([
                'status'     => 'paid',
                'cashier_id' => auth()->id(),
                'shift_id'   => $openShift?->id,
                'discount'   => $discount,
                'total'      => $amount,
                'closed_at'  => now(),
            ]);

            if ($order->table_id) {
                Table::where('id', $order->table_id)->update(['status' => 'free']);
            }

            // Sklad: ingredient chiqimi (retsept asosida)
            try {
                $order->load('items.product.ingredients');
                foreach ($order->items as $item) {
                    if (!$item->product) continue;
                    foreach ($item->product->ingredients as $ingredient) {
                        $used = $ingredient->pivot->quantity * $item->quantity;
                        $ingredient->decrement('quantity', $used);
                        StockMovement::create([
                            'ingredient_id' => $ingredient->id,
                            'type'          => 'out',
                            'quantity'      => $used,
                            'cost_per_unit' => $ingredient->cost_per_unit,
                            'reason'        => "Buyurtma #{$order->id}",
                            'user_id'       => auth()->id(),
                            'order_id'      => $order->id,
                        ]);
                    }
                }
            } catch (\Throwable $e) {
                // Sklad xatosi to'lovni to'xtatmasin
                \Log::warning('Stock deduction failed: ' . $e->getMessage());
            }

            return $payment;
        });

        return response()->json([
            'payment' => $payment,
            'order'   => $order->fresh(['table', 'items']),
        ], 201);
    }
}
