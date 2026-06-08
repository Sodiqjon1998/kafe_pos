import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _pinMode = true;
  String _pin = '';
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _passVisible = false;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  static const _keys = ['1','2','3','4','5','6','7','8','9','⌫','0','✓'];

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
  }

  void _shake() {
    _shakeCtrl.forward(from: 0);
  }

  void _onKey(String k) {
    if (k == '⌫') {
      setState(() => _pin = _pin.isEmpty ? '' : _pin.substring(0, _pin.length - 1));
    } else if (k == '✓') {
      _submitPin();
    } else {
      if (_pin.length < 6) setState(() => _pin += k);
    }
  }

  Future<void> _submitPin() async {
    if (_pin.length < 4) {
      _shake();
      _snack('PIN kamida 4 ta raqam', error: true);
      return;
    }
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
      final user = await auth.loginByPassword(
          _emailCtrl.text.trim(), _passCtrl.text);
      _navigate(user);
    } catch (e) {
      _snack(auth.error ?? 'Email yoki parol noto\'g\'ri', error: true);
    }
  }

  void _navigate(AppUser user) {
    if (user.isManagerOrAdmin) {
      context.go('/admin');
    } else {
      context.go('/waiter');
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.danger : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Dekorativ fon doiralari
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.04),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    children: [
                      // Logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.3), width: 2),
                        ),
                        child: const Center(
                          child: Icon(Icons.local_cafe, color: AppColors.primary, size: 38),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Kafe POS',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      const Text('Tizimga kirish',
                          style: TextStyle(color: AppColors.muted, fontSize: 13)),
                      const SizedBox(height: 28),

                      // Mode toggle
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            _modeBtn('PIN', _pinMode, () {
                              setState(() {
                                _pinMode = true;
                                _pin = '';
                              });
                            }),
                            _modeBtn('Parol', !_pinMode, () {
                              setState(() => _pinMode = false);
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (_pinMode)
                        _buildPinPad(auth)
                      else
                        _buildPasswordForm(auth),

                      const SizedBox(height: 20),
                      // Sozlamalar
                      TextButton.icon(
                        onPressed: () => context.push('/settings'),
                        icon: const Icon(Icons.settings_outlined,
                            color: AppColors.muted, size: 16),
                        label: const Text('Server sozlamalari',
                            style: TextStyle(color: AppColors.muted, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeBtn(String label, bool isActive, VoidCallback onTap) {
    final icon = label == 'PIN' ? Icons.dialpad : Icons.lock_outline;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3))
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: isActive ? AppColors.white : AppColors.muted, size: 14),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? AppColors.white : AppColors.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinPad(AuthProvider auth) {
    return Column(
      children: [
        // PIN dots with shake
        AnimatedBuilder(
          animation: _shakeAnim,
          builder: (_, child) {
            final dx = _shakeAnim.value == 0
                ? 0.0
                : (8 * (0.5 - _shakeAnim.value)).abs() *
                    (_shakeCtrl.value > 0.5 ? -1 : 1);
            return Transform.translate(offset: Offset(dx * 4, 0), child: child);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) {
              final filled = i < _pin.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 7),
                width: filled ? 20 : 13,
                height: filled ? 20 : 13,
                decoration: BoxDecoration(
                  color: filled ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: filled
                        ? AppColors.primary
                        : AppColors.border,
                    width: filled ? 0 : 2,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: filled
                      ? [
                          BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1)
                        ]
                      : null,
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
          children: _keys.map((k) => _keyBtn(k, auth)).toList(),
        ),
      ],
    );
  }

  Widget _keyBtn(String k, AuthProvider auth) {
    final isAction = k == '✓' || k == '⌫';
    final isConfirm = k == '✓';
    final isDelete = k == '⌫';

    return Material(
      color: isConfirm
          ? AppColors.primary
          : isDelete
              ? AppColors.surface
              : AppColors.card,
      borderRadius: BorderRadius.circular(14),
      elevation: isConfirm ? 4 : 0,
      shadowColor: isConfirm ? AppColors.primary.withOpacity(0.4) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        splashColor: isConfirm
            ? Colors.white24
            : AppColors.primary.withOpacity(0.12),
        onTap: auth.loading ? null : () => _onKey(k),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: isConfirm || isDelete
                ? null
                : Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: Center(
            child: auth.loading && isConfirm
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: AppColors.white, strokeWidth: 2))
                : isDelete
                    ? const Icon(Icons.backspace_outlined,
                        color: AppColors.muted, size: 22)
                    : Text(
                        k,
                        style: TextStyle(
                          color:
                              isConfirm ? AppColors.white : AppColors.text,
                          fontSize: isConfirm ? 20 : 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordForm(AuthProvider auth) {
    return Column(
      children: [
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: AppColors.text),
          decoration: _inputDecoration('Email', Icons.email_outlined),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passCtrl,
          obscureText: !_passVisible,
          style: const TextStyle(color: AppColors.text),
          decoration: _inputDecoration('Parol', Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(
                  _passVisible ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.muted,
                ),
                onPressed: () =>
                    setState(() => _passVisible = !_passVisible),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 4,
              shadowColor: AppColors.primary.withOpacity(0.4),
            ),
            child: auth.loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: AppColors.white, strokeWidth: 2.5))
                : const Text('Kirish',
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon,
      {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.border),
      prefixIcon: Icon(icon, color: AppColors.muted),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }
}
