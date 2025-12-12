/*
  # إضافة جداول الحسابات المالية للمنصة
  
  ## الجداول الجديدة
  
  ### 1. `payment_gateways` - بوابات الدفع
    - `gateway_id` (uuid, primary key) - معرف البوابة
    - `gateway_name` (text) - اسم البوابة
    - `gateway_code` (text) - رمز البوابة
    - `provider` (text) - المزود
    - `is_active` (boolean) - نشط
    - `configuration` (jsonb) - الإعدادات
    - `supported_currencies` (text[]) - العملات المدعومة
    - `transaction_fee_percentage` (numeric) - نسبة رسوم المعاملة
    - `transaction_fee_fixed` (numeric) - رسوم ثابتة للمعاملة
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 2. `payment_transactions` - معاملات الدفع
    - `transaction_id` (uuid, primary key) - معرف المعاملة
    - `user_id` (uuid) - معرف المستخدم
    - `subscription_id` (uuid) - معرف الاشتراك
    - `order_id` (uuid) - معرف الطلب
    - `gateway_id` (uuid) - معرف البوابة
    - `transaction_type` (text) - نوع المعاملة
    - `amount` (numeric) - المبلغ
    - `currency` (text) - العملة
    - `status` (text) - الحالة
    - `payment_method` (text) - طريقة الدفع
    - `gateway_transaction_id` (text) - معرف المعاملة لدى البوابة
    - `gateway_response` (jsonb) - استجابة البوابة
    - `processed_at` (timestamptz) - وقت المعالجة
    - `metadata` (jsonb) - بيانات إضافية
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 3. `commission_rates` - نسب العمولة
    - `rate_id` (uuid, primary key) - معرف النسبة
    - `rate_name` (text) - اسم النسبة
    - `category` (text) - الفئة
    - `commission_percentage` (numeric) - نسبة العمولة
    - `commission_fixed` (numeric) - عمولة ثابتة
    - `minimum_amount` (numeric) - الحد الأدنى
    - `maximum_amount` (numeric) - الحد الأقصى
    - `applies_to` (text) - تطبق على
    - `is_active` (boolean) - نشط
    - `effective_from` (date) - سارية من
    - `effective_until` (date) - سارية حتى
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 4. `platform_revenue` - إيرادات المنصة
    - `revenue_id` (uuid, primary key) - معرف الإيراد
    - `revenue_type` (text) - نوع الإيراد
    - `source_type` (text) - نوع المصدر
    - `source_id` (uuid) - معرف المصدر
    - `user_id` (uuid) - معرف المستخدم
    - `transaction_id` (uuid) - معرف المعاملة
    - `gross_amount` (numeric) - المبلغ الإجمالي
    - `commission_amount` (numeric) - مبلغ العمولة
    - `net_amount` (numeric) - المبلغ الصافي
    - `currency` (text) - العملة
    - `revenue_date` (date) - تاريخ الإيراد
    - `status` (text) - الحالة
    - `settled_at` (timestamptz) - وقت التسوية
    - `metadata` (jsonb) - بيانات إضافية
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 5. `refunds` - المرتجعات
    - `refund_id` (uuid, primary key) - معرف الإرجاع
    - `transaction_id` (uuid) - معرف المعاملة الأصلية
    - `user_id` (uuid) - معرف المستخدم
    - `refund_type` (text) - نوع الإرجاع
    - `refund_amount` (numeric) - مبلغ الإرجاع
    - `currency` (text) - العملة
    - `reason` (text) - السبب
    - `status` (text) - الحالة
    - `requested_by` (uuid) - طلب بواسطة
    - `requested_at` (timestamptz) - وقت الطلب
    - `approved_by` (uuid) - وافق بواسطة
    - `approved_at` (timestamptz) - وقت الموافقة
    - `processed_at` (timestamptz) - وقت المعالجة
    - `gateway_refund_id` (text) - معرف الإرجاع لدى البوابة
    - `notes` (text) - ملاحظات
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 6. `platform_expenses` - مصروفات المنصة
    - `expense_id` (uuid, primary key) - معرف المصروف
    - `expense_category` (text) - فئة المصروف
    - `description` (text) - الوصف
    - `amount` (numeric) - المبلغ
    - `currency` (text) - العملة
    - `expense_date` (date) - تاريخ المصروف
    - `payment_method` (text) - طريقة الدفع
    - `vendor` (text) - المورد
    - `receipt_url` (text) - رابط الإيصال
    - `status` (text) - الحالة
    - `approved_by` (uuid) - وافق بواسطة
    - `approved_at` (timestamptz) - وقت الموافقة
    - `notes` (text) - ملاحظات
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 7. `financial_reports` - التقارير المالية
    - `report_id` (uuid, primary key) - معرف التقرير
    - `report_type` (text) - نوع التقرير
    - `report_period` (text) - فترة التقرير
    - `period_start` (date) - بداية الفترة
    - `period_end` (date) - نهاية الفترة
    - `total_revenue` (numeric) - إجمالي الإيرادات
    - `total_expenses` (numeric) - إجمالي المصروفات
    - `net_profit` (numeric) - صافي الربح
    - `total_transactions` (integer) - إجمالي المعاملات
    - `total_refunds` (numeric) - إجمالي المرتجعات
    - `active_subscriptions` (integer) - الاشتراكات النشطة
    - `new_subscriptions` (integer) - اشتراكات جديدة
    - `cancelled_subscriptions` (integer) - اشتراكات ملغاة
    - `currency` (text) - العملة
    - `report_data` (jsonb) - بيانات التقرير
    - `generated_by` (uuid) - أُنشئ بواسطة
    - `generated_at` (timestamptz) - وقت الإنشاء
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 8. `payout_schedules` - جداول الدفعات
    - `payout_id` (uuid, primary key) - معرف الدفعة
    - `user_id` (uuid) - معرف المستخدم
    - `payout_period` (text) - فترة الدفعة
    - `period_start` (date) - بداية الفترة
    - `period_end` (date) - نهاية الفترة
    - `gross_amount` (numeric) - المبلغ الإجمالي
    - `commission_amount` (numeric) - مبلغ العمولة
    - `net_amount` (numeric) - المبلغ الصافي
    - `currency` (text) - العملة
    - `status` (text) - الحالة
    - `scheduled_date` (date) - تاريخ الدفع المجدول
    - `paid_at` (timestamptz) - وقت الدفع
    - `payment_method` (text) - طريقة الدفع
    - `payment_reference` (text) - مرجع الدفع
    - `notes` (text) - ملاحظات
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 9. `tax_settings` - إعدادات الضرائب
    - `tax_id` (uuid, primary key) - معرف الضريبة
    - `tax_name` (text) - اسم الضريبة
    - `tax_code` (text) - رمز الضريبة
    - `tax_rate` (numeric) - نسبة الضريبة
    - `tax_type` (text) - نوع الضريبة
    - `applies_to` (text[]) - تطبق على
    - `location_id` (uuid) - معرف الموقع
    - `is_active` (boolean) - نشط
    - `effective_from` (date) - سارية من
    - `effective_until` (date) - سارية حتى
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ## الأمان
    - تفعيل RLS على جميع الجداول
    - إضافة سياسات للتحكم في الوصول (المشرفين فقط)
*/

