/*
  # إضافة جداول التحليلات والتوقعات
  
  ## الجداول الجديدة
  
  ### 1. `performance_summaries` - ملخصات الأداء الدورية
    - `summary_id` (uuid, primary key) - معرف الملخص
    - `user_id` (uuid) - معرف المستخدم
    - `apiary_id` (uuid) - معرف المنحل
    - `hive_id` (uuid) - معرف الخلية
    - `period_type` (text) - نوع الفترة (daily, weekly, monthly, quarterly, yearly)
    - `period_start` (date) - بداية الفترة
    - `period_end` (date) - نهاية الفترة
    - `total_inspections` (integer) - إجمالي الفحوصات
    - `average_health_score` (numeric) - متوسط درجة الصحة
    - `total_honey_harvested` (numeric) - إجمالي العسل المحصود
    - `total_pollen_harvested` (numeric) - إجمالي حبوب اللقاح
    - `feeding_frequency` (integer) - تكرار التغذية
    - `issues_detected` (integer) - المشاكل المكتشفة
    - `issues_resolved` (integer) - المشاكل المحلولة
    - `queen_replacements` (integer) - استبدال الملكات
    - `swarms_created` (integer) - الطرود المنشأة
    - `mortality_rate` (numeric) - معدل الوفيات
    - `productivity_score` (numeric) - درجة الإنتاجية
    - `trends` (jsonb) - الاتجاهات
    - `insights` (jsonb) - الرؤى
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 2. `production_forecasts` - توقعات الإنتاج
    - `forecast_id` (uuid, primary key) - معرف التوقع
    - `apiary_id` (uuid) - معرف المنحل
    - `hive_id` (uuid) - معرف الخلية
    - `forecast_type` (text) - نوع التوقع (honey, pollen, royal_jelly)
    - `forecast_period` (text) - فترة التوقع
    - `period_start` (date) - بداية الفترة
    - `period_end` (date) - نهاية الفترة
    - `predicted_quantity` (numeric) - الكمية المتوقعة
    - `predicted_quality` (text) - الجودة المتوقعة
    - `confidence_interval_low` (numeric) - الحد الأدنى للثقة
    - `confidence_interval_high` (numeric) - الحد الأعلى للثقة
    - `factors_considered` (jsonb) - العوامل المعتبرة
    - `actual_quantity` (numeric) - الكمية الفعلية
    - `forecast_accuracy` (numeric) - دقة التوقع
    - `created_by_model` (uuid) - أُنشئ بواسطة نموذج
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 3. `hive_health_trends` - اتجاهات صحة الخلايا
    - `trend_id` (uuid, primary key) - معرف الاتجاه
    - `hive_id` (uuid) - معرف الخلية
    - `date` (date) - التاريخ
    - `health_score` (integer) - درجة الصحة
    - `strength_level` (text) - مستوى القوة
    - `food_stores_score` (integer) - درجة مخزون الغذاء
    - `brood_pattern_score` (integer) - درجة نمط الحضنة
    - `disease_risk` (text) - خطر المرض
    - `pest_pressure` (integer) - ضغط الآفات
    - `queen_performance` (integer) - أداء الملكة
    - `population_estimate` (integer) - تقدير العدد
    - `notes` (text) - ملاحظات
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 4. `seasonal_patterns` - الأنماط الموسمية
    - `pattern_id` (uuid, primary key) - معرف النمط
    - `region` (text) - المنطقة
    - `season` (text) - الموسم
    - `pattern_type` (text) - نوع النمط
    - `typical_behavior` (jsonb) - السلوك النموذجي
    - `expected_production` (jsonb) - الإنتاج المتوقع
    - `common_issues` (jsonb) - المشاكل الشائعة
    - `recommended_actions` (jsonb) - الإجراءات الموصى بها
    - `optimal_inspection_frequency` (integer) - تكرار الفحص الأمثل
    - `feeding_requirements` (jsonb) - متطلبات التغذية
    - `temperature_range` (jsonb) - نطاق الحرارة
    - `humidity_range` (jsonb) - نطاق الرطوبة
    - `created_at` (timestamptz) - تاريخ الإنشاء
    - `updated_at` (timestamptz) - تاريخ التحديث
  
  ### 5. `comparative_analytics` - التحليلات المقارنة
    - `comparison_id` (uuid, primary key) - معرف المقارنة
    - `user_id` (uuid) - معرف المستخدم
    - `comparison_type` (text) - نوع المقارنة
    - `entity_ids` (uuid[]) - معرفات الكيانات
    - `metrics` (jsonb) - المقاييس
    - `period_start` (date) - بداية الفترة
    - `period_end` (date) - نهاية الفترة
    - `results` (jsonb) - النتائج
    - `insights` (text) - الرؤى
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 6. `benchmarks` - المعايير القياسية
    - `benchmark_id` (uuid, primary key) - معرف المعيار
    - `benchmark_name` (text) - اسم المعيار
    - `category` (text) - الفئة
    - `region` (text) - المنطقة
    - `hive_type` (text) - نوع الخلية
    - `metric_name` (text) - اسم المقياس
    - `percentile_25` (numeric) - الربيع الأول
    - `percentile_50` (numeric) - الوسيط
    - `percentile_75` (numeric) - الربيع الثالث
    - `percentile_90` (numeric) - الربيع التاسع
    - `sample_size` (integer) - حجم العينة
    - `last_updated` (timestamptz) - آخر تحديث
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ## الأمان
    - تفعيل RLS على جميع الجداول
    - إضافة سياسات للتحكم في الوصول
*/

