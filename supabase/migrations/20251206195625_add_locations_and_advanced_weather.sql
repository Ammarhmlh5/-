/*
  # إضافة جداول المواقع والطقس المتقدمة
  
  ## الجداول الجديدة
  
  ### 1. `locations` - المواقع الجغرافية
    - `location_id` (uuid, primary key) - معرف الموقع
    - `name_ar` (text) - الاسم بالعربية
    - `name_en` (text) - الاسم بالإنجليزية
    - `location_type` (text) - نوع الموقع (country, region, city, district)
    - `parent_location_id` (uuid) - الموقع الأب
    - `latitude` (numeric) - خط العرض
    - `longitude` (numeric) - خط الطول
    - `elevation` (numeric) - الارتفاع
    - `area_km2` (numeric) - المساحة بالكيلومتر المربع
    - `population` (integer) - عدد السكان
    - `timezone` (text) - المنطقة الزمنية
    - `country_code` (text) - رمز الدولة
    - `postal_code` (text) - الرمز البريدي
    - `is_active` (boolean) - نشط
    - `metadata` (jsonb) - بيانات إضافية
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 2. `climate_zones` - المناطق المناخية
    - `zone_id` (uuid, primary key) - معرف المنطقة
    - `zone_name` (text) - اسم المنطقة المناخية
    - `zone_code` (text) - رمز المنطقة
    - `description` (text) - الوصف
    - `temperature_range` (jsonb) - نطاق الحرارة
    - `humidity_range` (jsonb) - نطاق الرطوبة
    - `rainfall_range` (jsonb) - نطاق الأمطار
    - `characteristics` (jsonb) - الخصائص
    - `suitable_plants` (text[]) - النباتات المناسبة
    - `beekeeping_conditions` (jsonb) - ظروف النحل
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 3. `location_climate_zones` - ربط المواقع بالمناطق المناخية
    - `id` (uuid, primary key) - المعرف
    - `location_id` (uuid) - معرف الموقع
    - `climate_zone_id` (uuid) - معرف المنطقة المناخية
    - `coverage_percentage` (numeric) - نسبة التغطية
    - `notes` (text) - ملاحظات
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 4. `weather_stations` - محطات الطقس
    - `station_id` (uuid, primary key) - معرف المحطة
    - `station_code` (text) - رمز المحطة
    - `station_name` (text) - اسم المحطة
    - `location_id` (uuid) - معرف الموقع
    - `latitude` (numeric) - خط العرض
    - `longitude` (numeric) - خط الطول
    - `elevation` (numeric) - الارتفاع
    - `station_type` (text) - نوع المحطة
    - `data_provider` (text) - مزود البيانات
    - `is_active` (boolean) - نشطة
    - `last_reading_at` (timestamptz) - آخر قراءة
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 5. `precipitation_data` - بيانات هطول الأمطار
    - `precipitation_id` (uuid, primary key) - معرف البيانات
    - `location_id` (uuid) - معرف الموقع
    - `station_id` (uuid) - معرف المحطة
    - `date` (date) - التاريخ
    - `hour` (integer) - الساعة
    - `precipitation_amount` (numeric) - كمية الهطول (mm)
    - `precipitation_type` (text) - نوع الهطول
    - `intensity` (text) - الشدة
    - `duration_minutes` (integer) - المدة بالدقائق
    - `accumulation_24h` (numeric) - التراكم 24 ساعة
    - `accumulation_7d` (numeric) - التراكم 7 أيام
    - `accumulation_30d` (numeric) - التراكم 30 يوم
    - `is_forecast` (boolean) - توقع أم قياس فعلي
    - `data_quality` (text) - جودة البيانات
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 6. `extended_weather_forecasts` - توقعات الطقس الممتدة
    - `forecast_id` (uuid, primary key) - معرف التوقع
    - `location_id` (uuid) - معرف الموقع
    - `forecast_date` (date) - تاريخ التوقع
    - `forecast_time` (time) - وقت التوقع
    - `issued_at` (timestamptz) - وقت الإصدار
    - `forecast_horizon` (text) - أفق التوقع (hourly, daily, weekly)
    - `temperature_min` (numeric) - أقل حرارة
    - `temperature_max` (numeric) - أعلى حرارة
    - `temperature_avg` (numeric) - متوسط الحرارة
    - `humidity` (numeric) - الرطوبة
    - `wind_speed` (numeric) - سرعة الرياح
    - `wind_direction` (text) - اتجاه الرياح
    - `precipitation_probability` (numeric) - احتمالية الهطول
    - `precipitation_amount` (numeric) - كمية الهطول المتوقعة
    - `cloud_cover` (numeric) - الغطاء السحابي
    - `uv_index` (numeric) - مؤشر الأشعة فوق البنفسجية
    - `air_quality_index` (numeric) - مؤشر جودة الهواء
    - `conditions` (text) - حالة الطقس
    - `foraging_conditions` (text) - ظروف البحث عن الطعام للنحل
    - `flight_conditions` (text) - ظروف الطيران للنحل
    - `confidence_level` (numeric) - مستوى الثقة
    - `data_source` (text) - مصدر البيانات
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 7. `seasonal_weather_patterns` - أنماط الطقس الموسمية
    - `pattern_id` (uuid, primary key) - معرف النمط
    - `location_id` (uuid) - معرف الموقع
    - `month` (integer) - الشهر
    - `season` (text) - الموسم
    - `avg_temp_min` (numeric) - متوسط أقل حرارة
    - `avg_temp_max` (numeric) - متوسط أعلى حرارة
    - `avg_humidity` (numeric) - متوسط الرطوبة
    - `avg_precipitation` (numeric) - متوسط الهطول
    - `rainy_days_avg` (numeric) - متوسط الأيام الممطرة
    - `sunshine_hours` (numeric) - ساعات الشمس
    - `typical_conditions` (jsonb) - الظروف النموذجية
    - `beekeeping_activities` (jsonb) - أنشطة النحل الموصى بها
    - `historical_data_years` (integer) - عدد السنوات التاريخية
    - `last_updated` (timestamptz) - آخر تحديث
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ## الأمان
    - تفعيل RLS على الجداول المطلوبة
    - إضافة سياسات للتحكم في الوصول
*/

