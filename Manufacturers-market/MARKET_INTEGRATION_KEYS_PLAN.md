# خطة تنفيذ مفاتيح ربط السوق

## 1. الهدف والنطاق

تحدد هذه الوثيقة متطلبات قاعدة البيانات والخلفية الخاصة بنظام السوق الحرة لإدارة مفاتيح الموردين وربط عمليات السوق بـ ERPNext. السوق هو مالك بيانات الموردين وعمليات السوق، لكنه لا يتصل مباشرة بقاعدة بيانات ERPNext.

مسار التكامل الإجباري:

```text
موظف المورد / السوق
        |
        v
Market Backend + Market DB
        |
        | MARKET_ERP_KEY
        v
OP-03 Integration Gateway
        |
        | Supplier credential المخزن خادميًا عند الحاجة
        v
ERPNext
```

لا يرسل السوق أي `api_secret` إلى تطبيق المورد أو المتصفح. مفتاح موظف المورد مفتاح تشغيلي محلي، وليس حساب ERPNext.

## 2. أنواع المفاتيح في السوق

| المفتاح | مكان التخزين | الوظيفة |
|---|---|---|
| `MARKET_ERP_KEY` | Secret Manager الخاص بخدمة السوق أو OP-03 | تمرير عمليات السوق إلى بوابة التكامل |
| مفتاح المورد التشغيلي | قاعدة بيانات السوق، محفوظ كهاش | دخول المورد وموظفيه وتنفيذ العمليات المحلية |
| اعتماد المورد المحاسبي | Secret Manager خادمي | تنفيذ العملية المحاسبية باسم المورد المرتبط بكيان `Supplier` |
| مفتاح موظف المورد | قاعدة بيانات السوق، محفوظ كهاش | تحديد الموظف المنفذ وتقييد حركته داخل مؤسسة المورد |

المفتاح التشغيلي للمورد ومفاتيح موظفيه لا تمنح اتصالًا بـ ERPNext. كل عملية محاسبية تستخدم قناة السوق، ثم يختار OP-03 اعتماد المورد المحاسبي المخزن وفق `tenant_id` والعملية.

## 3. تصميم قاعدة البيانات

### 3.1 `market_tenants`

