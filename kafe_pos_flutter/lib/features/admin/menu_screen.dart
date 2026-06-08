import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/menu_model.dart';
import '../../core/providers/menu_provider.dart';

String _prodEmoji(String name) {
  final n = name.toLowerCase();
  if (n.contains('osh') || n.contains('plov')) return '🍚';
  if (n.contains('shashlik') || n.contains('kabob')) return '🍖';
  if (n.contains('lag\'mon') || n.contains('lagman')) return '🍜';
  if (n.contains('manti')) return '🥟';
  if (n.contains('manpar')) return '🍜';
  if (n.contains('dimlama')) return '🫕';
  if (n.contains('sho\'rva') || n.contains('shurpa') || n.contains('mastava')) return '🍵';
  if (n.contains('salat') || n.contains('achchiq')) return '🥗';
  if (n.contains('choy') || n.contains('tea')) return '🍵';
  if (n.contains('pepsi') || n.contains('cola') || n.contains('limonad')) return '🥤';
  if (n.contains('kompot') || n.contains('sharbat')) return '🍹';
  if (n.contains('samsa')) return '🫓';
  if (n.contains('non')) return '🫓';
  if (n.contains('pizza')) return '🍕';
  return '🍽️';
}

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _selectedCat = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mp = context.read<MenuProvider>();
      if (mp.categories.isEmpty) mp.fetchMenu();
    });
  }

  // ── Kategoriya CRUD ──────────────────────────────────────────────────────

  Future<void> _openCategoryForm([Category? cat]) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CategoryForm(
          category: cat,
          onSaved: () => context.read<MenuProvider>().fetchMenu()),
    );
  }

  Future<void> _deleteCategory(Category cat) async {
    final ok = await _confirm(
        '"${cat.nameUz}" kategoriyasini o\'chirasizmi? Ichidagi mahsulotlar ham o\'chadi!');
    if (!ok) return;
    try {
      await context.read<MenuProvider>().deleteCategory(cat.id);
      setState(() => _selectedCat = 0);
      _snack('O\'chirildi');
    } catch (e) {
      _snack(e.toString(), error: true);
    }
  }

  // ── Mahsulot CRUD ─────────────────────────────────────────────────────────

  Future<void> _openProductForm(int categoryId, [Product? product]) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ProductForm(
          product: product,
          categoryId: categoryId,
          onSaved: () => context.read<MenuProvider>().fetchMenu()),
    );
  }

  Future<void> _deleteProduct(Product p) async {
    final ok = await _confirm('"${p.nameUz}" ni o\'chirasizmi?');
    if (!ok) return;
    try {
      await context.read<MenuProvider>().deleteProduct(p.id);
      _snack('O\'chirildi');
    } catch (e) {
      _snack(e.toString(), error: true);
    }
  }

  Future<bool> _confirm(String msg) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Tasdiqlash',
              style: TextStyle(color: AppColors.text)),
          content: Text(msg,
              style: const TextStyle(color: AppColors.muted)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Bekor',
                    style: TextStyle(color: AppColors.muted))),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('O\'chirish',
                    style: TextStyle(color: AppColors.danger))),
          ],
        ),
      ) ??
      false;

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.danger : AppColors.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final menuP = context.watch<MenuProvider>();
    final cats  = menuP.categories;

    if (menuP.loading && cats.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    final selCat = cats.isNotEmpty && _selectedCat < cats.length
        ? cats[_selectedCat]
        : null;

    return Column(
      children: [
        // ── Kategoriyalar qatori ─────────────────────────────────────────
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: cats.length,
                    itemBuilder: (_, i) {
                      final active = i == _selectedCat;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCat = i),
                        onLongPress: () => _openCategoryForm(cats[i]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary
                                : AppColors.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: active
                                    ? AppColors.primary
                                    : AppColors.border),
                          ),
                          child: Center(
                            child: Text(
                              cats[i].icon != null
                                  ? '${cats[i].icon} ${cats[i].nameUz}'
                                  : cats[i].nameUz,
                              style: TextStyle(
                                  color: active
                                      ? AppColors.white
                                      : AppColors.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Kategoriya qo'shish
              IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    color: AppColors.primary),
                onPressed: () => _openCategoryForm(),
                tooltip: 'Kategoriya qo\'shish',
              ),
            ],
          ),
        ),

        // ── Mahsulotlar ──────────────────────────────────────────────────
        Expanded(
          child: selCat == null
              ? const Center(
                  child: Text('Kategoriya yo\'q',
                      style: TextStyle(color: AppColors.muted)))
              : Column(
                  children: [
                    // Kategoriya header
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
                      decoration: const BoxDecoration(
                        color: AppColors.bg,
                        border: Border(
                            bottom: BorderSide(color: AppColors.border)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${selCat.nameUz} — ${selCat.products.length} ta mahsulot',
                              style: const TextStyle(
                                  color: AppColors.muted, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Mahsulot qo'shish
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline,
                                color: AppColors.primary, size: 22),
                            onPressed: () => _openProductForm(selCat.id),
                            tooltip: 'Mahsulot qo\'shish',
                          ),
                          // Kategoriyani tahrirlash
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                color: AppColors.muted, size: 20),
                            onPressed: () => _openCategoryForm(selCat),
                            tooltip: 'Kategoriya tahrirlash',
                          ),
                          // Kategoriyani o'chirish
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.danger, size: 20),
                            onPressed: () => _deleteCategory(selCat),
                            tooltip: 'Kategoriya o\'chirish',
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        onRefresh: () =>
                            context.read<MenuProvider>().fetchMenu(),
                        child: selCat.products.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.restaurant_menu,
                                        color: AppColors.muted, size: 40),
                                    const SizedBox(height: 8),
                                    const Text(
                                        'Bu kategoriyada mahsulot yo\'q',
                                        style: TextStyle(
                                            color: AppColors.muted)),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _openProductForm(selCat.id),
                                      icon: const Icon(Icons.add,
                                          color: AppColors.white),
                                      label: const Text('Mahsulot qo\'shish',
                                          style: TextStyle(
                                              color: AppColors.white)),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.primary),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount:
                                    selCat.products.length,
                                itemBuilder: (_, i) {
                                  final p = selCat.products[i];
                                  return _ProductTile(
                                    product: p,
                                    onEdit: () => _openProductForm(
                                        selCat.id, p),
                                    onDelete: () => _deleteProduct(p),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductTile(
      {required this.product,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: product.isAvailable
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.border.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              product.isAvailable ? _prodEmoji(product.nameUz) : '🚫',
              style: const TextStyle(fontSize: 22),
            ),
          ),
        ),
        title: Text(product.nameUz,
            style: TextStyle(
                color: product.isAvailable
                    ? AppColors.text
                    : AppColors.muted,
                fontWeight: FontWeight.w600)),
        subtitle: Text(product.priceFormatted,
            style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!product.isAvailable)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Text('Mavjud emas',
                    style: TextStyle(
                        color: AppColors.danger, fontSize: 10)),
              ),
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: AppColors.muted, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.danger, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Kategoriya formi ─────────────────────────────────────────────────────────

