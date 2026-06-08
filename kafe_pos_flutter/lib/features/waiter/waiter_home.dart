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

    final allTables   = halls.expand((h) => h.tables).toList();
    final freeCount   = allTables.where((t) => t.status == 'free').length;
    final occupied    = allTables.where((t) => t.status == 'occupied').length;
    final bill        = allTables.where((t) => t.status == 'bill_requested').length;
    final total       = allTables.length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // ── Professional AppBar ──────────────────────────────────────────
          _buildAppBar(auth, freeCount, occupied, bill, total, halls),

          // ── Tab Bar (zallar) ─────────────────────────────────────────────
          if (halls.isNotEmpty && _tabCtrl != null)
            _buildTabBar(halls),

          // ── Asosiy kontent ───────────────────────────────────────────────
          Expanded(
            child: tbls.loading && halls.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : tbls.error != null
                    ? _buildError(tbls.error!)
                    : halls.isEmpty
                        ? _buildEmpty()
                        : _tabCtrl != null
                            ? TabBarView(
                                controller: _tabCtrl,
                                children: halls
                                    .map((h) => _HallGrid(
                                          hall: h,
                                          onTableTap: _onTableTap,
                                        ))
                                    .toList(),
                              )
                            : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(AuthProvider auth, int free, int occ, int bill,
      int total, List halls) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Row(
            children: [
              // ── Logo ────────────────────────────────────────────────────
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.9),
                      AppColors.primary.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.local_cafe,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),

              // ── Title + role ─────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Kafe POS',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${auth.user?.name ?? ''} • ${auth.user?.roleLabel ?? ''}',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Stats ────────────────────────────────────────────────────
              _buildStatBadge('$free', "Bo'sh", AppColors.success),
              const SizedBox(width: 5),
              _buildStatBadge('$occ', 'Band', AppColors.warning),
              if (bill > 0) ...[
                const SizedBox(width: 5),
                _buildStatBadge('$bill', 'Hisob', AppColors.info),
              ],
              const SizedBox(width: 4),

              // ── Actions ──────────────────────────────────────────────────
              if (auth.isManager)
                _buildIconBtn(
                  Icons.admin_panel_settings_outlined,
                  AppColors.primary,
                  () => context.go('/admin'),
                  tooltip: 'Admin',
                ),
              _buildIconBtn(
                Icons.history_rounded,
                AppColors.info,
                () => context.push('/waiter/history'),
                tooltip: 'Tarix',
              ),
              _buildIconBtn(
                Icons.refresh_rounded,
                AppColors.muted,
                _load,
                tooltip: 'Yangilash',
              ),
              _buildIconBtn(
                Icons.logout_rounded,
                AppColors.danger.withOpacity(0.8),
                () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) context.go('/login');
                },
                tooltip: 'Chiqish',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, Color color, VoidCallback onTap,
      {String? tooltip}) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  Widget _buildTabBar(List<Hall> halls) {
    return Container(
      height: 44,
      color: AppColors.surface,
      child: TabBar(
        controller: _tabCtrl,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorWeight: 3,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.muted,
        labelStyle: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tabs: halls.map((h) {
          final count = h.tables.length;
          final occ = h.tables.where((t) => t.status == 'occupied').length;
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(h.name),
                if (occ > 0) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$occ/$count',
                      style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildError(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
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
                      const TextStyle(color: AppColors.muted, fontSize: 13),
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
        ),
      );

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.table_restaurant,
                  color: AppColors.muted, size: 48),
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
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.9,
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
    final color    = table.statusColor;
    final order    = table.activeOrder;
    final isOcc    = table.status == 'occupied';
    final isBill   = table.status == 'bill_requested';
    final isActive = isOcc || isBill;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: isActive
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.15),
                      AppColors.card,
                    ],
                  )
                : null,
            color: isActive ? null : AppColors.card,
            border: Border.all(
              color: isActive ? color.withOpacity(0.5) : AppColors.border,
              width: isActive ? 1.5 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Status indicator bar ────────────────────────────────────
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),

              // ── Stol nomi ───────────────────────────────────────────────
              Text(
                table.name,
                style: TextStyle(
                  color: isActive ? AppColors.text : AppColors.muted,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // ── Sig'im ──────────────────────────────────────────────────
              Row(
                children: [
                  Icon(Icons.people_outline,
                      color: AppColors.muted.withOpacity(0.6), size: 10),
                  const SizedBox(width: 2),
                  Text('${table.capacity}',
                      style: TextStyle(
                          color: AppColors.muted.withOpacity(0.6),
                          fontSize: 10)),
                ],
              ),

              const Spacer(),

              // ── Buyurtma ma'lumotlari yoki status ───────────────────────
              if (order != null) ...[
                Text(
                  order.orderNumber,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order.totalFormatted,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ] else ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    table.statusLabel,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
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
    if (n == 0) return '';
    final s = n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]} ',
    );
    return '$s so\'m';
  }
}