-- جدول بوابات الدفع
CREATE TABLE IF NOT EXISTS payment_gateways (
  gateway_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  gateway_name text NOT NULL,
  gateway_code text UNIQUE NOT NULL,
  provider text NOT NULL,
  is_active boolean DEFAULT true,
  configuration jsonb,
  supported_currencies text[] DEFAULT ARRAY['SAR']::text[],
  transaction_fee_percentage numeric DEFAULT 0 CHECK (transaction_fee_percentage >= 0 AND transaction_fee_percentage <= 100),
  transaction_fee_fixed numeric DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- جدول معاملات الدفع
CREATE TABLE IF NOT EXISTS payment_transactions (
  transaction_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  subscription_id uuid REFERENCES user_subscriptions(subscription_id) ON DELETE SET NULL,
  order_id uuid REFERENCES orders(order_id) ON DELETE SET NULL,
  gateway_id uuid REFERENCES payment_gateways(gateway_id) ON DELETE SET NULL,
  transaction_type text CHECK (transaction_type IN ('subscription', 'order', 'refund', 'payout', 'credit', 'debit')),
  amount numeric NOT NULL CHECK (amount >= 0),
  currency text DEFAULT 'SAR',
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded')),
  payment_method text,
  gateway_transaction_id text,
  gateway_response jsonb,
  processed_at timestamptz,
  metadata jsonb,
  created_at timestamptz DEFAULT now()
);

-- جدول نسب العمولة
CREATE TABLE IF NOT EXISTS commission_rates (
  rate_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rate_name text NOT NULL,
  category text NOT NULL CHECK (category IN ('subscription', 'product_sale', 'service', 'marketplace', 'custom')),
  commission_percentage numeric CHECK (commission_percentage >= 0 AND commission_percentage <= 100),
  commission_fixed numeric DEFAULT 0,
  minimum_amount numeric,
  maximum_amount numeric,
  applies_to text CHECK (applies_to IN ('all', 'sellers', 'stores', 'specific_users')),
  is_active boolean DEFAULT true,
  effective_from date DEFAULT CURRENT_DATE,
  effective_until date,
  created_at timestamptz DEFAULT now()
);

-- جدول إيرادات المنصة
CREATE TABLE IF NOT EXISTS platform_revenue (
  revenue_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  revenue_type text CHECK (revenue_type IN ('subscription', 'commission', 'listing_fee', 'advertising', 'premium_feature', 'other')),
  source_type text CHECK (source_type IN ('subscription', 'order', 'store', 'user', 'other')),
  source_id uuid,
  user_id uuid REFERENCES users(user_id) ON DELETE SET NULL,
  transaction_id uuid REFERENCES payment_transactions(transaction_id) ON DELETE SET NULL,
  gross_amount numeric NOT NULL CHECK (gross_amount >= 0),
  commission_amount numeric DEFAULT 0,
  net_amount numeric GENERATED ALWAYS AS (gross_amount - commission_amount) STORED,
  currency text DEFAULT 'SAR',
  revenue_date date DEFAULT CURRENT_DATE,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'settled', 'disputed')),
  settled_at timestamptz,
  metadata jsonb,
  created_at timestamptz DEFAULT now()
);

