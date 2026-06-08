import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color bg      = Color(0xFF0F172A);
  static const Color surface = Color(0xFF1E293B);
  static const Color card    = Color(0xFF263548);
  static const Color border  = Color(0xFF334155);
  static const Color primary = Color(0xFFF97316);
  static const Color text    = Color(0xFFF1F5F9);
  static const Color muted   = Color(0xFF94A3B8);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFEAB308);
  static const Color danger  = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);
  static const Color white   = Color(0xFFFFFFFF);

  // Stol holatlari
  static Color tableStatus(String status) {
    switch (status) {
      case 'free':           return success;
      case 'occupied':       return danger;
      case 'reserved':       return warning;
      case 'bill_requested': return info;
      default:               return muted;
    }
  }

  // Buyurtma holatlari
  static Color orderStatus(String status) {
    switch (status) {
      case 'open':      return info;
      case 'sent':      return warning;
      case 'ready':     return success;
      case 'bill':      return primary;
      case 'paid':      return muted;
      case 'cancelled': return danger;
      default:          return muted;
    }
  }
}
