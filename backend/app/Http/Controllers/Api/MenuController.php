<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class MenuController extends Controller
{
    // GET /api/menu — kategoriya va mahsulotlar
    public function index()
    {
        $categories = Category::where('is_active', true)
            ->orderBy('sort_order')
            ->with(['products' => function ($q) {
                $q->where('is_active', true)->orderBy('sort_order');
            }])
            ->get();

        return response()->json($categories);
    }

    // GET /api/categories
    public function categories()
    {
        return response()->json(
            Category::orderBy('sort_order')->get()
        );
    }

    // POST /api/categories
    public function storeCategory(Request $request)
    {
        $data = $request->validate([
            'name_uz'    => 'required|string',
            'name_ru'    => 'required|string',
            'icon'       => 'nullable|string',
            'color'      => 'nullable|string',
            'sort_order' => 'integer',
            'is_active'  => 'boolean',
        ]);
        return response()->json(Category::create($data), 201);
    }

    // PUT /api/categories/{id}
    public function updateCategory(Request $request, Category $category)
    {
        $category->update($request->validate([
            'name_uz'    => 'string',
            'name_ru'    => 'string',
            'icon'       => 'nullable|string',
            'color'      => 'nullable|string',
            'sort_order' => 'integer',
            'is_active'  => 'boolean',
        ]));
        return response()->json($category);
    }

    // DELETE /api/categories/{id}
    public function destroyCategory(Category $category)
    {
        $category->delete();
        return response()->json(null, 204);
    }

    // GET /api/products
    public function products()
    {
        return response()->json(
            Product::with('category')->orderBy('sort_order')->get()
        );
    }

    // POST /api/products
    public function storeProduct(Request $request)
    {
        $data = $request->validate([
            'category_id'    => 'required|exists:categories,id',
            'name_uz'        => 'required|string',
            'name_ru'        => 'required|string',
            'price'          => 'required|numeric|min:0',
            'unit_uz'        => 'nullable|string',
            'unit_ru'        => 'nullable|string',
            'cook_time'      => 'integer|min:0',
            'is_available'   => 'boolean',
            'is_active'      => 'boolean',
            'sort_order'     => 'integer',
        ]);

        if ($request->hasFile('image')) {
            $data['image'] = $this->saveImage($request->file('image'));
        }

        return response()->json(Product::create($data), 201);
    }

    // PUT /api/products/{id}
    public function updateProduct(Request $request, Product $product)
    {
        $data = $request->validate([
            'category_id'  => 'exists:categories,id',
            'name_uz'      => 'string',
            'name_ru'      => 'string',
            'price'        => 'numeric|min:0',
            'is_available' => 'boolean',
            'is_active'    => 'boolean',
        ]);

        if ($request->hasFile('image')) {
            $this->deleteCloudinaryImage($product->image);
            $data['image'] = $this->saveImage($request->file('image'));
        }

        $product->update($data);
        return response()->json($product->fresh());
    }

    // POST /api/products/{id}/image — rasmni yuklash
    public function uploadImage(Request $request, Product $product)
    {
        $request->validate(['image' => 'required|image|max:3072']);

        $this->deleteCloudinaryImage($product->image);
        $product->update(['image' => $this->saveImage($request->file('image'))]);
        return response()->json($product->fresh());
    }

    // DELETE /api/products/{id}/image
    public function deleteImage(Product $product)
    {
        if ($product->image) {
            $this->deleteCloudinaryImage($product->image);
            $product->update(['image' => null]);
        }
        return response()->json($product->fresh());
    }

    // DELETE /api/products/{id}
    public function destroyProduct(Product $product)
    {
        $this->deleteCloudinaryImage($product->image);
        $product->delete();
        return response()->json(null, 204);
    }

    // ── Rasmni base64 formatida saqlash (bazaga) ────────────────────────────
    private function saveImage($file): string
    {
        $imageData = file_get_contents($file->getRealPath());
        $mime      = $file->getMimeType();
        return 'data:' . $mime . ';base64,' . base64_encode($imageData);
    }

    // ── Rasmni "o'chirish" — base64 uchun hech narsa qilish shart emas ───────
    private function deleteCloudinaryImage(?string $imageUrl): void
    {
        // Base64 bazada saqlanadi — alohida o'chirish kerak emas
        // Eski URL bo'lsa (local fayl) — o'chirib tashlaymiz
        if ($imageUrl && str_contains($imageUrl, '/uploads/products/')) {
            $path = public_path('uploads/products/' . basename($imageUrl));
            if (file_exists($path)) @unlink($path);
        }
    }
}
