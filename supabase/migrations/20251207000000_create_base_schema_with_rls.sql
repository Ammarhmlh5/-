/*
  # إنشاء المخطط الأساسي مع سياسات أمان صارمة
  
  ## الجداول الأساسية
  
  ### 1. `users` - المستخدمون
    - `user_id` (uuid, primary key) - معرف المستخدم
    - `email` (text) - البريد الإلكتروني
    - `full_name` (text) - الاسم الكامل
    - `phone` (text) - رقم الهاتف
    - `role` (text) - دور المستخدم (admin, subscriber)
    - `created_at` (timestamptz) - تاريخ الإنشاء
    - `updated_at` (timestamptz) - تاريخ التحديث
  
  ### 2. `apiaries` - المناحل
    - `apiary_id` (uuid, primary key) - معرف المنحل
    - `owner_id` (uuid) - معرف المالك
    - `name` (text) - اسم المنحل
    - `description` (text) - وصف المنحل
    - `type` (text) - نوع المنحل (fixed, mobile)
    - `latitude` (numeric) - خط العرض
    - `longitude` (numeric) - خط الطول
    - `altitude` (numeric) - الارتفاع
    - `region` (text) - المنطقة
    - `hive_count` (integer) - عدد الخلايا
    - `created_at` (timestamptz) - تاريخ الإنشاء
    - `updated_at` (timestamptz) - تاريخ التحديث
  
  ### 3. `hives` - الخلايا
    - `hive_id` (uuid, primary key) - معرف الخلية
    - `apiary_id` (uuid) - معرف المنحل
    - `hive_number` (text) - رقم الخلية
    - `hive_type` (text) - نوع الخلية
    - `queen_age_months` (integer) - عمر الملكة بالشهور
    - `frame_count` (integer) - عدد الإطارات
    - `status` (text) - حالة الخلية
    - `health_status` (text) - حالة الصحة
    - `last_inspection_date` (date) - تاريخ آخر فحص
    - `notes` (text) - ملاحظات
    - `created_at` (timestamptz) - تاريخ الإنشاء
    - `updated_at` (timestamptz) - تاريخ التحديث
  
  ### 4. `inspections` - الفحوصات
    - `id` (uuid, primary key) - المعرف
    - `hive_id` (uuid) - معرف الخلية
    - `inspection_date` (date) - تاريخ الفحص
    - بيانات الفحص الأخرى...
  
  ### 5. `production` - الإنتاج
    - `id` (uuid, primary key) - المعرف
    - `hive_id` (uuid) - معرف الخلية
    - `production_date` (date) - تاريخ الإنتاج
    - بيانات الإنتاج الأخرى...
  
  ### 6. `feeding_logs` - سجلات التغذية
    - `feeding_id` (uuid, primary key) - معرف التغذية
    - `hive_id` (uuid) - معرف الخلية
    - بيانات التغذية الأخرى...
  
  ## الأمان
    - تفعيل RLS على جميع الجداول
    - إضافة سياسات لضمان عزل بيانات المستخدمين
    - التمييز بين المسؤولين والمشتركين
*/

-- جدول المستخدمين
CREATE TABLE IF NOT EXISTS users (
  user_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE NOT NULL,
  full_name text,
  phone text,
  role text DEFAULT 'subscriber' CHECK (role IN ('admin', 'subscriber')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- جدول المناحل
CREATE TABLE IF NOT EXISTS apiaries (
  apiary_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  type text CHECK (type IN ('fixed', 'mobile')),
  latitude numeric,
  longitude numeric,
  altitude numeric,
  region text,
  hive_count integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- جدول الخلايا
CREATE TABLE IF NOT EXISTS hives (
  hive_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  apiary_id uuid NOT NULL REFERENCES apiaries(apiary_id) ON DELETE CASCADE,
  hive_number text NOT NULL,
  hive_type text,
  queen_age_months integer,
  frame_count integer,
  status text DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'swarmed', 'queenless')),
  health_status text CHECK (health_status IN ('excellent', 'good', 'fair', 'poor')),
  last_inspection_date date,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(apiary_id, hive_number)
);

-- جدول الفحوصات
CREATE TABLE IF NOT EXISTS inspections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hive_id uuid NOT NULL REFERENCES hives(hive_id) ON DELETE CASCADE,
  inspection_date date NOT NULL,
  inspector_name text,
  queen_seen boolean DEFAULT false,
  eggs_seen boolean DEFAULT false,
  larvae_seen boolean DEFAULT false,
  capped_brood_seen boolean DEFAULT false,
  temperament text CHECK (temperament IN ('calm', 'defensive', 'aggressive')),
  population_estimate text CHECK (population_estimate IN ('weak', 'medium', 'strong', 'very_strong')),
  honey_stores text CHECK (honey_stores IN ('none', 'low', 'medium', 'high', 'full')),
  pollen_stores text CHECK (pollen_stores IN ('none', 'low', 'medium', 'high')),
  diseases_found text,
  pests_found text,
  treatments_applied text,
  feeding_done boolean DEFAULT false,
  frames_added integer DEFAULT 0,
  frames_removed integer DEFAULT 0,
  weather_conditions text,
  temperature_celsius numeric,
  notes text,
  overall_health text CHECK (overall_health IN ('excellent', 'good', 'fair', 'poor', 'critical')),
  created_at timestamptz DEFAULT now()
);