-- جدول المرتجعات
CREATE TABLE IF NOT EXISTS refunds (
  refund_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid NOT NULL REFERENCES payment_transactions(transaction_id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  refund_type text CHECK (refund_type IN ('full', 'partial', 'chargeback')),
  refund_amount numeric NOT NULL CHECK (refund_amount > 0),
  currency text DEFAULT 'SAR',
  reason text NOT NULL,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'processing', 'completed', 'failed')),
  requested_by uuid REFERENCES users(user_id),
  requested_at timestamptz DEFAULT now(),
  approved_by uuid REFERENCES users(user_id),
  approved_at timestamptz,
  processed_at timestamptz,
  gateway_refund_id text,
  notes text,
  created_at timestamptz DEFAULT now()
);

-- جدول مصروفات المنصة
CREATE TABLE IF NOT EXISTS platform_expenses (
  expense_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  expense_category text CHECK (expense_category IN ('infrastructure', 'marketing', 'salaries', 'software', 'services', 'operations', 'legal', 'other')),
  description text NOT NULL,
  amount numeric NOT NULL CHECK (amount > 0),
  currency text DEFAULT 'SAR',
  expense_date date DEFAULT CURRENT_DATE,
  payment_method text,
  vendor text,
  receipt_url text,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'paid', 'rejected')),
  approved_by uuid REFERENCES users(user_id),
  approved_at timestamptz,
  notes text,
  created_at timestamptz DEFAULT now()
);

-- جدول التقارير المالية
CREATE TABLE IF NOT EXISTS financial_reports (
  report_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  report_type text CHECK (report_type IN ('daily', 'weekly', 'monthly', 'quarterly', 'yearly', 'custom')),
  report_period text NOT NULL,
  period_start date NOT NULL,
  period_end date NOT NULL,
  total_revenue numeric DEFAULT 0,
  total_expenses numeric DEFAULT 0,
  net_profit numeric GENERATED ALWAYS AS (total_revenue - total_expenses) STORED,
  total_transactions integer DEFAULT 0,
  total_refunds numeric DEFAULT 0,
  active_subscriptions integer DEFAULT 0,
  new_subscriptions integer DEFAULT 0,
  cancelled_subscriptions integer DEFAULT 0,
  currency text DEFAULT 'SAR',
  report_data jsonb,
  generated_by uuid REFERENCES users(user_id),
  generated_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

-- جدول جداول الدفعات
CREATE TABLE IF NOT EXISTS payout_schedules (
  payout_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  payout_period text,
  period_start date NOT NULL,
  period_end date NOT NULL,
  gross_amount numeric NOT NULL CHECK (gross_amount >= 0),
  commission_amount numeric DEFAULT 0,
  net_amount numeric GENERATED ALWAYS AS (gross_amount - commission_amount) STORED,
  currency text DEFAULT 'SAR',
  status text DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'processing', 'completed', 'failed', 'cancelled')),
  scheduled_date date,
  paid_at timestamptz,
  payment_method text,
  payment_reference text,
  notes text,
  created_at timestamptz DEFAULT now()
);

-- جدول إعدادات الضرائب
CREATE TABLE IF NOT EXISTS tax_settings (
  tax_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tax_name text NOT NULL,
  tax_code text UNIQUE NOT NULL,
  tax_rate numeric NOT NULL CHECK (tax_rate >= 0 AND tax_rate <= 100),
  tax_type text CHECK (tax_type IN ('vat', 'sales', 'income', 'withholding', 'other')),
  applies_to text[] DEFAULT ARRAY['all']::text[],
  location_id uuid REFERENCES locations(location_id) ON DELETE SET NULL,
  is_active boolean DEFAULT true,
  effective_from date DEFAULT CURRENT_DATE,
  effective_until date,
  created_at timestamptz DEFAULT now()
);

