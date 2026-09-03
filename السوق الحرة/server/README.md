# خادم السوق الحرة (Free Market Server)

خادم API مستقل للمشروع "السوق الحرة" — نظام إدارة الموردين الصينيين والكتالوج والطلبات التجارية، مبني بـ **FastAPI + SQLAlchemy**، ومفصول بالكامل عن قاعدة بيانات ERPNext (كل العمليات المالية تمر عبر قناة التكامل OP-03).

## البنية

```
server/
├── app/
│   ├── main.py              # نقطة الدخول (FastAPI app)
│   ├── config.py            # إعدادات التطبيق
│   ├── database.py          # SQLAlchemy engine + session
│   ├── models.py            # نماذج قاعدة البيانات
│   ├── schemas.py           # نماذج Pydantic
│   ├── security.py          # JWT + الهاش + المفاتيح
│   ├── deps.py              # اعتماديات المصادقة وفحص الملكية
│   ├── services/
│   │   ├── currency.py      # محرك تحويل CNY -> USD
│   │   ├── catalog_service.py
│   │   ├── order_service.py
│   │   ├── tenant_service.py
│   │   ├── key_service.py
│   │   └── audit_service.py
│   └── routes/
│       ├── auth.py
│       ├── suppliers.py
│       ├── tenant_users.py
│       ├── catalog.py
│       ├── orders.py
│       ├── api_keys.py
│       └── integration_status.py
├── tests/test_smoke.py
├── requirements.txt
└── .env.example
```

## التشغيل

```bash
# 1. متطلبات
pip install -r requirements.txt

# 2. إعداد المتغيرات
copy .env.example .env   # عدّل DATABASE_URL وقيم JWT

# 3. التشغيل (تطوير)
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
# أو
python -m app.main
```

التوثيق التفاعلي على `/docs`.

**قاعدة البيانات:** يعمل على PostgreSQL عبر
`postgresql+psycopg://USER:PASS@HOST:PORT/DB`.

## المسارات الرئيسية (تحت `api/market`)

| الوظيفة | المسار |
|---|---|
| تسجيل الدخول | `POST /auth/login` |
| الموردون | `GET/POST /suppliers` ، `POST /suppliers/{id}/provision` |
| موظفو المورد | `POST /tenant-users` |
| الكتالوج | `GET /catalog` (تصفح مع سعر USD محسوب) ، `POST /catalog` ، `PUT /catalog/{id}` ، `PUT /catalog/{id}/stock` ، `POST /catalog/{id}/publish` |
| الطلبات | `POST /orders` ، `POST /orders/{ref}/confirm` ، `POST /orders/{ref}/pay` |
| المفاتيح | `POST /api-keys` ، `POST /api-keys/{id}/rotate` |
| حالة التكامل | `GET /integration/suppliers/{id}` |

## مبادئ الأمان المنفذة

- المورّد الافتراضي: `admin` / `Admin123!` (غيّره فوراً في الإنتاج).
- مفاتيح المورد محفوظة كهاش؛ السر يُعرض مرة واحدة فقط ولا يصل إلى المتصفح.
- لا يُخزَّن سر ERPNext؛ تُحفظ مراجع واعتماديات فقط (`secret_ref`).
- عزل تام: لا يمكن لمفتاح مورد الوصول إلى منتجات مورد آخر.
- السعر النهائي USD يُحسب لحظياً من سعر الصرف، لا يُخزَّن سعر قديم.

## اختبارات

```bash
python -m pytest server/tests -v
```

> خادم أولي قيد التطوير. ربط ERPNext يتم عبر بوابة OP-03 بمفتاح خادمي `MARKET_ERP_KEY`، ولا يُرسل مفتاح ERPNext إلى أي عميل.
