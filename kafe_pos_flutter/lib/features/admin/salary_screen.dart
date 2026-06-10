import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';

// ─── Model ──────────────────────────────────────────────────────────────────
class _SalaryUser {
  final int    id;
  final String name;
  final String role;
  final bool   isActive;
  final int    monthlySalary;
  final int    paidThisMonth;
  final int    debt;

  const _SalaryUser({
    required this.id,
    required this.name,
    required this.role,
    required this.isActive,
    required this.monthlySalary,
    required this.paidThisMonth,
    required this.debt,
  });

  factory _SalaryUser.fromJson(Map<String, dynamic> j) => _SalaryUser(
        id:            j['id'],
        name:          j['name'] ?? '',
        role:          j['role'] ?? '',
        isActive:      j['is_active'] ?? true,
        monthlySalary: _toInt(j['monthly_salary']),
        paidThisMonth: _toInt(j['paid_this_month']),
        debt:          _toInt(j['debt']),
      );

  static int _toInt(dynamic v) => int.tryParse(v?.toString() ?? '0') ?? 0;
}

class _Payment {
  final int    id;
  final int    amount;
  final String type;
  final String month;
  final String? note;
  final String? paidByName;
  final DateTime createdAt;

  const _Payment({
    required this.id,
    required this.amount,
    required this.type,
    required this.month,
    this.note,
    this.paidByName,
    required this.createdAt,
  });

  factory _Payment.fromJson(Map<String, dynamic> j) => _Payment(
        id:         j['id'],
        amount:     _SalaryUser._toInt(j['amount']),
        type:       j['type'] ?? 'monthly',
        month:      j['month'] ?? '',
        note:       j['note'],
        paidByName: j['paid_by_user']?['name'],
        createdAt:  DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      );
}

// ─── Maosh ekrani ─────────────────────────────────────────────────────────────
class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  final _api = ApiClient();

  List<_SalaryUser> _users  = [];
  bool              _loading = false;
  String?           _error;

  String _month = _currentMonth();

  static String _currentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get('/salaries', params: {'month': _month});
      _users = (res.data as List)
          .map((u) => _SalaryUser.fromJson(u as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = ApiClient.errorMessage(e);
    } finally {
      setState(() => _loading = false);
    }
  }

  // Statistika
  int get _totalSalary => _users.fold(0, (s, u) => s + u.monthlySalary);
  int get _totalPaid   => _users.fold(0, (s, u) => s + u.paidThisMonth);
  int get _totalDebt   => _users.fold(0, (s, u) => s + u.debt);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _buildHeader(),
          _buildStats(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: AppColors.surface,
      child: Row(
        children: [
          const Text('💰', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Xodimlar Maoshi',
                style: TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          // Oy tanlash
          GestureDetector(
            onTap: _pickMonth,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_month, style: const TextStyle(color: AppColors.text, fontSize: 13)),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, color: AppColors.muted, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  // ── Statistika ──────────────────────────────────────────────────────────────
  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _StatChip(label: 'Fond', value: _fmt(_totalSalary), color: AppColors.info),
          const SizedBox(width: 8),
          _StatChip(label: "To'langan", value: _fmt(_totalPaid), color: AppColors.success),
          const SizedBox(width: 8),
          _StatChip(label: 'Qarz', value: _fmt(_totalDebt), color: AppColors.danger),
        ],
      ),
    );
  }

  // ── Ro'yxat ─────────────────────────────────────────────────────────────────
  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: AppColors.danger)));
    }
    if (_users.isEmpty) {
      return const Center(child: Text('Xodimlar topilmadi', style: TextStyle(color: AppColors.muted)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _UserCard(
        user: _users[i],
        month: _month,
        onSetSalary: () => _showSetSalary(_users[i]),
        onPay:       () => _showPayModal(_users[i]),
        onHistory:   () => _showHistory(_users[i]),
      ),
    );
  }

  // ── Oy tanlash ───────────────────────────────────────────────────────────────
  Future<void> _pickMonth() async {
    final months = List.generate(12, (i) {
      final d = DateTime(DateTime.now().year, DateTime.now().month - i);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}';
    });

    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Oy tanlang', style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ...months.map((m) => ListTile(
            title: Text(m, style: TextStyle(color: m == _month ? AppColors.primary : AppColors.text)),
            trailing: m == _month ? const Icon(Icons.check, color: AppColors.primary) : null,
            onTap: () => Navigator.pop(context, m),
          )),
          const SizedBox(height: 16),
        ],
      ),
    );

    if (picked != null && picked != _month) {
      setState(() => _month = picked);
      _load();
    }
  }

  // ── Maosh belgilash ──────────────────────────────────────────────────────────
  Future<void> _showSetSalary(_SalaryUser user) async {
    final ctrl = TextEditingController(text: user.monthlySalary.toString());
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SetSalarySheet(user: user, ctrl: ctrl, api: _api),
    );
    if (saved == true) _load();
  }

  // ── To'lov modal ─────────────────────────────────────────────────────────────
  Future<void> _showPayModal(_SalaryUser user) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PaySheet(user: user, month: _month, api: _api),
    );
    if (saved == true) _load();
  }

  // ── To'lov tarixi ─────────────────────────────────────────────────────────────
  Future<void> _showHistory(_SalaryUser user) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _HistorySheet(user: user, month: _month, api: _api, onDeleted: _load),
    );
  }
}

