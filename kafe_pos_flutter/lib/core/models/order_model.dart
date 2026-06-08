import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'table_model.dart';

class OrderItem {
  final int id;
  final int orderId;
  final int productId;
  final String productName;
  final double productPrice;
  final int quantity;
  final double total;
  final String status; // pending | cooking | ready | served | cancelled
  final String? note;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.quantity,
    required this.total,
    this.status = 'pending',
    this.note,
  });

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        id: j['id'],
        orderId: j['order_id'] ?? 0,
        productId: j['product_id'] ?? 0,
        productName: j['product_name'] ?? '',
        productPrice: double.tryParse(j['product_price'].toString()) ?? 0,
        quantity: j['quantity'] ?? 1,
        total: double.tryParse(j['total'].toString()) ?? 0,
        status: j['status'] ?? 'pending',
        note: j['note'],
      );

  String get statusLabel {
    const labels = {
      'pending':   'Kutmoqda',
      'cooking':   'Pishmoqda',
      'ready':     'Tayyor',
      'served':    'Berildi',
      'cancelled': 'Bekor',
    };
    return labels[status] ?? status;
  }

  Color get statusColor {
    switch (status) {
      case 'pending':   return AppColors.muted;
      case 'cooking':   return AppColors.warning;
      case 'ready':     return AppColors.success;
      case 'served':    return AppColors.info;
      case 'cancelled': return AppColors.danger;
      default:          return AppColors.muted;
    }
  }

  // total DB da 0 bo'lsa, product_price * quantity orqali hisoblash
  double get effectiveTotal => total > 0 ? total : productPrice * quantity;

  String get totalFormatted {
    final n = effectiveTotal.toInt();
    final s = n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]} ',
    );
    return '$s so\'m';
  }
}

class Order {
  final int id;
  final String orderNumber;
  final int? tableId;
  final int? waiterId;
  final String status; // open | sent | ready | bill | paid | cancelled
  final String type;   // dine_in | takeaway
  final int guestsCount;
  final String? note;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final List<OrderItem> items;
  final TableModel? table;

  const Order({
    required this.id,
    required this.orderNumber,
    this.tableId,
    this.waiterId,
    required this.status,
    this.type = 'dine_in',
    this.guestsCount = 1,
    this.note,
    this.subtotal = 0,
    this.discount = 0,
    this.tax = 0,
    this.total = 0,
    this.items = const [],
    this.table,
  });

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'],
        orderNumber: j['order_number'] ?? '',
        tableId: j['table_id'],
        waiterId: j['waiter_id'],
        status: j['status'] ?? 'open',
        type: j['type'] ?? 'dine_in',
        guestsCount: j['guests_count'] ?? 1,
        note: j['note'],
        subtotal: double.tryParse(j['subtotal'].toString()) ?? 0,
        discount: double.tryParse(j['discount'].toString()) ?? 0,
        tax: double.tryParse(j['tax'].toString()) ?? 0,
        total: double.tryParse(j['total'].toString()) ?? 0,
        items: (j['items'] as List? ?? [])
            .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
            .toList(),
        table: j['table'] != null
            ? TableModel.fromJson(j['table'] as Map<String, dynamic>)
            : null,
      );

  String get statusLabel {
    const labels = {
      'open':      'Ochiq',
      'sent':      'Oshpazda',
      'ready':     'Tayyor',
      'bill':      'Hisob',
      'paid':      "To'landi",
      'cancelled': 'Bekor',
    };
    return labels[status] ?? status;
  }

  Color get statusColor => AppColors.orderStatus(status);

  bool get canSendToKitchen => status == 'open' && items.isNotEmpty;
  bool get canAddItems => status == 'open' || status == 'sent';

  // total DB da 0 bo'lsa, items yig'indisi orqali hisoblash (web orderTotal() kabi)
  double get effectiveTotal {
    if (total > 0) return total;
    return items.fold(0.0, (s, i) => s + i.effectiveTotal);
  }

  String get totalFormatted {
    final n = effectiveTotal.toInt();
    final s = n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]} ',
    );
    return '$s so\'m';
  }
}
