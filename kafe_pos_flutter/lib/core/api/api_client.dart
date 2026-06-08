import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ilovaning yagona HTTP klienti.
/// Singleton — [ApiClient()] orqali ishlatiladi.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();
  factory ApiClient() => instance;

  late Dio _dio;
  String _baseUrl = 'http://192.168.1.1';
  String? _cachedToken; // SharedPreferences har so'rovda o'qilmasin

  Dio get dio => _dio;
  String get baseUrl => _baseUrl;

  /// Ilova ishga tushganda chaqiriladi.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('api_base_url') ?? 'http://192.168.1.1';
    _cachedToken = prefs.getString('pos_token');
    _buildDio();
  }

  void _buildDio() {
    _dio = Dio(BaseOptions(
      baseUrl: '$_baseUrl/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.clear();
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Cache dan olish — SharedPreferences har so'rovda emas
        if (_cachedToken != null) {
          options.headers['Authorization'] = 'Bearer $_cachedToken';
        }
        return handler.next(options);
      },
      onError: (err, handler) {
        // 401 → tokenni tozalash (AuthProvider logout qiladi)
        if (err.response?.statusCode == 401) {
          _cachedToken = null;
          SharedPreferences.getInstance()
              .then((p) => p.remove('pos_token'));
        }
        return handler.next(err);
      },
    ));
  }

  // ── URL sozlash ────────────────────────────────────────────────────────────

  Future<void> updateBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', url);
    _baseUrl = url;
    _buildDio();
  }

  // ── Token ──────────────────────────────────────────────────────────────────

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pos_token', token);
    _buildDio(); // yangi token bilan interceptor yangilansin
  }

  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString('pos_token');
    return _cachedToken;
  }

  Future<void> removeToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pos_token');
  }

  // ── HTTP metodlar ──────────────────────────────────────────────────────────

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  /// Xato xabarini chiqarish uchun yordamchi
  static String errorMessage(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Server javob bermadi. URL ni tekshiring.';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Ulanish xatosi. IP manzilni tekshiring.';
      }
    }
    return e.toString();
  }
}
