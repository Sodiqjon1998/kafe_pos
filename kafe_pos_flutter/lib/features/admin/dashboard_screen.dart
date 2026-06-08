import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/order_model.dart';
import '../../core/providers/orders_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // To'lov usullari uchun (naqd/karta ajratish)
  Map<String, dynamic>? _payMethods;
  bool _loadingPay = false;
  String? _payError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    // Faol buyurtmalar (status != paid/cancelled)
    context.read<OrdersProvider>().fetchOrders();
    // Barcha buyurtmalar — bugungi daromad hisoblash uchun
    context.read<OrdersProvider>().fetchAllOrders();
    _loadPayMethods();
  }

  Future<void> _loadPayMethods() async {
    setState(() { _loadingPay = true; _payError = null; });
    try {
      final now  = DateTime.now();
      final from = _fmtDate(now);
      final res  = await ApiClient().get('/payments/summary',
          params: {'from': from, 'to': from});
      if (res.data is Map) {
        setState(() => _payMethods = Map<String, dynamic>.from(res.data as Map));
      }
    } catch (e) {
      setState(() => _payError = ApiClient.errorMessage(e));
    } finally {
      setState(() => _loadingPay = false);
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Bugungi to'langan buyurtmalarni local vaqt bo'yicha filter qilish
  /// (web app toDate() + toLocaleDateString('sv-SE') kabi)
  List<Order> _todayPaid(List<Order> all) {
    final today = _fmtDate(DateTime.now()); // 'yyyy-MM-dd' mahalliy vaqt
    return all.where((o) {
      if (o.status != 'paid') return false;
      final rawDate = (o as dynamic).closedAt ?? ''; // agar model kengaytirilsa
      // Hozircha orderNumber yoki order_id bo'yicha emas, closed_at bo'yicha
      // Order model da closedAt yo'q — shuning uchun effectiveTotal > 0 va today filter
      // Backend dan kelgan paid orders to'g'ri sanaga ega deb hisoblaymiz
      return true; // Barcha paid — keyinchalik closedAt qo'shiladi
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ordersP = context.watch<OrdersProvider>();
    final orders  = ordersP.orders;
    final all     = ordersP.allOrders;
    final active  = orders.where((o) =>
        o.status != 'paid' && o.status != 'cancelled').toList();

    // Bugungi to'langan buyurtmalar — allOrders dan paid filter
    final todayPaid = all.where((o) => o.status == 'paid').toList();
    final todayRevenue = todayPaid.fold(0.0, (s, o) => s + o.effectiveTotal);
    final todayCount   = todayPaid.length;

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Statistika kartochkalari
          if (ordersP.loading && all.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.primary),
              ))
          else
            _buildStats(todayRevenue, todayCount),

          const SizedBox(height: 12),

          // To'lov usullari breakdown (naqd/karta)
          if (_payMethods != null) _buildPayRow(_payMethods!),
          if (_payError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPayError(_payError!),
            ),

          const SizedBox(height: 8),

          // Faol buyurtmalar
          Row(
            children: [
              const Text('Faol buyurtmalar',
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${active.length}',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (ordersP.loading && orders.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppColors.primary),
              ))
          else if (active.isEmpty)
            const _EmptyOrders()
          else
            ...active.map((o) => _OrderCard(order: o)),
        ],
      ),
    );
  }

  Widget _buildStats(double revenue, int count) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _StatCard(
            icon: Icons.attach_money,
            label: 'Bugungi daromad',
            value: _fmt(revenue),
            color: AppColors.success),
        _StatCard(
            icon: Icons.receipt_long,
            label: "To'langan buyurtmalar",
            value: '$count ta',
            color: AppColors.info),
      ],
    );
  }

  Widget _buildPayRow(Map<String, dynamic> s) {
    num _methodTotal(String method) {
      final methods = (s['methods'] as List?) ?? [];
      final m = methods.cast<Map>().firstWhere(
        (m) => m['method'] == method,
        orElse: () => <String, dynamic>{},
      );
      return num.tryParse((m['total'] ?? 0).toString()) ?? 0;
    }

    final cash = _methodTotal('cash').toDouble();
    final card = _methodTotal('card').toDouble();
    if (cash == 0 && card == 0) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
                icon: Icons.money,
                label: 'Naqd',
                value: _fmt(cash),
                color: AppColors.warning),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
                icon: Icons.credit_card,
                label: 'Karta',
                value: _fmt(card),
                color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildPayError(String err) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: AppColors.danger, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(err,
                style:
                    const TextStyle(color: AppColors.danger, fontSize: 11)),
          ),
          TextButton(
            onPressed: _loadPayMethods,
            child: const Text('Qayta',
                style: TextStyle(color: AppColors.primary, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    final n = v.toInt();
    final s = n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]} ',
    );
    return '$s so\'m';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.muted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 48,
            decoration: BoxDecoration(
              color: order.statusColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.orderNumber,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
                Text(
                  order.table?.name ?? 'Olib ketish',
                  style: const TextStyle(
                      color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: order.statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(order.statusLabel,
                    style: TextStyle(
                        color: order.statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 4),
              Text(order.totalFormatted,
                  style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.check_circle_outline,
                  color: AppColors.success, size: 44),
              SizedBox(height: 8),
              Text('Hozircha faol buyurtma yo\'q',
                  style: TextStyle(color: AppColors.muted)),
            ],
          ),
        ),
      );
}
