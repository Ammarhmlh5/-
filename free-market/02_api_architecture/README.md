# Task 2: هيكل Python API الأساسي
# API Architecture - نظام الشحن

## الملفات المنشأة

```
02_api_architecture/
├── app/
│   ├── __init__.py
│   ├── main.py              # Flask Application Factory
│   ├── config.py            # إعدادات التطبيق
│   ├── database.py          # SQLAlchemy initialization
│   ├── models/
│   │   └── __init__.py      # جميع نماذج قاعدة البيانات
│   ├── routes/
│   │   ├── __init__.py
│   │   ├── auth.py          # تسجيل الدخول والصلاحيات
│   │   ├── branches.py      # إدارة الفروع
│   │   ├── warehouses.py    # إدارة المستودعات
│   │   ├── customers.py     # إدارة العملاء
│   │   ├── shipments.py     # إدارة الشحنات
│   │   ├── containers.py    # إدارة الحاويات
│   │   ├── tracking.py      # تتبع الحاويات
│   │   ├── invoices.py      # إدارة الفواتير
│   │   ├── payments.py      # إدارة المدفوعات
│   │   ├── erpnext.py       # ربط ERPNext
│   │   ├── ports.py         # الموانئ
│   │   └── shipping_lines.py # شركات الشحن
│   └── utils/
│       └── __init__.py
├── requirements.txt
├── .env.example
└── README.md
```

---

## التثبيت والتشغيل

### 1. تثبيت المتطلبات
```bash
cd 02_api_architecture
pip install -r requirements.txt
```

### 2. إعداد المتغيرات البيئية
```bash
copy .env.example .env
# عدل القيم في .env
```

### 3. تشغيل التطبيق

```bash
flask --app app run --host 0.0.0.0 --port 5000
# أو مباشرة
python -c "from app import create_app; create_app().run(host='0.0.0.0', port=5000)"
```

ملاحظة: عند الإقلاع في وضع التطوير يُنشئ التطبيق الجداول تلقائيًا عبر `db.create_all()`.
للسكيما الكاملة بالبيانات الأولية استخدم `01_database_setup/create_tables.sql`.

### تشغيل عامل التكامل المالي

بعد تشغيل Redis، شغّل عامل Celery في نافذة مستقلة:

```bash
celery -A app.tasks:celery_app worker --beat --loglevel=INFO
```

العامل يقرأ `integration_outbox` ويرسل الأوامر المالية إلى ERPNext مع إعادة المحاولة والتدقيق. لا تستدعي ERPNext مباشرة من تطبيقات العملاء أو من طلبات Flask.

---

## المسارات (Endpoints) الرئيسية

### المصادقة
| Method | Endpoint | الوصف |
|--------|----------|-------|
| POST | `/api/auth/login` | تسجيل دخول |
| POST | `/api/auth/register` | تسجيل مستخدم جديد |
| GET | `/api/auth/me` | المستخدم الحالي |
| PUT | `/api/auth/change-password` | تغيير كلمة المرور |

### الفروع
| Method | Endpoint | الوصف |
|--------|----------|-------|
| GET | `/api/branches` | قائمة الفروع |
| POST | `/api/branches` | إنشاء فرع |
| GET | `/api/branches/{id}` | تفاصيل الفرع |
| PUT | `/api/branches/{id}` | تحديث الفرع |
| DELETE | `/api/branches/{id}` | حذف الفرع |

### العملاء
| Method | Endpoint | الوصف |
|--------|----------|-------|
| GET | `/api/customers` | قائمة العملاء |
| POST | `/api/customers` | إنشاء عميل |
| GET | `/api/customers/{id}` | تفاصيل العميل |
| PUT | `/api/customers/{id}` | تحديث العميل |
| DELETE | `/api/customers/{id}` | حذف العميل |

### الشحنات
| Method | Endpoint | الوصف |
|--------|----------|-------|
| GET | `/api/shipments` | قائمة الشحنات |
| POST | `/api/shipments` | إنشاء شحنة |
| GET | `/api/shipments/{id}` | تفاصيل الشحنة |
| PUT | `/api/shipments/{id}` | تحديث الشحنة |
| PUT | `/api/shipments/{id}/status` | تحديث الحالة |
| POST | `/api/shipments/{id}/invoice` | ربط فاتورة |

### الحاويات
| Method | Endpoint | الوصف |
|--------|----------|-------|
| GET | `/api/containers` | قائمة الحاويات |
| POST | `/api/containers` | إنشاء حاوية |
| GET | `/api/containers/{id}` | تفاصيل الحاوية |
| GET | `/api/containers/{id}/tracking` | تتبع الحاوية |

### التتبع
| Method | Endpoint | الوصف |
|--------|----------|-------|
| GET | `/api/tracking` | قائمة أحداث التتبع |
| POST | `/api/tracking` | إضافة حدث تتبع |
| GET | `/api/tracking/shipment/{id}/timeline` | timeline الشحنة |

### الفواتير
| Method | Endpoint | الوصف |
|--------|----------|-------|
| GET | `/api/invoices` | قائمة الفواتير |
| POST | `/api/invoices` | إنشاء فاتورة |
| GET | `/api/invoices/{id}` | تفاصيل الفاتورة |

### ERPNext
| Method | Endpoint | الوصف |
|--------|----------|-------|
| GET | `/api/erpnext/test-connection` | اختبار الاتصال |
| POST | `/api/erpnext/sync-customer` | مزامنة عميل |
| POST | `/api/erpnext/create-sales-invoice` | إنشاء فاتورة مبيعات |
| POST | `/api/erpnext/create-payment` | إنشاء دفعة |

---

## النماذج (Models)

جميع النماذج موجودة في `app/models/__init__.py`:

- **Branch** - الفروع (مكاتب China, Yemen)
- **Warehouse** - المستودعات
- **Customer** - العملاء
- **Shipment** - الشحنات
- **Container** - الحاويات
- **TrackingEvent** - أحداث التتبع
- **Invoice** - الفواتير
- **Payment** - المدفوعات
- **User** - المستخدمين
- **ShipmentItem** - بنود الشحنات
- **ShippingLine** - شركات الشحن
- **Port** - الموانئ
- **AuditLog** - سجل المراجعة

---

## المصادقة

النظام يستخدم JWT authentication. جميع المسارات المحمية تتطلب token.

### استخدام Token
```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "Admin123!"}'
```

سيعيد الرد:
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": {...}
}
```

### استخدام Token في الطلبات
```bash
curl http://localhost:5000/api/shipments \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc..."
```

---

## الأدوار (Roles)

| الدور | الوصف |
|-------|-------|
| **admin** | كامل الصلاحيات |
| **manager** | إدارة الموظفين والشحنات |
| **operator** | إنشاء وتعديل الشحنات |
| **viewer** | عرض فقط |

---

## الخطوات التالية

بعد إعداد الـ API، انتقل إلى:
- Task 3: نظام المستخدمين والصلاحيات (مكتمل بالفعل في هذا الـ task)
- أو مباشرة لبناء Flutter Apps

---

## ملاحظات

- يتم توليد رقم الشحنة تلقائياً: `SHIP-CHN-2026-0001`
- حالة الشحنة تتغير من: `pending` → `loaded` → `in_transit` → `customs` → `delivered`
- ربط الفاتورة مع ERPNext يتطلب إعداد API Key في .env
- هذا الدليل هو **الخادم الرسمي المعتمد** بارتباطه السكيما الرسمية `01_database_setup/create_tables.sql`