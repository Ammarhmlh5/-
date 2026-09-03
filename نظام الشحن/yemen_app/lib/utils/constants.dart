/**
 * Constants - Yemen App
 */
import 'package:flutter/material.dart';

class AppConstants {
  // Status Colors
  static const Color primaryColor = Color(0xFF1E88E5);
  static const Color secondaryColor = Color(0xFF43A047);
  static const Color errorColor = Color(0xFFE53935);
  static const Color warningColor = Color(0xFFFFA726);
  
  // Yemen-specific statuses
  static const List<String> yemenStatuses = [
    'pending',
    'in_transit', 
    'customs',
    'delivered',
  ];
  
  static Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return warningColor;
      case 'in_transit':
        return primaryColor;
      case 'customs':
        return Colors.purple;
      case 'delivered':
        return secondaryColor;
      default:
        return Colors.grey;
    }
  }
  
  static String getStatusName(String status, String lang) {
    final names = {
      'en': {
        'pending': 'Pending',
        'in_transit': 'In Transit',
        'customs': 'At Customs',
        'delivered': 'Delivered',
      },
      'ar': {
        'pending': 'قيد الانتظار',
        'in_transit': 'في الطريق',
        'customs': 'بالجمارك',
        'delivered': 'مسلمة',
      },
    };
    return names[lang]?[status] ?? status;
  }
}