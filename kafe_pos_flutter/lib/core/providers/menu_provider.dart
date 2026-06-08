import 'package:flutter/foundation.dart' hide Category;
import '../api/api_client.dart';
import '../models/menu_model.dart';

class MenuProvider extends ChangeNotifier {
  List<Category> _categories = [];
  bool _loading = false;
  String? _error;

  List<Category> get categories => _categories;
  bool get loading              => _loading;
  String? get error             => _error;

  final _api = ApiClient();

  // ── Menyu yuklash ─────────────────────────────────────────────────────────

  Future<void> fetchMenu() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.get('/menu');
      _categories = (res.data as List)
          .map((c) => Category.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = ApiClient.errorMessage(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Admin: Kategoriya CRUD ─────────────────────────────────────────────────

  Future<void> createCategory(Map<String, dynamic> data) async {
    await _api.post('/categories', data: data);
    await fetchMenu();
  }

  Future<void> updateCategory(int id, Map<String, dynamic> data) async {
    await _api.put('/categories/$id', data: data);
    await fetchMenu();
  }

  Future<void> deleteCategory(int id) async {
    await _api.delete('/categories/$id');
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  // ── Admin: Mahsulot CRUD ───────────────────────────────────────────────────

  Future<void> createProduct(Map<String, dynamic> data) async {
    await _api.post('/products', data: data);
    await fetchMenu();
  }

  Future<void> updateProduct(int id, Map<String, dynamic> data) async {
    await _api.put('/products/$id', data: data);
    await fetchMenu();
  }

  Future<void> deleteProduct(int id) async {
    await _api.delete('/products/$id');
    _categories = _categories.map((cat) {
      return Category(
        id: cat.id,
        nameUz: cat.nameUz,
        nameRu: cat.nameRu,
        icon: cat.icon,
        color: cat.color,
        isActive: cat.isActive,
        sortOrder: cat.sortOrder,
        products: cat.products.where((p) => p.id != id).toList(),
      );
    }).toList();
    notifyListeners();
  }

  // ── Yordamchi ─────────────────────────────────────────────────────────────

  List<Product> get allProducts =>
      _categories.expand((c) => c.products).toList();
}
