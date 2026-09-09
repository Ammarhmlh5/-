# خطة تنفيذ مفاتيح الإدارة المركزية

## 1. الهدف والنطاق

تحدد هذه الوثيقة متطلبات النظام الإداري المركزي الذي يدير مفاتيح القنوات الثلاثة ويراقب تكامل ERPNext مع نظام الشحن والسوق. الإدارة هي الجهة الوحيدة التي تدير دورة حياة المفاتيح الرئيسية، لكنها لا تتجاوز حدود الخدمات ولا تتصل بقواعد بيانات الشحن أو السوق مباشرة.

المفاتيح الرئيسية:

- `ADMIN_ERP_KEY`: قناة الإدارة إلى ERPNext للعمليات المركزية.
- `MARKET_ERP_KEY`: قناة السوق إلى ERPNext.
- `SHIPPING_ERP_KEY`: قناة الشحن إلى ERPNext.

يحفظ النظام الإداري الأسرار في Secret Manager، بينما يخزن في قاعدة البيانات المعرفات والبصمات والحالات وسجل التدقيق فقط.

## 2. مسؤوليات النظام الإداري

- إنشاء وتسجيل مفاتيح القنوات الثلاثة.
- تدوير المفتاح الحالي مع دعم فترة انتقالية.
- إبطال أو تعطيل مفتاح فورًا.
- إدارة اعتمادات العملاء والموردين كبيانات وصفية ومراجع أسرار، لا عرض أسرارها.
- مراقبة صحة OP-03، الشحن، السوق، والطوابير.
- متابعة provisioning وإعادة المحاولة والتنبيهات.
- تسجيل كل إجراء إداري ومنفذه وسببه.

لا ينفذ النظام الإداري استعلامات مباشرة على قاعدة بيانات السوق أو الشحن، ولا يرسل `ADMIN_ERP_KEY` إلى أي واجهة أمامية أو خدمة غير مصرح بها.

## 3. تصميم قاعدة البيانات

### 3.1 `integration_channels`

