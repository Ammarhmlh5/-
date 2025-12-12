# تطبيق النحالين - Beekeeping Management App 🐝

## 🎉 تم دمج المشروعين بنجاح / Projects Successfully Merged!

تطبيق شامل ومتقدم لإدارة المناحل يجمع بين أفضل ميزات مشروعي HNY و MAM-HANY. نظام رقمي ذكي متكامل يساعد النحالين المبتدئين والمحترفين مع دعم الهواتف المحمولة والذكاء الاصطناعي.

A comprehensive and advanced beekeeping management platform combining the best features of HNY and MAM-HANY projects. An integrated smart digital system for beginner and professional beekeepers with mobile support and AI capabilities.

> 📖 **للحصول على تفاصيل كاملة عن الدمج، راجع:** [MERGE-DOCUMENTATION.md](./MERGE-DOCUMENTATION.md)
>
> 📖 **For complete merge details, see:** [MERGE-DOCUMENTATION.md](./MERGE-DOCUMENTATION.md)

## ⭐ الميزات الرئيسية / Key Features

### الميزات الأساسية / Core Features
- 🏠 **إدارة المناحل والخلايا** - تتبع تفصيلي لكل خلية ومواصفاتها
- 🔍 **نظام الفحص الذكي** - تقييم بالألوان والنقاط مع توصيات ذكية
- 🍯 **إدارة المنتجات** - تتبع العسل والغذاء الملكي وحبوب اللقاح والملكات
- 📊 **التحليلات والتقارير** - إحصائيات مفصلة وتوقعات ذكية

### الميزات المتقدمة الجديدة / New Advanced Features
- 🤖 **الذكاء الاصطناعي** - محادثة AI وتوصيات ذكية بناءً على البيانات
- 🌸 **مكتبة النباتات المتخصصة** - قاعدة بيانات شاملة للنباتات الرحيقية
- 📱 **تطبيق الهاتف المحمول** - دعم iOS و Android عبر Capacitor
- 🌦️ **نظام الطقس المتقدم** - تنبيهات ذكية وتوقعات طويلة المدى
- 🔒 **نظام أمان متقدم** - Row Level Security (RLS) وعزل البيانات
- 📈 **تحليلات متقدمة** - توقعات الإنتاج والتعلم الآلي
- 🗺️ **نظام الخرائط** - اكتشاف المناحل المجاورة والتواصل
- 💾 **العمل دون اتصال** - مزامنة تلقائية للبيانات

## 🛠️ التقنيات المستخدمة / Technologies Used

### Frontend
- **React 18** مع **TypeScript** - واجهة المستخدم الحديثة
- **Vite** - نظام بناء سريع
- **Tailwind CSS** - تصميم عصري ومرن
- **Lucide React** - أيقونات جميلة

### Backend
- **Supabase** - Backend كامل مع PostgreSQL، المصادقة، والتخزين
- **Row Level Security (RLS)** - أمان على مستوى قاعدة البيانات
- **Edge Functions** - معالجة بدون خادم

### Mobile
- **Capacitor 7.x** - تطبيقات أصلية لـ iOS و Android
- الوصول إلى الكاميرا، الموقع الجغرافي، وحالة الشبكة

### Legacy Support
- **Express.js + Node.js** - API routes (للتوافق)
- **Sequelize ORM** - للملفات القديمة

## 💻 متطلبات النظام / System Requirements

- Node.js >= 18.0.0
- npm >= 9.0.0
- PostgreSQL >= 12 (أو حساب Supabase / or Supabase account)

## 🚀 التثبيت والإعداد / Installation and Setup

### 1. استنساخ المشروع / Clone the Project
```bash
git clone <repository-url>
cd beekeeping-app
```

### 2. تثبيت التبعيات / Install Dependencies
```bash
npm install
```

### 3. إعداد قاعدة البيانات / Database Setup

