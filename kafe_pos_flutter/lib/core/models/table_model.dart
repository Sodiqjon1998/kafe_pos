import '../constants/app_colors.dart';
import 'package:flutter/material.dart';

class ActiveOrder {
  final int id;
  final String orderNumber;
  final String status;
  final double total;

  const ActiveOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.total,
  });

  factory ActiveOrder.fromJson(Map<String, dynamic> j) => ActiveOrder(
        id: j['id'],
        orderNumber: j['order_number'] ?? '',
        status: j['status'] ?? 'open',
        total: double.tryParse(j['total'].toString()) ?? 0,
      );
}

class TableModel {
  final int id;
  final int hallId;
  final String name;
  final int capacity;
  final String status; // free | occupied | reserved | bill_requested
  final String shape;  // square | round | rectangle
  final int posX;
  final int posY;
  final ActiveOrder? activeOrder;

  const TableModel({
    required this.id,
    required this.hallId,
    required this.name,
    required this.capacity,
    required this.status,
    required this.shape,
    this.posX = 0,
    this.posY = 0,
    this.activeOrder,
  });

  factory TableModel.fromJson(Map<String, dynamic> j) => TableModel(
        id: j['id'],
        hallId: j['hall_id'] ?? 0,
        name: j['name'] ?? '',
        capacity: j['capacity'] ?? 4,
        status: j['status'] ?? 'free',
        shape: j['shape'] ?? 'square',
        posX: j['pos_x'] ?? 0,
        posY: j['pos_y'] ?? 0,
        activeOrder: j['active_order'] != null
            ? ActiveOrder.fromJson(j['active_order'])
            : null,
      );

  TableModel copyWith({String? status, ActiveOrder? activeOrder}) => TableModel(
        id: id,
        hallId: hallId,
        name: name,
        capacity: capacity,
        status: status ?? this.status,
        shape: shape,
        posX: posX,
        posY: posY,
        activeOrder: activeOrder ?? this.activeOrder,
      );

  Color get statusColor => AppColors.tableStatus(status);

  String get statusLabel {
    const labels = {
      'free':           "Bo'sh",
      'occupied':       'Band',
      'reserved':       'Bron',
      'bill_requested': 'Hisob',
    };
    return labels[status] ?? status;
  }

  bool get isFree => status == 'free';
}

class Hall {
  final int id;
  final String nameUz;
  final String nameRu;
  final List<TableModel> tables;

  const Hall({
    required this.id,
    required this.nameUz,
    required this.nameRu,
    required this.tables,
  });

  factory Hall.fromJson(Map<String, dynamic> j) => Hall(
        id: j['id'],
        nameUz: j['name_uz'] ?? '',
        nameRu: j['name_ru'] ?? '',
        tables: (j['tables'] as List? ?? [])
            .map((t) => TableModel.fromJson(t as Map<String, dynamic>))
            .toList(),
      );

  String get name => nameUz;
}
