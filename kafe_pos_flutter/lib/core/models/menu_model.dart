class Product {
  final int id;
  final int categoryId;
  final String nameUz;
  final String nameRu;
  final double price;
  final String unitUz;
  final String unitRu;
  final String? image;
  final bool isAvailable;
  final bool isActive;
  final int cookTime;
  final int sortOrder;

  const Product({
    required this.id,
    required this.categoryId,
    required this.nameUz,
    required this.nameRu,
    required this.price,
    this.unitUz = 'dona',
    this.unitRu = 'шт',
    this.image,
    this.isAvailable = true,
    this.isActive = true,
    this.cookTime = 0,
    this.sortOrder = 0,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'],
        categoryId: j['category_id'] ?? 0,
        nameUz: j['name_uz'] ?? '',
        nameRu: j['name_ru'] ?? '',
        price: double.tryParse(j['price'].toString()) ?? 0,
        unitUz: j['unit_uz'] ?? 'dona',
        unitRu: j['unit_ru'] ?? 'шт',
        image: j['image'],
        isAvailable: j['is_available'] ?? true,
        isActive: j['is_active'] ?? true,
        cookTime: j['cook_time'] ?? 0,
        sortOrder: j['sort_order'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'category_id':  categoryId,
        'name_uz':      nameUz,
        'name_ru':      nameRu,
        'price':        price,
        'unit_uz':      unitUz,
        'unit_ru':      unitRu,
        'is_available': isAvailable,
        'is_active':    isActive,
        'cook_time':    cookTime,
        'sort_order':   sortOrder,
      };

  String get name => nameUz;

  String get priceFormatted {
    final n = price.toInt();
    final s = n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]} ',
    );
    return '$s so\'m';
  }
}

class Category {
  final int id;
  final String nameUz;
  final String nameRu;
  final String? icon;
  final String color;
  final bool isActive;
  final int sortOrder;
  final List<Product> products;

  const Category({
    required this.id,
    required this.nameUz,
    required this.nameRu,
    this.icon,
    this.color = '#FF6B35',
    this.isActive = true,
    this.sortOrder = 0,
    this.products = const [],
  });

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'],
        nameUz: j['name_uz'] ?? '',
        nameRu: j['name_ru'] ?? '',
        icon: j['icon'],
        color: j['color'] ?? '#FF6B35',
        isActive: j['is_active'] ?? true,
        sortOrder: j['sort_order'] ?? 0,
        products: (j['products'] as List? ?? [])
            .map((p) => Product.fromJson(p as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'name_uz':    nameUz,
        'name_ru':    nameRu,
        'icon':       icon,
        'color':      color,
        'is_active':  isActive,
        'sort_order': sortOrder,
      };

  String get name => nameUz;
}
