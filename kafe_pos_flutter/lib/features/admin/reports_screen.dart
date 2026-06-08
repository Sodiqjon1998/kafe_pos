import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _api = ApiClient();

  // _paymentSummary  = { methods: [{method, count, total}], grand_total }
  // _expenseSummary  = { revenue, expense, net_profit, by_type }
  Map<String, dynamic>? _paymentSummary;
  Map<String, dynamic>? _expenseSummary;
  bool _loading = false;
  String? _error;

  int _periodIndex = 0;
  static const _periods = ['Bugun', 'Hafta', 'Oy'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  (String, String) _dateRange() {
    final now = DateTime.now();
    final to  = _fmtDate(now);
    switch (_periodIndex) {
      case 0: return (_fmtDate(now), to);
      case 1: return (_fmtDate(now.subtract(const Duration(days: 7))), to);
      case 2: return (_fmtDate(DateTime(now.year, now.month, 1)), to);
    }
    return (_fmtDate(now), to);
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final (from, to) = _dateRange();
      final pay = await _api.get('/payments/summary', params: {'from': from, 'to': to});
      final exp = await _api.get('/expenses/summary',  params: {'from': from, 'to': to});
      setState(() {
        if (pay.data is Map) _paymentSummary = Map<String, dynamic>.from(pay.data as Map);
        if (exp.data is Map) _expenseSummary = Map<String, dynamic>.from(exp.data as Map);
      });
    } catch (e) {
      setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      setState(() => _loading = false);
    }
  }

  // MySQL COUNT/SUM → string yoki num bo'lishi mumkin, har ikkisini ham qabul qilish
  num _methodTotal(String method) {
    final methods = (_paymentSummary?['methods'] as List?) ?? [];
    final m = methods.cast<Map>().firstWhere(
      (m) => m['method'] == method,
      orElse: () => {},
    );
    return num.tryParse((m['total'] ?? 0).toString()) ?? 0;
  }

  int _totalOrders() {
    final methods = (_paymentSummary?['methods'] as List?) ?? [];
    return methods.cast<Map>().fold(0,
        (sum, m) => sum + (int.tryParse((m['count'] ?? 0).toString()) ?? 0));
  }

  String _money(dynamic val) {
    if (val == null) return '0 so\'m';
    final n = (val is num ? val : num.tryParse(val.toString()) ?? 0).toInt();
    final s = n.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ');
    return '$s so\'m';
  }

  double _pct(dynamic part, dynamic total) {
    final p = part is num ? part.toDouble() : double.tryParse(part?.toString() ?? '') ?? 0;
    final t = total is num ? total.toDouble() : double.tryParse(total?.toString() ?? '') ?? 0;
    if (t == 0) return 0;
    return (p / t).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // Davr tanlash
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              children: List.generate(_periods.length, (i) {
                final active = i == _periodIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () { setState(() => _periodIndex = i); _load(); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : AppColors.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: active ? AppColors.primary : AppColors.border),
                      ),
                      child: Text(
                        _periods[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: active ? AppColors.white : AppColors.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.danger, size: 40),
                            const SizedBox(height: 12),
                            Text(_error!, style: const TextStyle(color: AppColors.muted)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _load,
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                              child: const Text('Qayta', style: TextStyle(color: AppColors.white)),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.all(14),
                          children: [
                            _buildFinance(),
                            const SizedBox(height: 16),
                            _buildPaymentBreakdown(),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinance() {
    // revenue va expense/net_profit — expenses/summary dan
    // num.tryParse — MySQL string yoki num har ikkalasini ham qabul qiladi
    final revenue   = num.tryParse((_expenseSummary?['revenue']   ?? 0).toString()) ?? 0;
    final expense   = num.tryParse((_expenseSummary?['expense']   ?? 0).toString()) ?? 0;
    final netProfit = num.tryParse((_expenseSummary?['net_profit'] ?? 0).toString()) ?? 0;
    final isProfit  = netProfit >= 0;

    final ordersCount = _totalOrders();
    final grandTotal  = num.tryParse((_paymentSummary?['grand_total'] ?? 0).toString()) ?? 0;
    final avgNum = ordersCount > 0
        ? (grandTotal.toDouble() / ordersCount).toInt()
        : 0;
    final avgStr = avgNum.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Net profit karta
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (isProfit ? AppColors.success : AppColors.danger).withOpacity(0.15),
                AppColors.card,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isProfit ? AppColors.success : AppColors.danger).withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isProfit ? Icons.trending_up : Icons.trending_down,
                    color: isProfit ? AppColors.success : AppColors.danger,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isProfit ? 'Foyda' : 'Zarar',
                    style: TextStyle(
                        color: isProfit ? AppColors.success : AppColors.danger,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _money(netProfit),
                style: TextStyle(
                    color: isProfit ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.w800,
                    fontSize: 26),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 4 ta karta
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Daromad',
                value: _money(revenue),
                icon: Icons.trending_up,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                label: 'Xarajat',
                value: _money(expense),
                icon: Icons.payments_outlined,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Buyurtmalar',
                value: '$ordersCount ta',
                icon: Icons.receipt_long_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                label: 'O\'rtacha check',
                value: '$avgStr so\'m',
                icon: Icons.calculate_outlined,
                color: AppColors.info,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentBreakdown() {
    final methods  = (_paymentSummary?['methods'] as List?) ?? [];
    if (methods.isEmpty) return const SizedBox();

    final grandTotal = num.tryParse((_paymentSummary?['grand_total'] ?? 0).toString()) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("To'lov usullari",
            style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: Column(
            children: methods.cast<Map>().map((m) {
              final method = (m['method'] ?? '').toString();
              final total  = num.tryParse((m['total']  ?? 0).toString()) ?? 0;
              final count  = int.tryParse((m['count']  ?? 0).toString()) ?? 0;
              final (label, icon, color) = _methodInfo(method);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PayRow(
                  label: label,
                  value: _money(total),
                  sub: '$count ta',
                  pct: _pct(total, grandTotal),
                  color: color,
                  icon: icon,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  (String, IconData, Color) _methodInfo(String method) {
    switch (method) {
      case 'cash':     return ('Naqd',   Icons.payments_outlined,     AppColors.success);
      case 'card':     return ('Karta',  Icons.credit_card,  AppColors.primary);
      case 'click':    return ('Click',  Icons.phone_android, AppColors.info);
      case 'payme':    return ('Payme',  Icons.phone_android, AppColors.warning);
      case 'transfer': return ('O\'tkazma', Icons.swap_horiz,         AppColors.muted);
      case 'debt':     return ('Qarz',   Icons.warning_amber,  AppColors.danger);
      default:         return (method,   Icons.payments_outlined,     AppColors.muted);
    }
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _PayRow extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final double pct;
  final Color color;
  final IconData icon;

  const _PayRow({
    required this.label,
    required this.value,
    required this.sub,
    required this.pct,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label, style: const TextStyle(color: AppColors.text, fontSize: 13)),
            ),
            Text(sub, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            const SizedBox(width: 8),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: AppColors.border,
            color: color,
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}
