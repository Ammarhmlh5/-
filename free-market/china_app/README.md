# China Shipping App - تطبيق مكتب الصين

## الوصف
تطبيق Flutter لإدارة عمليات الشحن من مكتب الصين مع دعم 3 لغات (العربية، الإنجليزية، الصينية).

## اللغات المدعومة
- 🇺🇸 الإنجليزية (English)
- 🇸🇦 العربية (العربية)
- 🇨🇳 الصينية (中文)

## هيكل المشروع

```
china_app/
├── lib/
│   ├── main.dart                 # نقطة الدخول
│   ├── config/
│   │   └── api_config.dart       # إعدادات API
│   ├── models/
│   │   └── models.dart           # نماذج البيانات
│   ├── providers/
│   │   ├── auth_provider.dart    # مزود المصادقة
│   │   └── locale_provider.dart  # مزود اللغة
│   ├── services/
│   │   └── api_service.dart      # خدمة API
│   ├── screens/
│   │   ├── splash_screen.dart    # شاشة البداية
│   │   ├── login_screen.dart     # تسجيل الدخول
│   │   ├── home_screen.dart      # الشاشة الرئيسية
│   │   ├── settings_screen.dart  # الإعدادات
│   │   ├── shipments/            # الشحنات
│   │   ├── containers/           # الحاويات
│   │   ├── tracking/             # التتبع
│   │   └── customers/            # العملاء
│   ├── utils/
│   │   ├── constants.dart        # الثوابت
│   │   ├── helpers.dart          # دوال مساعدة
│   │   └── localization.dart     # الترجمة
│   └── l10n/
│       ├── app_en.arb            # ملف الإنجليزية
│       ├── app_ar.arb            # ملف العربية
│       └── app_zh.arb            # ملف الصينية
└── pubspec.yaml
```

## التثبيت

```bash
cd china_app
flutter pub get
flutter run
```

## المميزات

### ✅ تسجيل الدخول
- دعم JWT Authentication
- تغيير اللغة

### ✅ لوحة التحكم
- إحصائيات الشحنات
- أحدث الشحنات

### ✅ إدارة الشحنات
- إنشاء شحنة جديدة
- قائمة الشحنات
- تفاصيل الشحنة
- ربط فاتورة ERPNext

### ✅ إدارة الحاويات
- إضافة حاوية
- تتبع الحاوية

### ✅ تتبع الشحنات
- إضافة حدث تتبع
- عرض Timeline

### ✅ الإعدادات
- تغيير اللغة
- تسجيل الخروج

## التقنيات

- Flutter 3.x
- Provider (State Management)
- http (API Calls)
- shared_preferences (Local Storage)
- flutter_localizations (Multi-language)

## API Endpoints المستخدمة

- `POST /api/auth/login`
- `GET /api/shipments`
- `POST /api/shipments`
- `GET /api/shipments/{id}`
- `POST /api/shipments/{id}/invoice`
- `GET /api/containers`
- `POST /api/containers`
- `GET /api/tracking`
- `POST /api/tracking`
- `GET /api/customers`
- `GET /api/ports`

## ERPNext Integration

التكامل مع ERPNext يتضمن:
- إنشاء فاتورة مبيعات
- مزامنة العملاء
- تسجيل المدفوعات

## Steps Next

بعد إكمال China App، يمكن البدء بـ Yemen App.