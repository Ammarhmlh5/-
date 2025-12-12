/*
  # إضافة جداول التنبيهات والجدولة الذكية
  
  ## الجداول الجديدة
  
  ### 1. `alert_rules` - قواعد التنبيهات الذكية
    - `rule_id` (uuid, primary key) - معرف القاعدة
    - `user_id` (uuid) - معرف المستخدم
    - `apiary_id` (uuid) - معرف المنحل
    - `hive_id` (uuid) - معرف الخلية
    - `rule_name` (text) - اسم القاعدة
    - `rule_type` (text) - نوع القاعدة
    - `trigger_condition` (jsonb) - شرط التفعيل
    - `notification_template` (text) - قالب الإشعار
    - `channels` (text[]) - قنوات الإشعار
    - `priority` (text) - الأولوية
    - `is_active` (boolean) - القاعدة نشطة
    - `cooldown_hours` (integer) - فترة الانتظار بين الإشعارات
    - `last_triggered_at` (timestamptz) - آخر تفعيل
    - `trigger_count` (integer) - عدد مرات التفعيل
    - `created_at` (timestamptz) - تاريخ الإنشاء
    - `updated_at` (timestamptz) - تاريخ التحديث
  
  ### 2. `smart_schedules` - الجدولة الذكية للمهام
    - `schedule_id` (uuid, primary key) - معرف الجدولة
    - `user_id` (uuid) - معرف المستخدم
    - `apiary_id` (uuid) - معرف المنحل
    - `hive_id` (uuid) - معرف الخلية
    - `task_type` (text) - نوع المهمة
    - `schedule_name` (text) - اسم الجدولة
    - `description` (text) - الوصف
    - `recurrence_pattern` (jsonb) - نمط التكرار
    - `ai_adjusted` (boolean) - معدلة بواسطة الذكاء الاصطناعي
    - `adjustment_reason` (text) - سبب التعديل
    - `next_occurrence` (timestamptz) - الموعد التالي
    - `last_occurrence` (timestamptz) - الموعد السابق
    - `is_active` (boolean) - الجدولة نشطة
    - `auto_create_task` (boolean) - إنشاء المهمة تلقائياً
    - `created_at` (timestamptz) - تاريخ الإنشاء
    - `updated_at` (timestamptz) - تاريخ التحديث
  
  ### 3. `user_preferences` - تفضيلات المستخدم
    - `preference_id` (uuid, primary key) - معرف التفضيل
    - `user_id` (uuid) - معرف المستخدم
    - `notification_settings` (jsonb) - إعدادات الإشعارات
    - `ai_assistance_level` (text) - مستوى مساعدة الذكاء الاصطناعي
    - `language` (text) - اللغة
    - `timezone` (text) - المنطقة الزمنية
    - `measurement_units` (jsonb) - وحدات القياس
    - `dashboard_layout` (jsonb) - تخطيط لوحة التحكم
    - `alerts_config` (jsonb) - إعدادات التنبيهات
    - `work_schedule` (jsonb) - جدول العمل المفضل
    - `privacy_settings` (jsonb) - إعدادات الخصوصية
    - `created_at` (timestamptz) - تاريخ الإنشاء
    - `updated_at` (timestamptz) - تاريخ التحديث
  
  ### 4. `triggered_alerts` - سجل التنبيهات المُفعلة
    - `triggered_alert_id` (uuid, primary key) - معرف التنبيه المُفعل
    - `rule_id` (uuid) - معرف القاعدة
    - `user_id` (uuid) - معرف المستخدم
    - `hive_id` (uuid) - معرف الخلية
    - `apiary_id` (uuid) - معرف المنحل
    - `alert_data` (jsonb) - بيانات التنبيه
    - `severity` (text) - الخطورة
    - `is_acknowledged` (boolean) - تم الاطلاع
    - `acknowledged_at` (timestamptz) - تاريخ الاطلاع
    - `action_taken` (text) - الإجراء المتخذ
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 5. `schedule_adjustments` - تعديلات الجدولة الذكية
    - `adjustment_id` (uuid, primary key) - معرف التعديل
    - `schedule_id` (uuid) - معرف الجدولة
    - `original_date` (timestamptz) - التاريخ الأصلي
    - `adjusted_date` (timestamptz) - التاريخ المعدل
    - `adjustment_type` (text) - نوع التعديل
    - `reason` (text) - السبب
    - `factors_considered` (jsonb) - العوامل المعتبرة
    - `confidence` (numeric) - مستوى الثقة
    - `user_accepted` (boolean) - قبول المستخدم
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ## الأمان
    - تفعيل RLS على جميع الجداول
    - إضافة سياسات للتحكم في الوصول
*/

