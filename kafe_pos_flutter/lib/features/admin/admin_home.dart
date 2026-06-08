import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import 'dashboard_screen.dart';
import 'expenses_screen.dart';
import 'menu_screen.dart';
import 'reports_screen.dart';
import 'shifts_screen.dart';
import 'sklad_screen.dart';
import 'tables_admin_screen.dart';
import 'users_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _tab = 0;

  static const _pages = [
    _PageItem(icon: Icons.dashboard_outlined,     label: 'Bosh sahifa'),
    _PageItem(icon: Icons.menu_book_outlined,     label: 'Menyu'),
    _PageItem(icon: Icons.table_restaurant,       label: 'Stollar'),
    _PageItem(icon: Icons.access_time_outlined,   label: 'Smenalar'),
    _PageItem(icon: Icons.people_outline,         label: 'Xodimlar'),
    _PageItem(icon: Icons.inventory_2_outlined,   label: 'Sklad'),
    _PageItem(icon: Icons.payments_outlined,      label: 'Xarajatlar'),
    _PageItem(icon: Icons.bar_chart,      label: 'Hisobotlar'),
  ];

  // Bir marta yaratilgan sahifalar ro'yxati (lazy — faqat birinchi kirish paytida)
  final _cache = <int, Widget>{};

  Widget _getPage(int index) {
    return _cache.putIfAbsent(index, () {
      const screens = [
        DashboardScreen(),
        MenuScreen(),
        TablesAdminScreen(),
        ShiftsScreen(),
        UsersScreen(),
        SkladScreen(),
        ExpensesScreen(),
        ReportsScreen(),
      ];
      return screens[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final page = _pages[_tab];

    return Scaffold(
      backgroundColor: AppColors.bg,
      drawer: _buildDrawer(auth),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded,
                color: AppColors.text, size: 24),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Icon(page.icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(page.label,
                    style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                Text(auth.user?.roleLabel ?? '',
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/waiter'),
            icon: const Icon(Icons.table_restaurant,
                color: AppColors.primary, size: 16),
            label: const Text('Zalga',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 4),
        ],
      ),
      // Lazy loading: faqat birinchi marta kirilganda sahifa yaratiladi
      body: _getPage(_tab),
    );
  }

  Widget _buildDrawer(AuthProvider auth) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.4)),
                    ),
                    child: const Center(
                        child: Icon(Icons.local_cafe, color: AppColors.primary, size: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Kafe POS',
                            style: TextStyle(
                                color: AppColors.text,
                                fontWeight: FontWeight.w800,
                                fontSize: 16)),
                        Text(auth.user?.name ?? '',
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: List.generate(_pages.length, (i) {
                  final p = _pages[i];
                  final active = i == _tab;
                  return _DrawerItem(
                    page: p,
                    active: active,
                    onTap: () {
                      setState(() => _tab = i);
                      Navigator.pop(context);
                    },
                  );
                }),
              ),
            ),

            // Footer
            const Divider(color: AppColors.border, height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Zalga o'tish
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.go('/waiter');
                      },
                      icon: const Icon(Icons.table_restaurant,
                          color: AppColors.primary, size: 16),
                      label: const Text('Zalga o\'tish',
                          style: TextStyle(color: AppColors.primary)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Chiqish
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await context.read<AuthProvider>().logout();
                        if (context.mounted) context.go('/login');
                      },
                      icon: const Icon(Icons.logout,
                          color: AppColors.danger, size: 16),
                      label: const Text('Chiqish',
                          style: TextStyle(color: AppColors.danger)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: AppColors.danger),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final _PageItem page;
  final bool active;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.page,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: active ? AppColors.primary.withOpacity(0.12) : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          page.icon,
          color: active ? AppColors.primary : AppColors.muted,
          size: 20,
        ),
        title: Text(
          page.label,
          style: TextStyle(
            color: active ? AppColors.primary : AppColors.text,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: onTap,
        selected: active,
        selectedColor: AppColors.primary,
      ),
    );
  }
}

class _PageItem {
  final IconData icon;
  final String label;
  const _PageItem({required this.icon, required this.label});
}
