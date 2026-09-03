/**
 * Locale Provider - مزود اللغة
 */
import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  
  Locale get locale => _locale;
  
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
    Locale('zh'),
  ];
  
  static const Map<String, String> localeNames = {
    'en': 'English',
    'ar': 'العربية',
    'zh': '中文',
  };
  
  void setLocale(Locale locale) {
    if (!supportedLocales.contains(locale)) return;
    _locale = locale;
    notifyListeners();
  }
  
  void setLocaleByCode(String code) {
    setLocale(Locale(code));
  }
  
  String getLocaleName(String code) {
    return localeNames[code] ?? code;
  }
}