-- جدول قواعد التنبيهات الذكية
CREATE TABLE IF NOT EXISTS alert_rules (
  rule_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  apiary_id uuid REFERENCES apiaries(apiary_id) ON DELETE CASCADE,
  hive_id uuid REFERENCES hives(hive_id) ON DELETE CASCADE,
  rule_name text NOT NULL,
  rule_type text NOT NULL CHECK (rule_type IN (
    'health_decline', 'disease_detection', 'low_food_stores',
    'swarming_risk', 'temperature_alert', 'weather_warning',
    'inspection_due', 'feeding_due', 'harvest_ready',
    'queen_age', 'pest_detected', 'custom'
  )),
  trigger_condition jsonb NOT NULL,
  notification_template text,
  channels text[] DEFAULT ARRAY['push', 'in_app']::text[],
  priority text DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  is_active boolean DEFAULT true,
  cooldown_hours integer DEFAULT 24,
  last_triggered_at timestamptz,
  trigger_count integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- جدول الجدولة الذكية
CREATE TABLE IF NOT EXISTS smart_schedules (
  schedule_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  apiary_id uuid REFERENCES apiaries(apiary_id) ON DELETE CASCADE,
  hive_id uuid REFERENCES hives(hive_id) ON DELETE CASCADE,
  task_type text NOT NULL CHECK (task_type IN (
    'inspection', 'feeding', 'harvest', 'treatment',
    'maintenance', 'queen_check', 'pest_control'
  )),
  schedule_name text NOT NULL,
  description text,
  recurrence_pattern jsonb NOT NULL,
  ai_adjusted boolean DEFAULT false,
  adjustment_reason text,
  next_occurrence timestamptz,
  last_occurrence timestamptz,
  is_active boolean DEFAULT true,
  auto_create_task boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- جدول تفضيلات المستخدم
CREATE TABLE IF NOT EXISTS user_preferences (
  preference_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE REFERENCES users(user_id) ON DELETE CASCADE,
  notification_settings jsonb DEFAULT '{
    "push_enabled": true,
    "email_enabled": true,
    "sms_enabled": false,
    "quiet_hours": {"start": "22:00", "end": "07:00"}
  }'::jsonb,
  ai_assistance_level text DEFAULT 'balanced' CHECK (ai_assistance_level IN ('minimal', 'balanced', 'proactive', 'full')),
  language text DEFAULT 'ar',
  timezone text DEFAULT 'Asia/Riyadh',
  measurement_units jsonb DEFAULT '{
    "weight": "kg",
    "temperature": "celsius",
    "distance": "km",
    "volume": "liter"
  }'::jsonb,
  dashboard_layout jsonb,
  alerts_config jsonb DEFAULT '{
    "critical_alerts": true,
    "routine_reminders": true,
    "ai_suggestions": true,
    "weather_alerts": true
  }'::jsonb,
  work_schedule jsonb DEFAULT '{
    "preferred_days": ["sunday", "monday", "tuesday", "wednesday", "thursday"],
    "preferred_hours": {"start": "08:00", "end": "17:00"}
  }'::jsonb,
  privacy_settings jsonb DEFAULT '{
    "share_data_for_ai": true,
    "public_profile": false,
    "show_statistics": true
  }'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- جدول التنبيهات المُفعلة
