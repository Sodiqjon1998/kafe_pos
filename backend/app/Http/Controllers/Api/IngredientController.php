<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Ingredient;
use App\Models\StockMovement;
use App\Models\Expense;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class IngredientController extends Controller
{
    // ── Ingredientlar ro'yxati ───────────────────────────────────────────────
    public function index()
    {
        $ingredients = Ingredient::orderBy('name')->get()->map(function ($i) {
            return array_merge($i->toArray(), ['low_stock' => $i->low_stock]);
        });

        return response()->json($ingredients);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name'          => 'required|string|max:100',
            'unit'          => 'required|string|max:20',
            'quantity'      => 'nullable|numeric|min:0',
            'min_quantity'  => 'nullable|numeric|min:0',
            'cost_per_unit' => 'nullable|numeric|min:0',
        ]);

        $ingredient = Ingredient::create($data);

        // Boshlang'ich qoldiq bo'lsa — xarajat va harakatlar tarixi yozamiz
        $qty  = floatval($data['quantity'] ?? 0);
        $cost = floatval($data['cost_per_unit'] ?? 0);
        if ($qty > 0) {
            StockMovement::create([
                'ingredient_id' => $ingredient->id,
                'type'          => 'in',
                'quantity'      => $qty,
                'cost_per_unit' => $cost,
                'reason'        => 'Boshlang\'ich qoldiq',
                'user_id'       => $request->user()?->id,
            ]);

            if ($cost > 0) {
                Expense::create([
                    'type'          => 'stock_in',
                    'amount'        => $qty * $cost,
                    'note'          => "{$ingredient->name} {$qty} {$ingredient->unit} — boshlang'ich qoldiq",
                    'user_id'       => $request->user()?->id,
                    'ingredient_id' => $ingredient->id,
                ]);
            }
        }

        return response()->json($ingredient, 201);
    }

    public function update(Request $request, Ingredient $ingredient)
    {
        $data = $request->validate([
            'name'          => 'sometimes|string|max:100',
            'unit'          => 'sometimes|string|max:20',
            'min_quantity'  => 'sometimes|numeric|min:0',
            'cost_per_unit' => 'sometimes|numeric|min:0',
        ]);

        $ingredient->update($data);
        return response()->json($ingredient->fresh());
    }

    public function destroy(Ingredient $ingredient)
    {
        $ingredient->delete();
        return response()->json(['ok' => true]);
    }

    // ── Kirim (sklad to'ldirish) ─────────────────────────────────────────────
    public function addStock(Request $request, Ingredient $ingredient)
    {
        $data = $request->validate([
            'quantity'      => 'required|numeric|min:0.001',
            'cost_per_unit' => 'nullable|numeric|min:0',
            'reason'        => 'nullable|string|max:200',
        ]);

        DB::transaction(function () use ($ingredient, $data, $request) {
            $ingredient->increment('quantity', $data['quantity']);

            $costPerUnit = $data['cost_per_unit'] ?? $ingredient->cost_per_unit;
            if (!empty($data['cost_per_unit'])) {
                $ingredient->update(['cost_per_unit' => $data['cost_per_unit']]);
            }

            StockMovement::create([
                'ingredient_id' => $ingredient->id,
                'type'          => 'in',
                'quantity'      => $data['quantity'],
                'cost_per_unit' => $costPerUnit,
                'reason'        => $data['reason'] ?? 'Kirim',
                'user_id'       => $request->user()->id,
            ]);

            // Xarajat avtomatik yoziladi
            $totalCost = $data['quantity'] * $costPerUnit;
            if ($totalCost > 0) {
                Expense::create([
                    'type'          => 'stock_in',
                    'amount'        => $totalCost,
                    'note'          => "{$ingredient->name} {$data['quantity']} {$ingredient->unit} kirim" . ($data['reason'] ? " — {$data['reason']}" : ''),
                    'user_id'       => $request->user()->id,
                    'ingredient_id' => $ingredient->id,
                ]);
            }
        });

        return response()->json($ingredient->fresh());
    }

    // ── Harakatlar tarixi ────────────────────────────────────────────────────
    public function movements(Ingredient $ingredient)
    {
        $movements = $ingredient->movements()
            ->with('user:id,name')
            ->latest()
            ->limit(100)
            ->get();

        return response()->json($movements);
    }

    // ── Mahsulot retsepti (product_ingredients) ──────────────────────────────
    public function getRecipe(Product $product)
    {
        $ingredients = $product->ingredients()->get()->map(function ($i) {
            return [
                'id'            => $i->id,
                'name'          => $i->name,
                'unit'          => $i->unit,
                'quantity'      => $i->pivot->quantity,
                'cost_per_unit' => $i->cost_per_unit,
            ];
        });

        return response()->json($ingredients);
    }

    public function saveRecipe(Request $request, Product $product)
    {
        $request->validate([
            'ingredients'              => 'required|array',
            'ingredients.*.id'        => 'required|exists:ingredients,id',
            'ingredients.*.quantity'  => 'required|numeric|min:0.001',
        ]);

        $sync = collect($request->ingredients)->mapWithKeys(function ($item) {
            return [$item['id'] => ['quantity' => $item['quantity']]];
        })->toArray();

        $product->ingredients()->sync($sync);

        return response()->json(['ok' => true]);
    }

    // ── Barcha ingredientlar qoldig'i (dashboard uchun) ─────────────────────
    public function lowStock()
    {
        $items = Ingredient::where('min_quantity', '>', 0)
            ->whereColumn('quantity', '<=', 'min_quantity')
            ->orderBy('name')
            ->get();

        return response()->json($items);
    }

    // ── Barcha mahsulotlar tannarxi (retsept asosida) ────────────────────────
    public function allRecipeCosts()
    {
        $products = Product::with('ingredients')->get();

        $costs = $products->map(function ($p) {
            $cost = $p->ingredients->sum(
                fn($i) => $i->pivot->quantity * $i->cost_per_unit
            );
            return [
                'product_id' => $p->id,
                'cost'       => round($cost),
                'has_recipe' => $p->ingredients->count() > 0,
            ];
        });

        return response()->json($costs);
    }
}