-- جدول ملخصات الأداء
CREATE TABLE IF NOT EXISTS performance_summaries (
  summary_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  apiary_id uuid REFERENCES apiaries(apiary_id) ON DELETE CASCADE,
  hive_id uuid REFERENCES hives(hive_id) ON DELETE CASCADE,
  period_type text NOT NULL CHECK (period_type IN ('daily', 'weekly', 'monthly', 'quarterly', 'yearly')),
  period_start date NOT NULL,
  period_end date NOT NULL,
  total_inspections integer DEFAULT 0,
  average_health_score numeric CHECK (average_health_score >= 0 AND average_health_score <= 40),
  total_honey_harvested numeric DEFAULT 0,
  total_pollen_harvested numeric DEFAULT 0,
  feeding_frequency integer DEFAULT 0,
  issues_detected integer DEFAULT 0,
  issues_resolved integer DEFAULT 0,
  queen_replacements integer DEFAULT 0,
  swarms_created integer DEFAULT 0,
  mortality_rate numeric CHECK (mortality_rate >= 0 AND mortality_rate <= 1),
  productivity_score numeric CHECK (productivity_score >= 0 AND productivity_score <= 100),
  trends jsonb,
  insights jsonb,
  created_at timestamptz DEFAULT now(),
  UNIQUE(hive_id, period_type, period_start)
);

-- جدول توقعات الإنتاج
CREATE TABLE IF NOT EXISTS production_forecasts (
  forecast_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  apiary_id uuid REFERENCES apiaries(apiary_id) ON DELETE CASCADE,
  hive_id uuid REFERENCES hives(hive_id) ON DELETE CASCADE,
  forecast_type text NOT NULL CHECK (forecast_type IN ('honey', 'pollen', 'royal_jelly', 'wax', 'propolis')),
  forecast_period text NOT NULL,
  period_start date NOT NULL,
  period_end date NOT NULL,
  predicted_quantity numeric NOT NULL,
  predicted_quality text CHECK (predicted_quality IN ('low', 'medium', 'high', 'premium')),
  confidence_interval_low numeric,
  confidence_interval_high numeric,
  factors_considered jsonb,
  actual_quantity numeric,
  forecast_accuracy numeric CHECK (forecast_accuracy >= 0 AND forecast_accuracy <= 1),
  created_by_model uuid REFERENCES ai_models(model_id),
  created_at timestamptz DEFAULT now()
);

-- جدول اتجاهات صحة الخلايا
CREATE TABLE IF NOT EXISTS hive_health_trends (
  trend_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hive_id uuid NOT NULL REFERENCES hives(hive_id) ON DELETE CASCADE,
  date date NOT NULL,
  health_score integer CHECK (health_score >= 0 AND health_score <= 40),
  strength_level text CHECK (strength_level IN ('weak', 'medium', 'strong')),
  food_stores_score integer CHECK (food_stores_score >= 0 AND food_stores_score <= 10),
  brood_pattern_score integer CHECK (brood_pattern_score >= 0 AND brood_pattern_score <= 10),
  disease_risk text CHECK (disease_risk IN ('low', 'medium', 'high')),
  pest_pressure integer CHECK (pest_pressure >= 0 AND pest_pressure <= 10),
  queen_performance integer CHECK (queen_performance >= 0 AND queen_performance <= 10),
  population_estimate integer,
  notes text,
  created_at timestamptz DEFAULT now(),
  UNIQUE(hive_id, date)
);

