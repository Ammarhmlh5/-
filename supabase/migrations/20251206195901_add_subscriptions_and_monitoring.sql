/*
  # إضافة جداول الاشتراكات والمراقبة
  
  ## الجداول الجديدة
  
  ### 1. `subscription_plans` - خطط الاشتراك
    - `plan_id` (uuid, primary key) - معرف الخطة
    - `plan_name_ar` (text) - الاسم بالعربية
    - `plan_name_en` (text) - الاسم بالإنجليزية
    - `plan_code` (text) - رمز الخطة
    - `description` (text) - الوصف
    - `plan_type` (text) - نوع الخطة (free, basic, premium, enterprise)
    - `billing_cycle` (text) - دورة الفوترة
    - `price` (numeric) - السعر
    - `currency` (text) - العملة
    - `trial_days` (integer) - أيام التجربة
    - `features` (jsonb) - الميزات
    - `limits` (jsonb) - القيود
    - `is_active` (boolean) - نشط
    - `is_popular` (boolean) - شائع
    - `sort_order` (integer) - ترتيب العرض
    - `created_at` (timestamptz) - تاريخ الإنشاء
    - `updated_at` (timestamptz) - تاريخ التحديث
  
  ### 2. `subscription_features` - ميزات الاشتراكات
    - `feature_id` (uuid, primary key) - معرف الميزة
    - `feature_code` (text) - رمز الميزة
    - `feature_name_ar` (text) - الاسم بالعربية
    - `feature_name_en` (text) - الاسم بالإنجليزية
    - `description` (text) - الوصف
    - `feature_type` (text) - نوع الميزة
    - `is_active` (boolean) - نشط
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 3. `plan_features` - ميزات كل خطة
    - `id` (uuid, primary key) - المعرف
    - `plan_id` (uuid) - معرف الخطة
    - `feature_id` (uuid) - معرف الميزة
    - `is_included` (boolean) - مضمن
    - `limit_value` (numeric) - قيمة الحد
    - `limit_unit` (text) - وحدة الحد
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 4. `user_subscriptions` - اشتراكات المستخدمين
    - `subscription_id` (uuid, primary key) - معرف الاشتراك
    - `user_id` (uuid) - معرف المستخدم
    - `plan_id` (uuid) - معرف الخطة
    - `status` (text) - الحالة
    - `start_date` (timestamptz) - تاريخ البداية
    - `end_date` (timestamptz) - تاريخ الانتهاء
    - `trial_end_date` (timestamptz) - تاريخ انتهاء التجربة
    - `auto_renew` (boolean) - تجديد تلقائي
    - `payment_method` (text) - طريقة الدفع
    - `amount_paid` (numeric) - المبلغ المدفوع
    - `currency` (text) - العملة
    - `billing_cycle` (text) - دورة الفوترة
    - `next_billing_date` (timestamptz) - تاريخ الفوترة القادم
    - `cancelled_at` (timestamptz) - تاريخ الإلغاء
    - `cancellation_reason` (text) - سبب الإلغاء
    - `metadata` (jsonb) - بيانات إضافية
    - `created_at` (timestamptz) - تاريخ الإنشاء
    - `updated_at` (timestamptz) - تاريخ التحديث
  
  ### 5. `subscription_usage` - استهلاك الاشتراك
    - `usage_id` (uuid, primary key) - معرف الاستهلاك
    - `subscription_id` (uuid) - معرف الاشتراك
    - `user_id` (uuid) - معرف المستخدم
    - `feature_code` (text) - رمز الميزة
    - `usage_date` (date) - تاريخ الاستهلاك
    - `usage_count` (integer) - عدد الاستخدام
    - `usage_amount` (numeric) - كمية الاستهلاك
    - `limit_exceeded` (boolean) - تجاوز الحد
    - `metadata` (jsonb) - بيانات إضافية
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 6. `subscription_history` - سجل الاشتراكات
    - `history_id` (uuid, primary key) - معرف السجل
    - `subscription_id` (uuid) - معرف الاشتراك
    - `user_id` (uuid) - معرف المستخدم
    - `plan_id` (uuid) - معرف الخطة
    - `action` (text) - الإجراء
    - `old_status` (text) - الحالة القديمة
    - `new_status` (text) - الحالة الجديدة
    - `changed_by` (uuid) - تم التغيير بواسطة
    - `reason` (text) - السبب
    - `metadata` (jsonb) - بيانات إضافية
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 7. `subscription_invoices` - فواتير الاشتراكات
    - `invoice_id` (uuid, primary key) - معرف الفاتورة
    - `subscription_id` (uuid) - معرف الاشتراك
    - `user_id` (uuid) - معرف المستخدم
    - `invoice_number` (text) - رقم الفاتورة
    - `invoice_date` (date) - تاريخ الفاتورة
    - `due_date` (date) - تاريخ الاستحقاق
    - `amount` (numeric) - المبلغ
    - `tax_amount` (numeric) - مبلغ الضريبة
    - `total_amount` (numeric) - المبلغ الإجمالي
    - `currency` (text) - العملة
    - `status` (text) - الحالة
    - `paid_at` (timestamptz) - تاريخ الدفع
    - `payment_method` (text) - طريقة الدفع
    - `payment_reference` (text) - مرجع الدفع
    - `invoice_url` (text) - رابط الفاتورة
    - `notes` (text) - ملاحظات
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 8. `usage_alerts` - تنبيهات الاستهلاك
    - `alert_id` (uuid, primary key) - معرف التنبيه
    - `user_id` (uuid) - معرف المستخدم
    - `subscription_id` (uuid) - معرف الاشتراك
    - `feature_code` (text) - رمز الميزة
    - `alert_type` (text) - نوع التنبيه
    - `threshold_percentage` (numeric) - نسبة العتبة
    - `current_usage` (numeric) - الاستهلاك الحالي
    - `limit_value` (numeric) - قيمة الحد
    - `triggered_at` (timestamptz) - وقت التفعيل
    - `acknowledged` (boolean) - تم الاطلاع
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ## الأمان
    - تفعيل RLS على جميع الجداول
    - إضافة سياسات للتحكم في الوصول
*/

