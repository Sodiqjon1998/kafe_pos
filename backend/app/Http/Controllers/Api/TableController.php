<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Hall;
use App\Models\Table;
use Illuminate\Http\Request;

class TableController extends Controller
{
    // GET /api/halls — zal va stollar
    public function halls()
    {
        $halls = Hall::where('is_active', true)
            ->orderBy('sort_order')
            ->with(['tables' => function ($q) {
                $q->where('is_active', true)
                  ->with(['activeOrder:id,table_id,order_number,status,total,waiter_id', 'activeOrder.waiter:id,name']);
            }])
            ->get();

        return response()->json($halls);
    }

    // GET /api/tables
    public function index()
    {
        return response()->json(
            Table::with('hall')->orderBy('hall_id')->orderBy('name')->get()
        );
    }

    // PATCH /api/tables/{id}/status
    public function updateStatus(Request $request, Table $table)
    {
        $request->validate([
            'status' => 'required|in:free,occupied,reserved,bill_requested',
        ]);
        $table->update(['status' => $request->status]);
        return response()->json($table);
    }

    // POST /api/halls
    public function storeHall(Request $request)
    {
        $data = $request->validate([
            'name_uz'    => 'required|string',
            'name_ru'    => 'required|string',
            'sort_order' => 'integer',
        ]);
        return response()->json(Hall::create($data), 201);
    }

    // POST /api/tables
    public function storeTable(Request $request)
    {
        $data = $request->validate([
            'hall_id'  => 'required|exists:halls,id',
            'name'     => 'required|string',
            'capacity' => 'integer|min:1',
            'shape'    => 'in:square,round,rectangle',
        ]);
        return response()->json(Table::create($data), 201);
    }

    // PUT /api/tables/{id}
    public function updateTable(Request $request, Table $table)
    {
        $table->update($request->validate([
            'name'      => 'string',
            'capacity'  => 'integer|min:1',
            'is_active' => 'boolean',
        ]));
        return response()->json($table);
    }

    // DELETE /api/tables/{id}
    public function destroyTable(Table $table)
    {
        $table->delete();
        return response()->json(null, 204);
    }
}