-- جدول الأنماط الموسمية
CREATE TABLE IF NOT EXISTS seasonal_patterns (
  pattern_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  region text NOT NULL,
  season text NOT NULL CHECK (season IN ('spring', 'summer', 'fall', 'winter')),
  pattern_type text NOT NULL CHECK (pattern_type IN ('production', 'health', 'behavior', 'management')),
  typical_behavior jsonb,
  expected_production jsonb,
  common_issues jsonb,
  recommended_actions jsonb,
  optimal_inspection_frequency integer,
  feeding_requirements jsonb,
  temperature_range jsonb,
  humidity_range jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(region, season, pattern_type)
);

-- جدول التحليلات المقارنة
CREATE TABLE IF NOT EXISTS comparative_analytics (
  comparison_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  comparison_type text NOT NULL CHECK (comparison_type IN ('hives', 'apiaries', 'periods', 'regions')),
  entity_ids uuid[] NOT NULL,
  metrics jsonb NOT NULL,
  period_start date NOT NULL,
  period_end date NOT NULL,
  results jsonb NOT NULL,
  insights text,
  created_at timestamptz DEFAULT now()
);

-- جدول المعايير القياسية
CREATE TABLE IF NOT EXISTS benchmarks (
  benchmark_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  benchmark_name text NOT NULL,
  category text NOT NULL CHECK (category IN ('production', 'health', 'efficiency', 'growth')),
  region text NOT NULL,
  hive_type text,
  metric_name text NOT NULL,
  percentile_25 numeric,
  percentile_50 numeric,
  percentile_75 numeric,
  percentile_90 numeric,
  sample_size integer DEFAULT 0,
  last_updated timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  UNIQUE(category, region, metric_name)
);

-- إنشاء الفهارس
CREATE INDEX IF NOT EXISTS idx_performance_summaries_user ON performance_summaries(user_id);
CREATE INDEX IF NOT EXISTS idx_performance_summaries_apiary ON performance_summaries(apiary_id);
CREATE INDEX IF NOT EXISTS idx_performance_summaries_hive ON performance_summaries(hive_id);
CREATE INDEX IF NOT EXISTS idx_performance_summaries_period ON performance_summaries(period_type, period_start);
CREATE INDEX IF NOT EXISTS idx_production_forecasts_hive ON production_forecasts(hive_id);
CREATE INDEX IF NOT EXISTS idx_production_forecasts_type ON production_forecasts(forecast_type);
CREATE INDEX IF NOT EXISTS idx_production_forecasts_period ON production_forecasts(period_start, period_end);
CREATE INDEX IF NOT EXISTS idx_hive_health_trends_hive ON hive_health_trends(hive_id);
CREATE INDEX IF NOT EXISTS idx_hive_health_trends_date ON hive_health_trends(date);
CREATE INDEX IF NOT EXISTS idx_seasonal_patterns_region ON seasonal_patterns(region, season);
CREATE INDEX IF NOT EXISTS idx_comparative_analytics_user ON comparative_analytics(user_id);
CREATE INDEX IF NOT EXISTS idx_benchmarks_category ON benchmarks(category, region);

-- تفعيل RLS
ALTER TABLE performance_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE production_forecasts ENABLE ROW LEVEL SECURITY;
ALTER TABLE hive_health_trends ENABLE ROW LEVEL SECURITY;
ALTER TABLE seasonal_patterns ENABLE ROW LEVEL SECURITY;
ALTER TABLE comparative_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE benchmarks ENABLE ROW LEVEL SECURITY;

-- سياسات performance_summaries
CREATE POLICY "Users can view own performance summaries"
  ON performance_summaries FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "System can insert performance summaries"
  ON performance_summaries FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- سياسات production_forecasts
CREATE POLICY "Users can view forecasts for their hives"
  ON production_forecasts FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM hives h
      JOIN apiaries a ON h.apiary_id = a.apiary_id
      WHERE h.hive_id = production_forecasts.hive_id
      AND a.owner_id = auth.uid()
    )
  );

-- سياسات hive_health_trends
CREATE POLICY "Users can view health trends for their hives"
  ON hive_health_trends FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM hives h
      JOIN apiaries a ON h.apiary_id = a.apiary_id
      WHERE h.hive_id = hive_health_trends.hive_id
      AND a.owner_id = auth.uid()
    )
  );

-- سياسات seasonal_patterns (عامة للجميع)
CREATE POLICY "Anyone can view seasonal patterns"
  ON seasonal_patterns FOR SELECT
  TO authenticated
  USING (true);

-- سياسات comparative_analytics
CREATE POLICY "Users can view own comparative analytics"
  ON comparative_analytics FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own comparative analytics"
  ON comparative_analytics FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- سياسات benchmarks (عامة للجميع)
CREATE POLICY "Anyone can view benchmarks"
  ON benchmarks FOR SELECT
  TO authenticated
  USING (true);