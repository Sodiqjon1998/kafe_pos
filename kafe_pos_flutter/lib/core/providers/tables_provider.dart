import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../models/table_model.dart';

class TablesProvider extends ChangeNotifier {
  List<Hall> _halls = [];
  bool _loading = false;
  String? _error;

  List<Hall> get halls   => _halls;
  bool get loading       => _loading;
  String? get error      => _error;

  final _api = ApiClient();

  // ── Zallar va stollarni yuklash ───────────────────────────────────────────

  Future<void> fetchHalls() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.get('/halls');
      _halls = (res.data as List)
          .map((h) => Hall.fromJson(h as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = ApiClient.errorMessage(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Stol holatini yangilash ────────────────────────────────────────────────

  Future<void> updateTableStatus(int tableId, String status) async {
    try {
      await _api.patch('/tables/$tableId/status', data: {'status': status});
      // Localda ham yangilaymiz
      _halls = _halls.map((hall) {
        final tables = hall.tables.map((t) {
          if (t.id == tableId) return t.copyWith(status: status);
          return t;
        }).toList();
        return Hall(
          id: hall.id,
          nameUz: hall.nameUz,
          nameRu: hall.nameRu,
          tables: tables,
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      _error = ApiClient.errorMessage(e);
      notifyListeners();
    }
  }

  // ── Stol bo'yicha aktiv buyurtmani olish ──────────────────────────────────

  TableModel? findTable(int tableId) {
    for (final hall in _halls) {
      for (final table in hall.tables) {
        if (table.id == tableId) return table;
      }
    }
    return null;
  }
}