class _CategoryForm extends StatefulWidget {
  final Category? category;
  final VoidCallback onSaved;

  const _CategoryForm({this.category, required this.onSaved});

  @override
  State<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<_CategoryForm> {
  final _uzCtrl   = TextEditingController();
  final _ruCtrl   = TextEditingController();
  final _iconCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _uzCtrl.text   = widget.category!.nameUz;
      _ruCtrl.text   = widget.category!.nameRu;
      _iconCtrl.text = widget.category!.icon ?? '';
    }
  }

  @override
  void dispose() {
    _uzCtrl.dispose();
    _ruCtrl.dispose();
    _iconCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_uzCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final data = {
        'name_uz': _uzCtrl.text.trim(),
        'name_ru': _ruCtrl.text.trim().isEmpty
            ? _uzCtrl.text.trim()
            : _ruCtrl.text.trim(),
        if (_iconCtrl.text.isNotEmpty) 'icon': _iconCtrl.text.trim(),
      };
      if (widget.category != null) {
        await context
            .read<MenuProvider>()
            .updateCategory(widget.category!.id, data);
      } else {
        await context.read<MenuProvider>().createCategory(data);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: AppColors.danger,
      ));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.category == null
                  ? 'Yangi kategoriya'
                  : 'Kategoriya tahrirlash',
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            _tf('Nom (UZ) *', _uzCtrl),
            const SizedBox(height: 12),
            _tf('Nom (RU)', _ruCtrl),
            const SizedBox(height: 12),
            _tf('Emoji/Icon', _iconCtrl, hint: '🍕'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  widget.category == null ? 'Qo\'shish' : 'Saqlash',
                  style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tf(String label, TextEditingController ctrl, {String? hint}) =>
      Column(
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
            style: const TextStyle(color: AppColors.text),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.border),
              filled: true,
              fillColor: AppColors.bg,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.primary),
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