#### الخيار أ: استخدام Supabase (موصى به / Recommended)
1. إنشاء مشروع جديد على [Supabase](https://supabase.com)
2. تطبيق migrations من مجلد `supabase/migrations/` بالترتيب
3. نسخ `SUPABASE_URL` و `SUPABASE_ANON_KEY`

#### الخيار ب: PostgreSQL محلي / Local PostgreSQL
```bash
# إنشاء قاعدة بيانات PostgreSQL
createdb beekeeping_app

# أو باستخدام psql
psql -U postgres
CREATE DATABASE beekeeping_app;
```

### 4. إعداد متغيرات البيئة / Environment Variables

إنشاء ملف `.env` في المجلد الرئيسي:

```env
# Supabase (إذا كنت تستخدم Supabase / If using Supabase)
VITE_SUPABASE_URL=your_supabase_project_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key

# PostgreSQL المحلي (إذا كنت تستخدم قاعدة بيانات محلية / If using local database)
DB_HOST=localhost
DB_PORT=5432
DB_NAME=beekeeping_app
DB_USER=postgres
DB_PASSWORD=your_password

# JWT
JWT_SECRET=your_super_secret_jwt_key
JWT_EXPIRES_IN=7d

# Server
PORT=3000
NODE_ENV=development
```

### 5. تشغيل التطبيق / Run the Application

#### وضع التطوير / Development Mode
```bash
npm run dev
```
التطبيق سيعمل على `http://localhost:5173`

#### بناء للإنتاج / Build for Production
```bash
npm run build
npm run preview
```

## 🚀 النشر / Deployment

لنشر التطبيق على منصات الاستضافة مثل Vercel، Netlify، أو غيرها:

📖 **راجع دليل النشر الشامل:** [DEPLOYMENT.md](./DEPLOYMENT.md)

For deploying the application to hosting platforms like Vercel, Netlify, or others:

📖 **See the comprehensive deployment guide:** [DEPLOYMENT.md](./DEPLOYMENT.md)

### خطوات سريعة / Quick Steps

1. **قم بإعداد Supabase:**
   - أنشئ مشروع على [Supabase](https://supabase.com)
   - طبّق migrations من مجلد `supabase/migrations/`
   - احصل على `SUPABASE_URL` و `SUPABASE_ANON_KEY`

2. **أضف المتغيرات البيئية على منصة النشر:**
   ```
   VITE_SUPABASE_URL=your_supabase_url
   VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

3. **انشر التطبيق:**
   - Vercel: استخدم ملف `vercel.json` المتضمن
   - Netlify: استخدم ملف `netlify.toml` المتضمن

## 📱 تطبيق الهاتف المحمول / Mobile App

### مزامنة التطبيق / Sync the App
```bash
npm run mobile:sync
```

### Android
```bash
# فتح Android Studio
npm run mobile:android

# أو التشغيل مباشرة
npm run mobile:run:android
```

### iOS (يتطلب macOS / Requires macOS)
```bash
# فتح Xcode
npm run mobile:ios

# أو التشغيل مباشرة
npm run mobile:run:ios
```

📖 **للمزيد من التفاصيل:** [MOBILE-APP-GUIDE.md](./MOBILE-APP-GUIDE.md)

## 🗄️ قاعدة البيانات / Database

### المخطط الشامل / Comprehensive Schema

تحتوي قاعدة البيانات على 10 ملفات migration شاملة:

1. **Base Schema** - المخطط الأساسي مع RLS
2. **Device Management** - إدارة الأجهزة والمزامنة
3. **AI Tables** - جداول الذكاء الاصطناعي
4. **Smart Alerts** - التنبيهات الذكية والجداول الزمنية
5. **Analytics** - التحليلات والتوقعات
6. **Weather System** - نظام الطقس المتقدم
7. **Advanced Weather** - المواقع والطقس المتقدم
8. **Flora Library** - مكتبة النباتات المتخصصة
9. **Subscriptions** - الاشتراكات والمراقبة
10. **Financial Accounting** - المحاسبة المالية للمنصة

### الأمان / Security

النظام يستخدم **Row Level Security (RLS)** لضمان:
- ✅ عزل تام بين بيانات المستخدمين
- ✅ نظام أدوار (admin/subscriber)
- ✅ حماية البيانات الحساسة
- ✅ سياسات أمان صارمة

📖 **للتفاصيل الكاملة:** [SECURITY-MODEL.md](./SECURITY-MODEL.md)

## 🧪 الاختبار / Testing

```bash
# تشغيل الاختبارات
npm test

# فحص أنواع TypeScript
npm run typecheck

# فحص جودة الكود
npm run lint
```

## 📚 الوثائق / Documentation

- [MERGE-DOCUMENTATION.md](./MERGE-DOCUMENTATION.md) - تفاصيل دمج المشروعين
- [SECURITY-MODEL.md](./SECURITY-MODEL.md) - نموذج الأمان وعزل البيانات
- [IMPLEMENTATION-REPORT.md](./IMPLEMENTATION-REPORT.md) - تقرير التنفيذ
- [MOBILE-APP-GUIDE.md](./MOBILE-APP-GUIDE.md) - دليل تطبيق الهاتف المحمول
- [MOBILE-QUICK-START.md](./MOBILE-QUICK-START.md) - دليل البدء السريع للهاتف
```bash
# نسخ ملف البيئة النموذجي
cp .env.example .env

# تحرير الملف وإضافة القيم المناسبة
nano .env
```

#### 5. تشغيل التطبيق

##### وضع التطوير
```bash
npm run dev
```

##### وضع الإنتاج
```bash
npm run build
npm start
```

### الطريقة الثانية: التشغيل السريع

#### استخدام سكريبت التشغيل السريع
```bash
# تشغيل وضع التطوير (سيقوم بتثبيت التبعيات تلقائياً)
node start.js dev

# تشغيل الاختبارات
node start.js test

# عرض جميع الأوامر المتاحة
node start.js help
```

### الطريقة الثالثة: استخدام Docker

#### تشغيل بيئة التطوير
```bash
# تشغيل جميع الخدمات (قاعدة البيانات + التطبيق)
docker-compose --profile dev up -d

# مشاهدة السجلات
docker-compose logs -f app-dev
```

#### تشغيل بيئة الإنتاج
```bash
# تشغيل بيئة الإنتاج مع Nginx
docker-compose --profile prod up -d

# التحقق من حالة الخدمات
docker-compose ps
```

#### أوامر Docker مفيدة
```bash
# إيقاف جميع الخدمات
docker-compose down

# إعادة بناء التطبيق
docker-compose build app-dev

# تنظيف البيانات (احذر: سيحذف جميع البيانات)
docker-compose down -v
```

## 🎯 API Endpoints

### المصادقة / Authentication
- `POST /api/auth/register` - تسجيل مستخدم جديد
- `POST /api/auth/login` - تسجيل الدخول
- `GET /api/auth/me` - الحصول على بيانات المستخدم الحالي
- `PUT /api/auth/profile` - تحديث الملف الشخصي

### المناحل / Apiaries
- `GET /api/apiaries` - قائمة المناحل
- `POST /api/apiaries` - إنشاء منحل جديد
- `GET /api/apiaries/:id` - تفاصيل منحل محدد
- `PUT /api/apiaries/:id` - تحديث منحل
- `DELETE /api/apiaries/:id` - حذف منحل

### الخلايا / Hives
- `GET /api/hives` - قائمة الخلايا
- `POST /api/hives` - إضافة خلية جديدة
- `GET /api/hives/:id` - تفاصيل خلية محددة
- `PUT /api/hives/:id` - تحديث خلية

## 🏗️ هيكل المشروع / Project Structure

```
beekeeping-app/
├── supabase/
│   └── migrations/              # 10 migration files (3600+ lines)
├── src/                         # TypeScript source code
│   ├── pages/                   # Page components (Dashboard, Apiaries, etc.)
│   ├── components/              # Reusable UI components
│   ├── services/                # Business logic and API calls
│   ├── contexts/                # React contexts (Auth, etc.)
│   ├── types/                   # TypeScript type definitions
│   ├── utils/                   # Utility functions
│   └── lib/                     # Library configurations (Supabase, etc.)
├── android/                     # Android mobile app
├── ios/                         # iOS mobile app
├── [Legacy JavaScript files]    # Original JS files (kept for compatibility)
├── tsconfig.json               # TypeScript configuration
├── vite.config.ts              # Vite build configuration
├── capacitor.config.ts         # Capacitor mobile configuration
├── tailwind.config.js          # Tailwind CSS configuration
└── package.json                # Dependencies and scripts
```

## 🌟 الميزات المتقدمة / Advanced Features

### 1. الذكاء الاصطناعي / AI Features
- **محادثة AI** - استشارات ذكية للنحالين
- **توصيات تلقائية** - بناءً على تحليل البيانات
- **التنبؤ بالإنتاج** - باستخدام التعلم الآلي

### 2. مكتبة النباتات / Flora Library
- قاعدة بيانات شاملة للنباتات الرحيقية
- معلومات عن مواسم الإزهار
- فوائد كل نبات للنحل وجودة العسل

### 3. نظام الطقس / Weather System
- تنبيهات الطقس في الوقت الفعلي
- توقعات طويلة المدى
- تأثير الطقس على أنشطة النحل

### 4. التحليلات المتقدمة / Advanced Analytics
- تحليل اتجاهات الإنتاج
- مقارنة الأداء بين الخلايا
- تقارير شاملة ورسوم بيانية

### 5. العمل دون اتصال / Offline Support
- مزامنة تلقائية للبيانات
- العمل بدون إنترنت
- حفظ التغييرات محلياً

## 🔄 الترحيل من JavaScript إلى TypeScript / Migration from JavaScript to TypeScript

المشروع يدعم كلاً من JavaScript و TypeScript:
- ✅ جميع الملفات القديمة محفوظة
- ✅ TypeScript للميزات الجديدة
- ✅ ترحيل تدريجي ممكن
- ✅ توافق كامل بين الإصدارين

The project supports both JavaScript and TypeScript:
- ✅ All legacy files are preserved
- ✅ TypeScript for new features
- ✅ Gradual migration possible
- ✅ Full compatibility between versions

## 📖 التوثيق الإضافي / Additional Documentation

### بالعربية / Arabic
- [دليل دمج المشاريع](./MERGE-DOCUMENTATION.md) - شرح كامل لعملية الدمج
- [نموذج الأمان](./SECURITY-MODEL.md) - تفاصيل الأمان وعزل البيانات
- [تقرير التنفيذ](./IMPLEMENTATION-REPORT.md) - تقرير تفصيلي عن التنفيذ
- [دليل الهاتف المحمول](./MOBILE-APP-GUIDE.md) - كيفية بناء تطبيق الهاتف

### English
- [Merge Documentation](./MERGE-DOCUMENTATION.md) - Complete merge explanation
- [Security Model](./SECURITY-MODEL.md) - Security and data isolation details
- [Implementation Report](./IMPLEMENTATION-REPORT.md) - Detailed implementation report
- [Mobile App Guide](./MOBILE-APP-GUIDE.md) - How to build mobile app

## 🤝 المساهمة / Contributing

نرحب بالمساهمات! يرجى:

1. Fork المشروع / Fork the project
2. إنشاء فرع للميزة الجديدة / Create a feature branch
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. Commit التغييرات / Commit changes
   ```bash
   git commit -m 'Add amazing feature'
   ```
4. Push للفرع / Push to branch
   ```bash
   git push origin feature/amazing-feature
   ```
5. فتح Pull Request / Open a Pull Request

### معايير المساهمة / Contribution Guidelines
- استخدم TypeScript للكود الجديد / Use TypeScript for new code
- اتبع نموذج الأمان / Follow the security model
- اكتب الاختبارات / Write tests
- وثق التغييرات / Document changes

## 📄 الترخيص / License

هذا المشروع مرخص تحت رخصة MIT - راجع ملف [LICENSE](LICENSE) للتفاصيل.

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 الدعم / Support

للحصول على الدعم أو الإبلاغ عن مشاكل / For support or reporting issues:
- فتح Issue في GitHub / Open an Issue on GitHub
- مراجعة الوثائق / Review the documentation
- التواصل عبر البريد الإلكتروني / Contact via email

## 🗺️ خارطة الطريق / Roadmap

### ✅ مكتمل / Completed
- [x] إعداد البنية الأساسية
- [x] نظام المصادقة والتفويض
- [x] إدارة المناحل والخلايا
- [x] دمج المشروعين (HNY + MAM-HANY)
- [x] دعم TypeScript
- [x] دعم الهواتف المحمولة (iOS/Android)
- [x] نظام الأمان المتقدم (RLS)
- [x] قاعدة بيانات شاملة
- [x] مكتبة النباتات
- [x] الذكاء الاصطناعي
- [x] نظام الطقس المتقدم

### 🚧 قيد التطوير / In Progress
- [ ] تحسين واجهة المستخدم
- [ ] إضافة المزيد من اختبارات الوحدة
- [ ] تحسين الأداء

### 📋 مخطط مستقبلي / Future Plans
- [ ] نظام الإشعارات Push
- [ ] دعم لغات متعددة
- [ ] تطبيق سطح المكتب (Electron)
- [ ] تكامل مع أجهزة IoT
- [ ] نظام marketplace للمنتجات

## 📊 الإحصائيات / Statistics

- 📁 **ملفات قاعدة البيانات** / Database Files: 10 migrations (3600+ lines)
- 🔒 **سياسات الأمان** / Security Policies: 20+ RLS policies
- 📱 **منصات مدعومة** / Supported Platforms: Web, iOS, Android
- 🌍 **اللغات** / Languages: العربية، English
- ⚡ **التقنيات** / Technologies: React, TypeScript, Supabase, Capacitor

## 🎉 شكر خاص / Special Thanks

شكراً لجميع المساهمين في مشروعي HNY و MAM-HANY على جهودهم في بناء هذه المنصة الرائعة.

Thanks to all contributors of HNY and MAM-HANY projects for their efforts in building this amazing platform.

---

**النسخة / Version:** 1.0.0 (Merged Edition)  
**تاريخ الدمج / Merge Date:** December 2024  
**الحالة / Status:** ✅ Production Ready

Made with ❤️ for beekeepers everywhere 🐝🍯