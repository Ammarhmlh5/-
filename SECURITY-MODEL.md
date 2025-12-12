# نموذج الأمان وعزل البيانات / Security Model and Data Isolation

## نظرة عامة / Overview

تم تصميم نظام المنصة بنموذج أمان صارم يضمن الفصل التام بين:
1. المسؤولين (إدارة المنصة)
2. المشتركين (مستخدمي المنصة)
3. بيانات كل مشترك عن الآخر

The platform is designed with a strict security model that ensures complete separation between:
1. Administrators (platform management)
2. Subscribers (platform users)
3. Each subscriber's data from others

## البنية الأمنية / Security Architecture

### 1. Row Level Security (RLS)

تم تفعيل RLS على جميع الجداول الحساسة لضمان عزل البيانات على مستوى قاعدة البيانات.

RLS is enabled on all sensitive tables to ensure data isolation at the database level.

#### الجداول الأساسية / Core Tables

- **users**: المستخدمون - كل مستخدم يرى بياناته فقط
- **apiaries**: المناحل - يتم التصفية بناءً على `owner_id`
- **hives**: الخلايا - يتم التصفية من خلال العلاقة مع المنحل
- **inspections**: الفحوصات - يتم التصفية من خلال الخلية → المنحل
- **production**: الإنتاج - يتم التصفية من خلال الخلية → المنحل
- **feeding_logs**: سجلات التغذية - يتم التصفية من خلال الخلية → المنحل

### 2. السياسات الأمنية / Security Policies

#### سياسات المستخدمين العاديين / Regular User Policies

```sql
-- مثال: سياسة عرض المناحل
CREATE POLICY "Users can view own apiaries"
  ON apiaries FOR SELECT
  TO authenticated
  USING (auth.uid() = owner_id);
```

- يمكن للمستخدمين فقط رؤية وتعديل بياناتهم الخاصة
- لا يمكن للمشترك رؤية بيانات مشترك آخر
- جميع العمليات (SELECT, INSERT, UPDATE, DELETE) محمية

#### سياسات المسؤولين / Admin Policies

```sql
-- مثال: سياسة عرض جميع المناحل للمسؤولين
CREATE POLICY "Admins can view all apiaries"
  ON apiaries FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.user_id = auth.uid()
      AND users.role = 'admin'
    )
  );
```

- المسؤولون يمكنهم رؤية جميع البيانات للمراقبة
- المسؤولون لا يمكنهم تعديل بيانات المشتركين مباشرة
- يتم التحقق من دور المستخدم في كل عملية

### 3. نموذج الأدوار / Role Model

#### الأدوار المتاحة / Available Roles

1. **admin**: مسؤول المنصة
   - رؤية جميع البيانات (للمراقبة والتحليل)
   - إدارة إعدادات المنصة
   - إدارة الاشتراكات والفواتير
   - لا يمكن تعديل بيانات المشتركين مباشرة

2. **subscriber**: مشترك في المنصة (الافتراضي)
   - رؤية وتعديل بياناته الخاصة فقط
   - إدارة مناحله وخلاياه
   - عزل تام عن بيانات المشتركين الآخرين

### 4. عزل البيانات الحساسة / Sensitive Data Isolation

#### بيانات الإنتاج / Production Data

بيانات إنتاج المناحل محمية بشكل خاص:
- كل مشترك يرى فقط إنتاج خلاياه
- البيانات الإحصائية العامة لا تكشف معلومات فردية
- المعايير القياسية (benchmarks) مجهولة الهوية

Production data from apiaries is specially protected:
- Each subscriber only sees production from their own hives
- General statistics don't reveal individual information
- Benchmarks are anonymized

```sql
CREATE POLICY "Users can view own production"
  ON production FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM hives
      JOIN apiaries ON apiaries.apiary_id = hives.apiary_id
      WHERE hives.hive_id = production.hive_id
      AND apiaries.owner_id = auth.uid()
    )
  );
```

#### بيانات الموقع / Location Data

- إحداثيات المناحل خاصة بكل مشترك
- لا يمكن لمشترك رؤية مواقع مناحل الآخرين
- بيانات الطقس العامة متاحة للجميع

