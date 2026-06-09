import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/order_model.dart';
import '../../core/providers/auth_provider.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  final _api = ApiClient();

  List<Order> _orders = [];
  bool _loading = true;
  String? _error;
  Timer? _timer;
  DateTime _lastUpdated = DateTime.now();

  // Filtrlash: pending | sent | cooking | all
  String _filter = 'active';

  @override
  void initState() {
    super.initState();
    // Ekranni har doim yoniq ushlash (oshpaz ekrani)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _logout() async {
    // Tasdiqlash dialogi
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E28),
        title: const Text('Chiqish', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Oshpaz ekranidan chiqmoqchimisiz?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Bekor', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Chiqish',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    // Kitchen APK bo'lsa settings ga, aks holda logout
    if (AppConfig.isKitchenMode) {
      context.go('/settings');
    } else {
      await context.read<AuthProvider>().logout();
      if (mounted) context.go('/login');
    }
  }

  Future<void> _load() async {
    try {
      final res = await _api.get('/orders', params: {'all': '1'});
      final all = (res.data as List)
          .map((o) => Order.fromJson(o as Map<String, dynamic>))
          .toList();

      // Oshpaz faqat shu statuslarni ko'radi
      final kitchen = all
          .where((o) =>
              o.status == 'sent' ||
              o.status == 'cooking' ||
              o.status == 'ready')
          .toList();

      // Yangi buyurtma kelganida vibro/zvuk
      if (_orders.length < kitchen.length) {
        HapticFeedback.heavyImpact();
      }

      if (mounted) {
        setState(() {
          _orders = kitchen;
          _loading = false;
          _error = null;
          _lastUpdated = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ApiClient.errorMessage(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _updateStatus(Order order, String status) async {
    try {
      await _api.patch('/orders/${order.id}/status', data: {'status': status});
      HapticFeedback.mediumImpact();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.errorMessage(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  List<Order> get _filtered {
    if (_filter == 'sent') return _orders.where((o) => o.status == 'sent').toList();
    if (_filter == 'cooking') return _orders.where((o) => o.status == 'cooking').toList();
    if (_filter == 'ready') return _orders.where((o) => o.status == 'ready').toList();
    return _orders; // 'active' — all kitchen orders
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterBar(),
            Expanded(
              child: _loading && _orders.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.warning,
                        strokeWidth: 3,
                      ),
                    )
                  : _error != null && _orders.isEmpty
                      ? _buildError()
                      : _filtered.isEmpty
                          ? _buildEmpty()
                          : _buildOrderGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final sent    = _orders.where((o) => o.status == 'sent').length;
    final cooking = _orders.where((o) => o.status == 'cooking').length;
    final ready   = _orders.where((o) => o.status == 'ready').length;

    final t = _lastUpdated;
    final time =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF131318),
        border: Border(
          bottom: BorderSide(color: Color(0xFF2A2A35), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.warning.withOpacity(0.4), width: 1.5),
            ),
            child: const Icon(Icons.soup_kitchen,
                color: AppColors.warning, size: 20),
          ),
          const SizedBox(width: 12),

          // Sarlavha + vaqt — Expanded bilan qolgan joyni oladi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'OSHPAZ EKRANI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  'Yangilandi: $time',
                  style: const TextStyle(
                      color: Color(0xFF666680), fontSize: 10),
                ),
              ],
            ),
          ),

          // Kompakt raqamli badgelar (faqat son)
          _buildMiniCountBadge(sent, AppColors.danger),
          const SizedBox(width: 6),
          _buildMiniCountBadge(cooking, AppColors.warning),
          const SizedBox(width: 6),
          _buildMiniCountBadge(ready, AppColors.success),
          const SizedBox(width: 8),

          // Refresh
          GestureDetector(
            onTap: _load,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E28),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2A2A35)),
              ),
              child: const Icon(Icons.refresh, color: Colors.white70, size: 18),
            ),
          ),
          const SizedBox(width: 6),

          // Logout
          GestureDetector(
            onTap: _logout,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.danger.withOpacity(0.3)),
              ),
              child: const Icon(Icons.logout_rounded,
                  color: AppColors.danger, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // Faqat son ko'rsatuvchi kichik badge
  Widget _buildMiniCountBadge(int count, Color color) {
    return Container(
      constraints: const BoxConstraints(minWidth: 34),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35), width: 1.5),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 17,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }

  Widget _buildCountBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: color.withOpacity(0.7), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = [
      ('active', 'Barchasi', Colors.white70),
      ('sent', 'Yangi', AppColors.danger),
      ('cooking', 'Tayyorlanmoqda', AppColors.warning),
      ('ready', 'Tayyor', AppColors.success),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF0F0F14),
      child: Row(
        children: filters.map((f) {
          final isActive = _filter == f.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _filter = f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? f.$3.withOpacity(0.15)
                      : const Color(0xFF1A1A22),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive
                        ? f.$3.withOpacity(0.5)
                        : const Color(0xFF2A2A35),
                    width: isActive ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  f.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isActive ? f.$3 : const Color(0xFF888899),
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrderGrid() {
    final orders = _filtered;
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: orders.length,
      itemBuilder: (_, i) => _KitchenOrderCard(
        order: orders[i],
        onStatusUpdate: _updateStatus,
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline,
              color: AppColors.success.withOpacity(0.5), size: 72),
          const SizedBox(height: 16),
          const Text(
            'Hozircha yangi buyurtma yo\'q',
            style: TextStyle(
              color: Color(0xFF666680),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Har 10 soniyada yangilanadi',
            style: TextStyle(color: Color(0xFF444455), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, color: AppColors.danger, size: 56),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Ulanish xatosi',
            style: const TextStyle(color: AppColors.danger, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Qayta urinish'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Buyurtma kartochkasi ─────────────────────────────────────────────────────

class _KitchenOrderCard extends StatelessWidget {
  final Order order;
  final Future<void> Function(Order order, String status) onStatusUpdate;

  const _KitchenOrderCard({
    required this.order,
    required this.onStatusUpdate,
  });

  Color get _statusColor {
    switch (order.status) {
      case 'sent':    return AppColors.danger;
      case 'cooking': return AppColors.warning;
      case 'ready':   return AppColors.success;
      default:        return AppColors.muted;
    }
  }

  String get _statusLabel {
    switch (order.status) {
      case 'sent':    return '🔴 YANGI';
      case 'cooking': return '🟡 TAYYORLANMOQDA';
      case 'ready':   return '🟢 TAYYOR';
      default:        return order.status.toUpperCase();
    }
  }

  String? get _nextStatus {
    switch (order.status) {
      case 'sent':    return 'cooking';
      case 'cooking': return 'ready';
      default:        return null;
    }
  }

  String? get _nextLabel {
    switch (order.status) {
      case 'sent':    return 'Tayyorlashni boshlash';
      case 'cooking': return 'Tayyor deb belgilash';
      default:        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = order.items;
    final next  = _nextStatus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: const Color(0xFF131318),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _statusColor.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(
                bottom: BorderSide(
                    color: _statusColor.withOpacity(0.25), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        order.table?.name ?? 'Olib ketish',
                        style: const TextStyle(
                          color: Color(0xFF888899),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _statusColor.withOpacity(0.4), width: 1),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Mahsulotlar ro'yxati
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                final isDone = item.status == 'ready' || item.status == 'served';
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.success.withOpacity(0.06)
                        : const Color(0xFF1A1A22),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDone
                          ? AppColors.success.withOpacity(0.2)
                          : const Color(0xFF2A2A35),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Miqdor
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDone
                              ? AppColors.success.withOpacity(0.15)
                              : AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '×${item.quantity}',
                            style: TextStyle(
                              color: isDone
                                  ? AppColors.success
                                  : AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: TextStyle(
                                color:
                                    isDone ? const Color(0xFF666680) : Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                decoration: isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            if (item.note != null && item.note!.isNotEmpty)
                              Text(
                                '📝 ${item.note}',
                                style: const TextStyle(
                                    color: AppColors.warning, fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                      if (isDone)
                        const Icon(Icons.check_circle,
                            color: AppColors.success, size: 18),
                    ],
                  ),
                );
              },
            ),
          ),

          // Amal tugmasi
          if (next != null)
            Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: () => onStatusUpdate(order, next),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _statusColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _nextLabel!,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.success.withOpacity(0.3), width: 1.5),
                ),
                child: const Center(
                  child: Text(
                    '✓ Ofitsiantga uzatildi',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
