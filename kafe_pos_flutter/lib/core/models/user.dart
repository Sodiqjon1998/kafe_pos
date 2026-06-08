class AppUser {
  final int id;
  final String name;
  final String? email;
  final String? pin;
  final String role;
  final bool isActive;

  const AppUser({
    required this.id,
    required this.name,
    this.email,
    this.pin,
    required this.role,
    this.isActive = true,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'],
        name: j['name'] ?? '',
        email: j['email'],
        pin: j['pin'],
        role: j['role'] ?? 'waiter',
        isActive: j['is_active'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'pin': pin,
        'role': role,
        'is_active': isActive,
      };

  bool get isManagerOrAdmin => role == 'admin' || role == 'manager';
  bool get isAdmin => role == 'admin';

  String get roleLabel {
    const labels = {
      'admin':   'Admin',
      'manager': 'Menejer',
      'cashier': 'Kassir',
      'waiter':  'Ofitsiant',
      'kitchen': 'Oshpaz',
    };
    return labels[role] ?? role;
  }
}