-- جدول الإنتاج
CREATE TABLE IF NOT EXISTS production (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hive_id uuid NOT NULL REFERENCES hives(hive_id) ON DELETE CASCADE,
  production_date date NOT NULL,
  product_type text NOT NULL CHECK (product_type IN ('honey', 'wax', 'propolis', 'royal_jelly', 'pollen')),
  quantity_kg numeric NOT NULL CHECK (quantity_kg >= 0),
  quality_grade text,
  notes text,
  created_at timestamptz DEFAULT now()
);

-- جدول سجلات التغذية
CREATE TABLE IF NOT EXISTS feeding_logs (
  feeding_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hive_id uuid NOT NULL REFERENCES hives(hive_id) ON DELETE CASCADE,
  feeding_type text NOT NULL CHECK (feeding_type IN ('syrup', 'pollen_sub', 'protein', 'vitamins', 'candy')),
  amount numeric,
  unit text,
  feeding_date date NOT NULL,
  reason text,
  notes text,
  created_at timestamptz DEFAULT now()
);

-- إنشاء الفهارس
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_apiaries_owner ON apiaries(owner_id);
CREATE INDEX IF NOT EXISTS idx_hives_apiary ON hives(apiary_id);
CREATE INDEX IF NOT EXISTS idx_inspections_hive ON inspections(hive_id);
CREATE INDEX IF NOT EXISTS idx_inspections_date ON inspections(inspection_date);
CREATE INDEX IF NOT EXISTS idx_production_hive ON production(hive_id);
CREATE INDEX IF NOT EXISTS idx_production_date ON production(production_date);
CREATE INDEX IF NOT EXISTS idx_feeding_logs_hive ON feeding_logs(hive_id);
CREATE INDEX IF NOT EXISTS idx_feeding_logs_date ON feeding_logs(feeding_date);

-- تفعيل RLS على جميع الجداول
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE apiaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE hives ENABLE ROW LEVEL SECURITY;
ALTER TABLE inspections ENABLE ROW LEVEL SECURITY;
ALTER TABLE production ENABLE ROW LEVEL SECURITY;
ALTER TABLE feeding_logs ENABLE ROW LEVEL SECURITY;

-- سياسات جدول المستخدمين
-- المستخدمون يمكنهم فقط رؤية بياناتهم الخاصة
CREATE POLICY "Users can view own profile"
  ON users FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- المسؤولون يمكنهم رؤية جميع المستخدمين
CREATE POLICY "Admins can view all users"
  ON users FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.user_id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- سياسات جدول المناحل
-- المستخدمون يمكنهم فقط رؤية مناحلهم الخاصة
CREATE POLICY "Users can view own apiaries"
  ON apiaries FOR SELECT
  TO authenticated
  USING (auth.uid() = owner_id);

CREATE POLICY "Users can insert own apiaries"
  ON apiaries FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update own apiaries"
  ON apiaries FOR UPDATE
  TO authenticated
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can delete own apiaries"
  ON apiaries FOR DELETE
  TO authenticated
  USING (auth.uid() = owner_id);

-- المسؤولون يمكنهم رؤية جميع المناحل (للمراقبة فقط)
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

-- سياسات جدول الخلايا
-- المستخدمون يمكنهم فقط رؤية الخلايا في مناحلهم
CREATE POLICY "Users can view own hives"
  ON hives FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM apiaries
      WHERE apiaries.apiary_id = hives.apiary_id
      AND apiaries.owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert own hives"
  ON hives FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM apiaries
      WHERE apiaries.apiary_id = hives.apiary_id
      AND apiaries.owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can update own hives"
  ON hives FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM apiaries
      WHERE apiaries.apiary_id = hives.apiary_id
      AND apiaries.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM apiaries
      WHERE apiaries.apiary_id = hives.apiary_id
      AND apiaries.owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete own hives"
  ON hives FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM apiaries
      WHERE apiaries.apiary_id = hives.apiary_id
      AND apiaries.owner_id = auth.uid()
    )
  );

