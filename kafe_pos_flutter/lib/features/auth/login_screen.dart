import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/user.dart';
import '../../core/api/api_client.dart';

// ─── Staff model (minimal, auth shart emas) ────────────────────────────────
class _StaffItem {
  final int id;
  final String name;
  final String role;
  const _StaffItem({required this.id, required this.name, required this.role});

  factory _StaffItem.fromJson(Map j) => _StaffItem(
        id:   j['id'],
        name: j['name'] ?? '',
        role: j['role'] ?? '',
      );

  String get roleLabel {
    const m = {'admin': 'Admin', 'manager': 'Menejer', 'cashier': 'Kassir', 'waiter': 'Ofitsiant', 'kitchen': 'Oshpaz'};
    return m[role] ?? role;
  }

  Color get roleColor {
    const m = {
      'admin':   Color(0xFF7C3AED),
      'manager': Color(0xFF2563EB),
      'cashier': Color(0xFF0891B2),
      'waiter':  Color(0xFFD97706),
      'kitchen': Color(0xFFDC2626),
    };
    return m[role] ?? AppColors.muted;
  }

  String get roleIcon {
    const m = {'admin': '👑', 'manager': '🏆', 'cashier': '💵', 'waiter': '🍽️', 'kitchen': '👨‍🍳'};
    return m[role] ?? '👤';
  }
}

