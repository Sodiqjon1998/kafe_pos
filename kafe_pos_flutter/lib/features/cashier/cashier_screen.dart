import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/order_model.dart';
import '../../core/providers/auth_provider.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiClient();
  late TabController _tabCtrl;

  // Smena
  Map<String, dynamic>? _shift;
  bool _shiftLoading = true;

  // Buyurtmalar
  List<Order> _orders = [];
  bool _ordersLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadShift();
    _loadOrders();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _loadOrders());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadShift() async {
    setState(() => _shiftLoading = true);
    try {
      final res = await _api.get('/shifts/current');
      setState(() => _shift = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : null);
    } catch (_) {
      setState(() => _shift = null);
    } finally {
      setState(() => _shiftLoading = false);
    }
  }

  Future<void> _loadOrders() async {
    setState(() => _ordersLoading = true);
    try {
      final res = await _api.get('/payments/orders');
      setState(() {
        _orders = (res.data as List)
            .map((o) => Order.fromJson(o as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {
    } finally {
      setState(() => _ordersLoading = false);
    }
  }

  Future<void> _openShift(double cash) async {
    try {
      await _api.post('/shifts/open', data: {'opening_cash': cash});
      await _loadShift();
      _snack('Smena ochildi ✓', AppColors.success);
    } catch (e) {
      _snack(ApiClient.errorMessage(e), AppColors.danger);
    }
  }

  Future<void> _closeShift(double cash) async {
    try {
      await _api.post('/shifts/close', data: {'closing_cash': cash});
      await _loadShift();
      _snack('Smena yopildi', AppColors.warning);
    } catch (e) {
      _snack(ApiClient.errorMessage(e), AppColors.danger);
    }
  }

  Future<void> _pay(Order order, String method, double amount,
      {double cashReceived = 0, double discount = 0}) async {
    try {
      await _api.post('/payments', data: {
        'order_id':      order.id,
        'method':        method,
        'cash_received': cashReceived > 0 ? cashReceived : amount,
        'discount':      discount,
      });
      await _loadOrders();
      _snack('To\'lov qabul qilindi ✓', AppColors.success);
    } catch (e) {
      _snack(ApiClient.errorMessage(e), AppColors.danger);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar(user?.name ?? 'Kassir'),
      body: Column(
        children: [
          // Smena status banner
          _buildShiftBanner(),
          // Tabs
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabCtrl,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.muted,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(text: "To'lov qilish"),
                Tab(text: 'Smena'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildPaymentTab(),
                _buildShiftTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(String name) => AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.point_of_sale,
                  color: AppColors.warning, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kassir',
                    style: TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                Text(name,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 11)),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.muted),
            onPressed: () { _loadShift(); _loadOrders(); },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded,
                color: AppColors.danger, size: 22),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (mounted) context.go('/login');
            },
          ),
        ],
      );

  Widget _buildShiftBanner() {
    if (_shiftLoading) {
      return const LinearProgressIndicator(
          color: AppColors.primary, backgroundColor: AppColors.border);
    }
    final isOpen = _shift != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isOpen
          ? AppColors.success.withOpacity(0.08)
          : AppColors.danger.withOpacity(0.08),
      child: Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              color: isOpen ? AppColors.success : AppColors.danger,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isOpen
                  ? 'Smena ochiq — Kassa: ${_fmtMoney((_shift!['opening_cash'] as num?)?.toDouble() ?? 0)}'
                  : 'Smena yopiq — To\'lov qabul qilib bo\'lmaydi',
              style: TextStyle(
                color: isOpen ? AppColors.success : AppColors.danger,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!isOpen)
            GestureDetector(
              onTap: () => _showOpenShiftDialog(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Ochish',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }

  // ── TO'LOV TABI ─────────────────────────────────────────────────────────────

  Widget _buildPaymentTab() {
    if (_ordersLoading && _orders.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                color: AppColors.success.withOpacity(0.4), size: 56),
            const SizedBox(height: 12),
            const Text("To'lov kutayotgan buyurtma yo'q",
                style: TextStyle(color: AppColors.muted, fontSize: 15)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _orders.length,
        itemBuilder: (_, i) => _PaymentOrderCard(
          order: _orders[i],
          shiftOpen: _shift != null,
          onPay: (method, amount, {cashReceived, discount}) => _pay(
            _orders[i], method, amount,
            cashReceived: cashReceived ?? amount,
            discount: discount ?? 0,
          ),
        ),
      ),
    );
  }

  // ── SMENA TABI ────────────────────────────────────────────────────────────

  Widget _buildShiftTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_shift != null) ...[
            _buildShiftCard(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _showCloseShiftDialog(),
                icon: const Icon(Icons.lock_outline),
                label: const Text('Smenani yopish',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ] else ...[
            _buildNoShiftCard(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _showOpenShiftDialog(),
                icon: const Icon(Icons.lock_open_outlined),
                label: const Text('Smenani ochish',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShiftCard() {
    final s = _shift!;
    final openedAt = s['opened_at']?.toString() ?? '';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.lock_open,
                    color: AppColors.success, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Smena ochiq',
                        style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                    Text(openedAt.length > 10 ? openedAt.substring(0, 16) : openedAt,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.border, height: 24),
          _shiftRow("Boshlang'ich kassa",
              _fmtMoney((s['opening_cash'] as num?)?.toDouble() ?? 0)),
          const SizedBox(height: 8),
          _shiftRow("Faol buyurtmalar", '${_orders.length} ta'),
        ],
      ),
    );
  }

  Widget _buildNoShiftCard() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.danger.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline,
                  color: AppColors.danger, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Smena yopiq',
                style: TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
              "To'lov qabul qilish uchun avval smenani oching",
              style: TextStyle(color: AppColors.muted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _shiftRow(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ],
      );

  // ── Dialogs ─────────────────────────────────────────────────────────────────

  void _showOpenShiftDialog() {
    final ctrl = TextEditingController(text: '0');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Smenani ochish',
            style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Kassadagi boshlang'ich summa:",
                style: TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: AppColors.text, fontSize: 16),
              decoration: InputDecoration(
                suffixText: "so'm",
                suffixStyle: const TextStyle(color: AppColors.muted),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor',
                style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openShift(double.tryParse(ctrl.text) ?? 0);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Ochish',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showCloseShiftDialog() {
    final ctrl = TextEditingController(text: '0');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Smenani yopish',
            style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kassadagi yakuniy summa:',
                style: TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: AppColors.text, fontSize: 16),
              decoration: InputDecoration(
                suffixText: "so'm",
                suffixStyle: const TextStyle(color: AppColors.muted),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor',
                style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _closeShift(double.tryParse(ctrl.text) ?? 0);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Yopish',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  String _fmtMoney(double v) {
    final s = v.toInt().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]} ',
    );
    return "$s so'm";
  }
}

// ── To'lov kartochkasi ────────────────────────────────────────────────────────

typedef PayCallback = Future<void> Function(
  String method,
  double amount, {
  double? cashReceived,
  double? discount,
});

class _PaymentOrderCard extends StatefulWidget {
  final Order order;
  final bool shiftOpen;
  final PayCallback onPay;

  const _PaymentOrderCard({
    required this.order,
    required this.shiftOpen,
    required this.onPay,
  });

  @override
  State<_PaymentOrderCard> createState() => _PaymentOrderCardState();
}

class _PaymentOrderCardState extends State<_PaymentOrderCard> {
  bool _expanded = false;
  String _method = 'cash';
  final _discountCtrl = TextEditingController(text: '0');
  final _cashCtrl     = TextEditingController();
  bool _paying = false;

  double get _subtotal => widget.order.effectiveTotal;
  double get _discount => double.tryParse(_discountCtrl.text) ?? 0;
  double get _total    => (_subtotal - _discount).clamp(0, double.infinity);

  @override
  void initState() {
    super.initState();
    _cashCtrl.text = _subtotal.toInt().toString();
  }

  @override
  void dispose() {
    _discountCtrl.dispose();
    _cashCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!widget.shiftOpen) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Avval smenani oching!'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }
    setState(() => _paying = true);
    await widget.onPay(
      _method, _total,
      cashReceived: _method == 'cash'
          ? (double.tryParse(_cashCtrl.text) ?? _total)
          : _total,
      discount: _discount,
    );
    if (mounted) setState(() => _paying = false);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_long,
                        color: AppColors.warning, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.orderNumber,
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 15)),
                        Text(order.table?.name ?? 'Olib ketish',
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(order.totalFormatted,
                          style: const TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                      Text('${order.items.length} ta mahsulot',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          ),

          // To'lov formi
          if (_expanded) ...[
            const Divider(color: AppColors.border, height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mahsulotlar
                  ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text('${item.quantity}×',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text(item.productName,
                                style: const TextStyle(
                                    color: AppColors.text, fontSize: 12))),
                        Text(item.totalFormatted,
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 12)),
                      ],
                    ),
                  )),
                  const Divider(color: AppColors.border, height: 16),

                  // To'lov usuli
                  const Text("To'lov usuli",
                      style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _buildMethodSelector(),
                  const SizedBox(height: 12),

                  // Chegirma
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Chegirma:',
                            style: TextStyle(
                                color: AppColors.muted, fontSize: 13)),
                      ),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _discountCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: const TextStyle(
                              color: AppColors.text, fontSize: 14),
                          textAlign: TextAlign.right,
                          onChanged: (_) => setState(() {
                            _cashCtrl.text = _total.toInt().toString();
                          }),
                          decoration: InputDecoration(
                            suffixText: "so'm",
                            suffixStyle: const TextStyle(
                                color: AppColors.muted, fontSize: 11),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Naqd qabul
                  if (_method == 'cash') ...[
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Qabul qilingan:',
                              style: TextStyle(
                                  color: AppColors.muted, fontSize: 13)),
                        ),
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _cashCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: const TextStyle(
                                color: AppColors.text, fontSize: 14),
                            textAlign: TextAlign.right,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              suffixText: "so'm",
                              suffixStyle: const TextStyle(
                                  color: AppColors.muted, fontSize: 11),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: AppColors.primary),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Qaytim
                    if ((double.tryParse(_cashCtrl.text) ?? 0) > _total)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.success.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Qaytim:',
                                style: TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600)),
                            Text(
                              _fmtMoney(
                                  (double.tryParse(_cashCtrl.text) ?? 0) -
                                      _total),
                              style: const TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],

                  // Jami
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Jami to\'lash:',
                            style: TextStyle(
                                color: AppColors.text,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        Text(_fmtMoney(_total),
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 18)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // To'lov tugmasi
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _paying ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.shiftOpen
                            ? AppColors.success
                            : AppColors.muted,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _paying
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "To'lovni qabul qilish",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMethodSelector() {
    final methods = [
      ('cash', 'Naqd', Icons.money),
      ('card', 'Karta', Icons.credit_card),
      ('click', 'Click', Icons.phone_android),
      ('payme', 'Payme', Icons.payment),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: methods.map((m) {
        final active = _method == m.$1;
        return GestureDetector(
          onTap: () => setState(() => _method = m.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(m.$3,
                    color: active ? Colors.white : AppColors.muted,
                    size: 16),
                const SizedBox(width: 5),
                Text(m.$2,
                    style: TextStyle(
                      color: active ? Colors.white : AppColors.muted,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w400,
                      fontSize: 13,
                    )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _fmtMoney(double v) {
    final s = v.toInt().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]} ',
    );
    return "$s so'm";
  }
}