-- جدول المواقع الجغرافية
CREATE TABLE IF NOT EXISTS locations (
  location_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name_ar text NOT NULL,
  name_en text,
  location_type text NOT NULL CHECK (location_type IN ('country', 'region', 'city', 'district', 'village')),
  parent_location_id uuid REFERENCES locations(location_id) ON DELETE CASCADE,
  latitude numeric,
  longitude numeric,
  elevation numeric,
  area_km2 numeric,
  population integer,
  timezone text DEFAULT 'Asia/Riyadh',
  country_code text,
  postal_code text,
  is_active boolean DEFAULT true,
  metadata jsonb,
  created_at timestamptz DEFAULT now()
);

-- جدول المناطق المناخية
CREATE TABLE IF NOT EXISTS climate_zones (
  zone_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  zone_name text NOT NULL UNIQUE,
  zone_code text UNIQUE,
  description text,
  temperature_range jsonb,
  humidity_range jsonb,
  rainfall_range jsonb,
  characteristics jsonb,
  suitable_plants text[],
  beekeeping_conditions jsonb,
  created_at timestamptz DEFAULT now()
);

-- جدول ربط المواقع بالمناطق المناخية
CREATE TABLE IF NOT EXISTS location_climate_zones (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  location_id uuid NOT NULL REFERENCES locations(location_id) ON DELETE CASCADE,
  climate_zone_id uuid NOT NULL REFERENCES climate_zones(zone_id) ON DELETE CASCADE,
  coverage_percentage numeric CHECK (coverage_percentage >= 0 AND coverage_percentage <= 100),
  notes text,
  created_at timestamptz DEFAULT now(),
  UNIQUE(location_id, climate_zone_id)
);

