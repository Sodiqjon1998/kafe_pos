import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/table_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/tables_provider.dart';

class WaiterHome extends StatefulWidget {
  const WaiterHome({super.key});

  @override
  State<WaiterHome> createState() => _WaiterHomeState();
}

class _WaiterHomeState extends State<WaiterHome>
    with SingleTickerProviderStateMixin {
  TabController? _tabCtrl;
  int _hallCount = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    // 30 soniyada bir stol holatlarini yangilash (POS real-vaqt)
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) context.read<TablesProvider>().fetchHalls();
    });
  }

  Future<void> _load() async {
    await context.read<TablesProvider>().fetchHalls();
    final halls = context.read<TablesProvider>().halls;
    if (halls.isNotEmpty && mounted) {
      setState(() {
        _hallCount = halls.length;
        _tabCtrl = TabController(length: _hallCount, vsync: this);
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabCtrl?.dispose();
    super.dispose();
  }

  void _onTableTap(TableModel table) {
    if (table.activeOrder != null) {
      context.push('/waiter/order/${table.activeOrder!.id}', extra: table);
    } else {
      context.push('/waiter/new-order', extra: table);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthProvider>();
    final tbls  = context.watch<TablesProvider>();
    final halls = tbls.halls;

    final freeCount     = halls.expand((h) => h.tables).where((t) => t.status == 'free').length;
    final occupiedCount = halls.expand((h) => h.tables).where((t) => t.status == 'occupied').length;
    final totalCount    = halls.expand((h) => h.tables).length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.4)),
                      ),
                      child: const Center(
                        child: Icon(Icons.local_cafe, color: AppColors.primary, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Kafe POS',
                              style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800)),
                          Text(auth.user?.name ?? '',
                              style: const TextStyle(
                                  color: AppColors.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                    // Stats chips
                    _StatChip(
                        label: '$freeCount bo\'sh',
                        color: AppColors.success),
                    const SizedBox(width: 6),
                    _StatChip(
                        label: '$occupiedCount band',
                        color: AppColors.warning),
                    const SizedBox(width: 8),
                    // Actions
                    if (auth.isManager)
                      IconButton(
                        icon: const Icon(Icons.admin_panel_settings,
                            color: AppColors.primary),
                        onPressed: () => context.go('/admin'),
                        tooltip: 'Admin panel',
                      ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: AppColors.muted),
                      onPressed: () async {
                        await context.read<AuthProvider>().logout();
                        if (context.mounted) context.go('/login');
                      },
                    ),
                  ],
                ),
              ),
            ),
            bottom: halls.isNotEmpty && _tabCtrl != null
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(48),
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                            top: BorderSide(color: AppColors.border)),
                      ),
                      child: TabBar(
                        controller: _tabCtrl,
                        isScrollable: true,
                        indicatorColor: AppColors.primary,
                        indicatorSize: TabBarIndicatorSize.label,
                        indicatorWeight: 3,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.muted,
                        labelStyle: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                        unselectedLabelStyle:
                            const TextStyle(fontWeight: FontWeight.w500),
                        tabs: halls.map((h) => Tab(text: h.name)).toList(),
                      ),
                    ),
                  )
                : null,
          ),
        ],
        body: tbls.loading && halls.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : tbls.error != null
                ? _buildError(tbls.error!)
                : halls.isEmpty
                    ? _buildEmpty()
                    : _tabCtrl != null
                        ? TabBarView(
                            controller: _tabCtrl,
                            children: halls.map((h) => _HallGrid(
                                  hall: h,
                                  onTableTap: _onTableTap,
                                )).toList(),
                          )
                        : const SizedBox(),
      ),
      // Yangilash FAB
      floatingActionButton: FloatingActionButton.small(
        onPressed: _load,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        elevation: 2,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildError(String msg) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off,
                  color: AppColors.danger, size: 40),
            ),
            const SizedBox(height: 16),
            Text(msg,
                style:
                    const TextStyle(color: AppColors.muted, fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Qayta urinish'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      );

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.table_restaurant, color: AppColors.muted, size: 48),
            ),
            const SizedBox(height: 16),
            const Text('Zallar topilmadi',
                style: TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Admin paneldan zal va stollar qo\'shing',
                style: TextStyle(color: AppColors.muted, fontSize: 13)),
          ],
        ),
      );
}

// ── Stat chip ───────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── Zal ichidagi stol gridi ─────────────────────────────────────────────────

class _HallGrid extends StatelessWidget {
  final Hall hall;
  final void Function(TableModel) onTableTap;

  const _HallGrid({required this.hall, required this.onTableTap});

  @override
  Widget build(BuildContext context) {
    final tables = hall.tables;
    if (tables.isEmpty) {
      return const Center(
        child: Text('Bu zalda stollar yo\'q',
            style: TextStyle(color: AppColors.muted)),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () => context.read<TablesProvider>().fetchHalls(),
      child: GridView.builder(
        padding: const EdgeInsets.all(14),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.88,
        ),
        itemCount: tables.length,
        itemBuilder: (_, i) => _TableCard(
          table: tables[i],
          onTap: () => onTableTap(tables[i]),
        ),
      ),
    );
  }
}

// ── Stol kartochkasi ────────────────────────────────────────────────────────

class _TableCard extends StatelessWidget {
  final TableModel table;
  final VoidCallback onTap;

  const _TableCard({required this.table, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = table.statusColor;
    final order = table.activeOrder;
    final isOccupied = table.status == 'occupied';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isOccupied
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.18),
                      AppColors.card,
                    ],
                  )
                : null,
            color: isOccupied ? null : AppColors.card,
            border: Border.all(
              color: isOccupied
                  ? color.withOpacity(0.6)
                  : AppColors.border,
              width: isOccupied ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.all(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ustki qator: stol nomi + status
              Row(
                children: [
                  // Stol ikonka
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(Icons.table_bar, color: color, size: 14),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      table.name,
                      style: TextStyle(
                          color: isOccupied ? AppColors.text : AppColors.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Sig'im
              Row(
                children: [
                  const Icon(Icons.people_outline,
                      color: AppColors.muted, size: 11),
                  const SizedBox(width: 3),
                  Text('${table.capacity} kishi',
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 10)),
                ],
              ),

              const SizedBox(height: 6),

              // Buyurtma yoki holat
              if (order != null) ...[
                // Buyurtma raqami
                Text(
                  order.orderNumber,
                  style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                // Summa
                Text(
                  order.totalFormatted,
                  style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w800),
                ),
              ] else ...[
                // Bo'sh holat badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(
                    table.statusLabel,
                    style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

extension on ActiveOrder {
  String get totalFormatted {
    final n = total.toInt();
    final s = n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]} ',
    );
    return '$s so\'m';
  }
}