-- إنشاء الفهارس
CREATE INDEX IF NOT EXISTS idx_payment_gateways_active ON payment_gateways(is_active);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_user ON payment_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_subscription ON payment_transactions(subscription_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_order ON payment_transactions(order_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_status ON payment_transactions(status);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_created ON payment_transactions(created_at);
CREATE INDEX IF NOT EXISTS idx_commission_rates_category ON commission_rates(category);
CREATE INDEX IF NOT EXISTS idx_commission_rates_active ON commission_rates(is_active);
CREATE INDEX IF NOT EXISTS idx_platform_revenue_type ON platform_revenue(revenue_type);
CREATE INDEX IF NOT EXISTS idx_platform_revenue_date ON platform_revenue(revenue_date);
CREATE INDEX IF NOT EXISTS idx_platform_revenue_user ON platform_revenue(user_id);
CREATE INDEX IF NOT EXISTS idx_refunds_transaction ON refunds(transaction_id);
CREATE INDEX IF NOT EXISTS idx_refunds_user ON refunds(user_id);
CREATE INDEX IF NOT EXISTS idx_refunds_status ON refunds(status);
CREATE INDEX IF NOT EXISTS idx_platform_expenses_category ON platform_expenses(expense_category);
CREATE INDEX IF NOT EXISTS idx_platform_expenses_date ON platform_expenses(expense_date);
CREATE INDEX IF NOT EXISTS idx_financial_reports_period ON financial_reports(period_start, period_end);
CREATE INDEX IF NOT EXISTS idx_financial_reports_type ON financial_reports(report_type);
CREATE INDEX IF NOT EXISTS idx_payout_schedules_user ON payout_schedules(user_id);
CREATE INDEX IF NOT EXISTS idx_payout_schedules_status ON payout_schedules(status);
CREATE INDEX IF NOT EXISTS idx_tax_settings_active ON tax_settings(is_active);
CREATE INDEX IF NOT EXISTS idx_tax_settings_location ON tax_settings(location_id);

-- تفعيل RLS (كل الجداول المالية محمية - المشرفين فقط)
ALTER TABLE payment_gateways ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE commission_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform_revenue ENABLE ROW LEVEL SECURITY;
ALTER TABLE refunds ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE financial_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE payout_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE tax_settings ENABLE ROW LEVEL SECURITY;

-- سياسات (المشرفين فقط لكل الجداول المالية)
CREATE POLICY "Admins can view payment gateways"
  ON payment_gateways FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN roles r ON ur.role_id = r.role_id
      WHERE ur.user_id = auth.uid() AND r.role_name = 'admin'
    )
  );

CREATE POLICY "Admins can manage payment gateways"
  ON payment_gateways FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN roles r ON ur.role_id = r.role_id
      WHERE ur.user_id = auth.uid() AND r.role_name = 'admin'
    )
  );

-- سياسات payment_transactions
CREATE POLICY "Users can view own transactions"
  ON payment_transactions FOR SELECT
  TO authenticated
  USING (
    auth.uid() = user_id OR
    EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN roles r ON ur.role_id = r.role_id
      WHERE ur.user_id = auth.uid() AND r.role_name = 'admin'
    )
  );

CREATE POLICY "Admins can manage transactions"
  ON payment_transactions FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN roles r ON ur.role_id = r.role_id
      WHERE ur.user_id = auth.uid() AND r.role_name = 'admin'
    )
  );

-- سياسات للجداول الأخرى (المشرفين فقط)
CREATE POLICY "Admins can view commission rates"
  ON commission_rates FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN roles r ON ur.role_id = r.role_id
      WHERE ur.user_id = auth.uid() AND r.role_name = 'admin'
    )
  );

CREATE POLICY "Admins can view platform revenue"
  ON platform_revenue FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN roles r ON ur.role_id = r.role_id
      WHERE ur.user_id = auth.uid() AND r.role_name = 'admin'
    )
  );

-- سياسات refunds
CREATE POLICY "Users can view own refunds"
  ON refunds FOR SELECT
  TO authenticated
  USING (
    auth.uid() = user_id OR
    EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN roles r ON ur.role_id = r.role_id
      WHERE ur.user_id = auth.uid() AND r.role_name = 'admin'
    )
  );

CREATE POLICY "Users can request refunds"
  ON refunds FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- سياسات payout_schedules
CREATE POLICY "Users can view own payouts"
  ON payout_schedules FOR SELECT
  TO authenticated
  USING (
    auth.uid() = user_id OR
    EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN roles r ON ur.role_id = r.role_id
      WHERE ur.user_id = auth.uid() AND r.role_name = 'admin'
    )
  );

-- سياسات tax_settings (عامة للقراءة)
CREATE POLICY "Anyone can view active tax settings"
  ON tax_settings FOR SELECT
  TO authenticated
  USING (is_active = true);