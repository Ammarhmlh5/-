/**
 * Constants - الثوابت
 */
import 'package:flutter/material.dart';

class AppConstants {
  // Container Types
  static const List<Map<String, String>> containerTypes = [
    {'code': '20GP', 'name': '20ft General Purpose'},
    {'code': '40GP', 'name': '40ft General Purpose'},
    {'code': '40HC', 'name': '40ft High Cube'},
    {'code': '45HC', 'name': '45ft High Cube'},
  ];
  
  // Shipment Status
  static const List<String> shipmentStatuses = [
    'pending',
    'loaded',
    'in_transit',
    'customs',
    'delivered',
    'cancelled',
  ];
  
  // Tracking Event Types
  static const List<String> trackingEventTypes = [
    'departure',
    'in_transit',
    'arrival',
    'customs',
    'delivery',
    'delay',
    'inspection',
  ];
  
  // Payment Methods
  static const List<String> paymentMethods = [
    'cash',
    'bank_transfer',
    'credit_card',
  ];
  
  // Colors
  static const Color primaryColor = Color(0xFF1E88E5);
  static const Color secondaryColor = Color(0xFF43A047);
  static const Color errorColor = Color(0xFFE53935);
  static const Color warningColor = Color(0xFFFFA726);
  static const Color infoColor = Color(0xFF29B6F6);
  
  // Status Colors
  static Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return warningColor;
      case 'loaded':
        return infoColor;
      case 'in_transit':
        return primaryColor;
      case 'customs':
        return Colors.purple;
      case 'delivered':
        return secondaryColor;
      case 'cancelled':
        return errorColor;
      default:
        return Colors.grey;
    }
  }
  
  // Status Names (English)
  static const Map<String, String> statusNames = {
    'pending': 'Pending',
    'loaded': 'Loaded',
    'in_transit': 'In Transit',
    'customs': 'Customs',
    'delivered': 'Delivered',
    'cancelled': 'Cancelled',
  };
  
  // Status Names (Arabic)
  static const Map<String, String> statusNamesAr = {
    'pending': 'قيد الانتظار',
    'loaded': 'محملة',
    'in_transit': 'في الطريق',
    'customs': 'تخليص جمركي',
    'delivered': 'مسلمة',
    'cancelled': 'ملغاة',
  };
  
  // Status Names (Chinese)
  static const Map<String, String> statusNamesZh = {
    'pending': '待处理',
    'loaded': '已装船',
    'in_transit': '运输中',
    'customs': '清关中',
    'delivered': '已交付',
    'cancelled': '已取消',
  };
  
  static String getStatusName(String status, String lang) {
    switch (lang) {
      case 'ar':
        return statusNamesAr[status] ?? status;
      case 'zh':
        return statusNamesZh[status] ?? status;
      default:
        return statusNames[status] ?? status;
    }
  }
}