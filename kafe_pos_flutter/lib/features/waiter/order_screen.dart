import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/menu_model.dart';
import '../../core/models/order_model.dart';
import '../../core/models/table_model.dart';
import '../../core/providers/menu_provider.dart';
import '../../core/providers/orders_provider.dart';
import '../../core/providers/tables_provider.dart';

// Kategoriya nomiga qarab icon qaytaradi
IconData _categoryIcon(String name) {
  final n = name.toLowerCase();
  if (n.contains('ichimlik') || n.contains('napitki') || n.contains('choy')) return Icons.local_bar;
  if (n.contains('salat')) return Icons.eco;
  if (n.contains('non') || n.contains('xleb') || n.contains('bread') || n.contains('samsa')) return Icons.bakery_dining;
  if (n.contains('sho\'rva') || n.contains('sup') || n.contains('shurpa')) return Icons.set_meal;
  if (n.contains('dessert') || n.contains('shirinlik')) return Icons.cake;
  if (n.contains('pizza')) return Icons.local_pizza;
  if (n.contains('burger') || n.contains('fast')) return Icons.fastfood;
  return Icons.restaurant;
}

// Mahsulot nomiga qarab icon qaytaradi
IconData _productIcon(String name) {
  final n = name.toLowerCase();
  if (n.contains('choy') || n.contains('tea') || n.contains('kofe') || n.contains('coffee')) return Icons.local_cafe;
  if (n.contains('pepsi') || n.contains('cola') || n.contains('limonad') || n.contains('sharbat') || n.contains('kompot')) return Icons.local_bar;
  if (n.contains('salat') || n.contains('achchiq') || n.contains('eco')) return Icons.eco;
  if (n.contains('non') || n.contains('samsa') || n.contains('lavash')) return Icons.bakery_dining;
  if (n.contains('sho\'rva') || n.contains('mastava') || n.contains('shurpa') || n.contains('lag\'mon') || n.contains('lagman')) return Icons.set_meal;
  if (n.contains('pizza')) return Icons.local_pizza;
  if (n.contains('burger')) return Icons.fastfood;
  return Icons.restaurant;
}

class OrderScreen extends StatefulWidget {
  final int? orderId;
  final TableModel? table;

