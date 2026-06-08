import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _api = ApiClient();
  List<Map<String, dynamic>> _expenses = [];
  Map<String, dynamic>? _summary;
  bool _loading = true;
  String? _error;

  static final _types = <String, (String, IconData)>{
    'stock_in'  : ('Sklad kirim',   Icons.inventory_2_outlined),
    'salary'    : ('Maosh',         Icons.person_outline),
    'rent'      : ('Ijara',         Icons.home_outlined),
    'utility'   : ('Kommunal',      Icons.bolt),
    'equipment' : ('Jihozlar',      Icons.build_outlined),
    'other'     : ('Boshqa',        Icons.more_horiz),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final now  = DateTime.now();
      final from = _dateStr(now.subtract(const Duration(days: 30)));
      final to   = _dateStr(now);
      final list = await _api.get('/expenses', params: {'from': from, 'to': to});
      final sum  = await _api.get('/expenses/summary', params: {'from': from, 'to': to});
      setState(() {
        if (list.data is List) {
          _expenses = (list.data as List)
              .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
              .toList();
        }
        if (sum.data is Map) _summary = Map<String, dynamic>.from(sum.data as Map);
      });
    } catch (e) {
      setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      setState(() => _loading = false);
    }
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  Future<void> _addExpense() async {
    String selectedType = 'other';
    final amountCtrl = TextEditingController();
    final noteCtrl   = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Yangi xarajat',
                    style: TextStyle(
                        color: AppColors.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),

                // Tur tanlash
                const Text('Xarajat turi',
                    style: TextStyle(color: AppColors.muted, fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _types.entries.map((e) {
                    final active = selectedType == e.key;
                    return GestureDetector(
                      onTap: () => setLocal(() => selectedType = e.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : AppColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: active
                                  ? AppColors.primary
                                  : AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(e.value.$2,
                                color: active ? AppColors.white : AppColors.muted,
                                size: 14),
                            const SizedBox(width: 5),
                            Text(
                              e.value.$1,
                              style: TextStyle(
                                  color: active
                                      ? AppColors.white
                                      : AppColors.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Summa
                _field('Miqdor (so\'m) *', amountCtrl,
                    keyboard: TextInputType.number),
                const SizedBox(height: 12),
                _field('Izoh (ixtiyoriy)', noteCtrl),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final amount = double.tryParse(amountCtrl.text);
                      if (amount == null || amount <= 0) return;
                      Navigator.pop(ctx);
                      try {
                        await _api.post('/expenses', data: {
                          'type':   selectedType,
                          'amount': amount,
                          if (noteCtrl.text.isNotEmpty)
                            'note': noteCtrl.text.trim(),
                        });
                        await _load();
                        _snack('Xarajat qo\'shildi ✓');
                      } catch (e) {
                        _snack(ApiClient.errorMessage(e), error: true);
                      }
                    },
                    child: const Text('Saqlash',
                        style: TextStyle(
                            color: AppColors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    amountCtrl.dispose(); noteCtrl.dispose();
  }

  Future<void> _deleteExpense(dynamic id) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('O\'chirish', style: TextStyle(color: AppColors.text)),
            content: const Text('Bu xarajatni o\'chirasizmi?',
                style: TextStyle(color: AppColors.muted)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Bekor', style: TextStyle(color: AppColors.muted))),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('O\'chirish', style: TextStyle(color: AppColors.danger))),
            ],
          ),
        ) ?? false;
    if (!ok) return;
    try {
      await _api.delete('/expenses/$id');
      await _load();
      _snack('O\'chirildi');
    } catch (e) {
      _snack(ApiClient.errorMessage(e), error: true);
    }
  }

  Widget _field(String label, TextEditingController ctrl,
      {TextInputType keyboard = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          style: const TextStyle(color: AppColors.text),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.bg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border)),
          ),
        ),
      ],
    );
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.danger : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  String _money(dynamic val) {
    if (val == null) return '0';
    final n = (val is num ? val : num.tryParse(val.toString()) ?? 0).toInt();
    return '${n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ')} so\'m';
  }

  String _fmtDate(dynamic val) {
    if (val == null) return '';
    try {
      final dt = DateTime.parse(val.toString()).toLocal();
      return '${dt.day.toString().padLeft(2,'0')}.${dt.month.toString().padLeft(2,'0')} '
          '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return val.toString(); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 40),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Qayta',
                    style: TextStyle(color: AppColors.white))),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            // Summary card
            if (_summary != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.danger.withOpacity(0.15), AppColors.card],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.danger.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _SumCard(label: 'Daromad',
                            value: _money(_summary!['revenue']),
                            color: AppColors.success),
                        const SizedBox(width: 8),
                        _SumCard(label: 'Xarajat',
                            value: _money(_summary!['expense']),
                            color: AppColors.danger),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _SumCard(label: 'Sof foyda',
                        value: _money(_summary!['net_profit']),
                        color: (num.tryParse((_summary!['net_profit'] ?? 0).toString()) ?? 0) >= 0
                            ? AppColors.success
                            : AppColors.danger,
                        full: true),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text('So\'nggi 30 kun xarajatlari',
                  style: TextStyle(color: AppColors.muted, fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
            ],

            // Xarajatlar ro'yxati
            if (_expenses.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Xarajatlar yo\'q',
                      style: TextStyle(color: AppColors.muted)),
                ),
              )
            else
              ..._expenses.map((e) {
                final typeInfo = _types[e['type']] ?? ('Boshqa', Icons.more_horiz);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.border.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(typeInfo.$2, color: AppColors.danger, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(typeInfo.$1,
                                style: const TextStyle(
                                    color: AppColors.text,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            if (e['note'] != null)
                              Text(e['note'],
                                  style: const TextStyle(
                                      color: AppColors.muted, fontSize: 11)),
                            Text(_fmtDate(e['created_at']),
                                style: const TextStyle(
                                    color: AppColors.muted, fontSize: 10)),
                          ],
                        ),
                      ),
                      Text(_money(e['amount']),
                          style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _deleteExpense(e['id']),
                        child: const Icon(Icons.delete_outline,
                            color: AppColors.muted, size: 18),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExpense,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }
}

class _SumCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool full;
  const _SumCard({required this.label, required this.value,
      required this.color, this.full = false});

  @override
  Widget build(BuildContext context) {
    final w = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(
              color: AppColors.muted, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(
              color: color, fontWeight: FontWeight.w800, fontSize: 14)),
        ],
      ),
    );
    return full ? SizedBox(width: double.infinity, child: w) : Expanded(child: w);
  }
}
