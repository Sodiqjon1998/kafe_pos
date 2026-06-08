import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../models/order_model.dart';

class OrdersProvider extends ChangeNotifier {
  List<Order> _orders = [];
  Order? _currentOrder;
  bool _loading = false;
  bool _actionLoading = false;
  String? _error;

  List<Order> get orders        => _orders;
  Order? get currentOrder       => _currentOrder;
  bool get loading              => _loading;
  bool get actionLoading        => _actionLoading;
  String? get error             => _error;

  final _api = ApiClient();

  // ── Buyurtmalar ro'yxati ──────────────────────────────────────────────────

  Future<void> fetchOrders({bool myOrders = false}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final params = myOrders
          ? {'mine': '1', 'all': '1'}
          : <String, String>{};
      final res = await _api.get('/orders', params: params);
      _orders = (res.data as List)
          .map((o) => Order.fromJson(o as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = ApiClient.errorMessage(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Admin: barcha buyurtmalarni yuklash (to'langan ham) ──────────────────

  List<Order> _allOrders = [];
  List<Order> get allOrders => _allOrders;

  Future<void> fetchAllOrders() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.get('/orders', params: {'all': '1'});
      _allOrders = (res.data as List)
          .map((o) => Order.fromJson(o as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = ApiClient.errorMessage(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Yangi buyurtma yaratish ───────────────────────────────────────────────

  Future<Order> createOrder({
    int? tableId,
    String type = 'dine_in',
    int guestsCount = 1,
  }) async {
    _actionLoading = true;
    notifyListeners();
    try {
      final res = await _api.post('/orders', data: {
        if (tableId != null) 'table_id': tableId,
        'type': type,
        'guests_count': guestsCount,
      });
      final order = Order.fromJson(res.data as Map<String, dynamic>);
      _currentOrder = order;
      _orders.insert(0, order);
      notifyListeners();
      return order;
    } catch (e) {
      _error = ApiClient.errorMessage(e);
      rethrow;
    } finally {
      _actionLoading = false;
      notifyListeners();
    }
  }

  // ── Buyurtmani yuklash ────────────────────────────────────────────────────

  Future<void> loadOrder(int id) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await _api.get('/orders/$id');
      _currentOrder = Order.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      _error = ApiClient.errorMessage(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Mahsulot qo'shish ─────────────────────────────────────────────────────

  Future<void> addItem(
    int orderId,
    int productId,
    int quantity, {
    String? note,
  }) async {
    _actionLoading = true;
    notifyListeners();
    try {
      await _api.post('/orders/$orderId/items', data: {
        'product_id': productId,
        'quantity': quantity,
        if (note != null) 'note': note,
      });
      await loadOrder(orderId);
    } catch (e) {
      _error = ApiClient.errorMessage(e);
      rethrow;
    } finally {
      _actionLoading = false;
      notifyListeners();
    }
  }

  // ── Miqdor o'zgartirish ───────────────────────────────────────────────────

  Future<void> updateItem(int orderId, int itemId, int quantity) async {
    _actionLoading = true;
    notifyListeners();
    try {
      await _api.patch('/orders/$orderId/items/$itemId',
          data: {'quantity': quantity});
      await loadOrder(orderId);
    } catch (e) {
      _error = ApiClient.errorMessage(e);
      rethrow;
    } finally {
      _actionLoading = false;
      notifyListeners();
    }
  }

  // ── Elementni o'chirish ───────────────────────────────────────────────────

  Future<void> removeItem(int orderId, int itemId) async {
    _actionLoading = true;
    notifyListeners();
    try {
      await _api.delete('/orders/$orderId/items/$itemId');
      await loadOrder(orderId);
    } catch (e) {
      _error = ApiClient.errorMessage(e);
      rethrow;
    } finally {
      _actionLoading = false;
      notifyListeners();
    }
  }

  // ── Oshpazga yuborish ─────────────────────────────────────────────────────

  Future<String> sendToKitchen(int orderId) async {
    _actionLoading = true;
    notifyListeners();
    try {
      final res = await _api.post('/orders/$orderId/send');
      await loadOrder(orderId);
      return (res.data as Map<String, dynamic>)['message']?.toString() ??
          'Yuborildi';
    } catch (e) {
      _error = ApiClient.errorMessage(e);
      rethrow;
    } finally {
      _actionLoading = false;
      notifyListeners();
    }
  }

  // ── Status o'zgartirish ───────────────────────────────────────────────────

  Future<void> updateStatus(int orderId, String status) async {
    _actionLoading = true;
    notifyListeners();
    try {
      await _api.patch('/orders/$orderId/status', data: {'status': status});
      await loadOrder(orderId);
    } catch (e) {
      _error = ApiClient.errorMessage(e);
      rethrow;
    } finally {
      _actionLoading = false;
      notifyListeners();
    }
  }

  // ── Buyurtmani bekor qilish ───────────────────────────────────────────────

  Future<void> cancelOrder(int orderId) async {
    try {
      await _api.patch('/orders/$orderId/status', data: {'status': 'cancelled'});
    } catch (_) {
      // bekor qilish muvaffaqiyatsiz bo'lsa ham davomini bloklama
    }
    _currentOrder = null;
    _orders.removeWhere((o) => o.id == orderId);
    notifyListeners();
  }

  // ── Tozalash ──────────────────────────────────────────────────────────────

  void clearCurrent() {
    _currentOrder = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
