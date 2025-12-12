/*
  # إضافة جداول الطقس والجداول المساعدة
  
  ## الجداول الجديدة
  
  ### 1. `weather_data` - بيانات الطقس
    - `weather_id` (uuid, primary key) - معرف بيانات الطقس
    - `apiary_id` (uuid) - معرف المنحل
    - `date` (date) - التاريخ
    - `time` (time) - الوقت
    - `temperature` (numeric) - درجة الحرارة
    - `feels_like` (numeric) - درجة الحرارة المحسوسة
    - `humidity` (numeric) - الرطوبة
    - `pressure` (numeric) - الضغط الجوي
    - `wind_speed` (numeric) - سرعة الرياح
    - `wind_direction` (text) - اتجاه الرياح
    - `precipitation` (numeric) - هطول الأمطار
    - `cloud_cover` (numeric) - الغطاء السحابي
    - `uv_index` (numeric) - مؤشر الأشعة فوق البنفسجية
    - `conditions` (text) - حالة الطقس
    - `visibility` (numeric) - الرؤية
    - `is_forecast` (boolean) - توقع أم قياس فعلي
    - `data_source` (text) - مصدر البيانات
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 2. `weather_alerts` - تنبيهات الطقس
    - `alert_id` (uuid, primary key) - معرف التنبيه
    - `apiary_id` (uuid) - معرف المنحل
    - `alert_type` (text) - نوع التنبيه
    - `severity` (text) - الخطورة
    - `title` (text) - العنوان
    - `description` (text) - الوصف
    - `start_time` (timestamptz) - وقت البداية
    - `end_time` (timestamptz) - وقت النهاية
    - `recommended_actions` (jsonb) - الإجراءات الموصى بها
    - `is_active` (boolean) - التنبيه نشط
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 3. `flora_calendar` - تقويم النباتات
    - `flora_id` (uuid, primary key) - معرف النبات
    - `plant_name_ar` (text) - الاسم بالعربية
    - `plant_name_en` (text) - الاسم بالإنجليزية
    - `scientific_name` (text) - الاسم العلمي
    - `region` (text) - المنطقة
    - `flowering_start` (text) - بداية الإزهار (شهر)
    - `flowering_end` (text) - نهاية الإزهار (شهر)
    - `nectar_quality` (text) - جودة الرحيق
    - `pollen_quality` (text) - جودة حبوب اللقاح
    - `honey_type` (text) - نوع العسل
    - `honey_color` (text) - لون العسل
    - `expected_yield` (text) - الإنتاج المتوقع
    - `notes` (text) - ملاحظات
    - `images` (text[]) - صور
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 4. `knowledge_base` - قاعدة المعرفة
    - `article_id` (uuid, primary key) - معرف المقالة
    - `category` (text) - الفئة
    - `title` (text) - العنوان
    - `content` (text) - المحتوى
    - `tags` (text[]) - الوسوم
    - `difficulty_level` (text) - مستوى الصعوبة
    - `reading_time_minutes` (integer) - وقت القراءة
    - `author_id` (uuid) - معرف المؤلف
    - `is_published` (boolean) - منشور
    - `views_count` (integer) - عدد المشاهدات
    - `helpful_count` (integer) - عدد التقييمات المفيدة
    - `images` (text[]) - صور
    - `videos` (text[]) - فيديوهات
    - `related_articles` (uuid[]) - مقالات ذات صلة
    - `created_at` (timestamptz) - تاريخ الإنشاء
    - `updated_at` (timestamptz) - تاريخ التحديث
  
  ### 5. `user_achievements` - إنجازات المستخدمين
    - `achievement_id` (uuid, primary key) - معرف الإنجاز
    - `user_id` (uuid) - معرف المستخدم
    - `achievement_type` (text) - نوع الإنجاز
    - `title` (text) - العنوان
    - `description` (text) - الوصف
    - `icon` (text) - الأيقونة
    - `points` (integer) - النقاط
    - `level` (text) - المستوى
    - `progress` (numeric) - التقدم
    - `target` (numeric) - الهدف
    - `completed` (boolean) - مكتمل
    - `completed_at` (timestamptz) - تاريخ الإكمال
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 6. `resource_inventory` - جرد الموارد
    - `inventory_id` (uuid, primary key) - معرف الجرد
    - `user_id` (uuid) - معرف المستخدم
    - `apiary_id` (uuid) - معرف المنحل
    - `resource_type` (text) - نوع المورد
    - `resource_name` (text) - اسم المورد
    - `quantity` (numeric) - الكمية
    - `unit` (text) - الوحدة
    - `reorder_level` (numeric) - مستوى إعادة الطلب
    - `last_restocked_at` (timestamptz) - آخر تجديد
    - `expiry_date` (date) - تاريخ الانتهاء
    - `storage_location` (text) - موقع التخزين
    - `notes` (text) - ملاحظات
    - `created_at` (timestamptz) - تاريخ الإنشاء
    - `updated_at` (timestamptz) - تاريخ التحديث
  
  ### 7. `learning_progress` - تقدم التعلم
    - `progress_id` (uuid, primary key) - معرف التقدم
    - `user_id` (uuid) - معرف المستخدم
    - `article_id` (uuid) - معرف المقالة
    - `progress_percentage` (numeric) - نسبة التقدم
    - `completed` (boolean) - مكتمل
    - `quiz_score` (numeric) - درجة الاختبار
    - `notes` (text) - ملاحظات
    - `last_accessed_at` (timestamptz) - آخر وصول
    - `completed_at` (timestamptz) - تاريخ الإكمال
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ## الأمان
    - تفعيل RLS على جميع الجداول
    - إضافة سياسات للتحكم في الوصول
*/

