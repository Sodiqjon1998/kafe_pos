<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderItem;
use Illuminate\Http\Request;

class KitchenController extends Controller
{
    // GET /api/kitchen/tickets — oshpaz uchun aktiv buyurtmalar
    public function tickets()
    {
        // Faqat oshpazga kerakli buyurtmalar:
        // pending yoki cooking itemlari bor buyurtmalar (ready itemlar ko'rsatilmaydi)
        $orders = Order::whereIn('status', ['sent', 'ready'])
            ->whereHas('items', fn($q) => $q->whereIn('status', ['pending', 'cooking']))
            ->with(['table.hall', 'waiter:id,name', 'items'])
            ->latest()
            ->get();

        return response()->json($orders);
    }

    // PATCH /api/kitchen/items/{item}/status
    public function updateItemStatus(Request $request, OrderItem $item)
    {
        $request->validate([
            'status' => 'required|in:cooking,ready,served',
        ]);

        $item->update(['status' => $request->status]);

        // Agar barcha itemlar ready bo'lsa, orderni ready ga o'tkaz
        $order = $item->order;
        $allReady = $order->items()
            ->whereNotIn('status', ['ready', 'served', 'cancelled'])
            ->doesntExist();

        if ($allReady) {
            $order->update(['status' => 'ready']);
        }

        return response()->json($item);
    }

    // PATCH /api/kitchen/orders/{order}/status
    // status: 'cooking' | 'ready'
    public function updateOrderStatus(Request $request, Order $order)
    {
        $request->validate([
            'status' => 'required|in:cooking,ready',
        ]);

        if ($request->status === 'cooking') {
            // Itemlarni cooking ga o'tkaz, order statusi 'sent' bo'lib qoladi
            $order->items()->where('status', 'pending')->update(['status' => 'cooking']);
            // Order statusini o'zgartirmaymiz (sent holida qoladi)
        } elseif ($request->status === 'ready') {
            $order->items()->whereIn('status', ['pending', 'cooking'])->update(['status' => 'ready']);
            $order->update(['status' => 'ready']);
        }

        return response()->json($order->fresh(['items']));
    }
}
