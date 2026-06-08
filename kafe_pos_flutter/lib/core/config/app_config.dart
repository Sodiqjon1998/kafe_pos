/// Har bir APK uchun rol --dart-define=APP_ROLE=waiter orqali beriladi.
/// Bu singlton build vaqtida aniqlanadi, o'zgarmaydi.
class AppConfig {
  AppConfig._();

  // Build vaqtida: flutter build apk --dart-define=APP_ROLE=waiter
  static const String _role =
      String.fromEnvironment('APP_ROLE', defaultValue: '');

  static const String appName =
      String.fromEnvironment('APP_NAME', defaultValue: 'Kafe POS');

  // ── Rol tekshirish ──────────────────────────────────────────────────────────

  /// Rol belgilangan APKmi?
  static bool get hasFixedRole => _role.isNotEmpty;

  /// Faqat ofitsiant vazifasi (stollar, buyurtmalar)
  static bool get isWaiterMode => _role == 'waiter';

  /// Faqat admin boshqaruv paneli
  static bool get isAdminMode => _role == 'admin';

  /// Oshpaz display — login talab qilinmaydi
  static bool get isKitchenMode => _role == 'kitchen';

  /// Kassir — to'lov va smena boshqaruvi
  static bool get isCashierMode => _role == 'cashier';

  static String get roleLabel {
    switch (_role) {
      case 'waiter':  return 'Ofitsiant';
      case 'admin':   return 'Admin';
      case 'kitchen': return 'Oshpaz';
      case 'cashier': return 'Kassir';
      default:        return '';
    }
  }
}