CREATE TABLE IF NOT EXISTS triggered_alerts (
  triggered_alert_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rule_id uuid REFERENCES alert_rules(rule_id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  hive_id uuid REFERENCES hives(hive_id) ON DELETE CASCADE,
  apiary_id uuid REFERENCES apiaries(apiary_id) ON DELETE CASCADE,
  alert_data jsonb NOT NULL,
  severity text DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  is_acknowledged boolean DEFAULT false,
  acknowledged_at timestamptz,
  action_taken text,
  created_at timestamptz DEFAULT now()
);

-- جدول تعديلات الجدولة
CREATE TABLE IF NOT EXISTS schedule_adjustments (
  adjustment_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  schedule_id uuid NOT NULL REFERENCES smart_schedules(schedule_id) ON DELETE CASCADE,
  original_date timestamptz NOT NULL,
  adjusted_date timestamptz NOT NULL,
  adjustment_type text CHECK (adjustment_type IN ('weather', 'colony_condition', 'resource_availability', 'seasonal', 'user_preference')),
  reason text NOT NULL,
  factors_considered jsonb,
  confidence numeric CHECK (confidence >= 0 AND confidence <= 1),
  user_accepted boolean,
  created_at timestamptz DEFAULT now()
);

-- إنشاء الفهارس
CREATE INDEX IF NOT EXISTS idx_alert_rules_user ON alert_rules(user_id);
CREATE INDEX IF NOT EXISTS idx_alert_rules_apiary ON alert_rules(apiary_id);
CREATE INDEX IF NOT EXISTS idx_alert_rules_hive ON alert_rules(hive_id);
CREATE INDEX IF NOT EXISTS idx_alert_rules_active ON alert_rules(is_active);
CREATE INDEX IF NOT EXISTS idx_smart_schedules_user ON smart_schedules(user_id);
CREATE INDEX IF NOT EXISTS idx_smart_schedules_next_occurrence ON smart_schedules(next_occurrence);
CREATE INDEX IF NOT EXISTS idx_smart_schedules_active ON smart_schedules(is_active);
CREATE INDEX IF NOT EXISTS idx_user_preferences_user ON user_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_triggered_alerts_user ON triggered_alerts(user_id);
CREATE INDEX IF NOT EXISTS idx_triggered_alerts_acknowledged ON triggered_alerts(is_acknowledged);
CREATE INDEX IF NOT EXISTS idx_schedule_adjustments_schedule ON schedule_adjustments(schedule_id);

-- تفعيل RLS
ALTER TABLE alert_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE smart_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE triggered_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE schedule_adjustments ENABLE ROW LEVEL SECURITY;

-- سياسات alert_rules
CREATE POLICY "Users can view own alert rules"
  ON alert_rules FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own alert rules"
  ON alert_rules FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own alert rules"
  ON alert_rules FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own alert rules"
  ON alert_rules FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- سياسات smart_schedules
CREATE POLICY "Users can view own schedules"
  ON smart_schedules FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own schedules"
  ON smart_schedules FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own schedules"
  ON smart_schedules FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own schedules"
  ON smart_schedules FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- سياسات user_preferences
CREATE POLICY "Users can view own preferences"
  ON user_preferences FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own preferences"
  ON user_preferences FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own preferences"
  ON user_preferences FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- سياسات triggered_alerts
CREATE POLICY "Users can view own triggered alerts"
  ON triggered_alerts FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own triggered alerts"
  ON triggered_alerts FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- سياسات schedule_adjustments
CREATE POLICY "Users can view schedule adjustments"
  ON schedule_adjustments FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM smart_schedules
      WHERE smart_schedules.schedule_id = schedule_adjustments.schedule_id
      AND smart_schedules.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update schedule adjustments"
  ON schedule_adjustments FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM smart_schedules
      WHERE smart_schedules.schedule_id = schedule_adjustments.schedule_id
      AND smart_schedules.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM smart_schedules
      WHERE smart_schedules.schedule_id = schedule_adjustments.schedule_id
      AND smart_schedules.user_id = auth.uid()
    )
  );