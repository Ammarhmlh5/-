/*
  # إضافة مكتبة النباتات المتخصصة
  
  ## الجداول الجديدة
  
  ### 1. `plant_families` - عائلات النباتات
    - `family_id` (uuid, primary key) - معرف العائلة
    - `family_name_ar` (text) - الاسم بالعربية
    - `family_name_en` (text) - الاسم بالإنجليزية
    - `family_name_scientific` (text) - الاسم العلمي
    - `description` (text) - الوصف
    - `characteristics` (jsonb) - الخصائص
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 2. `flora_library` - مكتبة النباتات الشاملة
    - `plant_id` (uuid, primary key) - معرف النبات
    - `family_id` (uuid) - معرف العائلة
    - `plant_name_ar` (text) - الاسم بالعربية
    - `plant_name_en` (text) - الاسم بالإنجليزية
    - `scientific_name` (text) - الاسم العلمي
    - `common_names` (text[]) - الأسماء الشائعة
    - `plant_type` (text) - نوع النبات
    - `description` (text) - الوصف
    - `distribution` (text[]) - مناطق الانتشار
    - `growth_habit` (text) - طبيعة النمو
    - `height_range` (jsonb) - نطاق الارتفاع
    - `lifespan` (text) - دورة الحياة
    - `images` (text[]) - صور
    - `is_verified` (boolean) - تم التحقق
    - `created_at` (timestamptz) - تاريخ الإنشاء
    - `updated_at` (timestamptz) - تاريخ التحديث
  
  ### 3. `nectar_sources` - مصادر الرحيق
    - `nectar_source_id` (uuid, primary key) - المعرف
    - `plant_id` (uuid) - معرف النبات
    - `nectar_quality` (text) - جودة الرحيق
    - `nectar_quantity` (text) - كمية الرحيق
    - `sugar_content` (numeric) - محتوى السكر %
    - `nectar_flow_period` (jsonb) - فترة تدفق الرحيق
    - `peak_production_time` (text) - وقت الذروة
    - `daily_production_pattern` (jsonb) - نمط الإنتاج اليومي
    - `weather_dependency` (jsonb) - الاعتماد على الطقس
    - `attractiveness_to_bees` (text) - الجاذبية للنحل
    - `notes` (text) - ملاحظات
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 4. `pollen_sources` - مصادر حبوب اللقاح
    - `pollen_source_id` (uuid, primary key) - المعرف
    - `plant_id` (uuid) - معرف النبات
    - `pollen_quality` (text) - جودة حبوب اللقاح
    - `pollen_quantity` (text) - كمية حبوب اللقاح
    - `protein_content` (numeric) - محتوى البروتين %
    - `pollen_color` (text) - لون حبوب اللقاح
    - `collection_period` (jsonb) - فترة الجمع
    - `peak_availability` (text) - وقت الذروة
    - `nutritional_value` (jsonb) - القيمة الغذائية
    - `attractiveness_to_bees` (text) - الجاذبية للنحل
    - `notes` (text) - ملاحظات
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 5. `honey_varieties` - أنواع العسل
    - `honey_variety_id` (uuid, primary key) - معرف النوع
    - `variety_name_ar` (text) - الاسم بالعربية
    - `variety_name_en` (text) - الاسم بالإنجليزية
    - `primary_plant_id` (uuid) - النبات الرئيسي
    - `secondary_plants` (uuid[]) - النباتات الثانوية
    - `color` (text) - اللون
    - `color_code` (text) - كود اللون
    - `taste_profile` (jsonb) - ملف المذاق
    - `aroma` (text) - الرائحة
    - `texture` (text) - القوام
    - `crystallization_rate` (text) - معدل التبلور
    - `moisture_content` (numeric) - محتوى الرطوبة
    - `medicinal_properties` (jsonb) - الخصائص الطبية
    - `market_value` (text) - القيمة السوقية
    - `production_regions` (text[]) - مناطق الإنتاج
    - `production_season` (jsonb) - موسم الإنتاج
    - `images` (text[]) - صور
    - `is_certified` (boolean) - معتمد
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 6. `plant_locations` - مواقع النباتات
    - `id` (uuid, primary key) - المعرف
    - `plant_id` (uuid) - معرف النبات
    - `location_id` (uuid) - معرف الموقع
    - `abundance` (text) - الوفرة
    - `density` (text) - الكثافة
    - `accessibility` (text) - سهولة الوصول
    - `notes` (text) - ملاحظات
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 7. `flowering_calendar` - تقويم الإزهار
    - `calendar_id` (uuid, primary key) - معرف التقويم
    - `plant_id` (uuid) - معرف النبات
    - `location_id` (uuid) - معرف الموقع
    - `climate_zone_id` (uuid) - معرف المنطقة المناخية
    - `flowering_start_month` (integer) - شهر بداية الإزهار
    - `flowering_end_month` (integer) - شهر نهاية الإزهار
    - `peak_flowering_month` (integer) - شهر ذروة الإزهار
    - `flowering_duration_days` (integer) - مدة الإزهار بالأيام
    - `bloom_intensity` (text) - شدة الإزهار
    - `triggers` (jsonb) - محفزات الإزهار
    - `year_recorded` (integer) - السنة المسجلة
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 8. `plant_cultivation_guide` - دليل زراعة النباتات
    - `guide_id` (uuid, primary key) - معرف الدليل
    - `plant_id` (uuid) - معرف النبات
    - `soil_requirements` (jsonb) - متطلبات التربة
    - `water_requirements` (text) - متطلبات الماء
    - `sunlight_requirements` (text) - متطلبات الشمس
    - `temperature_range` (jsonb) - نطاق الحرارة
    - `planting_season` (jsonb) - موسم الزراعة
    - `propagation_methods` (text[]) - طرق التكاثر
    - `spacing` (jsonb) - المسافات
    - `care_instructions` (jsonb) - تعليمات العناية
    - `common_pests` (text[]) - الآفات الشائعة
    - `common_diseases` (text[]) - الأمراض الشائعة
    - `companion_plants` (uuid[]) - نباتات مرافقة
    - `beekeeping_benefits` (text) - فوائد لتربية النحل
    - `created_at` (timestamptz) - تاريخ الإنشاء
    - `updated_at` (timestamptz) - تاريخ التحديث
  
  ## الأمان
    - تفعيل RLS على الجداول
    - إضافة سياسات للتحكم في الوصول
*/

