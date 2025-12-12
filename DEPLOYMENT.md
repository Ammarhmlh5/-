# دليل النشر / Deployment Guide

## نظرة عامة / Overview

هذا التطبيق يستخدم React + Vite ويتطلب Supabase كقاعدة بيانات. يمكن نشره على أي منصة تدعم تطبيقات React مثل Vercel، Netlify، أو Streamlit Cloud.

This application uses React + Vite and requires Supabase as a database. It can be deployed to any platform that supports React applications such as Vercel, Netlify, or Streamlit Cloud.

## المتطلبات الأساسية / Prerequisites

1. **حساب Supabase / Supabase Account**
   - قم بإنشاء مشروع جديد على [Supabase](https://supabase.com)
   - Create a new project on [Supabase](https://supabase.com)

2. **قاعدة البيانات / Database**
   - قم بتطبيق migrations من مجلد `supabase/migrations/`
   - Apply migrations from `supabase/migrations/` folder

## إعداد المتغيرات البيئية / Environment Variables Setup

### المتغيرات المطلوبة / Required Variables

```bash
VITE_SUPABASE_URL=your_supabase_project_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
```

### كيفية الحصول على القيم / How to Get the Values

1. افتح مشروع Supabase الخاص بك / Open your Supabase project
2. انتقل إلى Settings > API / Navigate to Settings > API
3. انسخ "Project URL" إلى `VITE_SUPABASE_URL`
4. انسخ "anon public" key إلى `VITE_SUPABASE_ANON_KEY`

## النشر على Vercel / Deploy to Vercel

### الطريقة 1: من خلال واجهة Vercel / Method 1: Through Vercel UI

1. قم بتسجيل الدخول إلى [Vercel](https://vercel.com)
2. انقر على "Add New Project"
3. استورد مشروعك من GitHub
4. أضف المتغيرات البيئية في قسم "Environment Variables"
5. انقر على "Deploy"

### الطريقة 2: باستخدام Vercel CLI / Method 2: Using Vercel CLI

```bash
# تثبيت Vercel CLI
npm i -g vercel

# تسجيل الدخول
vercel login

# النشر
vercel

# إضافة المتغيرات البيئية
vercel env add VITE_SUPABASE_URL
vercel env add VITE_SUPABASE_ANON_KEY

# نشر الإنتاج
vercel --prod
```

## النشر على Netlify / Deploy to Netlify

### الطريقة 1: من خلال واجهة Netlify / Method 1: Through Netlify UI

1. قم بتسجيل الدخول إلى [Netlify](https://netlify.com)
2. انقر على "Add new site" > "Import an existing project"
3. اختر مستودع GitHub الخاص بك
4. أضف المتغيرات البيئية في قسم "Environment variables"
5. اضبط Build command على: `npm run build`
6. اضبط Publish directory على: `dist`
7. انقر على "Deploy site"

### الطريقة 2: باستخدام netlify.toml / Method 2: Using netlify.toml

ملف `netlify.toml` موجود بالفعل في المشروع ويحتوي على الإعدادات المطلوبة.

The `netlify.toml` file is already included in the project with the required configuration.

```toml
[build]
  command = "npm run build"
  publish = "dist"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

فقط ارفع التغييرات إلى GitHub وسيتم النشر تلقائياً.

Just push the changes to GitHub and deployment will happen automatically.

## النشر على منصات أخرى / Deploy to Other Platforms

### GitHub Pages

```bash
# تثبيت gh-pages
npm install --save-dev gh-pages

# إضافة سكريبت في package.json
"scripts": {
  "deploy": "npm run build && gh-pages -d dist"
}

# النشر
npm run deploy
```

### Render

1. أنشئ حساب على [Render](https://render.com)
2. انقر على "New Static Site"
3. ربط مستودع GitHub
4. Build Command: `npm run build`
5. Publish Directory: `dist`
6. أضف المتغيرات البيئية

## استكشاف الأخطاء / Troubleshooting

### الخطأ: "Missing Supabase environment variables"

**المشكلة:** لم يتم تعيين متغيرات Supabase البيئية

**الحل:**
1. تأكد من إضافة `VITE_SUPABASE_URL` و `VITE_SUPABASE_ANON_KEY` في إعدادات منصة النشر
2. تأكد من استخدام البادئة `VITE_` لأن Vite يتطلبها
3. أعد نشر التطبيق بعد إضافة المتغيرات

### الشاشة البيضاء / الواجهة لا تظهر

**المشكلة:** التطبيق يعرض صفحة فارغة

**الحل:**
1. تحقق من سجلات المتصفح (F12 > Console)
2. تأكد من أن `index.html` يحتوي على `<script type="module" src="/src/main.tsx"></script>`
3. تأكد من أن جميع التبعيات مثبتة بشكل صحيح
4. تأكد من أن عملية البناء تمت بنجاح

### خطأ 404 عند التنقل

**المشكلة:** الصفحات الفرعية تعطي خطأ 404

**الحل:**
أضف redirects configuration:

**Vercel:** أنشئ `vercel.json`:
```json
{
  "rewrites": [
    { "source": "/(.*)", "destination": "/index.html" }
  ]
}
```

**Netlify:** أنشئ `public/_redirects`:
```
/* /index.html 200
```

## التحقق من النشر / Verify Deployment

بعد النشر، تحقق من:

1. ✅ الصفحة الرئيسية تحمل بشكل صحيح
2. ✅ لا توجد أخطاء في console المتصفح
3. ✅ يمكن تسجيل الدخول / إنشاء حساب
4. ✅ جميع الصفحات يمكن الوصول إليها
5. ✅ الاتصال بـ Supabase يعمل

## الأمان / Security

⚠️ **مهم:** لا تشارك `SUPABASE_SERVICE_ROLE_KEY` أبداً. استخدم فقط `SUPABASE_ANON_KEY` في التطبيق.

⚠️ **Important:** Never share the `SUPABASE_SERVICE_ROLE_KEY`. Only use `SUPABASE_ANON_KEY` in the application.

## الدعم / Support

إذا واجهت مشاكل في النشر:

1. راجع سجلات البناء (Build logs)
2. تحقق من سجلات المتصفح (Browser console)
3. تأكد من تطبيق جميع migrations في Supabase
4. تحقق من أن جميع المتغيرات البيئية صحيحة

---

**ملاحظة:** هذا الدليل يغطي النشر الأساسي. للحصول على تكوينات متقدمة، راجع وثائق المنصة المحددة.

**Note:** This guide covers basic deployment. For advanced configurations, refer to the specific platform documentation.