  const OrderScreen({super.key, this.orderId, this.table});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  int _selectedCatIndex = 0;
  bool _initializing = false;
  bool _isNewOrder = false; // yangi yaratilgan buyurtmami?
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer(int orderId) {
    _refreshTimer?.cancel();
    // 15 soniyada bir buyurtmani yangilash (oshpaz status o'zgarishini ko'rish)
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted && !context.read<OrdersProvider>().actionLoading) {
        context.read<OrdersProvider>().loadOrder(orderId);
      }
    });
  }

  Future<void> _init() async {
    setState(() => _initializing = true);
    final ordersP = context.read<OrdersProvider>();
    final menuP   = context.read<MenuProvider>();

    if (menuP.categories.isEmpty) await menuP.fetchMenu();

    if (widget.orderId != null) {
      await ordersP.loadOrder(widget.orderId!);
      if (mounted) _startRefreshTimer(widget.orderId!);
    } else if (widget.table != null) {
      try {
        await ordersP.createOrder(tableId: widget.table!.id);
        _isNewOrder = true;
        if (mounted && ordersP.currentOrder != null) {
          _startRefreshTimer(ordersP.currentOrder!.id);
        }
      } catch (e) {
        if (mounted) {
          _snack(e.toString(), error: true);
          context.pop();
        }
        return;
      }
    }
    if (mounted) setState(() => _initializing = false);
  }

  Future<void> _addToOrder(Product product) async {
    final ordersP = context.read<OrdersProvider>();
    final order   = ordersP.currentOrder;
    if (order == null) return;
    if (!order.canAddItems) {
      _snack('Bu holatta mahsulot qo\'shib bo\'lmaydi', error: true);
      return;
    }
    try {
      await ordersP.addItem(order.id, product.id, 1);
      _snack('${product.nameUz} qo\'shildi ✓');
    } catch (e) {
      _snack(ordersP.error ?? e.toString(), error: true);
    }
  }

  Future<void> _removeItem(OrderItem item) async {
    final ordersP = context.read<OrdersProvider>();
    final order   = ordersP.currentOrder;
    if (order == null) return;
    try {
      await ordersP.removeItem(order.id, item.id);
    } catch (e) {
      _snack(ordersP.error ?? e.toString(), error: true);
    }
  }

  Future<void> _changeQty(OrderItem item, int delta) async {
    final ordersP = context.read<OrdersProvider>();
    final order   = ordersP.currentOrder;
    if (order == null) return;
    final newQty = item.quantity + delta;
    if (newQty <= 0) {
      _removeItem(item);
      return;
    }
    try {
      await ordersP.updateItem(order.id, item.id, newQty);
    } catch (e) {
      _snack(ordersP.error ?? e.toString(), error: true);
    }
  }

  Future<void> _sendToKitchen() async {
    final ordersP = context.read<OrdersProvider>();
    final order   = ordersP.currentOrder;
    if (order == null || !order.canSendToKitchen) return;

    try {
      final msg = await ordersP.sendToKitchen(order.id);
      _snack('$msg 🍳');
      await context.read<TablesProvider>().fetchHalls();
    } catch (e) {
      _snack(ordersP.error ?? e.toString(), error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.danger : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ordersP = context.watch<OrdersProvider>();
    final menuP   = context.watch<MenuProvider>();
    final order   = ordersP.currentOrder;

    if (_initializing || (ordersP.loading && order == null)) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              const Text('Yuklanmoqda...',
                  style: TextStyle(color: AppColors.muted, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    if (order == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(backgroundColor: AppColors.surface),
        body: const Center(
            child: Text('Buyurtma topilmadi',
                style: TextStyle(color: AppColors.muted))),
      );
    }

    final categories = menuP.categories;
    final selectedCat = categories.isNotEmpty &&
            _selectedCatIndex < categories.length
        ? categories[_selectedCatIndex]
        : null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar(order),
      body: ordersP.actionLoading
          ? Stack(children: [
              _buildBody(order, categories, selectedCat),
              Container(
                  color: Colors.black26,
                  child: const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))),
            ])
          : _buildBody(order, categories, selectedCat),
    );
  }

  Future<void> _handleBack(Order order) async {
    final ordersP = context.read<OrdersProvider>();
    // Yangi buyurtma va taomlar yo'q → bekor qilishni so'ra
    if (_isNewOrder && order.items.isEmpty) {
      final cancel = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Buyurtmani bekor qilish',
              style: TextStyle(color: AppColors.text, fontSize: 15)),
          content: const Text('Taom tanlanmadi. Buyurtmani bekor qilasizmi?',
              style: TextStyle(color: AppColors.muted, fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Davom etish',
                  style: TextStyle(color: AppColors.primary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Bekor qilish',
                  style: TextStyle(color: AppColors.danger)),
            ),
          ],
        ),
      );
      if (cancel == true) {
        await ordersP.cancelOrder(order.id);
        await context.read<TablesProvider>().fetchHalls();
        if (mounted) context.pop();
      }
      return;
    }
    ordersP.clearCurrent();
    context.pop();
  }

  AppBar _buildAppBar(Order order) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            color: AppColors.text, size: 20),
        onPressed: () => _handleBack(order),
      ),
      title: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.orderNumber,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
              Text(
                order.table?.name ?? 'Olib ketish',
                style: const TextStyle(
                    color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: order.statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: order.statusColor.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                    color: order.statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(order.statusLabel,
                  style: TextStyle(
                      color: order.statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody(
      Order order, List<Category> categories, Category? selectedCat) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              // ── Chap: buyurtma ────────────────────────────────────────
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.40,
                child: PrimaryScrollController(
                  controller: ScrollController(),
                  child: _OrderPanel(
                    order: order,
                    onRemove: _removeItem,
                    onChangeQty: _changeQty,
                  ),
                ),
              ),
              Container(width: 1, color: AppColors.border),

              // ── O'ng: menyu ───────────────────────────────────────────
              Expanded(
                child: PrimaryScrollController(
                  controller: ScrollController(),
                  child: _MenuPanel(
                    categories: categories,
                    selectedIndex: _selectedCatIndex,
                    selectedCategory: selectedCat,
                    onCatSelect: (i) => setState(() => _selectedCatIndex = i),
                    onProductTap: _addToOrder,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Pastki panel ─────────────────────────────────────────────
        _BottomPanel(order: order, onSend: _sendToKitchen),
      ],
    );
  }
}

// ── Buyurtma paneli ─────────────────────────────────────────────────────────

class _OrderPanel extends StatelessWidget {
  final Order order;
  final void Function(OrderItem) onRemove;
  final void Function(OrderItem, int) onChangeQty;

  const _OrderPanel({
    required this.order,
    required this.onRemove,
    required this.onChangeQty,
  });

  @override
  Widget build(BuildContext context) {
    final items = order.items;
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              const Icon(Icons.receipt_long,
                  color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Buyurtma (${items.length})',
                    style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
              if (items.isNotEmpty)
                Text(
                  order.totalFormatted,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
            ],
          ),
        ),

        // Items
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.restaurant_menu,
                            color: AppColors.muted, size: 36),
                      ),
                      const SizedBox(height: 12),
                      const Text('Buyurtma bo\'sh',
                          style: TextStyle(
                              color: AppColors.muted, fontSize: 13)),
                      const SizedBox(height: 4),
                      const Text('O\'ngdan taom tanlang',
                          style: TextStyle(
                              color: AppColors.border, fontSize: 11)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      vertical: 6, horizontal: 6),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _OrderItemTile(
                    item: items[i],
                    onRemove: () => onRemove(items[i]),
                    onChangeQty: (d) => onChangeQty(items[i], d),
                  ),
                ),
        ),
      ],
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  final OrderItem item;
  final VoidCallback onRemove;
  final void Function(int) onChangeQty;

  const _OrderItemTile({
    required this.item,
    required this.onRemove,
    required this.onChangeQty,
  });

  @override
  Widget build(BuildContext context) {
    final name = item.productName.contains(' / ')
        ? item.productName.split(' / ').first
        : item.productName;
    final iconData = _productIcon(name);

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          // Icon
          Icon(iconData, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          // Nom va narx
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                Text(item.totalFormatted,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          // Miqdor va o'chirish
          Column(
            children: [
              GestureDetector(
                onTap: onRemove,
                child: const Icon(Icons.close,
                    color: AppColors.danger, size: 14),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _QtyBtn(icon: Icons.remove, onTap: () => onChangeQty(-1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Text('${item.quantity}',
                        style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 13)),
                  ),
                  _QtyBtn(icon: Icons.add, onTap: () => onChangeQty(1)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.text, size: 12),
        ),
      );
}

// ── Menyu paneli ─────────────────────────────────────────────────────────────

class _MenuPanel extends StatelessWidget {
  final List<Category> categories;
  final int selectedIndex;
  final Category? selectedCategory;
  final void Function(int) onCatSelect;
  final void Function(Product) onProductTap;

  const _MenuPanel({
    required this.categories,
    required this.selectedIndex,
    required this.selectedCategory,
    required this.onCatSelect,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Kategoriya tabs
        Container(
          height: 50,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: categories.isEmpty
              ? const Center(
                  child: Text('Kategoriyalar yo\'q',
                      style: TextStyle(color: AppColors.muted, fontSize: 12)))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  itemCount: categories.length,
                  itemBuilder: (_, i) {
                    final cat = categories[i];
                    final active = i == selectedIndex;
                    final iconData = _categoryIcon(cat.nameUz);
                    return GestureDetector(
                      onTap: () => onCatSelect(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 2),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primary
                              : AppColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                      color: AppColors.primary.withOpacity(0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2))
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(iconData,
                                color: active ? AppColors.white : AppColors.muted,
                                size: 14),
                            const SizedBox(width: 5),
                            Text(
                              cat.nameUz,
                              style: TextStyle(
                                color: active
                                    ? AppColors.white
                                    : AppColors.muted,
                                fontSize: 12,
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Mahsulotlar
        Expanded(
          child: selectedCategory == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        categories.isEmpty ? Icons.menu_book : Icons.touch_app,
                        color: AppColors.muted, size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        categories.isEmpty
                            ? 'Menyu bo\'sh'
                            : 'Kategoriya tanlang',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : Builder(builder: (context) {
                  final cat = selectedCategory!;
                  if (cat.products.isEmpty) {
                    return const Center(
                      child: Text('Bu kategoriyada mahsulot yo\'q',
                          style: TextStyle(
                              color: AppColors.muted, fontSize: 12)),
                    );
                  }
                  return ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      physics: const BouncingScrollPhysics(),
                    ),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(10),
                      physics: const AlwaysScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: cat.products.length,
                      itemBuilder: (_, i) {
                        final p = cat.products[i];
                        return _ProductCard(
                          product: p,
                          onTap: p.isAvailable ? () => onProductTap(p) : null,
                        );
                      },
                    ),
                  );
                }),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const _ProductCard({required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    final unavailable = !product.isAvailable;
    final iconData = _productIcon(product.nameUz);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: unavailable
                ? AppColors.card.withOpacity(0.4)
                : AppColors.card,
            border: Border.all(
              color: unavailable
                  ? AppColors.border.withOpacity(0.3)
                  : AppColors.border,
            ),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rasm yoki icon + mavjudlik
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _ProductImage(
                        imagePath: product.image,
                        fallbackIcon: iconData,
                        unavailable: unavailable,
                      ),
                    ),
                    if (unavailable)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Yoʻq',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 5),
              // Nom
              Text(
                product.nameUz,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: unavailable ? AppColors.muted : AppColors.text,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 3),

              // Narx
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.priceFormatted,
                      style: TextStyle(
                        color: unavailable
                            ? AppColors.muted
                            : AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (product.cookTime > 0 && !unavailable)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule,
                            color: AppColors.muted, size: 10),
                        const SizedBox(width: 2),
                        Text('${product.cookTime}\'',
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 10)),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pastki panel ─────────────────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  final Order order;
  final VoidCallback onSend;

  const _BottomPanel({required this.order, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Jami
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Jami',
                  style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
              Text(
                order.totalFormatted,
                style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5),
              ),
            ],
          ),
          const Spacer(),

          if (order.canSendToKitchen)
            ElevatedButton.icon(
              onPressed: onSend,
              icon: const Icon(Icons.send, size: 17),
              label: const Text('Oshpazga',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.4),
              ),
            )
          else if (order.status == 'sent' || order.status == 'ready')
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: order.statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: order.statusColor.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    order.status == 'ready'
                        ? Icons.check_circle
                        : Icons.kitchen,
                    color: order.statusColor,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(order.statusLabel,
                      style: TextStyle(
                          color: order.statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Mahsulot rasmi ────────────────────────────────────────────────────────────

class _ProductImage extends StatelessWidget {
  final String? imagePath;
  final IconData fallbackIcon;
  final bool unavailable;

  const _ProductImage({
    required this.imagePath,
    required this.fallbackIcon,
    required this.unavailable,
  });

  @override
  Widget build(BuildContext context) {
    final url = ApiClient().imageUrl(imagePath);

    if (url.isNotEmpty) {
      return SizedBox.expand(
        child: Image.network(
          url,
          fit: BoxFit.cover,
          color: unavailable ? Colors.white.withOpacity(0.4) : null,
          colorBlendMode: unavailable ? BlendMode.modulate : null,
          errorBuilder: (_, __, ___) => _fallback(),
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(
              color: unavailable
                  ? AppColors.muted.withOpacity(0.08)
                  : AppColors.primary.withOpacity(0.07),
              child: const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    return Container(
      color: unavailable
          ? AppColors.muted.withOpacity(0.08)
          : AppColors.primary.withOpacity(0.1),
      child: Center(
        child: Icon(
          fallbackIcon,
          color: unavailable ? AppColors.muted : AppColors.primary,
          size: unavailable ? 24 : 28,
        ),
      ),
    );
  }
}
