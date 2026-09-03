# Task 1: إعداد قاعدة البيانات
# Database Setup - نظام الشحن الصيني اليمني

## المتطلبات
- Docker و Docker Compose
- أو PostgreSQL 15+ مثبت محلياً

---

## الطريقة الأولى: استخدام Docker Compose (موصى به)

### 1. نسخ ملف البيئة
```bash
cp .env.example .env
# عدل القيم في .env حسب الحاجة
```

### 2. تشغيل PostgreSQL
```bash
docker-compose up -d
```

### 3. التحقق من التشغيل
```bash
docker-compose ps
docker-compose logs -f postgres
```

### 4. الاتصال بقاعدة البيانات
```bash
# من خارج الحاوية
psql -h localhost -U shipping_user -d shipping_system

# من داخل الحاوية
docker exec -it shipping_db psql -U shipping_user -d shipping_system
```

### 5. إيقاف الحاوية
```bash
docker-compose down
# للحذف مع البيانات
docker-compose down -v
```

---

## الطريقة الثانية: تشغيل SQL مباشرة

### 1. إنشاء قاعدة البيانات
```bash
createdb shipping_system -U postgres
```

### 2. تشغيل SQL
```bash
psql -U postgres -d shipping_system -f create_tables.sql
```

---

## الجداول المنشأة

| الجدول | الوصف |
|--------|-------|
| `branches` | الفروع (الصين، اليمن) |
| `warehouses` | المستودعات |
| `customers` | العملاء |
| `shipments` | الشحنات |
| `containers` | الحاويات |
| `tracking_events` | أحداث التتبع |
| `invoices` | الفواتير |
| `payments` | المدفوعات |
| `users` | المستخدمين |
| `shipments_items` | بنود الشحنات |
| `shipping_lines` | شركات الشحن |
| `ports` | الموانئ |
| `audit_logs` | سجل المراجعة |
| `integration_channels` | القنوات الرئيسية: ADMIN وMARKET وSHIPPING |
| `integration_credentials` | بيانات المفاتيح الوصفية والـ scopes بدون تخزين السر |
| `integration_key_events` | سجل إنشاء وتدوير وإبطال مفاتيح الربط |

---

## البيانات الأولية

### قنوات الربط
- `ADMIN`: قناة الإدارة إلى ERPNext
- `MARKET`: قناة نظام السوق إلى ERPNext
- `SHIPPING`: قناة نظام الشحن إلى ERPNext

الأسرار لا تحفظ في قاعدة البيانات. يحفظ الجدول `secret_ref` فقط، إضافة إلى بصمة المفتاح و`secret_hash` للتحقق والتدقيق.

### ترقية قاعدة موجودة

إذا كانت قاعدة البيانات منشأة مسبقًا، شغّل ملف الترقية بدل إعادة إنشاء المخطط:
```bash
psql -U postgres -d shipping_system -f migrations/001_integration_channels.sql
```

### الفروع
- مكتب الصين (CHN)
- مكتب اليمن (YEM)

### شركات الشحن
- COSCO, Maersk, MSC, Evergreen, Yang Ming

### الموانئ
-الصين: Shanghai, Ningbo, Shenzhen, Guangzhou, Qingdao
-اليمن: Aden, Hodeidah, Mukalla

### مستخدم افتراضي
- اسم المستخدم: `admin`
- كلمة المرور: `Admin123!`

---

## الخطوات التالية
بعد إعداد قاعدة البيانات، انتقل إلى `02_api_architecture` (خادم Flask):
```bash
cd ../02_api_architecture
pip install -r requirements.txt
copy .env.example .env
flask --app app run --host 0.0.0.0 --port 5000
```

> هذا الملف (`create_tables.sql`) هو **مصدر الحقيقة الرسمي** للسكيما، وترتبط به جميع النماذج في `02_api_architecture/app/models/`.