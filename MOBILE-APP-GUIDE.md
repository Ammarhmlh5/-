# دليل تطبيق الهاتف - مام هاني

## نظرة عامة
تطبيق مام هاني هو تطبيق إدارة مناحل شامل يعمل على أجهزة Android و iOS.

## معلومات التطبيق
- **اسم التطبيق**: مام هاني
- **معرف الحزمة**: com.mamhani.beekeeping
- **المنصات المدعومة**: Android, iOS
- **التقنيات المستخدمة**: React, TypeScript, Capacitor, Supabase

---

## المتطلبات الأساسية

### لبناء تطبيق Android:
1. **Node.js** (الإصدار 18 أو أحدث)
2. **Java Development Kit (JDK)** - الإصدار 17
3. **Android Studio** مع Android SDK
4. **Gradle** (يأتي مع Android Studio)

### لبناء تطبيق iOS:
1. **macOS** (مطلوب لبناء تطبيقات iOS)
2. **Xcode** (الإصدار 14 أو أحدث)
3. **CocoaPods** لإدارة التبعيات
4. **حساب Apple Developer** (للنشر على App Store)

---

## خطوات البناء والتطوير

### 1. تثبيت التبعيات
```bash
npm install
```

### 2. بناء التطبيق
```bash
npm run build
```

### 3. مزامنة الملفات مع المنصات
```bash
npx cap sync
```

---

## تشغيل التطبيق على Android

### في وضع التطوير:
```bash
# بناء المشروع
npm run build

# مزامنة مع Android
npx cap sync android

# فتح في Android Studio
npx cap open android
```

**ملاحظة:** في Android Studio:
1. انتظر حتى ينتهي Gradle من المزامنة
2. اختر جهازاً أو محاكياً
3. اضغط على زر "Run" (▶️)

### بناء APK للتوزيع:
1. افتح Android Studio
2. اذهب إلى: `Build > Build Bundle(s) / APK(s) > Build APK(s)`
3. سيتم حفظ الملف في: `android/app/build/outputs/apk/`

### بناء AAB للنشر على Google Play:
1. افتح Android Studio
2. اذهب إلى: `Build > Generate Signed Bundle / APK`
3. اختر "Android App Bundle"
4. أكمل خطوات التوقيع
5. سيتم حفظ الملف في: `android/app/build/outputs/bundle/`

---

## تشغيل التطبيق على iOS

### في وضع التطوير:
```bash
# بناء المشروع
npm run build

# مزامنة مع iOS
npx cap sync ios

# فتح في Xcode
npx cap open ios
```

**ملاحظة:** في Xcode:
1. اختر الفريق (Team) في إعدادات المشروع
2. اختر جهازاً أو محاكياً
3. اضغط على زر "Run" (▶️)

### بناء IPA للتوزيع:
1. افتح Xcode
2. اذهب إلى: `Product > Archive`
3. بعد اكتمال الأرشفة، اختر "Distribute App"
4. اتبع الخطوات حسب طريقة التوزيع المطلوبة

---

## الإضافات (Plugins) المثبتة

### الإضافات الأساسية:
- **@capacitor/app**: إدارة دورة حياة التطبيق
- **@capacitor/splash-screen**: شاشة البداية
- **@capacitor/status-bar**: التحكم في شريط الحالة
- **@capacitor/network**: مراقبة حالة الاتصال بالإنترنت
- **@capacitor/camera**: الوصول إلى الكاميرا (لإضافة صور المناحل)
- **@capacitor/geolocation**: تحديد الموقع الجغرافي

### استخدام الإضافات في الكود:
```typescript
import { Camera } from '@capacitor/camera';
import { Geolocation } from '@capacitor/geolocation';
import { Network } from '@capacitor/network';

// مثال: الحصول على الموقع
const position = await Geolocation.getCurrentPosition();

// مثال: التقاط صورة
const image = await Camera.getPhoto({
  quality: 90,
  allowEditing: false,
  resultType: 'uri'
});
```

---

## أوامر مفيدة

### تحديث الإضافات:
```bash
npm update @capacitor/core @capacitor/cli
npx cap sync
```

### تشغيل على جهاز حقيقي (Android):
```bash
# تأكد من تفعيل USB Debugging على الجهاز
npx cap run android
```

### تشغيل على جهاز حقيقي (iOS):
```bash
# يجب أن يكون الجهاز متصل بـ Mac
npx cap run ios
```

### مسح الكاش وإعادة البناء:
```bash
# Android
cd android
./gradlew clean
cd ..

# iOS
cd ios/App
xcodebuild clean
cd ../..

# إعادة البناء
npm run build
npx cap sync
```

---

## التكوينات الخاصة بالتطبيق

### الألوان والثيم:
- **اللون الأساسي**: #F59E0B (Amber)
- **لون شاشة البداية**: #F59E0B
- **اللغة**: العربية (RTL)

### الأذونات المطلوبة:

#### Android (android/app/src/main/AndroidManifest.xml):
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

#### iOS (ios/App/App/Info.plist):
```xml
<key>NSCameraUsageDescription</key>
<string>نحتاج إلى الوصول للكاميرا لالتقاط صور المناحل</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>نحتاج إلى موقعك لتحديد مواقع المناحل على الخريطة</string>
```

---

## النشر على المتاجر

### Google Play Store:
1. قم بإنشاء حساب Google Play Developer
2. أنشئ تطبيقاً جديداً في Console
3. قم ببناء AAB موقّع
4. ارفع الملف إلى Google Play Console
5. أكمل جميع المعلومات المطلوبة
6. أرسل للمراجعة

### Apple App Store:
1. قم بإنشاء App ID في Apple Developer Portal
2. أنشئ سجل تطبيق في App Store Connect
3. قم ببناء وأرشفة التطبيق في Xcode
4. ارفع التطبيق عبر Xcode أو Transporter
5. أكمل جميع المعلومات المطلوبة
6. أرسل للمراجعة

---

## استكشاف الأخطاء

### المشكلة: التطبيق لا يعمل بعد التحديث
**الحل:**
```bash
npm run build
npx cap sync
npx cap copy
```

### المشكلة: خطأ في Gradle (Android)
**الحل:**
```bash
cd android
./gradlew clean
cd ..
npx cap sync android
```

### المشكلة: خطأ في CocoaPods (iOS)
**الحل:**
```bash
cd ios/App
pod deintegrate
pod install
cd ../..
```

### المشكلة: التطبيق يعرض شاشة بيضاء
**الحل:**
1. تأكد من بناء المشروع: `npm run build`
2. تأكد من المزامنة: `npx cap sync`
3. تحقق من Console للأخطاء

---

## الدعم الفني

للمساعدة والدعم:
- راجع [وثائق Capacitor](https://capacitorjs.com/docs)
- راجع [وثائق Supabase](https://supabase.com/docs)

---

## ملاحظات مهمة

1. **قبل كل build جديد**: قم بتشغيل `npm run build` ثم `npx cap sync`
2. **الاتصال بـ Supabase**: تأكد من تحديث متغيرات البيئة في `.env`
3. **الأيقونات والشاشات**: يمكن تخصيصها في مجلدات `android/app/src/main/res` و `ios/App/App/Assets.xcassets`
4. **التحديثات**: عند تحديث الكود، يجب إعادة البناء والمزامنة
5. **الاختبار**: اختبر دائماً على أجهزة حقيقية قبل النشر

---

## سجل التحديثات

### الإصدار 1.0.0
- إطلاق أول نسخة من التطبيق
- دعم إدارة المناحل والخلايا
- تتبع الفحوصات والإنتاج
- لوحة تحليلات ذكية
- مكتبة النباتات