```sql
CREATE TABLE integration_channels (
    channel_id UUID PRIMARY KEY,
    channel_code VARCHAR(20) NOT NULL UNIQUE CHECK (channel_code IN ('ADMIN', 'MARKET', 'SHIPPING')),
    target_system VARCHAR(30) NOT NULL DEFAULT 'ERPNEXT',
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    current_credential_id UUID,
    previous_credential_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### 3.2 `integration_credentials`

```sql
CREATE TABLE integration_credentials (
    credential_id UUID PRIMARY KEY,
    channel_id UUID NOT NULL REFERENCES integration_channels(channel_id),
    owner_type VARCHAR(30) NOT NULL,
    owner_id UUID,
    secret_ref VARCHAR(300) NOT NULL,
    key_fingerprint CHAR(64) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    scopes JSONB NOT NULL DEFAULT '[]',
    environment VARCHAR(20) NOT NULL,
    created_by UUID NOT NULL,
    expires_at TIMESTAMPTZ,
    activated_at TIMESTAMPTZ,
    revoked_by UUID,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_credentials_channel_status ON integration_credentials(channel_id, status);
```

القيمة السرية موجودة في Secret Manager خلف `secret_ref` فقط. يمنع عرضها في API أو التقارير.

### 3.3 `credential_provisioning_jobs`

```sql
CREATE TABLE credential_provisioning_jobs (
    job_id UUID PRIMARY KEY,
    credential_id UUID REFERENCES integration_credentials(credential_id),
    principal_type VARCHAR(30) NOT NULL,
    principal_id UUID NOT NULL,
    operation VARCHAR(40) NOT NULL,
    idempotency_key VARCHAR(140) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    attempt_count INT NOT NULL DEFAULT 0,
    last_error_code VARCHAR(80),
    next_attempt_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ
);
```

### 3.4 `integration_key_events`

```sql
CREATE TABLE integration_key_events (
    event_id UUID PRIMARY KEY,
    credential_id UUID REFERENCES integration_credentials(credential_id),
    key_id UUID,
    channel_code VARCHAR(20) NOT NULL,
    actor_id UUID,
    action VARCHAR(40) NOT NULL,
    request_id UUID NOT NULL,
    result VARCHAR(20) NOT NULL,
    reason_code VARCHAR(80),
    source_ip INET,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

الجدول append-only. لا يسمح بتعديل أو حذف أحداث المفاتيح من واجهات التطبيق.

## 4. خدمات الخلفية

```text
admin_service/
├── routes/
│   ├── integration_channels.py
│   ├── credentials.py
│   ├── provisioning.py
│   ├── health.py
│   └── audit.py
├── services/
│   ├── credential_service.py
│   ├── secret_manager.py
│   ├── channel_guard.py
│   ├── provisioning_service.py
│   ├── rotation_service.py
│   └── audit_service.py
└── workers/
    ├── credential_provisioner.py
    ├── rotation_worker.py
    ├── health_monitor.py
    └── deadletter_notifier.py
```

### 4.1 إنشاء مفتاح قناة

1. يتحقق النظام من أن الطلب صادر من مسؤول نظام مخول.
2. يولد السر عبر Secret Manager أو مزود عشوائية آمن.
3. يحفظ السر في Secret Manager ويعيد السر مرة واحدة فقط إلى قناة إدارية محمية عند الحاجة.
4. يحفظ `secret_ref` والبصمة والنطاق والبيئة في قاعدة الإدارة.
5. يختبر الاتصال عبر OP-03 دون تسجيل السر.
6. يفعّل المفتاح ويسجل الحدث.

### 4.2 تدوير المفتاح

ينشئ النظام مفتاحًا بديلًا، يختبره، ثم يجعله `CURRENT` مع إبقاء القديم `GRACE_PERIOD` لفترة محددة. بعد انتهاء الفترة يبطل القديم. يجب أن تكون العملية قابلة للإعادة دون إنشاء نسخ غير مضبوطة.

### 4.3 إدارة اعتماد العميل أو المورد

لا تنشئ الإدارة حسابات ERPNext لموظفي العملاء أو الموردين. تسجل فقط حالة الاعتماد المحاسبي ومرجع سره وربطه بالمؤسسة والقناة. إنشاء الاعتماد نفسه ينفذه عامل خلفي عند provisioning المؤسسة، وتعرض الإدارة الحالة دون السر.

## 5. واجهات الإدارة

| الطريقة | المسار | الوظيفة |
|---|---|---|
| `POST` | `/api/admin/integration/channels/{channel}/credentials` | إنشاء اعتماد قناة |
| `GET` | `/api/admin/integration/credentials` | عرض البيانات الوصفية والحالة |
| `POST` | `/api/admin/integration/credentials/{id}/rotate` | تدوير اعتماد |
| `POST` | `/api/admin/integration/credentials/{id}/revoke` | إبطال اعتماد |
| `GET` | `/api/admin/integration/provisioning/{job_id}` | حالة provisioning |
| `GET` | `/api/admin/integration/health` | صحة القنوات والخدمات |
| `GET` | `/api/admin/integration/audit` | سجل الأحداث دون أسرار |

## 6. حراس القنوات

يجب أن يفرض OP-03 والحرس المشترك القواعد التالية:

- `ADMIN_ERP_KEY` يقبل مسارات الإدارة فقط.
- `MARKET_ERP_KEY` يقبل عمليات السوق والموردين فقط.
- `SHIPPING_ERP_KEY` يقبل عمليات الشحن والعملاء فقط.
- اعتماد العميل لا يقبل إلا `channel=SHIPPING` و`principal_type=CUSTOMER`.
- اعتماد المورد لا يقبل إلا `channel=MARKET` و`principal_type=SUPPLIER`.
- لا يثق الخادم في `tenant_id` أو `erp_entity_id` القادم من المستخدم دون مطابقة قاعدة البيانات.
- كل طلب يحمل `request_id` و`idempotency_key` وسياق المنفذ.

## 7. المراقبة والاستجابة

يراقب العامل صحة الاعتمادات والقنوات، انتهاء الصلاحية، فشل المصادقة، ارتفاع الرفض، وحالات `DEAD`. ترسل تنبيهات عند استخدام اعتماد ملغى، محاولة قناة خاطئة، فشل تدوير، أو اختلاف ربط ERPNext. لا تتضمن التنبيهات أسرارًا أو حمولة محاسبية كاملة.

## 8. معايير القبول

1. توجد ثلاثة سجلات قنوات مستقلة، ولا يمكن لقناة استخدام اعتماد قناة أخرى.
2. لا توجد قيمة سرية في قاعدة الإدارة أو السجلات أو استجابات API.
3. يمكن إنشاء الاعتماد وتدويره وإبطاله مع تدقيق كامل.
4. يمكن provisioning عميل أو مورد من الخلفية دون تدخل المستخدم ودون إنشاء حسابات موظفيهم في ERPNext.
5. تمنع اختبارات القناة استخدام `ADMIN_ERP_KEY` من السوق أو الشحن.
6. يمنع إبطال الاعتماد العمليات الجديدة فورًا.
7. يظهر في كل حدث `actor_id`, `actor_key_id`, `tenant_id`, `channel`, `credential_id`, والنتيجة عند انطباقها.
8. تستمر عمليات السوق والشحن المحلية عند تعطل لوحة الإدارة، وتبقى العمليات المحاسبية في الطابور حتى عودة OP-03.
9. لا يسمح النظام الإداري بالوصول المباشر إلى قواعد بيانات السوق أو الشحن.

## 9. ترتيب التنفيذ

1. تجهيز Secret Manager وبيئات التطوير والاختبار والإنتاج.
2. إنشاء جداول القنوات والاعتمادات والوظائف والتدقيق.
3. تنفيذ `credential_service` و`channel_guard`.
4. ربط OP-03 بالقنوات الثلاثة.
5. إضافة provisioning للعميل في الشحن وللمورد في السوق.
6. إضافة مفاتيح موظفي العملاء والموردين والتدقيق.
7. تنفيذ التدوير والإبطال والتنبيهات.
8. تشغيل اختبارات العزل والتكرار والفشل قبل التشغيل الفعلي.

هذه مواصفة تخطيطية للتنفيذ، ولا تنشئ مفاتيح حقيقية أو أسرارًا في هذه المرحلة.