-- المسؤولون يمكنهم رؤية جميع الخلايا
CREATE POLICY "Admins can view all hives"
  ON hives FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.user_id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- سياسات جدول الفحوصات
-- المستخدمون يمكنهم فقط رؤية فحوصات خلاياهم
CREATE POLICY "Users can view own inspections"
  ON inspections FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM hives
      JOIN apiaries ON apiaries.apiary_id = hives.apiary_id
      WHERE hives.hive_id = inspections.hive_id
      AND apiaries.owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert own inspections"
  ON inspections FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM hives
      JOIN apiaries ON apiaries.apiary_id = hives.apiary_id
      WHERE hives.hive_id = inspections.hive_id
      AND apiaries.owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can update own inspections"
  ON inspections FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM hives
      JOIN apiaries ON apiaries.apiary_id = hives.apiary_id
      WHERE hives.hive_id = inspections.hive_id
      AND apiaries.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM hives
      JOIN apiaries ON apiaries.apiary_id = hives.apiary_id
      WHERE hives.hive_id = inspections.hive_id
      AND apiaries.owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete own inspections"
  ON inspections FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM hives
      JOIN apiaries ON apiaries.apiary_id = hives.apiary_id
      WHERE hives.hive_id = inspections.hive_id
      AND apiaries.owner_id = auth.uid()
    )
  );

-- المسؤولون يمكنهم رؤية جميع الفحوصات
CREATE POLICY "Admins can view all inspections"
  ON inspections FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.user_id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- سياسات جدول الإنتاج
-- المستخدمون يمكنهم فقط رؤية إنتاج خلاياهم
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

CREATE POLICY "Users can insert own production"
  ON production FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM hives
      JOIN apiaries ON apiaries.apiary_id = hives.apiary_id
      WHERE hives.hive_id = production.hive_id
      AND apiaries.owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can update own production"
  ON production FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM hives
      JOIN apiaries ON apiaries.apiary_id = hives.apiary_id
      WHERE hives.hive_id = production.hive_id
      AND apiaries.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM hives
      JOIN apiaries ON apiaries.apiary_id = hives.apiary_id
      WHERE hives.hive_id = production.hive_id
      AND apiaries.owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete own production"
  ON production FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM hives
      JOIN apiaries ON apiaries.apiary_id = hives.apiary_id
      WHERE hives.hive_id = production.hive_id
      AND apiaries.owner_id = auth.uid()
    )
  );

-- المسؤولون يمكنهم رؤية جميع بيانات الإنتاج
CREATE POLICY "Admins can view all production"
  ON production FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.user_id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- سياسات جدول سجلات التغذية
-- المستخدمون يمكنهم فقط رؤية سجلات تغذية خلاياهم
CREATE POLICY "Users can view own feeding logs"
  ON feeding_logs FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM hives
      JOIN apiaries ON apiaries.apiary_id = hives.apiary_id
      WHERE hives.hive_id = feeding_logs.hive_id
      AND apiaries.owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert own feeding logs"
  ON feeding_logs FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM hives
      JOIN apiaries ON apiaries.apiary_id = hives.apiary_id
      WHERE hives.hive_id = feeding_logs.hive_id
      AND apiaries.owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can update own feeding logs"
  ON feeding_logs FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM hives
      JOIN apiaries ON apiaries.apiary_id = hives.apiary_id
      WHERE hives.hive_id = feeding_logs.hive_id
      AND apiaries.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM hives
      JOIN apiaries ON apiaries.apiary_id = hives.apiary_id
      WHERE hives.hive_id = feeding_logs.hive_id
      AND apiaries.owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete own feeding logs"
  ON feeding_logs FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM hives
      JOIN apiaries ON apiaries.apiary_id = hives.apiary_id
      WHERE hives.hive_id = feeding_logs.hive_id
      AND apiaries.owner_id = auth.uid()
    )
  );

-- المسؤولون يمكنهم رؤية جميع سجلات التغذية
CREATE POLICY "Admins can view all feeding logs"
  ON feeding_logs FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.user_id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- إنشاء دالة لتحديث updated_at تلقائياً
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- إضافة المحفزات لتحديث updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_apiaries_updated_at BEFORE UPDATE ON apiaries
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_hives_updated_at BEFORE UPDATE ON hives
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- إنشاء دالة لمزامنة user_id مع auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (user_id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- إنشاء محفز لإضافة المستخدمين الجدد تلقائياً
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
