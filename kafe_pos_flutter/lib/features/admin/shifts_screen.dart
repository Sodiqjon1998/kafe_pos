import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';

class ShiftsScreen extends StatefulWidget {
  const ShiftsScreen({super.key});

  @override
  State<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends State<ShiftsScreen> {
  final _api = ApiClient();
  Map<String, dynamic>? _current;
  List<dynamic> _history = [];
  bool _loading = true;
  String? _error;
  bool _acting = false;

  // Tarix filter: 0=Barchasi, 1=Bugun, 2=Hafta, 3=Oy
  int _filterIndex = 0;
  static const _filterLabels = ['Barchasi', 'Bugun', 'Hafta', 'Oy'];

  List<dynamic> get _filteredHistory {
    if (_filterIndex == 0) return _history;
    final now = DateTime.now();
    return _history.where((s) {
      final raw = s['opened_at']?.toString() ?? '';
      if (raw.isEmpty) return true;
      try {
        final dt = DateTime.parse(raw).toLocal();
        if (_filterIndex == 1) {
          return dt.year == now.year && dt.month == now.month && dt.day == now.day;
        } else if (_filterIndex == 2) {
          return now.difference(dt).inDays <= 7;
        } else {
          return dt.year == now.year && dt.month == now.month;
        }
      } catch (_) {
        return true;
      }
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final cur  = await _api.get('/shifts/current');
      final hist = await _api.get('/shifts');
      setState(() {
        _current = cur.data is Map ? cur.data as Map<String, dynamic> : null;
        _history = hist.data is List ? hist.data as List : [];
      });
    } catch (e) {
      setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openShift() async {
    setState(() => _acting = true);
    try {
      await _api.post('/shifts/open', data: {});
      _snack('Smena ochildi ✓');
      await _load();
    } catch (e) {
      _snack(ApiClient.errorMessage(e), error: true);
    } finally {
      setState(() => _acting = false);
    }
  }

  Future<void> _closeShift() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Smenani yopish',
            style: TextStyle(color: AppColors.text)),
        content: const Text(
          'Joriy smenani yopmoqchimisiz? Bu amal barcha ochiq buyurtmalarni yakunlaydi.',
          style: TextStyle(color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Bekor', style: TextStyle(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yopish', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    ) ?? false;
    if (!ok) return;

    setState(() => _acting = true);
    try {
      await _api.post('/shifts/close', data: {});
      _snack('Smena yopildi');
      await _load();
    } catch (e) {
      _snack(ApiClient.errorMessage(e), error: true);
    } finally {
      setState(() => _acting = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.danger : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
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
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Qayta', style: TextStyle(color: AppColors.white)),
            ),
          ],
        ),
      );
    }

    final isOpen = _current != null && (_current!['is_open'] == true);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Joriy smena kartochkasi ────────────────────────────────────
          _CurrentShiftCard(
            shift: _current,
            isOpen: isOpen,
            acting: _acting,
            onOpen: _openShift,
            onClose: _closeShift,
          ),

          const SizedBox(height: 20),

          // ── Filter chips ───────────────────────────────────────────────
          Row(
            children: [
              const Text('Smena tarixi',
                  style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              ..._filterLabels.asMap().entries.map((e) {
                final active = _filterIndex == e.key;
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: GestureDetector(
                    onTap: () => setState(() => _filterIndex = e.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primary.withOpacity(0.15)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        e.value,
                        style: TextStyle(
                          color: active ? AppColors.primary : AppColors.muted,
                          fontSize: 11,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 8),

          // ── Tarix ─────────────────────────────────────────────────────
          if (_filteredHistory.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text('Smena tarixi yo\'q',
                    style: TextStyle(color: AppColors.muted)),
              ),
            )
          else
            ..._filteredHistory
                .cast<Map<String, dynamic>>()
                .map((s) => _ShiftHistoryTile(shift: s)),
        ],
      ),
    );
  }
}

// ── Joriy smena kartochkasi ─────────────────────────────────────────────────

class _CurrentShiftCard extends StatelessWidget {
  final Map<String, dynamic>? shift;
  final bool isOpen;
  final bool acting;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  const _CurrentShiftCard({
    required this.shift,
    required this.isOpen,
    required this.acting,
    required this.onOpen,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isOpen
              ? [AppColors.success.withOpacity(0.2), AppColors.card]
              : [AppColors.surface, AppColors.card],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOpen
              ? AppColors.success.withOpacity(0.5)
              : AppColors.border,
          width: isOpen ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isOpen ? AppColors.success : AppColors.muted)
                      .withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOpen ? Icons.timer : Icons.timer_off,
                  color: isOpen ? AppColors.success : AppColors.muted,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOpen ? 'Smena ochiq' : 'Smena yopiq',
                      style: TextStyle(
                          color: isOpen ? AppColors.success : AppColors.muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 16),
                    ),
                    if (shift != null && isOpen)
                      Text(
                        'Ochildi: ${_formatTime(shift!['opened_at'])}',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),

          if (shift != null && isOpen) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.border),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatBox(
                  label: 'Buyurtmalar',
                  value: '${(shift!['stats'] as Map?)?['orders_total'] ?? 0}',
                  icon: Icons.receipt_long_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                _StatBox(
                  label: 'Tushum',
                  value: _formatMoney((shift!['stats'] as Map?)?['revenue']),
                  icon: Icons.payments_outlined,
                  color: AppColors.success,
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: acting
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2),
                    ),
                  )
                : isOpen
                    ? OutlinedButton.icon(
                        onPressed: onClose,
                        icon: const Icon(Icons.stop_circle,
                            color: AppColors.danger, size: 18),
                        label: const Text('Smenani yopish',
                            style: TextStyle(color: AppColors.danger)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.danger),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: onOpen,
                        icon: const Icon(Icons.play_circle_outline,
                            color: AppColors.white, size: 18),
                        label: const Text('Smenani ochish',
                            style: TextStyle(color: AppColors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  String _formatTime(dynamic val) {
    if (val == null) return '—';
    try {
      final dt = DateTime.parse(val.toString()).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return val.toString();
    }
  }

  String _formatMoney(dynamic val) {
    if (val == null) return '0 so\'m';
    final n = (val is num ? val : num.tryParse(val.toString()) ?? 0).toInt();
    final s = n.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ');
    return '$s so\'m';
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 10)),
                  Text(value,
                      style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tarix element ────────────────────────────────────────────────────────────

class _ShiftHistoryTile extends StatelessWidget {
  final Map<String, dynamic> shift;

  const _ShiftHistoryTile({required this.shift});

  String _fmt(dynamic val) {
    if (val == null) return '—';
    try {
      final dt = DateTime.parse(val.toString()).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return val.toString();
    }
  }

  String _money(dynamic val) {
    if (val == null) return '0';
    final n = (val is num ? val : num.tryParse(val.toString()) ?? 0).toInt();
    return n.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ');
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = shift['is_open'] == true;
    final color = isOpen ? AppColors.success : AppColors.muted;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fmt(shift['opened_at']),
                  style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                if (shift['closed_at'] != null)
                  Text(
                    '→ ${_fmt(shift['closed_at'])}',
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 11),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_money((shift['stats'] as Map?)?['revenue'])} so\'m',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
              Text(
                '${(shift['stats'] as Map?)?['orders_total'] ?? 0} buyurtma',
                style: const TextStyle(
                    color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
