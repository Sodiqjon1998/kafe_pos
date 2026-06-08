import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/models/table_model.dart';
import 'features/admin/admin_home.dart';
import 'features/auth/login_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/waiter/order_screen.dart';
import 'features/waiter/waiter_home.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    // Splash
    GoRoute(
      path: '/',
      builder: (_, __) => const SplashScreen(),
    ),

    // Settings
    GoRoute(
      path: '/settings',
      builder: (_, __) => const SettingsScreen(),
    ),

    // Login
    GoRoute(
      path: '/login',
      builder: (_, __) => const LoginScreen(),
    ),

    // Waiter
    GoRoute(
      path: '/waiter',
      builder: (_, __) => const WaiterHome(),
    ),

    // Mavjud buyurtmani ochish
    GoRoute(
      path: '/waiter/order/:orderId',
      builder: (_, state) {
        final orderId = int.tryParse(state.pathParameters['orderId'] ?? '');
        final table   = state.extra as TableModel?;
        return OrderScreen(orderId: orderId, table: table);
      },
    ),

    // Yangi buyurtma (stol bo'yicha)
    GoRoute(
      path: '/waiter/new-order',
      builder: (_, state) {
        final table = state.extra as TableModel?;
        return OrderScreen(table: table);
      },
    ),

    // Admin
    GoRoute(
      path: '/admin',
      builder: (_, __) => const AdminHome(),
    ),
  ],

  errorBuilder: (_, state) => Scaffold(
    body: Center(
      child: Text(
        'Sahifa topilmadi: ${state.uri}',
        style: const TextStyle(color: Colors.white),
      ),
    ),
    backgroundColor: const Color(0xFF0F172A),
  ),
);
