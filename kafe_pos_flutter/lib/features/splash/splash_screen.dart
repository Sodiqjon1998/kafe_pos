import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    // Kitchen APK — login shart emas, to'g'ridan-to'g'ri oshpaz ekrani
    if (AppConfig.isKitchenMode) {
      context.go('/kitchen');
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok   = await auth.checkAuth();
    if (!mounted) return;

    if (ok) {
      _navigateByRole(auth);
    } else {
      context.go('/login');
    }
  }

  void _navigateByRole(AuthProvider auth) {
    // Agar APK uchun rol belgilangan bo'lsa, shu rolga o'tish
    if (AppConfig.isAdminMode) {
      context.go('/admin');
      return;
    } else if (AppConfig.isCashierMode) {
      context.go('/cashier');
      return;
    } else if (AppConfig.isWaiterMode) {
      context.go('/waiter');
      return;
    }

    // Oddiy APK: foydalanuvchi DB dagi roliga qarab yo'naltirish
    final user = auth.user!;
    if (user.isManagerOrAdmin) {
      context.go('/admin');
    } else if (user.isCashier) {
      context.go('/cashier');
    } else if (user.isKitchen) {
      context.go('/kitchen');
    } else {
      context.go('/waiter');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.local_cafe,
                      color: Colors.white, size: 48),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppConfig.appName,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppConfig.hasFixedRole
                    ? AppConfig.roleLabel
                    : 'Restoran boshqaruv tizimi',
                style:
                    const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
