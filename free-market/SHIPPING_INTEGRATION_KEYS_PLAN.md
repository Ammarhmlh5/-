# خطة تنفيذ مفاتيح ربط نظام الشحن

## 1. الهدف والنطاق

تحدد هذه الوثيقة متطلبات قاعدة البيانات والخلفية الخاصة بنظام الشحن لإدارة مفاتيح العملاء وربط عمليات الشحن بـ ERPNext. نظام الشحن هو مالك بيانات العملاء والشحنات والفواتير التشغيلية، ولا يسمح لأي عميل أو موظف عميل بالاتصال المباشر بـ ERPNext.

مسار التكامل:

```text
موظف العميل / الشحن
        |
        v
Shipping Backend + Shipping DB
        |
        | SHIPPING_ERP_KEY
        v
OP-03 Integration Gateway
        |
        | Customer credential خادمي
        v
ERPNext
```

## 2. أنواع المفاتيح

| المفتاح | مكان التخزين | الوظيفة |
|---|---|---|
| `SHIPPING_ERP_KEY` | Secret Manager الخاص بالشحن أو OP-03 | تمرير عمليات الشحن إلى بوابة التكامل |
| مفتاح العميل التشغيلي | قاعدة بيانات الشحن، محفوظ كهاش | دخول العميل وتنفيذ عملياته المحلية |
| اعتماد العميل المحاسبي | Secret Manager خادمي | ربط العملية بكيان `Customer` في ERPNext |
| مفتاح موظف العميل | قاعدة بيانات الشحن، محفوظ كهاش | تحديد الموظف ونطاقه في المؤسسة |

المفتاح التشغيلي لا يصل إلى ERPNext. الاعتماد المحاسبي لا يستدعى مباشرة من العميل، بل يختاره الخادم بعد التحقق من المؤسسة والعملية.

## 3. تصميم قاعدة البيانات

### 3.1 `shipping_customers`