### 5. التحقق من الملكية / Ownership Verification

جميع العمليات تتحقق من الملكية عبر:

All operations verify ownership through:

1. **التحقق المباشر**: للجداول التي تحتوي على `owner_id` أو `user_id`
2. **التحقق غير المباشر**: للجداول المرتبطة (مثل: خلية → منحل → مالك)

```sql
-- مثال: التحقق غير المباشر للفحوصات
USING (
  EXISTS (
    SELECT 1 FROM hives
    JOIN apiaries ON apiaries.apiary_id = hives.apiary_id
    WHERE hives.hive_id = inspections.hive_id
    AND apiaries.owner_id = auth.uid()
  )
)
```

### 6. الأمان على مستوى التطبيق / Application-Level Security

#### الخدمات (Services)

جميع خدمات التطبيق تعتمد على RLS:
- `apiariesService`: يستخدم `owner_id` للتصفية
- `hivesService`: يعتمد على RLS من خلال العلاقة
- `inspectionsService`: محمي بواسطة RLS
- `productionService`: محمي بواسطة RLS
- `feedingService`: يستخدم JOIN للتحقق من الملكية

#### المصادقة (Authentication)

- استخدام Supabase Auth لإدارة الجلسات
- التحقق من الهوية في كل طلب
- رموز JWT آمنة
- انتهاء الجلسات تلقائياً

### 7. أفضل الممارسات / Best Practices

#### للمطورين / For Developers

1. **استخدام RLS دائماً**: لا تعتمد فقط على التصفية في التطبيق
2. **التحقق من الملكية**: تأكد من التحقق من `owner_id` أو العلاقات
3. **استخدام `auth.uid()`**: للحصول على معرف المستخدم الحالي
4. **تجنب البيانات العامة**: ما لم يكن مطلوباً صراحة
5. **اختبار العزل**: تأكد من عدم تسرب البيانات بين المستخدمين

#### للمسؤولين / For Administrators

1. **مراجعة الأدوار بانتظام**: تأكد من صحة أدوار المستخدمين
2. **مراقبة الوصول**: استخدم السجلات للكشف عن الأنشطة المشبوهة
3. **تحديث السياسات**: راجع سياسات RLS عند إضافة ميزات جديدة
4. **النسخ الاحتياطي**: حافظ على نسخ احتياطية منتظمة

### 8. الجداول المشتركة / Shared Tables

بعض الجداول متاحة للجميع (للقراءة فقط):

Some tables are available to everyone (read-only):

- **flora_library**: مكتبة النباتات
- **seasonal_patterns**: الأنماط الموسمية
- **knowledge_base**: قاعدة المعرفة
- **subscription_plans**: خطط الاشتراك
- **benchmarks**: المعايير القياسية (مجهولة)

### 9. السجلات والمراجعة / Logging and Auditing

- تسجيل جميع عمليات الوصول للبيانات الحساسة
- مراقبة محاولات الوصول غير المصرح به
- سجلات المراجعة للعمليات الإدارية

### 10. الامتثال / Compliance

النظام مصمم للامتثال لمعايير:
- حماية البيانات الشخصية
- الخصوصية والسرية
- أمان المعلومات

The system is designed to comply with:
- Personal data protection standards
- Privacy and confidentiality
- Information security

## الاختبار / Testing

### اختبار العزل / Isolation Testing

لاختبار عزل البيانات:

To test data isolation:

1. أنشئ مستخدمين اثنين مختلفين
2. أضف بيانات لكل مستخدم
3. تأكد من عدم رؤية أحدهما بيانات الآخر
4. اختبر جميع العمليات (قراءة، كتابة، تحديث، حذف)

## الإبلاغ عن المشاكل / Reporting Issues

إذا وجدت مشكلة أمنية:
1. لا تنشرها علناً
2. تواصل مع فريق الأمان مباشرة
3. قدم تفاصيل كاملة عن المشكلة

If you find a security issue:
1. Do not disclose it publicly
2. Contact the security team directly
3. Provide full details about the issue

## المراجع / References

- [Supabase RLS Documentation](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL RLS Documentation](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)
