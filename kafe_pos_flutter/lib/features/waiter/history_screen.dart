import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/order_model.dart';
import '../../core/providers/auth_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _api = ApiClient();
  List<Order> _orders = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all'; // all | paid | cancelled

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final auth = context.read<AuthProvider>();
      final isMine = !auth.user!.isManagerOrAdmin;
      final res = await _api.get('/orders', params: {
        'all': '1',
        if (isMine) 'mine': '1',
      });
      final all = (res.data as List)
          .map((o) => Order.fromJson(o as Map<String, dynamic>))
          .toList();
      // Faqat tugallangan buyurtmalar
      setState(() {
        _orders = all
            .where((o) => o.status == 'paid' || o.status == 'cancelled')
            .toList()
          ..sort((a, b) => b.id.compareTo(a.id));
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = ApiClient.errorMessage(e);
        _loading = false;
      });
    }
  }

  List<Order> get _filtered {
    if (_filter == 'paid') return _orders.where((o) => o.status == 'paid').toList();
    if (_filter == 'cancelled') return _orders.where((o) => o.status == 'cancelled').toList();
    return _orders;
  }

  double get _totalRevenue =>
      _orders.where((o) => o.status == 'paid').fold(0, (s, o) => s + o.effectiveTotal);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? _buildError()
                : Column(
                    children: [
                      _buildSummary(),
                      _buildFilterBar(),
                      Expanded(child: _buildList()),
                    ],
                  ),
      ),
    );
  }

  AppBar _buildAppBar() => AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Buyurtma tarixi',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.text),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.muted),
            onPressed: _load,
          ),
        ],
      );

  Widget _buildSummary() {
    final paid      = _orders.where((o) => o.status == 'paid').length;
    final cancelled = _orders.where((o) => o.status == 'cancelled').length;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: _summaryItem('Jami daromad', _fmtMoney(_totalRevenue), AppColors.success)),
          _divider(),
          Expanded(child: _summaryItem("To'langan", '$paid ta', AppColors.info)),
          _divider(),
          Expanded(child: _summaryItem('Bekor qilingan', '$cancelled ta', AppColors.danger)),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) => Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
              textAlign: TextAlign.center),
        ],
      );

  Widget _divider() => Container(
        width: 1, height: 40,
        color: AppColors.border,
        margin: const EdgeInsets.symmetric(horizontal: 8),
      );

  Widget _buildFilterBar() {
    final filters = [
      ('all', 'Barchasi'),
      ('paid', "To'langan"),
      ('cancelled', 'Bekor qilingan'),
    ];
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: filters.map((f) {
          final active = _filter == f.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _filter = f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: active ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    f.$2,
                    style: TextStyle(
                      color: active ? Colors.white : AppColors.muted,
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildList() {
    final list = _filtered;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                color: AppColors.muted.withOpacity(0.4), size: 56),
            const SizedBox(height: 12),
            const Text('Buyurtma tarixi bo\'sh',
                style: TextStyle(color: AppColors.muted, fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
      itemCount: list.length,
      itemBuilder: (_, i) => _HistoryCard(order: list[i]),
    );
  }

  Widget _buildError() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, color: AppColors.danger, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Qayta', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

  String _fmtMoney(double v) {
    final s = v.toInt().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]} ',
    );
    return '$s so\'m';
  }
}

// ── Tarix kartochkasi ─────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final Order order;
  const _HistoryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final isPaid = order.status == 'paid';
    final color  = isPaid ? AppColors.success : AppColors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              border: Border(
                  bottom: BorderSide(color: color.withOpacity(0.15))),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isPaid ? Icons.check_circle_outline : Icons.cancel_outlined,
                    color: color, size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.orderNumber,
                          style: const TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
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
                    Text(
                      order.totalFormatted,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 15),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.statusLabel,
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Mahsulotlar
          if (order.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                children: order.items.take(3).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text('${item.quantity}',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(item.productName,
                            style: const TextStyle(
                                color: AppColors.text, fontSize: 12)),
                      ),
                      Text(item.totalFormatted,
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                )).toList()
                  ..addAll(order.items.length > 3
                      ? [Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '+ ${order.items.length - 3} ta mahsulot',
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 11),
                          ),
                        )]
                      : []),
              ),
            ),
        ],
      ),
    );
  }
}