```sql
CREATE TABLE shipping_customers (
    customer_id UUID PRIMARY KEY,
    legal_name VARCHAR(200) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    erpnext_customer_id VARCHAR(140) UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

حالات العميل: `PENDING`, `ACTIVE`, `SUSPENDED`, `CLOSED`.

### 3.2 `shipping_employee_keys`

```sql
CREATE TABLE shipping_employee_keys (
    key_id UUID PRIMARY KEY,
    customer_id UUID NOT NULL REFERENCES shipping_customers(customer_id),
    employee_id UUID NOT NULL,
    key_fingerprint CHAR(64) NOT NULL UNIQUE,
    key_hash TEXT NOT NULL,
    scopes JSONB NOT NULL DEFAULT '[]',
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    expires_at TIMESTAMPTZ,
    last_used_at TIMESTAMPTZ,
    created_by UUID,
    revoked_by UUID,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(customer_id, employee_id, status)
);
CREATE INDEX idx_shipping_employee_keys_customer ON shipping_employee_keys(customer_id, status);
```

يجوز للموظف امتلاك مفتاح بديل أثناء التدوير، لكن لا يجوز وجود مفتاحين نشطين إلا ضمن سياسة انتقال موثقة.

### 3.3 `shipping_customer_credentials`

```sql
CREATE TABLE shipping_customer_credentials (
    credential_id UUID PRIMARY KEY,
    customer_id UUID NOT NULL UNIQUE REFERENCES shipping_customers(customer_id),
    channel VARCHAR(20) NOT NULL DEFAULT 'SHIPPING',
    erpnext_entity_type VARCHAR(30) NOT NULL DEFAULT 'Customer',
    erpnext_entity_id VARCHAR(140) NOT NULL UNIQUE,
    secret_ref VARCHAR(300) NOT NULL,
    key_fingerprint CHAR(64) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'PROVISIONING',
    allowed_operations JSONB NOT NULL DEFAULT '[]',
    expires_at TIMESTAMPTZ,
    rotated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

لا تخزن قيمة `api_key` أو `api_secret` في قاعدة الشحن، بل يخزن `secret_ref` فقط.

### 3.4 `shipping_provisioning_jobs`

```sql
CREATE TABLE shipping_provisioning_jobs (
    job_id UUID PRIMARY KEY,
    customer_id UUID NOT NULL REFERENCES shipping_customers(customer_id),
    operation VARCHAR(40) NOT NULL,
    idempotency_key VARCHAR(140) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    attempt_count INT NOT NULL DEFAULT 0,
    last_error_code VARCHAR(80),
    next_attempt_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

تضاف إلى سجل التكامل الحقول `request_id`, `customer_id`, `actor_id`, `actor_key_id`, `channel`, `credential_id`, `operation`, `result`.

## 4. خدمات الخلفية

```text
shipping_service/
├── routes/
│   ├── customers.py
│   ├── employee_keys.py
│   ├── shipments.py
│   ├── invoices.py
│   └── integration_status.py
├── services/
│   ├── key_service.py
│   ├── customer_provisioning.py
│   ├── credential_resolver.py
│   ├── shipment_billing_service.py
│   └── audit_service.py
└── workers/
    ├── customer_provisioner.py
    ├── integration_dispatcher.py
    └── key_rotation_worker.py
```

### 4.1 إنشاء العميل واعتماده

1. ينشئ الشحن العميل بحالة `PENDING`.
2. ينشئ مهمة provisioning idempotent دون أسرار.
3. يستخدم العامل `SHIPPING_ERP_KEY` عبر OP-03 لإنشاء أو مطابقة `Customer`.
4. ينشئ أو يربط اعتماد العميل في Secret Manager.
5. يحفظ `erpnext_customer_id`, `credential_id`, والبصمة فقط.
6. يعلن الحالة `READY/ACTIVE` بعد اكتمال الربط، ويعرض للمستخدم حالة وظيفية فقط.

### 4.2 إنشاء موظفي العميل ومفاتيحهم

ينشئ العميل أو موظف الشحن حساب موظف داخل نظام الشحن، ويولد النظام مفتاحًا عشوائيًا مستقلًا. يحفظ الهاش والبصمة والنطاق ويربط المفتاح بـ `customer_id` و`employee_id`. لا ينشئ النظام حساب ERPNext للموظف.

### 4.3 عملية شحن أو فاتورة

يتحقق الخادم من المفتاح والموظف والعميل وملكية الشحنة أو الفاتورة. العملية المحلية تسجل `actor_key_id`. العملية المحاسبية ترسل حدثًا للخلفية، ثم يستخدم العامل `SHIPPING_ERP_KEY` واعتماد العميل المناسب للوصول إلى OP-03 وERPNext، مع تسجيل المنفذ الحقيقي.

## 5. الواجهات الخلفية

| الطريقة | المسار | الوظيفة |
|---|---|---|
| `POST` | `/api/shipping/customers` | إنشاء عميل وبدء الربط |
| `GET` | `/api/shipping/customers/{id}/integration` | حالة ربط العميل |
| `POST` | `/api/shipping/customer-employees` | إنشاء موظف عميل ومفتاحه |
| `POST` | `/api/shipping/customer-employees/{id}/keys/rotate` | تدوير مفتاح الموظف |
| `POST` | `/api/shipping/shipments` | إنشاء شحنة محلية وتسجيل المنفذ |
| `POST` | `/api/shipping/invoices` | إنشاء فاتورة وإرسالها للخلفية |
| `POST` | `/api/shipping/integration/{job_id}/retry` | إعادة محاولة مصرح بها |

## 6. الخلفية وتجربة المستخدم

تستخدم Celery/Redis لتوفير provisioning، إرسال الفواتير، إعادة المحاولة والتسوية. يستجيب API برقم العملية وحالتها، ولا ينتظر اتصال ERPNext الطويل. الحالات `PENDING`, `PROCESSING`, `READY`, `FAILED`, `DEAD` تكفي للواجهة، بينما تحفظ التفاصيل التقنية في السجلات الإدارية.

## 7. الأمن ومعايير القبول

- لا يقبل الخادم `customer_id` أو `actor_id` من المستخدم كمرجع ملكية موثوق.
- لا يرى العميل أو موظفه `SHIPPING_ERP_KEY` أو اعتماد ERPNext.
- لا يستطيع مفتاح موظف تنفيذ عملية تخص عميلًا آخر.
- تنفذ العمليات المحاسبية عبر قناة الشحن فقط.
- يسجل كل طلب `actor_id` و`actor_key_id` و`customer_id` و`credential_id` والنتيجة.
- تمنع idempotency إنشاء عميل أو فاتورة ERPNext مكررة.
- يوقف تعطيل مفتاح الموظف حركته فورًا، ويوقف تعطيل العميل عملياته المحاسبية.
- ينجح التدوير مع فترة انتقال دون كشف الأسرار.
- تختبر المنظومة أن مفتاح السوق لا ينفذ عمليات الشحن وأن مفتاح الإدارة لا يستخدم في مسار الشحن.

## 8. الاعتماديات والتنفيذ

يعتمد التنفيذ على OP-03، وSecret Manager، وCelery/Redis، وقاعدة PostgreSQL مستقلة للشحن. يجب تنفيذ الاختبارات على العزل والملكية والتكرار والتدقيق قبل ربط تطبيقات العملاء.
