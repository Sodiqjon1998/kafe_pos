import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  bool _loading = false;
  String? _error;

  AppUser? get user    => _user;
  bool get loading     => _loading;
  String? get error    => _error;
  bool get isLoggedIn  => _user != null;
  bool get isManager   => _user?.isManagerOrAdmin ?? false;

  final _api = ApiClient();

  // ── Ilova ochilganda tokenni tekshirish ───────────────────────────────────

  Future<bool> checkAuth() async {
    final token = await _api.getToken();
    if (token == null) return false;

    try {
      final res = await _api.get('/auth/me');
      _user = AppUser.fromJson(res.data as Map<String, dynamic>);
      notifyListeners();
      return true;
    } catch (_) {
      await _api.removeToken();
      return false;
    }
  }

  // ── PIN bilan kirish ───────────────────────────────────────────────────────

  Future<AppUser> loginByPin(String pin) async {
    _setLoading(true);
    try {
      final res = await _api.post('/auth/pin', data: {'pin': pin});
      final data = res.data as Map<String, dynamic>;
      await _api.saveToken(data['token']);
      _user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      _error = null;
      notifyListeners();
      return _user!;
    } catch (e) {
      _error = ApiClient.errorMessage(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ── Email + parol bilan kirish ─────────────────────────────────────────────

  Future<AppUser> loginByPassword(String email, String password) async {
    _setLoading(true);
    try {
      final res = await _api.post('/auth/login',
          data: {'email': email, 'password': password});
      final data = res.data as Map<String, dynamic>;
      await _api.saveToken(data['token']);
      _user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      _error = null;
      notifyListeners();
      return _user!;
    } catch (e) {
      _error = ApiClient.errorMessage(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ── Chiqish ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {}
    await _api.removeToken();
    _user = null;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }
}