-- جدول خطط الاشتراك
CREATE TABLE IF NOT EXISTS subscription_plans (
  plan_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_name_ar text NOT NULL,
  plan_name_en text NOT NULL,
  plan_code text UNIQUE NOT NULL,
  description text,
  plan_type text NOT NULL CHECK (plan_type IN ('free', 'basic', 'premium', 'enterprise', 'custom')),
  billing_cycle text CHECK (billing_cycle IN ('monthly', 'quarterly', 'yearly', 'lifetime')),
  price numeric DEFAULT 0 CHECK (price >= 0),
  currency text DEFAULT 'SAR',
  trial_days integer DEFAULT 0,
  features jsonb,
  limits jsonb,
  is_active boolean DEFAULT true,
  is_popular boolean DEFAULT false,
  sort_order integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- جدول ميزات الاشتراكات
CREATE TABLE IF NOT EXISTS subscription_features (
  feature_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  feature_code text UNIQUE NOT NULL,
  feature_name_ar text NOT NULL,
  feature_name_en text NOT NULL,
  description text,
  feature_type text CHECK (feature_type IN ('boolean', 'numeric', 'unlimited', 'custom')),
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- جدول ميزات كل خطة
CREATE TABLE IF NOT EXISTS plan_features (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id uuid NOT NULL REFERENCES subscription_plans(plan_id) ON DELETE CASCADE,
  feature_id uuid NOT NULL REFERENCES subscription_features(feature_id) ON DELETE CASCADE,
  is_included boolean DEFAULT true,
  limit_value numeric,
  limit_unit text,
  created_at timestamptz DEFAULT now(),
  UNIQUE(plan_id, feature_id)
);

-- جدول اشتراكات المستخدمين
CREATE TABLE IF NOT EXISTS user_subscriptions (
  subscription_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  plan_id uuid NOT NULL REFERENCES subscription_plans(plan_id) ON DELETE RESTRICT,
  status text DEFAULT 'active' CHECK (status IN ('trial', 'active', 'past_due', 'cancelled', 'expired', 'suspended')),
  start_date timestamptz DEFAULT now(),
  end_date timestamptz,
  trial_end_date timestamptz,
  auto_renew boolean DEFAULT true,
  payment_method text,
  amount_paid numeric DEFAULT 0,
  currency text DEFAULT 'SAR',
  billing_cycle text,
  next_billing_date timestamptz,
  cancelled_at timestamptz,
  cancellation_reason text,
  metadata jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- جدول استهلاك الاشتراك
CREATE TABLE IF NOT EXISTS subscription_usage (
  usage_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id uuid NOT NULL REFERENCES user_subscriptions(subscription_id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  feature_code text NOT NULL,
  usage_date date DEFAULT CURRENT_DATE,
  usage_count integer DEFAULT 1,
  usage_amount numeric DEFAULT 0,
  limit_exceeded boolean DEFAULT false,
  metadata jsonb,
  created_at timestamptz DEFAULT now()
);

-- جدول سجل الاشتراكات
CREATE TABLE IF NOT EXISTS subscription_history (
  history_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id uuid REFERENCES user_subscriptions(subscription_id) ON DELETE SET NULL,
  user_id uuid NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  plan_id uuid REFERENCES subscription_plans(plan_id) ON DELETE SET NULL,
  action text NOT NULL CHECK (action IN ('created', 'activated', 'renewed', 'upgraded', 'downgraded', 'cancelled', 'expired', 'suspended', 'reactivated')),
  old_status text,
  new_status text,
  changed_by uuid REFERENCES users(user_id),
  reason text,
  metadata jsonb,
  created_at timestamptz DEFAULT now()
);

-- جدول فواتير الاشتراكات
CREATE TABLE IF NOT EXISTS subscription_invoices (
  invoice_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id uuid NOT NULL REFERENCES user_subscriptions(subscription_id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  invoice_number text UNIQUE NOT NULL,
  invoice_date date DEFAULT CURRENT_DATE,
  due_date date,
  amount numeric NOT NULL CHECK (amount >= 0),
  tax_amount numeric DEFAULT 0,
  total_amount numeric GENERATED ALWAYS AS (amount + tax_amount) STORED,
  currency text DEFAULT 'SAR',
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'overdue', 'cancelled', 'refunded')),
  paid_at timestamptz,
  payment_method text,
  payment_reference text,
  invoice_url text,
  notes text,
  created_at timestamptz DEFAULT now()
);

-- جدول تنبيهات الاستهلاك
CREATE TABLE IF NOT EXISTS usage_alerts (
  alert_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  subscription_id uuid NOT NULL REFERENCES user_subscriptions(subscription_id) ON DELETE CASCADE,
  feature_code text NOT NULL,
  alert_type text CHECK (alert_type IN ('approaching_limit', 'limit_reached', 'limit_exceeded')),
  threshold_percentage numeric CHECK (threshold_percentage >= 0 AND threshold_percentage <= 100),
  current_usage numeric,
  limit_value numeric,
  triggered_at timestamptz DEFAULT now(),
  acknowledged boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- إنشاء الفهارس
CREATE INDEX IF NOT EXISTS idx_subscription_plans_type ON subscription_plans(plan_type);
CREATE INDEX IF NOT EXISTS idx_subscription_plans_active ON subscription_plans(is_active);
CREATE INDEX IF NOT EXISTS idx_plan_features_plan ON plan_features(plan_id);
CREATE INDEX IF NOT EXISTS idx_plan_features_feature ON plan_features(feature_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user ON user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_plan ON user_subscriptions(plan_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_status ON user_subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_end_date ON user_subscriptions(end_date);
CREATE INDEX IF NOT EXISTS idx_subscription_usage_subscription ON subscription_usage(subscription_id);
CREATE INDEX IF NOT EXISTS idx_subscription_usage_user ON subscription_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_subscription_usage_date ON subscription_usage(usage_date);
CREATE INDEX IF NOT EXISTS idx_subscription_history_subscription ON subscription_history(subscription_id);
CREATE INDEX IF NOT EXISTS idx_subscription_history_user ON subscription_history(user_id);
CREATE INDEX IF NOT EXISTS idx_subscription_invoices_subscription ON subscription_invoices(subscription_id);
CREATE INDEX IF NOT EXISTS idx_subscription_invoices_user ON subscription_invoices(user_id);
CREATE INDEX IF NOT EXISTS idx_subscription_invoices_status ON subscription_invoices(status);
CREATE INDEX IF NOT EXISTS idx_usage_alerts_user ON usage_alerts(user_id);
CREATE INDEX IF NOT EXISTS idx_usage_alerts_subscription ON usage_alerts(subscription_id);
CREATE INDEX IF NOT EXISTS idx_usage_alerts_acknowledged ON usage_alerts(acknowledged);

-- تفعيل RLS
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_features ENABLE ROW LEVEL SECURITY;
ALTER TABLE plan_features ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE usage_alerts ENABLE ROW LEVEL SECURITY;

-- سياسات subscription_plans (عامة للقراءة)
CREATE POLICY "Anyone can view active subscription plans"
  ON subscription_plans FOR SELECT
  TO authenticated
  USING (is_active = true);

CREATE POLICY "Admins can manage subscription plans"
  ON subscription_plans FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN roles r ON ur.role_id = r.role_id
      WHERE ur.user_id = auth.uid() AND r.role_name = 'admin'
    )
  );

-- سياسات subscription_features (عامة للقراءة)
CREATE POLICY "Anyone can view subscription features"
  ON subscription_features FOR SELECT
  TO authenticated
  USING (is_active = true);

-- سياسات plan_features (عامة للقراءة)
CREATE POLICY "Anyone can view plan features"
  ON plan_features FOR SELECT
  TO authenticated
  USING (true);

-- سياسات user_subscriptions
CREATE POLICY "Users can view own subscriptions"
  ON user_subscriptions FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own subscriptions"
  ON user_subscriptions FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own subscriptions"
  ON user_subscriptions FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- سياسات subscription_usage
CREATE POLICY "Users can view own usage"
  ON subscription_usage FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "System can insert usage"
  ON subscription_usage FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- سياسات subscription_history
CREATE POLICY "Users can view own subscription history"
  ON subscription_history FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- سياسات subscription_invoices
CREATE POLICY "Users can view own invoices"
  ON subscription_invoices FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- سياسات usage_alerts
CREATE POLICY "Users can view own usage alerts"
  ON usage_alerts FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own usage alerts"
  ON usage_alerts FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);