-- جدول عائلات النباتات
CREATE TABLE IF NOT EXISTS plant_families (
  family_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  family_name_ar text NOT NULL,
  family_name_en text,
  family_name_scientific text UNIQUE NOT NULL,
  description text,
  characteristics jsonb,
  created_at timestamptz DEFAULT now()
);

-- جدول مكتبة النباتات الشاملة
CREATE TABLE IF NOT EXISTS flora_library (
  plant_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id uuid REFERENCES plant_families(family_id) ON DELETE SET NULL,
  plant_name_ar text NOT NULL,
  plant_name_en text,
  scientific_name text UNIQUE NOT NULL,
  common_names text[],
  plant_type text CHECK (plant_type IN ('tree', 'shrub', 'herb', 'grass', 'vine', 'succulent', 'annual', 'perennial')),
  description text,
  distribution text[],
  growth_habit text,
  height_range jsonb,
  lifespan text CHECK (lifespan IN ('annual', 'biennial', 'perennial', 'ephemeral')),
  images text[],
  is_verified boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- جدول مصادر الرحيق
CREATE TABLE IF NOT EXISTS nectar_sources (
  nectar_source_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plant_id uuid NOT NULL REFERENCES flora_library(plant_id) ON DELETE CASCADE,
  nectar_quality text CHECK (nectar_quality IN ('poor', 'fair', 'good', 'excellent', 'superior')),
  nectar_quantity text CHECK (nectar_quantity IN ('minimal', 'low', 'moderate', 'high', 'abundant')),
  sugar_content numeric CHECK (sugar_content >= 0 AND sugar_content <= 100),
  nectar_flow_period jsonb,
  peak_production_time text,
  daily_production_pattern jsonb,
  weather_dependency jsonb,
  attractiveness_to_bees text CHECK (attractiveness_to_bees IN ('low', 'moderate', 'high', 'very_high')),
  notes text,
  created_at timestamptz DEFAULT now(),
  UNIQUE(plant_id)
);

-- جدول مصادر حبوب اللقاح
CREATE TABLE IF NOT EXISTS pollen_sources (
  pollen_source_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plant_id uuid NOT NULL REFERENCES flora_library(plant_id) ON DELETE CASCADE,
  pollen_quality text CHECK (pollen_quality IN ('poor', 'fair', 'good', 'excellent', 'superior')),
  pollen_quantity text CHECK (pollen_quantity IN ('minimal', 'low', 'moderate', 'high', 'abundant')),
  protein_content numeric CHECK (protein_content >= 0 AND protein_content <= 100),
  pollen_color text,
  collection_period jsonb,
  peak_availability text,
  nutritional_value jsonb,
  attractiveness_to_bees text CHECK (attractiveness_to_bees IN ('low', 'moderate', 'high', 'very_high')),
  notes text,
  created_at timestamptz DEFAULT now(),
  UNIQUE(plant_id)
);

-- جدول أنواع العسل
CREATE TABLE IF NOT EXISTS honey_varieties (
  honey_variety_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  variety_name_ar text NOT NULL,
  variety_name_en text,
  primary_plant_id uuid NOT NULL REFERENCES flora_library(plant_id) ON DELETE CASCADE,
  secondary_plants uuid[],
  color text,
  color_code text,
  taste_profile jsonb,
  aroma text,
  texture text CHECK (texture IN ('liquid', 'creamy', 'crystallized', 'chunky')),
  crystallization_rate text CHECK (crystallization_rate IN ('very_slow', 'slow', 'moderate', 'fast', 'very_fast')),
  moisture_content numeric CHECK (moisture_content >= 0 AND moisture_content <= 100),
  medicinal_properties jsonb,
  market_value text CHECK (market_value IN ('budget', 'standard', 'premium', 'luxury')),
  production_regions text[],
  production_season jsonb,
  images text[],
  is_certified boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- جدول مواقع النباتات
CREATE TABLE IF NOT EXISTS plant_locations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plant_id uuid NOT NULL REFERENCES flora_library(plant_id) ON DELETE CASCADE,
  location_id uuid NOT NULL REFERENCES locations(location_id) ON DELETE CASCADE,
  abundance text CHECK (abundance IN ('rare', 'uncommon', 'common', 'abundant', 'dominant')),
  density text CHECK (density IN ('sparse', 'scattered', 'moderate', 'dense', 'very_dense')),
  accessibility text CHECK (accessibility IN ('difficult', 'moderate', 'easy')),
  notes text,
  created_at timestamptz DEFAULT now(),
  UNIQUE(plant_id, location_id)
);

-- جدول تقويم الإزهار
CREATE TABLE IF NOT EXISTS flowering_calendar (
  calendar_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plant_id uuid NOT NULL REFERENCES flora_library(plant_id) ON DELETE CASCADE,
  location_id uuid REFERENCES locations(location_id) ON DELETE CASCADE,
  climate_zone_id uuid REFERENCES climate_zones(zone_id) ON DELETE SET NULL,
  flowering_start_month integer CHECK (flowering_start_month >= 1 AND flowering_start_month <= 12),
  flowering_end_month integer CHECK (flowering_end_month >= 1 AND flowering_end_month <= 12),
  peak_flowering_month integer CHECK (peak_flowering_month >= 1 AND peak_flowering_month <= 12),
  flowering_duration_days integer,
  bloom_intensity text CHECK (bloom_intensity IN ('light', 'moderate', 'heavy', 'spectacular')),
  triggers jsonb,
  year_recorded integer,
  created_at timestamptz DEFAULT now()
);

-- جدول دليل زراعة النباتات
CREATE TABLE IF NOT EXISTS plant_cultivation_guide (
  guide_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plant_id uuid NOT NULL REFERENCES flora_library(plant_id) ON DELETE CASCADE,
  soil_requirements jsonb,
  water_requirements text CHECK (water_requirements IN ('very_low', 'low', 'moderate', 'high', 'very_high')),
  sunlight_requirements text CHECK (sunlight_requirements IN ('full_shade', 'partial_shade', 'partial_sun', 'full_sun')),
  temperature_range jsonb,
  planting_season jsonb,
  propagation_methods text[],
  spacing jsonb,
  care_instructions jsonb,
  common_pests text[],
  common_diseases text[],
  companion_plants uuid[],
  beekeeping_benefits text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(plant_id)
);

-- إنشاء الفهارس
CREATE INDEX IF NOT EXISTS idx_flora_library_family ON flora_library(family_id);
CREATE INDEX IF NOT EXISTS idx_flora_library_type ON flora_library(plant_type);
CREATE INDEX IF NOT EXISTS idx_flora_library_verified ON flora_library(is_verified);
CREATE INDEX IF NOT EXISTS idx_nectar_sources_plant ON nectar_sources(plant_id);
CREATE INDEX IF NOT EXISTS idx_nectar_sources_quality ON nectar_sources(nectar_quality);
CREATE INDEX IF NOT EXISTS idx_pollen_sources_plant ON pollen_sources(plant_id);
CREATE INDEX IF NOT EXISTS idx_pollen_sources_quality ON pollen_sources(pollen_quality);
CREATE INDEX IF NOT EXISTS idx_honey_varieties_primary_plant ON honey_varieties(primary_plant_id);
CREATE INDEX IF NOT EXISTS idx_plant_locations_plant ON plant_locations(plant_id);
CREATE INDEX IF NOT EXISTS idx_plant_locations_location ON plant_locations(location_id);
CREATE INDEX IF NOT EXISTS idx_flowering_calendar_plant ON flowering_calendar(plant_id);
CREATE INDEX IF NOT EXISTS idx_flowering_calendar_location ON flowering_calendar(location_id);
CREATE INDEX IF NOT EXISTS idx_flowering_calendar_month ON flowering_calendar(flowering_start_month, flowering_end_month);
CREATE INDEX IF NOT EXISTS idx_plant_cultivation_guide_plant ON plant_cultivation_guide(plant_id);

-- تفعيل RLS
ALTER TABLE plant_families ENABLE ROW LEVEL SECURITY;
ALTER TABLE flora_library ENABLE ROW LEVEL SECURITY;
ALTER TABLE nectar_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE pollen_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE honey_varieties ENABLE ROW LEVEL SECURITY;
ALTER TABLE plant_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE flowering_calendar ENABLE ROW LEVEL SECURITY;
ALTER TABLE plant_cultivation_guide ENABLE ROW LEVEL SECURITY;

-- سياسات (عامة للقراءة للجميع)
CREATE POLICY "Anyone can view plant families"
  ON plant_families FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Anyone can view flora library"
  ON flora_library FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Anyone can view nectar sources"
  ON nectar_sources FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Anyone can view pollen sources"
  ON pollen_sources FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Anyone can view honey varieties"
  ON honey_varieties FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Anyone can view plant locations"
  ON plant_locations FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Anyone can view flowering calendar"
  ON flowering_calendar FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Anyone can view cultivation guide"
  ON plant_cultivation_guide FOR SELECT
  TO authenticated
  USING (true);

-- سياسات الإضافة والتعديل للمشرفين
CREATE POLICY "Admins can manage plant families"
  ON plant_families FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN roles r ON ur.role_id = r.role_id
      WHERE ur.user_id = auth.uid() AND r.role_name = 'admin'
    )
  );

CREATE POLICY "Admins can manage flora library"
  ON flora_library FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN roles r ON ur.role_id = r.role_id
      WHERE ur.user_id = auth.uid() AND r.role_name = 'admin'
    )
  );