// ─── UserCard ─────────────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final _SalaryUser user;
  final String month;
  final VoidCallback onSetSalary;
  final VoidCallback onPay;
  final VoidCallback onHistory;

  const _UserCard({
    required this.user,
    required this.month,
    required this.onSetSalary,
    required this.onPay,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    final pct = user.monthlySalary > 0
        ? (user.paidThisMonth / user.monthlySalary).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: user.debt > 0 ? AppColors.danger.withOpacity(0.3) : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Yuqori qism
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: _roleColor(user.role),
                    borderRadius: BorderRadius.circular(23),
                  ),
                  child: Center(child: Text(_roleIcon(user.role), style: const TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 12),
                // Ism + rol
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Row(children: [
                        Text(_roleLabel(user.role), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                        if (!user.isActive) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                            child: const Text('Faol emas', style: TextStyle(color: AppColors.danger, fontSize: 10)),
                          ),
                        ],
                      ]),
                    ],
                  ),
                ),
                // Maosh raqami
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_fmt(user.monthlySalary), style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 14)),
                    const Text('oylik', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),

          // Progress bar
          if (user.monthlySalary > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation(pct >= 1.0 ? AppColors.success : AppColors.primary),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("To'langan: ${_fmt(user.paidThisMonth)}", style: const TextStyle(color: AppColors.success, fontSize: 11)),
                      if (user.debt > 0)
                        Text("Qarz: ${_fmt(user.debt)}", style: const TextStyle(color: AppColors.danger, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Tugmalar
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Row(
              children: [
                _ActionBtn(icon: Icons.settings_outlined, label: 'Maosh', color: AppColors.info, onTap: onSetSalary),
                _ActionBtn(icon: Icons.payments_outlined, label: "To'lash", color: AppColors.success, onTap: onPay),
                _ActionBtn(icon: Icons.history, label: 'Tarix', color: AppColors.muted, onTap: onHistory),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 3),
              Text(label, style: TextStyle(color: color, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SetSalarySheet ───────────────────────────────────────────────────────────
class _SetSalarySheet extends StatefulWidget {
  final _SalaryUser user;
  final TextEditingController ctrl;
  final ApiClient api;
  const _SetSalarySheet({required this.user, required this.ctrl, required this.api});

  @override
  State<_SetSalarySheet> createState() => _SetSalarySheetState();
}

class _SetSalarySheetState extends State<_SetSalarySheet> {
  bool _saving = false;

  Future<void> _save() async {
    final v = int.tryParse(widget.ctrl.text.trim());
    if (v == null) return;
    setState(() => _saving = true);
    try {
      await widget.api.put('/users/${widget.user.id}/salary', data: {'monthly_salary': v});
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.errorMessage(e)), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHandle(),
            const SizedBox(height: 4),
            Text('⚙️ Oylik maosh — ${widget.user.name}',
                style: const TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Oylik maosh (so\'m)', style: TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: widget.ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              style: const TextStyle(color: AppColors.text),
              decoration: InputDecoration(
                filled: true, fillColor: AppColors.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
                suffixText: "so'm",
                suffixStyle: const TextStyle(color: AppColors.muted),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(_saving ? 'Saqlanmoqda...' : '💾 Saqlash',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PaySheet ─────────────────────────────────────────────────────────────────
class _PaySheet extends StatefulWidget {
  final _SalaryUser user;
  final String month;
  final ApiClient api;
  const _PaySheet({required this.user, required this.month, required this.api});

  @override
  State<_PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends State<_PaySheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl   = TextEditingController();
  String _type    = 'monthly';
  bool   _saving  = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountCtrl.text = widget.user.debt > 0
        ? widget.user.debt.toString()
        : widget.user.monthlySalary.toString();
  }

  Future<void> _save() async {
    final amount = int.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount < 1) {
      setState(() => _error = 'Summa kiritilmagan');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await widget.api.post('/salary-payments', data: {
        'user_id': widget.user.id,
        'amount':  amount,
        'type':    _type,
        'month':   widget.month,
        'note':    _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() { _saving = false; _error = ApiClient.errorMessage(e); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = {'monthly': 'Oylik', 'advance': 'Avans', 'bonus': 'Bonus'};
    final typeColors = {'monthly': AppColors.success, 'advance': AppColors.info, 'bonus': AppColors.primary};

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHandle(),
            const SizedBox(height: 4),
            Text("💵 Maosh to'lash — ${widget.user.name}",
                style: const TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Qisqa info
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoChip('Oy', widget.month, AppColors.muted),
                  _InfoChip('Oylik', _fmt(widget.user.monthlySalary), AppColors.primary),
                  _InfoChip("To'langan", _fmt(widget.user.paidThisMonth), AppColors.success),
                  _InfoChip('Qarz', _fmt(widget.user.debt), widget.user.debt > 0 ? AppColors.danger : AppColors.muted),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Tur tanlash
            const Text("To'lov turi", style: TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: types.entries.map((e) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _type = e.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _type == e.key ? typeColors[e.key]! : AppColors.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _type == e.key ? typeColors[e.key]! : AppColors.border),
                      ),
                      child: Text(e.value,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _type == e.key ? Colors.white : AppColors.muted,
                          fontWeight: FontWeight.w600, fontSize: 13,
                        )),
                    ),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 14),
            const Text("Summa (so'm)", style: TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              style: const TextStyle(color: AppColors.text),
              decoration: _fieldDec("Masalan: 1500000"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteCtrl,
              style: const TextStyle(color: AppColors.text),
              decoration: _fieldDec('Izoh (ixtiyoriy)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(_saving ? 'Saqlanmoqda...' : '✅ Tasdiqlash',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── HistorySheet ─────────────────────────────────────────────────────────────
class _HistorySheet extends StatefulWidget {
  final _SalaryUser user;
  final String month;
  final ApiClient api;
  final VoidCallback onDeleted;

  const _HistorySheet({
    required this.user,
    required this.month,
    required this.api,
    required this.onDeleted,
  });

  @override
  State<_HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<_HistorySheet> {
  List<_Payment> _payments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await widget.api.get(
        '/users/${widget.user.id}/salary-payments',
        params: {'month': widget.month},
      );
      final raw = res.data;
      final list = raw is Map ? (raw['data'] as List?) ?? [] : raw as List;
      setState(() {
        _payments = list.map((p) => _Payment.fromJson(p as Map<String, dynamic>)).toList();
        _loading  = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("O'chirishni tasdiqlaysizmi?", style: TextStyle(color: AppColors.text)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Bekor")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("O'chirish", style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.api.delete('/salary-payments/$id');
      setState(() => _payments.removeWhere((p) => p.id == id));
      widget.onDeleted();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final total = _payments.fold(0, (s, p) => s + p.amount);
    final typeLabels = {'monthly': 'Oylik', 'advance': 'Avans', 'bonus': 'Bonus'};
    final typeIcons  = {'monthly': '💵', 'advance': '🔵', 'bonus': '🎁'};

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text('📋 Tarix — ${widget.user.name} (${widget.month})',
                        style: const TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                  Text(_fmt(total), style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _payments.isEmpty
                      ? const Center(child: Text("Bu oyda to'lov yo'q", style: TextStyle(color: AppColors.muted)))
                      : ListView.separated(
                          controller: ctrl,
                          padding: const EdgeInsets.all(12),
                          itemCount: _payments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final p = _payments[i];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Text(typeIcons[p.type] ?? '💵', style: const TextStyle(fontSize: 22)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_fmt(p.amount),
                                            style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 15)),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${typeLabels[p.type] ?? p.type} • ${p.paidByName ?? '–'} • '
                                          '${p.createdAt.day}.${p.createdAt.month}.${p.createdAt.year}',
                                          style: const TextStyle(color: AppColors.muted, fontSize: 11),
                                        ),
                                        if (p.note != null && p.note!.isNotEmpty)
                                          Text(p.note!, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                                    onPressed: () => _delete(p.id),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Kichik yordamchi widgetlar ───────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11)),
      ],
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        width: 40, height: 4,
        decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
String _fmt(int v) => '${v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ')} so\'m';

String _roleLabel(String role) {
  const m = {'admin': 'Admin', 'manager': 'Menejer', 'cashier': 'Kassir', 'waiter': 'Ofitsiant', 'kitchen': 'Oshpaz'};
  return m[role] ?? role;
}

String _roleIcon(String role) {
  const m = {'admin': '👑', 'manager': '🏆', 'cashier': '💵', 'waiter': '🍽️', 'kitchen': '👨‍🍳'};
  return m[role] ?? '👤';
}

Color _roleColor(String role) {
  const m = {
    'admin':   Color(0xFF7C3AED),
    'manager': Color(0xFF2563EB),
    'cashier': Color(0xFF0891B2),
    'waiter':  Color(0xFFD97706),
    'kitchen': Color(0xFFDC2626),
  };
  return m[role] ?? AppColors.muted;
}

InputDecoration _fieldDec(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: AppColors.muted),
  filled: true,
  fillColor: AppColors.card,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
);