// ─── LoginScreen ───────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {

  // Rejim: 'staff' = xodim tanlash, 'pin' = PIN kiritish, 'password' = parol
  String _mode = 'staff';

  // Staff list
  List<_StaffItem> _staff     = [];
  bool             _staffLoad = false;
  _StaffItem?      _selected;

  // PIN
  String _pin = '';
  static const _keys = ['1','2','3','4','5','6','7','8','9','⌫','0','✓'];

  // Password
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool  _passVisible = false;

  // Shake animation
  late AnimationController _shakeCtrl;
  late Animation<double>   _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() => _staffLoad = true);
    try {
      final res = await ApiClient().get('/auth/active-staff');
      if (mounted) {
        setState(() {
          _staff     = (res.data as List).map((j) => _StaffItem.fromJson(j)).toList();
          _staffLoad = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _staffLoad = false);
    }
  }

  void _selectStaff(_StaffItem item) {
    setState(() {
      _selected = item;
      _mode     = 'pin';
      _pin      = '';
    });
  }

  void _onKey(String k) {
    if (k == '⌫') {
      setState(() => _pin = _pin.isEmpty ? '' : _pin.substring(0, _pin.length - 1));
    } else if (k == '✓') {
      _submitPin();
    } else {
      if (_pin.length < 6) {
        setState(() => _pin += k);
        if (_pin.length >= 4) _submitPin();  // 4 raqam to'lsa — avtomatik yuborish
      }
    }
  }

  Future<void> _submitPin() async {
    if (_pin.length < 4) { _shake(); return; }
    final auth = context.read<AuthProvider>();
    try {
      final user = await auth.loginByPin(_pin);
      _navigate(user);
    } catch (e) {
      setState(() => _pin = '');
      _shake();
      _snack(auth.error ?? 'PIN noto\'g\'ri', error: true);
    }
  }

  Future<void> _submitPassword() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      _snack('Email va parolni kiriting', error: true);
      return;
    }
    final auth = context.read<AuthProvider>();
    try {
      final user = await auth.loginByPassword(_emailCtrl.text.trim(), _passCtrl.text);
      _navigate(user);
    } catch (e) {
      _snack(auth.error ?? 'Email yoki parol noto\'g\'ri', error: true);
    }
  }

  void _navigate(AppUser user) {
    if (user.isManagerOrAdmin) context.go('/admin');
    else if (user.isCashier)   context.go('/cashier');
    else if (user.isKitchen)   context.go('/kitchen');
    else                       context.go('/waiter');
  }

  void _shake() => _shakeCtrl.forward(from: 0);

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.danger : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Fon bezak
          Positioned(top: -80, right: -80, child: _bgCircle(280, 0.06)),
          Positioned(bottom: -60, left: -60, child: _bgCircle(200, 0.04)),

          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _mode == 'staff'
                        ? _buildStaffGrid()
                        : _mode == 'pin'
                            ? _buildPinScreen()
                            : _buildPasswordScreen(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: const Icon(Icons.local_cafe, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kafe POS', style: TextStyle(color: AppColors.text, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                Text('Tizimga kirish', style: TextStyle(color: AppColors.muted, fontSize: 11)),
              ],
            ),
          ),
          // Parol bilan kirish tugmasi
          TextButton.icon(
            onPressed: () => setState(() => _mode = _mode == 'password' ? 'staff' : 'password'),
            icon: Icon(_mode == 'password' ? Icons.people_outline : Icons.lock_outline, color: AppColors.muted, size: 14),
            label: Text(_mode == 'password' ? 'Orqaga' : 'Parol', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ),
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined, color: AppColors.muted, size: 20),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  // ── Xodimlar grid ────────────────────────────────────────────────────────────
  Widget _buildStaffGrid() {
    if (_staffLoad) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_staff.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline, color: AppColors.muted, size: 48),
            const SizedBox(height: 12),
            const Text('Xodimlar topilmadi', style: TextStyle(color: AppColors.muted, fontSize: 15)),
            const SizedBox(height: 8),
            const Text('Server bilan ulanishni tekshiring', style: TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadStaff,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Qayta urinish'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text('Kim siz?', style: TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w800)),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _staff.length,
            itemBuilder: (_, i) => _StaffCard(item: _staff[i], onTap: () => _selectStaff(_staff[i])),
          ),
        ),
      ],
    );
  }

  // ── PIN ekrani ───────────────────────────────────────────────────────────────
  Widget _buildPinScreen() {
    final auth = context.watch<AuthProvider>();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            children: [
              // Tanlangan xodim
              if (_selected != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_selected!.roleIcon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_selected!.name, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(_selected!.roleLabel, style: TextStyle(color: _selected!.roleColor, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => setState(() { _mode = 'staff'; _pin = ''; }),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(6)),
                          child: const Icon(Icons.close, color: AppColors.muted, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              const Text('PIN kiriting', style: TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 16),

              // PIN dots
              AnimatedBuilder(
                animation: _shakeAnim,
                builder: (_, child) {
                  final dx = _shakeAnim.value == 0
                      ? 0.0
                      : (8 * (0.5 - _shakeAnim.value)).abs() * (_shakeCtrl.value > 0.5 ? -1 : 1);
                  return Transform.translate(offset: Offset(dx * 4, 0), child: child);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) {
                    final filled = i < _pin.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 7),
                      width: filled ? 18 : 12,
                      height: filled ? 18 : 12,
                      decoration: BoxDecoration(
                        color: filled ? AppColors.primary : Colors.transparent,
                        border: Border.all(color: filled ? AppColors.primary : AppColors.border, width: filled ? 0 : 2),
                        shape: BoxShape.circle,
                        boxShadow: filled ? [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 8)] : null,
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 28),

              // Numpad
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.55,
                children: _keys.map((k) => _KeyBtn(k: k, loading: auth.loading, onTap: () => _onKey(k))).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Parol ekrani ─────────────────────────────────────────────────────────────
  Widget _buildPasswordScreen() {
    final auth = context.watch<AuthProvider>();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            children: [
              const Icon(Icons.lock_outline, color: AppColors.primary, size: 48),
              const SizedBox(height: 16),
              const Text('Admin kirishi', style: TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Email va parol bilan kirish', style: TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 28),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppColors.text),
                decoration: _fieldDec('Email', Icons.email_outlined),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passCtrl,
                obscureText: !_passVisible,
                style: const TextStyle(color: AppColors.text),
                decoration: _fieldDec('Parol', Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(_passVisible ? Icons.visibility_off : Icons.visibility, color: AppColors.muted),
                    onPressed: () => setState(() => _passVisible = !_passVisible),
                  )),
                onSubmitted: (_) => _submitPassword(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: auth.loading ? null : _submitPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                    shadowColor: AppColors.primary.withOpacity(0.4),
                  ),
                  child: auth.loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Kirish', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bgCircle(double size, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withOpacity(opacity)),
  );

  InputDecoration _fieldDec(String hint, IconData icon, {Widget? suffix}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.border),
    prefixIcon: Icon(icon, color: AppColors.muted),
    suffixIcon: suffix,
    filled: true, fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
  );
}

// ─── Staff Card ───────────────────────────────────────────────────────────────
class _StaffCard extends StatelessWidget {
  final _StaffItem item;
  final VoidCallback onTap;

  const _StaffCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: item.roleColor.withOpacity(0.12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar daire
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: item.roleColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: item.roleColor.withOpacity(0.4), width: 2),
                ),
                child: Center(
                  child: Text(item.roleIcon, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  item.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: item.roleColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(item.roleLabel, style: TextStyle(color: item.roleColor, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Key Button ───────────────────────────────────────────────────────────────
class _KeyBtn extends StatelessWidget {
  final String k;
  final bool loading;
  final VoidCallback onTap;

  const _KeyBtn({required this.k, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isConfirm = k == '✓';
    final isDelete  = k == '⌫';

    return Material(
      color: isConfirm ? AppColors.primary : isDelete ? AppColors.surface : AppColors.card,
      borderRadius: BorderRadius.circular(14),
      elevation: isConfirm ? 4 : 0,
      shadowColor: isConfirm ? AppColors.primary.withOpacity(0.4) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        splashColor: isConfirm ? Colors.white24 : AppColors.primary.withOpacity(0.12),
        onTap: loading ? null : onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: isConfirm || isDelete ? null : Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: Center(
            child: loading && isConfirm
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : isDelete
                    ? const Icon(Icons.backspace_outlined, color: AppColors.muted, size: 22)
                    : Text(k, style: TextStyle(color: isConfirm ? Colors.white : AppColors.text, fontSize: 22, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}
