<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Table;
use App\Models\Shift;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OrderController extends Controller
{
    /**
     * Barcha aktiv buyurtmalar
     */
    public function index(Request $request)
    {
        $query = Order::with(['table', 'waiter:id,name', 'items.product', 'payment:id,order_id,method,amount'])->latest();

        // ?mine=1 — faqat shu ofitsiantning buyurtmalari
        if ($request->boolean('mine')) {
            $query->where('waiter_id', auth()->id());
        }

        // ?all=1 bo'lsa barcha orderlar (tarix uchun), aks holda faqat aktiv
        if (!$request->boolean('all')) {
            $query->active();
        }

        return response()->json($query->get());
    }

    /**
     * Yangi buyurtma ochish
     */
    public function store(Request $request)
    {
        $request->validate([
            'table_id'     => 'nullable|exists:tables,id',
            'type'         => 'in:dine_in,takeaway',
            'guests_count' => 'integer|min:1',
        ]);

        $shift = Shift::current();

        $order = DB::transaction(function () use ($request, $shift) {
            $order = Order::create([
                'order_number'  => Order::generateNumber(),
                'table_id'      => $request->table_id,
                'waiter_id'     => auth()->id(),
                'shift_id'      => $shift?->id,
                'type'          => $request->type ?? 'dine_in',
                'guests_count'  => $request->guests_count ?? 1,
                'status'        => 'open',
                'opened_at'     => now(),
            ]);

            // Stolni band qilish
            if ($request->table_id) {
                Table::where('id', $request->table_id)
                    ->update(['status' => 'occupied']);
            }

            return $order;
        });

        return response()->json(
            $order->load(['table', 'items']),
            201
        );
    }

    /**
     * Buyurtma ko'rish
     */
    public function show(Order $order)
    {
        return response()->json(
            $order->load(['table', 'waiter:id,name', 'items.product', 'items.modifiers', 'payment'])
        );
    }

    /**
     * Buyurtmaga mahsulot qo'shish
     */
    public function addItem(Request $request, Order $order)
    {
        $request->validate([
            'product_id' => 'required|exists:products,id',
            'quantity'   => 'required|integer|min:1',
            'note'       => 'nullable|string',
            'modifiers'  => 'array',
        ]);

        $product = \App\Models\Product::findOrFail($request->product_id);

        $item = DB::transaction(function () use ($request, $order, $product) {
            // cook_time = 0 bo'lsa (ichimlik, non) — darhol tayyor
            $itemStatus = ($product->cook_time == 0) ? 'ready' : 'pending';

            $item = $order->items()->create([
                'product_id'    => $product->id,
                'product_name'  => $product->name_uz . ' / ' . $product->name_ru,
                'product_price' => $product->price,
                'quantity'      => $request->quantity,
                'total'         => $product->price * $request->quantity,
                'note'          => $request->note,
                'status'        => $itemStatus,
            ]);

            // Modifikatorlar
            if ($request->modifiers) {
                foreach ($request->modifiers as $modId) {
                    $mod = \App\Models\Modifier::find($modId);
                    if ($mod) {
                        $item->modifiers()->create([
                            'modifier_id'  => $mod->id,
                            'modifier_name'=> $mod->name_uz . ' / ' . $mod->name_ru,
                            'price_change' => $mod->price_change,
                        ]);
                    }
                }
                $item->recalculate();
            }

            $order->recalculate();

            return $item;
        });

        return response()->json($item, 201);
    }

    /**
     * Buyurtmani oshpazga yuborish
     */
    public function sendToKitchen(Order $order)
    {
        $pendingItems = $order->items()->where('status', 'pending')->get();
        $hasAnyItems  = $order->items()->count() > 0;

        if (!$hasAnyItems) {
            return response()->json(['message' => 'Buyurtmada mahsulot yo\'q'], 422);
        }

        if ($pendingItems->isEmpty()) {
            // Hammasi instant (cook_time=0) — order darhol ready
            $order->update(['status' => 'ready']);
            return response()->json(['message' => 'Barcha mahsulotlar tayyor']);
        }

        // Pending itemlarni oshpazga yuborish uchun belgilash
        $pendingItems->each(function ($item) {
            $item->update([
                'sent_by' => auth()->id(),
                'sent_at' => now(),
            ]);
        });

        $order->update(['status' => 'sent']);

        return response()->json(['message' => 'Oshpazga yuborildi']);
    }

    /**
     * Item miqdorini o'zgartirish
     */
    public function updateItem(Request $request, Order $order, OrderItem $item)
    {
        $request->validate(['quantity' => 'required|integer|min:1']);
        $item->update([
            'quantity' => $request->quantity,
            'total'    => $item->product_price * $request->quantity,
        ]);
        $order->recalculate();
        return response()->json($item->fresh());
    }

    /**
     * Item o'chirish
     */
    public function removeItem(Order $order, OrderItem $item)
    {
        $item->delete();
        $order->recalculate();
        return response()->json(null, 204);
    }

    /**
     * Buyurtma statusini o'zgartirish
     */
    public function updateStatus(Request $request, Order $order)
    {
        $request->validate([
            'status' => 'required|in:open,sent,ready,bill,paid,cancelled',
        ]);

        $order->update(['status' => $request->status]);

        // Agar to'landi yoki bekor bo'lsa, stolni bo'shat
        if (in_array($request->status, ['paid', 'cancelled']) && $order->table_id) {
            Table::where('id', $order->table_id)->update(['status' => 'free']);
            $order->update(['closed_at' => now()]);
        }

        return response()->json($order->fresh());
    }
}