-- جدول بيانات الطقس
CREATE TABLE IF NOT EXISTS weather_data (
  weather_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  apiary_id uuid REFERENCES apiaries(apiary_id) ON DELETE CASCADE,
  date date NOT NULL,
  time time,
  temperature numeric,
  feels_like numeric,
  humidity numeric CHECK (humidity >= 0 AND humidity <= 100),
  pressure numeric,
  wind_speed numeric,
  wind_direction text,
  precipitation numeric,
  cloud_cover numeric CHECK (cloud_cover >= 0 AND cloud_cover <= 100),
  uv_index numeric CHECK (uv_index >= 0 AND uv_index <= 15),
  conditions text,
  visibility numeric,
  is_forecast boolean DEFAULT false,
  data_source text DEFAULT 'api',
  created_at timestamptz DEFAULT now(),
  UNIQUE(apiary_id, date, time, is_forecast)
);

-- جدول تنبيهات الطقس
CREATE TABLE IF NOT EXISTS weather_alerts (
  alert_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  apiary_id uuid REFERENCES apiaries(apiary_id) ON DELETE CASCADE,
  alert_type text NOT NULL CHECK (alert_type IN (
    'extreme_heat', 'extreme_cold', 'storm', 'heavy_rain',
    'strong_wind', 'frost', 'drought', 'flood'
  )),
  severity text DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'extreme')),
  title text NOT NULL,
  description text,
  start_time timestamptz NOT NULL,
  end_time timestamptz,
  recommended_actions jsonb,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- جدول تقويم النباتات
CREATE TABLE IF NOT EXISTS flora_calendar (
  flora_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plant_name_ar text NOT NULL,
  plant_name_en text,
  scientific_name text,
  region text NOT NULL,
  flowering_start text,
  flowering_end text,
  nectar_quality text CHECK (nectar_quality IN ('low', 'medium', 'high', 'excellent')),
  pollen_quality text CHECK (pollen_quality IN ('low', 'medium', 'high', 'excellent')),
  honey_type text,
  honey_color text,
  expected_yield text,
  notes text,
  images text[],
  created_at timestamptz DEFAULT now()
);