// ── Mahsulot formi ────────────────────────────────────────────────────────────

class _ProductForm extends StatefulWidget {
  final Product? product;
  final int categoryId;
  final VoidCallback onSaved;

  const _ProductForm(
      {this.product, required this.categoryId, required this.onSaved});

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final _uzCtrl    = TextEditingController();
  final _ruCtrl    = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _timeCtrl  = TextEditingController(text: '0');
  bool _available = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _uzCtrl.text    = p.nameUz;
      _ruCtrl.text    = p.nameRu;
      _priceCtrl.text = p.price.toInt().toString();
      _timeCtrl.text  = p.cookTime.toString();
      _available      = p.isAvailable;
    }
  }

  @override
  void dispose() {
    _uzCtrl.dispose();
    _ruCtrl.dispose();
    _priceCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_uzCtrl.text.trim().isEmpty || _priceCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Nom va narx kiritilishi shart'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        'category_id': widget.categoryId,
        'name_uz':     _uzCtrl.text.trim(),
        'name_ru':     _ruCtrl.text.trim().isEmpty
            ? _uzCtrl.text.trim()
            : _ruCtrl.text.trim(),
        'price':       double.tryParse(_priceCtrl.text) ?? 0,
        'cook_time':   int.tryParse(_timeCtrl.text) ?? 0,
        'is_available': _available,
      };
      if (widget.product != null) {
        await context
            .read<MenuProvider>()
            .updateProduct(widget.product!.id, data);
      } else {
        await context.read<MenuProvider>().createProduct(data);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: AppColors.danger,
      ));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.product == null
                  ? 'Yangi mahsulot'
                  : 'Mahsulot tahrirlash',
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            _tf('Nom (UZ) *', _uzCtrl),
            const SizedBox(height: 12),
            _tf('Nom (RU)', _ruCtrl),
            const SizedBox(height: 12),
            _tf('Narx (so\'m) *', _priceCtrl,
                keyboard: TextInputType.number),
            const SizedBox(height: 12),
            _tf('Tayyorlash vaqti (daqiqa)', _timeCtrl,
                keyboard: TextInputType.number,
                hint: '0 = darhol tayyor (ichimlik, non)'),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Mavjud',
                    style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                Switch(
                  value: _available,
                  onChanged: (v) => setState(() => _available = v),
                  activeColor: AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  widget.product == null ? 'Qo\'shish' : 'Saqlash',
                  style: const TextStyle(
                      color: AppColors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tf(
    String label,
    TextEditingController ctrl, {
    TextInputType keyboard = TextInputType.text,
    String? hint,
  }) =>
      Column(
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
              hintText: hint,
              hintStyle: const TextStyle(
                  color: AppColors.border, fontSize: 12),
              filled: true,
              fillColor: AppColors.bg,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.primary),
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
