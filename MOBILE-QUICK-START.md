# البدء السريع - تطبيق الهاتف

## خطوات سريعة لتشغيل التطبيق

### 1. تثبيت المتطلبات
```bash
npm install
```

### 2. بناء التطبيق
```bash
npm run build
```

### 3. مزامنة مع المنصات
```bash
npx cap sync
```

---

## فتح التطبيق على Android

### الطريقة الأولى (استخدام Android Studio):
```bash
npm run mobile:android
```
أو:
```bash
npx cap open android
```

ثم من Android Studio:
1. انتظر حتى ينتهي Gradle Sync
2. اختر جهازاً أو محاكياً
3. اضغط Run ▶️

### الطريقة الثانية (تشغيل مباشر):
```bash
npm run mobile:run:android
```
*يتطلب جهاز متصل أو محاكي يعمل*

---

## فتح التطبيق على iOS

### الطريقة الأولى (استخدام Xcode):
```bash
npm run mobile:ios
```
أو:
```bash
npx cap open ios
```

ثم من Xcode:
1. اختر Team من إعدادات المشروع
2. اختر جهازاً أو محاكياً
3. اضغط Run ▶️

### الطريقة الثانية (تشغيل مباشر):
```bash
npm run mobile:run:ios
```
*يتطلب جهاز متصل أو محاكي يعمل*

---

## أوامر npm المفيدة

| الأمر | الوصف |
|-------|--------|
| `npm run mobile:sync` | بناء ومزامنة مع جميع المنصات |
| `npm run mobile:android` | بناء وفتح Android Studio |
| `npm run mobile:ios` | بناء وفتح Xcode |
| `npm run mobile:run:android` | بناء وتشغيل على Android |
| `npm run mobile:run:ios` | بناء وتشغيل على iOS |

---

## بعد كل تعديل في الكود

```bash
# قم بالبناء والمزامنة
npm run mobile:sync

# أو استخدم الأمر المخصص للمنصة
npm run mobile:android
# أو
npm run mobile:ios
```

---

## استكشاف الأخطاء السريع

### التطبيق لا يعمل بعد التحديث؟
```bash
npm run build
npx cap sync
```

### مشكلة في Android؟
```bash
cd android
./gradlew clean
cd ..
npm run mobile:android
```

### مشكلة في iOS؟
```bash
cd ios/App
pod install
cd ../..
npm run mobile:ios
```

---

## الملفات المهمة

- `capacitor.config.ts` - إعدادات Capacitor
- `android/` - مشروع Android الأصلي
- `ios/` - مشروع iOS الأصلي
- `MOBILE-APP-GUIDE.md` - دليل شامل للتطبيق
- `MOBILE-ASSETS-GUIDE.md` - دليل الأيقونات والشاشات

---

## المتطلبات

### لـ Android:
- Node.js 18+
- JDK 17
- Android Studio
- Android SDK

### لـ iOS:
- macOS
- Xcode 14+
- CocoaPods
- Apple Developer Account

---

## روابط مفيدة

- [دليل Capacitor](https://capacitorjs.com/docs)
- [دليل Android](https://developer.android.com)
- [دليل iOS](https://developer.apple.com/documentation)

---

## الدعم

للمزيد من المساعدة، راجع:
- `MOBILE-APP-GUIDE.md` للدليل الشامل
- `MOBILE-ASSETS-GUIDE.md` لإضافة الأيقونات