-- جدول قاعدة المعرفة
CREATE TABLE IF NOT EXISTS knowledge_base (
  article_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category text NOT NULL CHECK (category IN (
    'basics', 'hive_management', 'disease_treatment', 'harvesting',
    'queen_rearing', 'pest_control', 'seasonal_care', 'equipment',
    'honey_processing', 'business', 'advanced_techniques'
  )),
  title text NOT NULL,
  content text NOT NULL,
  tags text[],
  difficulty_level text DEFAULT 'beginner' CHECK (difficulty_level IN ('beginner', 'intermediate', 'advanced', 'expert')),
  reading_time_minutes integer,
  author_id uuid REFERENCES users(user_id),
  is_published boolean DEFAULT false,
  views_count integer DEFAULT 0,
  helpful_count integer DEFAULT 0,
  images text[],
  videos text[],
  related_articles uuid[],
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- جدول إنجازات المستخدمين
CREATE TABLE IF NOT EXISTS user_achievements (
  achievement_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  achievement_type text NOT NULL CHECK (achievement_type IN (
    'first_hive', 'first_inspection', 'first_harvest', 'hive_milestone',
    'production_milestone', 'learning_milestone', 'consistency',
    'expert_beekeeper', 'mentor', 'contributor'
  )),
  title text NOT NULL,
  description text,
  icon text,
  points integer DEFAULT 0,
  level text CHECK (level IN ('bronze', 'silver', 'gold', 'platinum')),
  progress numeric DEFAULT 0,
  target numeric,
  completed boolean DEFAULT false,
  completed_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- جدول جرد الموارد
CREATE TABLE IF NOT EXISTS resource_inventory (
  inventory_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  apiary_id uuid REFERENCES apiaries(apiary_id) ON DELETE CASCADE,
  resource_type text NOT NULL CHECK (resource_type IN (
    'feed', 'medication', 'equipment', 'protective_gear',
    'frames', 'foundation', 'packaging', 'tools', 'supplements'
  )),
  resource_name text NOT NULL,
  quantity numeric NOT NULL,
  unit text NOT NULL,
  reorder_level numeric,
  last_restocked_at timestamptz,
  expiry_date date,
  storage_location text,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- جدول تقدم التعلم
CREATE TABLE IF NOT EXISTS learning_progress (
  progress_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  article_id uuid NOT NULL REFERENCES knowledge_base(article_id) ON DELETE CASCADE,
  progress_percentage numeric DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
  completed boolean DEFAULT false,
  quiz_score numeric CHECK (quiz_score >= 0 AND quiz_score <= 100),
  notes text,
  last_accessed_at timestamptz DEFAULT now(),
  completed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, article_id)
);

-- إنشاء الفهارس
CREATE INDEX IF NOT EXISTS idx_weather_data_apiary ON weather_data(apiary_id);
CREATE INDEX IF NOT EXISTS idx_weather_data_date ON weather_data(date);
CREATE INDEX IF NOT EXISTS idx_weather_alerts_apiary ON weather_alerts(apiary_id);
CREATE INDEX IF NOT EXISTS idx_weather_alerts_active ON weather_alerts(is_active);
CREATE INDEX IF NOT EXISTS idx_flora_calendar_region ON flora_calendar(region);
CREATE INDEX IF NOT EXISTS idx_knowledge_base_category ON knowledge_base(category);
CREATE INDEX IF NOT EXISTS idx_knowledge_base_published ON knowledge_base(is_published);
CREATE INDEX IF NOT EXISTS idx_user_achievements_user ON user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_completed ON user_achievements(completed);
CREATE INDEX IF NOT EXISTS idx_resource_inventory_user ON resource_inventory(user_id);
CREATE INDEX IF NOT EXISTS idx_resource_inventory_apiary ON resource_inventory(apiary_id);
CREATE INDEX IF NOT EXISTS idx_learning_progress_user ON learning_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_learning_progress_article ON learning_progress(article_id);

-- تفعيل RLS
ALTER TABLE weather_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE weather_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE flora_calendar ENABLE ROW LEVEL SECURITY;
ALTER TABLE knowledge_base ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE resource_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE learning_progress ENABLE ROW LEVEL SECURITY;

-- سياسات weather_data
CREATE POLICY "Users can view weather for their apiaries"
  ON weather_data FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM apiaries
      WHERE apiaries.apiary_id = weather_data.apiary_id
      AND apiaries.owner_id = auth.uid()
    )
  );

-- سياسات weather_alerts
CREATE POLICY "Users can view weather alerts for their apiaries"
  ON weather_alerts FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM apiaries
      WHERE apiaries.apiary_id = weather_alerts.apiary_id
      AND apiaries.owner_id = auth.uid()
    )
  );

-- سياسات flora_calendar (عامة)
CREATE POLICY "Anyone can view flora calendar"
  ON flora_calendar FOR SELECT
  TO authenticated
  USING (true);

-- سياسات knowledge_base
CREATE POLICY "Anyone can view published articles"
  ON knowledge_base FOR SELECT
  TO authenticated
  USING (is_published = true OR author_id = auth.uid());

CREATE POLICY "Authors can insert articles"
  ON knowledge_base FOR INSERT
  TO authenticated
  WITH CHECK (author_id = auth.uid());

CREATE POLICY "Authors can update own articles"
  ON knowledge_base FOR UPDATE
  TO authenticated
  USING (author_id = auth.uid())
  WITH CHECK (author_id = auth.uid());

-- سياسات user_achievements
CREATE POLICY "Users can view own achievements"
  ON user_achievements FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "System can insert achievements"
  ON user_achievements FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "System can update achievements"
  ON user_achievements FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- سياسات resource_inventory
CREATE POLICY "Users can view own inventory"
  ON resource_inventory FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own inventory"
  ON resource_inventory FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own inventory"
  ON resource_inventory FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own inventory"
  ON resource_inventory FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- سياسات learning_progress
CREATE POLICY "Users can view own learning progress"
  ON learning_progress FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own learning progress"
  ON learning_progress FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own learning progress"
  ON learning_progress FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);