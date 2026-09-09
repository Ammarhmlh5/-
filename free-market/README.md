# نظام الشحن - Shipping System

نظام متكامل لإدارة الشحن والتتبع بين الصين واليمن (Flask + PostgreSQL + Flutter).

> **البنية المفعلة (Baseline):** خادم Flask واحد في `02_api_architecture` + مخطط قاعدة بيانات واحد في `01_database_setup/create_tables.sql`.
> ملفات `PROJECT_PLAN.md` و `OPERATIONS_PLAN/` و `DATABASE_ERPNEXT_BLUEPRINT.md` تصف معمارية FastAPI المقترحة مستقبلًا (غير مطبقة) وتُعد مرجعية فقط.

## هيكل المشروع

```
نظام الشحن/
├── 01_database_setup/       # قاعدة البيانات (PostgreSQL) - السكيما الرسمية
│   ├── create_tables.sql    # إنشاء الجداول + البيانات الأولية (المصدر الرسمي)
│   ├── docker-compose.yml   # تشغيل PostgreSQL في Docker
│   └── .env.example
├── 02_api_architecture/     # الخادم (Backend) - Flask Application Factory
│   ├── app/
│   │   ├── main.py          # إنشاء التطبيق
│   │   ├── config.py        # الإعدادات
│   │   ├── database.py      # SQLAlchemy
│   │   ├── models/          # نماذج قاعدة البيانات
│   │   └── routes/          # نقاط النهاية API
│   ├── requirements.txt
│   └── .env.example
├── china_app/               # تطبيق الصين (Flutter)
├── yemen_app/               # تطبيق اليمن (Flutter)
├── database/                # واجهة قديمة تعمل السكيما الرسمية (\ir)
├── backend/                 # [مؤرشف] خادم Flask قديم v1 - مفهرس في _archive
├── frontend/                # [مؤرشف] تطبيق قديم - مفهرس في _archive
├── _archive/                # نسخ قديمة محفوظة
└── PROJECT_PLAN.md          # مرجعي (FastAPI مستقبلي)
```

## التشغيل السريع

### 1) قاعدة البيانات

```bash
cd 01_database_setup
copy .env.example .env
docker-compose up -d
```

المستخدم الافتراضي: `admin` / `Admin123!`

### 2) الخادم (Backend)

```bash
cd 02_api_architecture
pip install -r requirements.txt
copy .env.example .env
flask --app app run --host 0.0.0.0 --port 5000
```

الخادم يعمل على: `http://localhost:5000`

### 3) تطبيقا Flutter

```bash
cd china_app   # أو yemen_app
flutter pub get
flutter run
```

## واجهة البرمجة (API) الرئيسية

| الوحدة | المسار |
|--------|--------|
| المصادقة | `/api/auth/login` ، `/api/auth/register` |
| الفروع | `/api/branches` |
| المستودعات | `/api/warehouses` |
| العملاء | `/api/customers` |
| الشحنات | `/api/shipments` ، `/api/shipments/<id>/status` ، `/api/shipments/stats` |
| الحاويات | `/api/containers` ، `/api/containers/types` |
| التتبع | `/api/tracking` ، `/api/tracking/shipment/<id>/timeline` |
| الفواتير | `/api/invoices` |
| المدفوعات | `/api/payments` |
| الموانئ | `/api/ports` |
| شركات الشحن | `/api/shipping-lines` |
| ERPNext | `/api/erpnext/...` |

المصادقة عبر JWT: أضف رأس `Authorization: Bearer <token>` لجميع المسارات المحمية.

## حالات الشحنة

`pending` → `loaded` → `in_transit` → `customs` → `delivered` → `cancelled`

## ملاحظات الهيكلة

- **مصدر الحقيقة لقاعدة البيانات** هو `01_database_setup/create_tables.sql`؛ جدولي `backend/` (خادم v1 القديم) و `frontend/` (التطبيق القديم) مأرشفان في `_archive/`.
- `database/init.sql` واجهة قديمة توجّه إلى السكيما الرسمية للحفاظ على التوافق.
- وثائق `OPERATIONS_PLAN/` و `PROJECT_PLAN.md` تصف توزيع FastAPI على 4 خدمات مستقبلية (منافذ 8000-8003) — ليست مطبقة حاليًا.