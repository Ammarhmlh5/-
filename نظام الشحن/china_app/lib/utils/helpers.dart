/**
 * Helpers - دوال مساعدة
 */
import 'package:flutter/material.dart';
import 'constants.dart';

class Helpers {
  static String formatDate(String? dateStr, {String lang = 'en'}) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
  
  static String formatDateTime(String? dateStr, {String lang = 'en'}) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
  
  static String formatCurrency(double? amount, {String currency = 'USD'}) {
    if (amount == null) return '0.00';
    return '${amount.toStringAsFixed(2)} $currency';
  }
  
  static String formatNumber(double? number) {
    if (number == null) return '0';
    if (number == number.toInt()) {
      return number.toInt().toString();
    }
    return number.toStringAsFixed(2);
  }
  
  static Color getStatusColor(String status) {
    return AppConstants.getStatusColor(status);
  }
  
  static String getStatusName(String status, String lang) {
    return AppConstants.getStatusName(status, lang);
  }
  
  static String getContainerTypeName(String type, String lang) {
    final typeMap = {
      '20GP': {'en': '20ft General Purpose', 'ar': 'حاوية 20 قدم عامة', 'zh': '20尺普通柜'},
      '40GP': {'en': '40ft General Purpose', 'ar': 'حاوية 40 قدم عامة', 'zh': '40尺普通柜'},
      '40HC': {'en': '40ft High Cube', 'ar': 'حاوية 40 قدم عالية', 'zh': '40尺高柜'},
      '45HC': {'en': '45ft High Cube', 'ar': 'حاوية 45 قدم عالية', 'zh': '45尺高柜'},
    };
    return typeMap[type]?[lang] ?? type;
  }
  
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppConstants.errorColor : AppConstants.secondaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }
  
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }
  
  static Future<bool> showConfirmDialog(
    BuildContext context, 
    String title, 
    String message,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}