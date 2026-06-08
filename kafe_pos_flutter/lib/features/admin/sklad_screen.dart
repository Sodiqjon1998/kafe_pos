import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';

class SkladScreen extends StatefulWidget {
  const SkladScreen({super.key});

  @override
  State<SkladScreen> createState() => _SkladScreenState();
}

class _SkladScreenState extends State<SkladScreen> {
  final _api = ApiClient();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  static const _units = ['kg', 'gr', 'litr', 'ml', 'dona', 'paket', 'quti'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get('/ingredients');
      if (res.data is List) {
        setState(() {
          _items = (res.data as List)
              .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
              .toList();
        });
      }
    } catch (e) {
      setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Jami inventar qiymati ────────────────────────────────────────────────
  int _totalValue() {
    return _items.fold(0, (sum, ing) {
      final q = _toDouble(ing['quantity']);
      final c = _toDouble(ing['cost_per_unit']);
      return sum + (q * c).round();
    });
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    return v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0;
  }

  String _fmtQty(Map<String, dynamic> ing) {
    final n = _toDouble(ing['quantity']);
    return n == n.toInt() ? '${n.toInt()}' : n.toStringAsFixed(2);
  }

  String _money(dynamic val) {
    if (val == null) return '0';
    final n = (val is num ? val : num.tryParse(val.toString()) ?? 0).toInt();
    return '${n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ')} so\'m';
  }

  // ── Kirim (stock-in) ─────────────────────────────────────────────────────
  Future<void> _openStockIn(Map<String, dynamic> ing) async {
    final qtyCtrl  = TextEditingController();
    final costCtrl = TextEditingController(text: ing['cost_per_unit']?.toString() ?? '');
    final noteCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.inventory_2_outlined, color: AppColors.success, size: 22),
                const SizedBox(width: 8),
                Expanded(child: Text('Kirim: ${ing['name']}',
                    style: const TextStyle(color: AppColors.text, fontSize: 17, fontWeight: FontWeight.w700))),
              ]),
              const SizedBox(height: 4),
              Text('Joriy: ${_fmtQty(ing)} ${ing['unit'] ?? ''}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 20),
              _field('Miqdor (${ing['unit'] ?? ''})*', qtyCtrl, keyboard: TextInputType.number),
              const SizedBox(height: 12),
              _field('Narx/birlik (so\'m)', costCtrl, keyboard: TextInputType.number),
              const SizedBox(height: 12),
              _field('Izoh (ixtiyoriy)', noteCtrl),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final qty = double.tryParse(qtyCtrl.text);
                    if (qty == null || qty <= 0) return;
                    Navigator.pop(ctx);
                    try {
                      await _api.post('/ingredients/${ing['id']}/stock', data: {
                        'quantity': qty,
                        if (costCtrl.text.isNotEmpty)
                          'cost_per_unit': double.tryParse(costCtrl.text) ?? 0,
                        if (noteCtrl.text.isNotEmpty) 'reason': noteCtrl.text.trim(),
                      });
                      await _load();
                      _snack('Kirim qo\'shildi ✓');
                    } catch (e) {
                      _snack(ApiClient.errorMessage(e), error: true);
                    }
                  },
                  child: const Text('Kirim qilish',
                      style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    qtyCtrl.dispose(); costCtrl.dispose(); noteCtrl.dispose();
  }

  // ── Qo'shish / Tahrirlash ────────────────────────────────────────────────
  Future<void> _openForm({Map<String, dynamic>? ing}) async {
    final isEdit = ing != null;
    final nameCtrl = TextEditingController(text: ing?['name'] ?? '');
    String selectedUnit = ing?['unit'] ?? 'kg';
    final qtyCtrl  = TextEditingController(text: isEdit ? '' : '0');
    final minCtrl  = TextEditingController(text: ing?['min_quantity']?.toString() ?? '0');
    final costCtrl = TextEditingController(text: ing?['cost_per_unit']?.toString() ?? '0');

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
                Text(isEdit ? 'Tahrirlash' : 'Yangi ingredient',
                    style: const TextStyle(color: AppColors.text, fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                _field('Nomi *', nameCtrl),
                const SizedBox(height: 12),
                // O'lchov birligi
                const Text('O\'lchov birligi',
                    style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _units.length,
                    itemBuilder: (_, i) {
                      final u = _units[i];
                      final active = u == selectedUnit;
                      return GestureDetector(
                        onTap: () => setLocal(() => selectedUnit = u),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: active ? AppColors.primary : AppColors.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: active ? AppColors.primary : AppColors.border),
                          ),
                          child: Text(u,
                              style: TextStyle(
                                color: active ? AppColors.white : AppColors.muted,
                                fontSize: 13, fontWeight: FontWeight.w600,
                              )),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                if (!isEdit) ...[
                  _field('Boshlang\'ich miqdor', qtyCtrl, keyboard: TextInputType.number),
                  const SizedBox(height: 12),
                ],
                Row(children: [
                  Expanded(child: _field('Min. qoldiq', minCtrl, keyboard: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: _field('Narx/birlik (so\'m)', costCtrl, keyboard: TextInputType.number)),
                ]),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      Navigator.pop(ctx);
                      try {
                        final data = {
                          'name': nameCtrl.text.trim(),
                          'unit': selectedUnit,
                          'min_quantity': double.tryParse(minCtrl.text) ?? 0,
                          'cost_per_unit': double.tryParse(costCtrl.text) ?? 0,
                          if (!isEdit) 'quantity': double.tryParse(qtyCtrl.text) ?? 0,
                        };
                        if (isEdit) {
                          await _api.put('/ingredients/${ing['id']}', data: data);
                        } else {
                          await _api.post('/ingredients', data: data);
                        }
                        await _load();
                        _snack(isEdit ? 'Yangilandi ✓' : 'Qo\'shildi ✓');
                      } catch (e) {
                        _snack(ApiClient.errorMessage(e), error: true);
                      }
                    },
                    child: const Text('Saqlash',
                        style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    nameCtrl.dispose(); qtyCtrl.dispose(); minCtrl.dispose(); costCtrl.dispose();
  }

  // ── Harakatlar tarixi ────────────────────────────────────────────────────
  Future<void> _openMovements(Map<String, dynamic> ing) async {
    List<Map<String, dynamic>> movements = [];
    bool loading = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          if (loading) {
            _api.get('/ingredients/${ing['id']}/movements').then((res) {
              setLocal(() {
                if (res.data is List) {
                  movements = (res.data as List)
                      .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
                      .toList();
                }
                loading = false;
              });
            }).catchError((_) => setLocal(() => loading = false));
          }

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            builder: (_, scroll) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${ing['name']} — harakatlar',
                            style: const TextStyle(
                                color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.border, height: 1),
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : movements.isEmpty
                          ? const Center(
                              child: Text('Harakatlar yo\'q',
                                  style: TextStyle(color: AppColors.muted)))
                          : ListView.separated(
                              controller: scroll,
                              padding: const EdgeInsets.all(16),
                              itemCount: movements.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(color: AppColors.border, height: 1),
                              itemBuilder: (_, i) {
                                final m = movements[i];
                                final isIn = m['type'] == 'in';
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isIn
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
                                        color: isIn ? AppColors.success : AppColors.danger,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${isIn ? '+' : '-'} ${_toDouble(m['quantity']).toStringAsFixed(2)} ${ing['unit'] ?? ''}',
                                              style: TextStyle(
                                                  color: isIn ? AppColors.success : AppColors.danger,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13),
                                            ),
                                            Text(m['reason'] ?? '—',
                                                style: const TextStyle(
                                                    color: AppColors.muted, fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        _fmtDate(m['created_at']),
                                        style: const TextStyle(color: AppColors.muted, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── O'chirish ────────────────────────────────────────────────────────────
  Future<void> _deleteIngredient(Map<String, dynamic> ing) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('O\'chirish', style: TextStyle(color: AppColors.text)),
            content: Text('"${ing['name']}"ni o\'chirasizmi?',
                style: const TextStyle(color: AppColors.muted)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Bekor', style: TextStyle(color: AppColors.muted))),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('O\'chirish', style: TextStyle(color: AppColors.danger))),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    try {
      await _api.delete('/ingredients/${ing['id']}');
      await _load();
      _snack('O\'chirildi');
    } catch (e) {
      _snack(ApiClient.errorMessage(e), error: true);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  Widget _field(String label, TextEditingController ctrl,
      {TextInputType keyboard = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          style: const TextStyle(color: AppColors.text),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.bg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

  String _fmtDate(dynamic val) {
    if (val == null) return '';
    try {
      final dt = DateTime.parse(val.toString()).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return val.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
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
            ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Qayta', style: TextStyle(color: AppColors.white))),
          ],
        ),
      );
    }

    final lowStock = _items.where((i) => i['low_stock'] == true).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            // ── Jami qiymat ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withOpacity(0.12), AppColors.card],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.inventory_2_outlined,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_items.length} ta ingredient',
                          style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      Text(_money(_totalValue()),
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 18)),
                    ],
                  ),
                  const Spacer(),
                  if (lowStock.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber,
                              color: AppColors.warning, size: 14),
                          const SizedBox(width: 4),
                          Text('${lowStock.length} kam',
                              style: const TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // ── Kam qolgan ogohlantirish ────────────────────────────────────
            if (lowStock.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.danger.withOpacity(0.35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber,
                        color: AppColors.danger, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kam qolgan: ${lowStock.map((i) => '${i['name']} (${_fmtQty(i)} ${i['unit']})').join(', ')}',
                        style: const TextStyle(
                            color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),
            const Text('Barcha ingredientlar',
                style: TextStyle(
                    color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            // ── Ingredientlar ro'yxati ────────────────────────────────────
            if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                    child: Text('Ingredient qo\'shilmagan',
                        style: TextStyle(color: AppColors.muted))),
              )
            else
              ..._items.map((ing) => _IngredientCard(
                    ing: ing,
                    onStockIn: () => _openStockIn(ing),
                    onEdit: () => _openForm(ing: ing),
                    onDelete: () => _deleteIngredient(ing),
                    onMovements: () => _openMovements(ing),
                    fmtQty: _fmtQty,
                    toDouble: _toDouble,
                    money: _money,
                  )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }
}

class _IngredientCard extends StatelessWidget {
  final Map<String, dynamic> ing;
  final VoidCallback onStockIn;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMovements;
  final String Function(Map<String, dynamic>) fmtQty;
  final double Function(dynamic) toDouble;
  final String Function(dynamic) money;

  const _IngredientCard({
    required this.ing,
    required this.onStockIn,
    required this.onEdit,
    required this.onDelete,
    required this.onMovements,
    required this.fmtQty,
    required this.toDouble,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    final isLow = ing['low_stock'] == true;
    final qty   = toDouble(ing['quantity']);
    final cost  = toDouble(ing['cost_per_unit']);
    final total = (qty * cost).round();
    final minQ  = toDouble(ing['min_quantity']);
    final hasPct = minQ > 0;
    final pct = hasPct ? (qty / (minQ * 2)).clamp(0.0, 1.0) : 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isLow
                ? AppColors.warning.withOpacity(0.5)
                : AppColors.border.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 6, 8),
            child: Row(
              children: [
                // Ikona
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (isLow ? AppColors.warning : AppColors.primary).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isLow
                        ? Icons.warning_amber
                        : Icons.inventory_2_outlined,
                    color: isLow ? AppColors.warning : AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),

                // Asosiy ma'lumot
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ing['name'] ?? '',
                          style: const TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          // Qoldiq
                          Text(
                            '${fmtQty(ing)} ${ing['unit'] ?? ''}',
                            style: TextStyle(
                                color: isLow ? AppColors.warning : AppColors.success,
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                          if (minQ > 0) ...[
                            Text(' / min: ${minQ.toInt()} ${ing['unit'] ?? ''}',
                                style: const TextStyle(
                                    color: AppColors.muted, fontSize: 11)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Qiymat
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(money(total),
                        style: const TextStyle(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w800,
                            fontSize: 12)),
                    Text('${money(cost.round())}/birlik',
                        style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                  ],
                ),

                // Amallar
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.muted, size: 20),
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (v) {
                    switch (v) {
                      case 'in':        onStockIn();   break;
                      case 'edit':      onEdit();      break;
                      case 'movements': onMovements(); break;
                      case 'delete':    onDelete();    break;
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'in',
                        child: Row(children: [
                          Icon(Icons.arrow_downward, color: AppColors.success, size: 16),
                          SizedBox(width: 8),
                          Text('Kirim', style: TextStyle(color: AppColors.text, fontSize: 13)),
                        ])),
                    const PopupMenuItem(value: 'movements',
                        child: Row(children: [
                          Icon(Icons.history, color: AppColors.primary, size: 16),
                          SizedBox(width: 8),
                          Text('Harakatlar', style: TextStyle(color: AppColors.text, fontSize: 13)),
                        ])),
                    const PopupMenuItem(value: 'edit',
                        child: Row(children: [
                          Icon(Icons.edit_outlined, color: AppColors.muted, size: 16),
                          SizedBox(width: 8),
                          Text('Tahrirlash', style: TextStyle(color: AppColors.text, fontSize: 13)),
                        ])),
                    const PopupMenuItem(value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline, color: AppColors.danger, size: 16),
                          SizedBox(width: 8),
                          Text('O\'chirish', style: TextStyle(color: AppColors.danger, fontSize: 13)),
                        ])),
                  ],
                ),
              ],
            ),
          ),

          // Progress bar (agar min_quantity belgilangan bo'lsa)
          if (hasPct)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: AppColors.border,
                  color: isLow ? AppColors.warning : AppColors.success,
                  minHeight: 4,
                ),
              ),
            ),

          // Status badge
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isLow
                        ? AppColors.warning.withOpacity(0.15)
                        : AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isLow ? 'Kam qolgan' : 'OK',
                    style: TextStyle(
                        color: isLow ? AppColors.warning : AppColors.success,
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                // Quick kirim tugmasi
                GestureDetector(
                  onTap: onStockIn,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: AppColors.success, size: 13),
                        SizedBox(width: 3),
                        Text('Kirim',
                            style: TextStyle(
                                color: AppColors.success,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