-- جدول محطات الطقس
CREATE TABLE IF NOT EXISTS weather_stations (
  station_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  station_code text UNIQUE NOT NULL,
  station_name text NOT NULL,
  location_id uuid REFERENCES locations(location_id) ON DELETE SET NULL,
  latitude numeric NOT NULL,
  longitude numeric NOT NULL,
  elevation numeric,
  station_type text CHECK (station_type IN ('automatic', 'manual', 'hybrid', 'satellite')),
  data_provider text,
  is_active boolean DEFAULT true,
  last_reading_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- جدول بيانات هطول الأمطار
CREATE TABLE IF NOT EXISTS precipitation_data (
  precipitation_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  location_id uuid REFERENCES locations(location_id) ON DELETE CASCADE,
  station_id uuid REFERENCES weather_stations(station_id) ON DELETE SET NULL,
  date date NOT NULL,
  hour integer CHECK (hour >= 0 AND hour <= 23),
  precipitation_amount numeric DEFAULT 0 CHECK (precipitation_amount >= 0),
  precipitation_type text CHECK (precipitation_type IN ('rain', 'drizzle', 'snow', 'sleet', 'hail', 'mixed')),
  intensity text CHECK (intensity IN ('light', 'moderate', 'heavy', 'violent')),
  duration_minutes integer,
  accumulation_24h numeric DEFAULT 0,
  accumulation_7d numeric DEFAULT 0,
  accumulation_30d numeric DEFAULT 0,
  is_forecast boolean DEFAULT false,
  data_quality text DEFAULT 'good' CHECK (data_quality IN ('excellent', 'good', 'fair', 'poor')),
  created_at timestamptz DEFAULT now()
);

-- جدول توقعات الطقس الممتدة
CREATE TABLE IF NOT EXISTS extended_weather_forecasts (
  forecast_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  location_id uuid NOT NULL REFERENCES locations(location_id) ON DELETE CASCADE,
  forecast_date date NOT NULL,
  forecast_time time,
  issued_at timestamptz DEFAULT now(),
  forecast_horizon text CHECK (forecast_horizon IN ('hourly', 'daily', 'weekly', 'monthly')),
  temperature_min numeric,
  temperature_max numeric,
  temperature_avg numeric,
  humidity numeric CHECK (humidity >= 0 AND humidity <= 100),
  wind_speed numeric,
  wind_direction text,
  precipitation_probability numeric CHECK (precipitation_probability >= 0 AND precipitation_probability <= 100),
  precipitation_amount numeric,
  cloud_cover numeric CHECK (cloud_cover >= 0 AND cloud_cover <= 100),
  uv_index numeric CHECK (uv_index >= 0 AND uv_index <= 15),
  air_quality_index numeric,
  conditions text,
  foraging_conditions text CHECK (foraging_conditions IN ('excellent', 'good', 'fair', 'poor', 'unsuitable')),
  flight_conditions text CHECK (flight_conditions IN ('excellent', 'good', 'fair', 'poor', 'dangerous')),
  confidence_level numeric CHECK (confidence_level >= 0 AND confidence_level <= 1),
  data_source text,
  created_at timestamptz DEFAULT now()
);

-- جدول أنماط الطقس الموسمية
CREATE TABLE IF NOT EXISTS seasonal_weather_patterns (
  pattern_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  location_id uuid NOT NULL REFERENCES locations(location_id) ON DELETE CASCADE,
  month integer NOT NULL CHECK (month >= 1 AND month <= 12),
  season text CHECK (season IN ('spring', 'summer', 'fall', 'winter')),
  avg_temp_min numeric,
  avg_temp_max numeric,
  avg_humidity numeric,
  avg_precipitation numeric,
  rainy_days_avg numeric,
  sunshine_hours numeric,
  typical_conditions jsonb,
  beekeeping_activities jsonb,
  historical_data_years integer DEFAULT 10,
  last_updated timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  UNIQUE(location_id, month)
);

-- إنشاء الفهارس
CREATE INDEX IF NOT EXISTS idx_locations_parent ON locations(parent_location_id);
CREATE INDEX IF NOT EXISTS idx_locations_type ON locations(location_type);
CREATE INDEX IF NOT EXISTS idx_locations_country_code ON locations(country_code);
CREATE INDEX IF NOT EXISTS idx_locations_coordinates ON locations(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_location_climate_zones_location ON location_climate_zones(location_id);
CREATE INDEX IF NOT EXISTS idx_location_climate_zones_zone ON location_climate_zones(climate_zone_id);
CREATE INDEX IF NOT EXISTS idx_weather_stations_location ON weather_stations(location_id);
CREATE INDEX IF NOT EXISTS idx_weather_stations_active ON weather_stations(is_active);
CREATE INDEX IF NOT EXISTS idx_precipitation_data_location ON precipitation_data(location_id);
CREATE INDEX IF NOT EXISTS idx_precipitation_data_date ON precipitation_data(date);
CREATE INDEX IF NOT EXISTS idx_precipitation_data_station ON precipitation_data(station_id);
CREATE INDEX IF NOT EXISTS idx_extended_forecasts_location ON extended_weather_forecasts(location_id);
CREATE INDEX IF NOT EXISTS idx_extended_forecasts_date ON extended_weather_forecasts(forecast_date);
CREATE INDEX IF NOT EXISTS idx_seasonal_patterns_location ON seasonal_weather_patterns(location_id);
CREATE INDEX IF NOT EXISTS idx_seasonal_patterns_month ON seasonal_weather_patterns(month);

-- تفعيل RLS للجداول التي تحتاج حماية
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE climate_zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE location_climate_zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE weather_stations ENABLE ROW LEVEL SECURITY;
ALTER TABLE precipitation_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE extended_weather_forecasts ENABLE ROW LEVEL SECURITY;
ALTER TABLE seasonal_weather_patterns ENABLE ROW LEVEL SECURITY;

-- سياسات locations (عامة للقراءة)
CREATE POLICY "Anyone can view locations"
  ON locations FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage locations"
  ON locations FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN roles r ON ur.role_id = r.role_id
      WHERE ur.user_id = auth.uid() AND r.role_name = 'admin'
    )
  );

-- سياسات climate_zones (عامة للقراءة)
CREATE POLICY "Anyone can view climate zones"
  ON climate_zones FOR SELECT
  TO authenticated
  USING (true);

-- سياسات location_climate_zones (عامة للقراءة)
CREATE POLICY "Anyone can view location climate zones"
  ON location_climate_zones FOR SELECT
  TO authenticated
  USING (true);

-- سياسات weather_stations (عامة للقراءة)
CREATE POLICY "Anyone can view weather stations"
  ON weather_stations FOR SELECT
  TO authenticated
  USING (true);

-- سياسات precipitation_data (عامة للقراءة)
CREATE POLICY "Anyone can view precipitation data"
  ON precipitation_data FOR SELECT
  TO authenticated
  USING (true);

-- سياسات extended_weather_forecasts (عامة للقراءة)
CREATE POLICY "Anyone can view extended forecasts"
  ON extended_weather_forecasts FOR SELECT
  TO authenticated
  USING (true);

-- سياسات seasonal_weather_patterns (عامة للقراءة)
CREATE POLICY "Anyone can view seasonal patterns"
  ON seasonal_weather_patterns FOR SELECT
  TO authenticated
  USING (true);