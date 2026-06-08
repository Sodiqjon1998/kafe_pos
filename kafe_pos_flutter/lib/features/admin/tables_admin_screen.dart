import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/table_model.dart';
import '../../core/providers/tables_provider.dart';

class TablesAdminScreen extends StatefulWidget {
  const TablesAdminScreen({super.key});

  @override
  State<TablesAdminScreen> createState() => _TablesAdminScreenState();
}

class _TablesAdminScreenState extends State<TablesAdminScreen> {
  final _api = ApiClient();
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TablesProvider>().fetchHalls();
    });
  }

  Future<void> _addTable(Hall hall) async {
    final nameCtrl = TextEditingController();
    final capCtrl  = TextEditingController(text: '4');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${hall.name} ga stol qo\'shish',
                  style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              _buildField('Stol nomi (masalan: 5-stol)', nameCtrl),
              const SizedBox(height: 12),
              _buildField('Sig\'im (kishi soni)', capCtrl,
                  keyboard: TextInputType.number),
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
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) {
                      _snack('Stol nomini kiriting!', error: true);
                      return;
                    }
                    final cap = int.tryParse(capCtrl.text.trim()) ?? 4;
                    final hallId = hall.id;
                    Navigator.pop(ctx);
                    setState(() => _adding = true);
                    try {
                      await _api.post('/tables', data: {
                        'hall_id': hallId,
                        'name': name,
                        'capacity': cap,
                      });
                      if (mounted) {
                        context.read<TablesProvider>().fetchHalls();
                        _snack('Stol qo\'shildi ✓');
                      }
                    } catch (e) {
                      _snack(_detailError(e), error: true);
                    } finally {
                      if (mounted) setState(() => _adding = false);
                    }
                  },
                  child: const Text('Qo\'shish',
                      style: TextStyle(
                          color: AppColors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    nameCtrl.dispose();
    capCtrl.dispose();
  }

  Future<void> _addHall() async {
    final nameCtrl = TextEditingController();

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
              const Text('Yangi zal',
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              _buildField('Zal nomi (masalan: VIP xona)', nameCtrl),
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
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) {
                      _snack('Zal nomini kiriting!', error: true);
                      return;
                    }
                    Navigator.pop(ctx);
                    try {
                      await _api.post('/halls', data: {
                        'name_uz': name,
                        'name_ru': name,
                      });
                      if (mounted) {
                        context.read<TablesProvider>().fetchHalls();
                        _snack('Zal qo\'shildi ✓');
                      }
                    } catch (e) {
                      _snack(_detailError(e), error: true);
                    }
                  },
                  child: const Text('Qo\'shish',
                      style: TextStyle(
                          color: AppColors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    nameCtrl.dispose();
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {TextInputType keyboard = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
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
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }

  // Backend validation xatolarini aniq ko'rsatish
  String _detailError(dynamic e) {
    if (e is Exception) {
      final str = e.toString();
      // DioException içida response ma'lumotlari bo'lishi mumkin
      // ApiClient.errorMessage dan oldin errors ni ham tekshir
      try {
        // ignore: avoid_dynamic_calls
        final resp = (e as dynamic).response;
        if (resp != null && resp.data is Map) {
          final data = resp.data as Map;
          if (data['errors'] is Map) {
            final errs = (data['errors'] as Map).values
                .expand((v) => v is List ? v.cast<String>() : [v.toString()])
                .take(3)
                .join(' | ');
            return errs;
          }
          if (data['message'] != null) return data['message'].toString();
        }
      } catch (_) {}
      return ApiClient.errorMessage(e);
    }
    return e.toString();
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
    final tbls = context.watch<TablesProvider>();
    final halls = tbls.halls;

    if (tbls.loading && halls.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (tbls.error != null && halls.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 40),
            const SizedBox(height: 12),
            Text(tbls.error!, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<TablesProvider>().fetchHalls(),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Qayta', style: TextStyle(color: AppColors.white)),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => context.read<TablesProvider>().fetchHalls(),
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              // Statistika
              Row(
                children: [
                  _SummaryChip(
                    label: '${halls.length} zal',
                    icon: Icons.home_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    label: '${halls.expand((h) => h.tables).length} stol',
                    icon: Icons.table_restaurant,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    label: '${halls.expand((h) => h.tables).where((t) => t.status == 'occupied').length} band',
                    icon: Icons.people,
                    color: AppColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Zallar va stollar
              ...halls.map((hall) => _HallSection(
                    hall: hall,
                    onAddTable: () => _addTable(hall),
                  )),

              // Zal qo'shish
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _addHall,
                icon: const Icon(Icons.add, color: AppColors.primary),
                label: const Text('Yangi zal qo\'shish',
                    style: TextStyle(color: AppColors.primary)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        if (_adding)
          Container(
            color: Colors.black26,
            child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SummaryChip(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _HallSection extends StatelessWidget {
  final Hall hall;
  final VoidCallback onAddTable;

  const _HallSection({required this.hall, required this.onAddTable});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zal header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                const Icon(Icons.meeting_room_outlined, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hall.name,
                    style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 15),
                  ),
                ),
                Text('${hall.tables.length} stol',
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 12)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppColors.primary, size: 20),
                  onPressed: onAddTable,
                  tooltip: 'Stol qo\'shish',
                ),
              ],
            ),
          ),

          // Stollar
          if (hall.tables.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text('Stollar yo\'q. "+" borib qo\'shing.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12)),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1.1,
                ),
                itemCount: hall.tables.length,
                itemBuilder: (_, i) {
                  final t = hall.tables[i];
                  final color = t.statusColor;
                  return Container(
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withOpacity(0.4)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.table_bar, color: AppColors.muted, size: 16),
                        Text(
                          t.name,
                          style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          t.statusLabel,
                          style: TextStyle(color: color, fontSize: 9),
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
  }
}