```sql
CREATE TABLE market_tenants (
    tenant_id UUID PRIMARY KEY,
    tenant_type VARCHAR(20) NOT NULL CHECK (tenant_type = 'SUPPLIER'),
    legal_name VARCHAR(200) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    erpnext_supplier_id VARCHAR(140) UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

حالات المؤسسة: `PENDING`, `ACTIVE`, `SUSPENDED`, `CLOSED`. لا تصبح المؤسسة `ACTIVE` للعمليات المحاسبية قبل اكتمال ربط ERPNext والاعتماد المطلوب.

### 3.2 `market_api_keys`

```sql
CREATE TABLE market_api_keys (
    key_id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES market_tenants(tenant_id),
    owner_type VARCHAR(20) NOT NULL CHECK (owner_type IN ('SYSTEM', 'TENANT', 'EMPLOYEE')),
    owner_id UUID NOT NULL,
    key_fingerprint CHAR(64) NOT NULL UNIQUE,
    key_hash TEXT NOT NULL,
    scopes JSONB NOT NULL DEFAULT '[]',
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    expires_at TIMESTAMPTZ,
    last_used_at TIMESTAMPTZ,
    created_by UUID,
    revoked_by UUID,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_market_keys_tenant ON market_api_keys(tenant_id, status);
```

يجب فرض قيد منطقي يمنع مفتاح موظف من الارتباط بأكثر من مؤسسة، ويمنع المفتاح من تنفيذ نطاق خارج مؤسسة مالكه.

### 3.3 `market_erp_credentials`

لا يخزن هذا الجدول السر المكشوف:

```sql
CREATE TABLE market_erp_credentials (
    credential_id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL UNIQUE REFERENCES market_tenants(tenant_id),
    channel VARCHAR(20) NOT NULL DEFAULT 'MARKET',
    erpnext_entity_type VARCHAR(30) NOT NULL DEFAULT 'Supplier',
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

`secret_ref` مرجع إلى Secret Manager فقط. لا يسمح لأي مسار API بإعادة قيمة السر.

### 3.4 `market_provisioning_jobs`

```sql
CREATE TABLE market_provisioning_jobs (
    job_id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES market_tenants(tenant_id),
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

### 3.5 التدقيق والسياق

يجب أن يحتوي سجل التكامل على `request_id`, `tenant_id`, `actor_id`, `actor_key_id`, `channel`, `credential_id`, `operation`, `result`، مع منع الأسرار والحمولة الحساسة غير الضرورية.

## 4. خدمات الخلفية

```text
market_service/
├── routes/
│   ├── suppliers.py
│   ├── supplier_users.py
│   ├── api_keys.py
│   └── integration_status.py
├── services/
│   ├── key_service.py
│   ├── supplier_provisioning.py
│   ├── credential_resolver.py
│   ├── integration_client.py
│   └── audit_service.py
└── workers/
    ├── supplier_provisioner.py
    ├── integration_dispatcher.py
    └── key_rotation_worker.py
```

### 4.1 إنشاء المورد والاعتماد المحاسبي

1. ينشئ السوق سجل المورد بحالة `PENDING`.
2. ينشئ `market_provisioning_job` بمفتاح idempotent.
3. يرسل العامل طلب إنشاء `Supplier` إلى OP-03 عبر `MARKET_ERP_KEY`.
4. بعد نجاح ERPNext، ينشئ Secret Manager السر أو يربط الاعتماد الموجود.
5. يحفظ المرجع والبصمة فقط، ثم يضع المؤسسة والاعتماد في `READY/ACTIVE`.
6. يكرر المحاولة عند فشل الشبكة أو ERPNext، ولا يكرر الإنشاء عند إعادة الحدث.

### 4.2 إنشاء موظف المورد

ينشئ مدير المورد أو موظف السوق حسابًا محليًا للموظف، ثم يولد النظام سرًا عشوائيًا يعرضه مرة واحدة أو يرسل دعوة آمنة. يحفظ النظام الهاش والبصمة والنطاق، ويربط المفتاح بـ `tenant_id` و`employee_id`. لا ينشئ النظام مستخدم ERPNext للموظف.

### 4.3 تنفيذ عملية محاسبية

تتحقق الخدمة من المفتاح والموظف والمؤسسة وملكية السجل، ثم تنشئ حدثًا لا يحتوي سرًا. يستخدم العامل `MARKET_ERP_KEY` و`credential_id` المحاسبي المناسب، ويسجل `actor_id` و`actor_key_id` في التدقيق.

## 5. الواجهات الخلفية

| الطريقة | المسار | الوظيفة |
|---|---|---|
| `POST` | `/api/market/suppliers` | إنشاء مورد وبدء provisioning |
| `GET` | `/api/market/suppliers/{id}/integration` | عرض حالة الربط دون السر |
| `POST` | `/api/market/tenant-users` | إنشاء موظف مورد ومفتاحه التشغيلي |
| `POST` | `/api/market/tenant-users/{id}/keys/rotate` | تدوير مفتاح الموظف |
| `POST` | `/api/market/erp-operations` | إرسال عملية محاسبية عبر الطابور |
| `POST` | `/api/market/integration/{job_id}/retry` | إعادة محاولة مصرح بها |

## 6. الأمن ومعايير القبول

- لا يقبل السوق طلبًا يحدد `tenant_id` أو `actor_id` مخالفًا لسياق المفتاح.
- لا يصل `MARKET_ERP_KEY` أو اعتماد المورد إلى الواجهة الأمامية.
- يمنع مفتاح المورد قراءة أو تعديل بيانات مورد آخر.
- يمنع مفتاح موظف المورد تنفيذ نطاق غير ممنوح له.
- لا ينشئ التكرار كيان `Supplier` أو اعتمادًا ثانيًا.
- يسجل كل طلب محاسبي الموظف ومفتاحه والقناة والاعتماد المستخدم والبنتيجة.
- يؤدي تعطيل مفتاح الموظف إلى منعه فورًا دون إبطال اعتماد المؤسسة تلقائيًا.
- يؤدي تعطيل المورد إلى إيقاف عمليات ERPNext التابعة له.
- تعرض الواجهة `PENDING`, `READY`, `FAILED` فقط، دون تفاصيل سرية.

## 7. الاعتماديات والتنفيذ

يعتمد التنفيذ على OP-03، وSecret Manager، وطابور Celery/Redis، وقاعدة PostgreSQL مستقلة للسوق. يجب اختبار الإنشاء والتكرار والتدوير والعزل قبل ربط واجهات الموردين.
