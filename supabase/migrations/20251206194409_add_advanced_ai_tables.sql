/*
  # إضافة جداول الذكاء الاصطناعي المتقدمة
  
  ## الجداول الجديدة
  
  ### 1. `ai_models` - نماذج الذكاء الاصطناعي
    - `model_id` (uuid, primary key) - معرف النموذج
    - `model_name` (text) - اسم النموذج
    - `model_type` (text) - نوع النموذج (disease_detection, production_forecast, colony_health, etc.)
    - `version` (text) - الإصدار
    - `description` (text) - الوصف
    - `architecture` (text) - البنية المعمارية
    - `framework` (text) - الإطار المستخدم (tensorflow, pytorch, etc.)
    - `input_schema` (jsonb) - مخطط الإدخال
    - `output_schema` (jsonb) - مخطط الإخراج
    - `model_url` (text) - رابط النموذج
    - `metrics` (jsonb) - المقاييس (accuracy, precision, recall, etc.)
    - `training_data_count` (integer) - عدد بيانات التدريب
    - `is_active` (boolean) - النموذج نشط
    - `created_by` (uuid) - أُنشئ بواسطة
    - `created_at` (timestamptz) - تاريخ الإنشاء
    - `updated_at` (timestamptz) - تاريخ التحديث
  
  ### 2. `ai_training_datasets` - مجموعات بيانات التدريب
    - `dataset_id` (uuid, primary key) - معرف مجموعة البيانات
    - `dataset_name` (text) - اسم مجموعة البيانات
    - `dataset_type` (text) - نوع البيانات (images, timeseries, structured, etc.)
    - `description` (text) - الوصف
    - `total_samples` (integer) - إجمالي العينات
    - `labeled_samples` (integer) - العينات المصنفة
    - `categories` (jsonb) - الفئات
    - `split_ratio` (jsonb) - نسب التقسيم (train, validation, test)
    - `storage_location` (text) - موقع التخزين
    - `metadata` (jsonb) - بيانات إضافية
    - `is_public` (boolean) - عام أم خاص
    - `created_by` (uuid) - أُنشئ بواسطة
    - `created_at` (timestamptz) - تاريخ الإنشاء
    - `updated_at` (timestamptz) - تاريخ التحديث
  
  ### 3. `ai_labeled_images` - الصور المصنفة للتدريب
    - `image_id` (uuid, primary key) - معرف الصورة
    - `dataset_id` (uuid) - معرف مجموعة البيانات
    - `user_id` (uuid) - معرف المستخدم
    - `hive_id` (uuid) - معرف الخلية
    - `inspection_id` (uuid) - معرف الفحص
    - `image_url` (text) - رابط الصورة
    - `thumbnail_url` (text) - رابط الصورة المصغرة
    - `label` (text) - التصنيف
    - `category` (text) - الفئة
    - `confidence` (numeric) - مستوى الثقة
    - `bbox` (jsonb) - إحداثيات الصندوق المحيط
    - `annotations` (jsonb) - التعليقات التوضيحية
    - `verified` (boolean) - تم التحقق
    - `verified_by` (uuid) - تم التحقق بواسطة
    - `verified_at` (timestamptz) - تاريخ التحقق
    - `metadata` (jsonb) - بيانات إضافية
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 4. `ai_predictions` - التنبؤات والتوقعات
    - `prediction_id` (uuid, primary key) - معرف التنبؤ
    - `model_id` (uuid) - معرف النموذج
    - `hive_id` (uuid) - معرف الخلية
    - `apiary_id` (uuid) - معرف المنحل
    - `prediction_type` (text) - نوع التنبؤ (disease, production, swarming, etc.)
    - `input_data` (jsonb) - بيانات الإدخال
    - `prediction_result` (jsonb) - نتيجة التنبؤ
    - `confidence_score` (numeric) - درجة الثقة
    - `risk_level` (text) - مستوى الخطر
    - `valid_from` (timestamptz) - صالح من
    - `valid_until` (timestamptz) - صالح حتى
    - `actual_outcome` (jsonb) - النتيجة الفعلية
    - `accuracy_feedback` (numeric) - تقييم الدقة
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 5. `ai_recommendations` - التوصيات الذكية
    - `recommendation_id` (uuid, primary key) - معرف التوصية
    - `user_id` (uuid) - معرف المستخدم
    - `hive_id` (uuid) - معرف الخلية
    - `apiary_id` (uuid) - معرف المنحل
    - `prediction_id` (uuid) - معرف التنبؤ المرتبط
    - `recommendation_type` (text) - نوع التوصية
    - `title` (text) - العنوان
    - `description` (text) - الوصف
    - `action_items` (jsonb) - بنود العمل
    - `priority` (text) - الأولوية
    - `urgency_score` (integer) - درجة الإلحاح
    - `estimated_impact` (text) - التأثير المتوقع
    - `reasoning` (text) - التبرير
    - `confidence` (numeric) - مستوى الثقة
    - `status` (text) - الحالة (pending, viewed, accepted, rejected, completed)
    - `user_feedback` (text) - ملاحظات المستخدم
    - `effectiveness_rating` (integer) - تقييم الفعالية
    - `created_at` (timestamptz) - تاريخ الإنشاء
    - `expires_at` (timestamptz) - تاريخ الانتهاء
    - `completed_at` (timestamptz) - تاريخ الإكمال
  
  ### 6. `ai_training_history` - سجل تدريب النماذج
    - `training_id` (uuid, primary key) - معرف التدريب
    - `model_id` (uuid) - معرف النموذج
    - `dataset_id` (uuid) - معرف مجموعة البيانات
    - `training_config` (jsonb) - إعدادات التدريب
    - `start_time` (timestamptz) - وقت البداية
    - `end_time` (timestamptz) - وقت الانتهاء
    - `duration_seconds` (integer) - المدة بالثواني
    - `epochs_completed` (integer) - عدد الدورات المكتملة
    - `final_metrics` (jsonb) - المقاييس النهائية
    - `loss_curve` (jsonb) - منحنى الخسارة
    - `accuracy_curve` (jsonb) - منحنى الدقة
    - `status` (text) - الحالة
    - `error_message` (text) - رسالة الخطأ
    - `created_by` (uuid) - أُنشئ بواسطة
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ## الأمان
    - تفعيل RLS على جميع الجداول
    - إضافة سياسات للتحكم في الوصول
*/

-- جدول نماذج الذكاء الاصطناعي
CREATE TABLE IF NOT EXISTS ai_models (
  model_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  model_name text NOT NULL,
  model_type text NOT NULL CHECK (model_type IN (
    'disease_detection', 'production_forecast', 'colony_health',
    'swarming_prediction', 'queen_quality', 'pest_detection',
    'honey_quality', 'weather_impact', 'resource_optimization'
  )),
  version text NOT NULL,
  description text,
  architecture text,
  framework text,
  input_schema jsonb,
  output_schema jsonb,
  model_url text,
  metrics jsonb,
  training_data_count integer DEFAULT 0,
  is_active boolean DEFAULT false,
  created_by uuid REFERENCES users(user_id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(model_name, version)
);

-- جدول مجموعات بيانات التدريب
CREATE TABLE IF NOT EXISTS ai_training_datasets (
  dataset_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  dataset_name text NOT NULL UNIQUE,
  dataset_type text NOT NULL CHECK (dataset_type IN ('images', 'timeseries', 'structured', 'mixed')),
  description text,
  total_samples integer DEFAULT 0,
  labeled_samples integer DEFAULT 0,
  categories jsonb,
  split_ratio jsonb DEFAULT '{"train": 0.7, "validation": 0.15, "test": 0.15}'::jsonb,
  storage_location text,
  metadata jsonb,
  is_public boolean DEFAULT false,
  created_by uuid REFERENCES users(user_id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- جدول الصور المصنفة
CREATE TABLE IF NOT EXISTS ai_labeled_images (
  image_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  dataset_id uuid REFERENCES ai_training_datasets(dataset_id) ON DELETE CASCADE,
  user_id uuid REFERENCES users(user_id),
  hive_id uuid REFERENCES hives(hive_id),
  inspection_id uuid REFERENCES inspections(inspection_id),
  image_url text NOT NULL,
  thumbnail_url text,
  label text NOT NULL,
  category text NOT NULL,
  confidence numeric CHECK (confidence >= 0 AND confidence <= 1),
  bbox jsonb,
  annotations jsonb,
  verified boolean DEFAULT false,
  verified_by uuid REFERENCES users(user_id),
  verified_at timestamptz,
  metadata jsonb,
  created_at timestamptz DEFAULT now()
);

-- جدول التنبؤات
CREATE TABLE IF NOT EXISTS ai_predictions (
  prediction_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  model_id uuid REFERENCES ai_models(model_id) ON DELETE SET NULL,
  hive_id uuid REFERENCES hives(hive_id) ON DELETE CASCADE,
  apiary_id uuid REFERENCES apiaries(apiary_id) ON DELETE CASCADE,
  prediction_type text NOT NULL,
  input_data jsonb,
  prediction_result jsonb NOT NULL,
  confidence_score numeric CHECK (confidence_score >= 0 AND confidence_score <= 1),
  risk_level text CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
  valid_from timestamptz DEFAULT now(),
  valid_until timestamptz,
  actual_outcome jsonb,
  accuracy_feedback numeric CHECK (accuracy_feedback >= 0 AND accuracy_feedback <= 1),
  created_at timestamptz DEFAULT now()
);

-- جدول التوصيات الذكية
CREATE TABLE IF NOT EXISTS ai_recommendations (
  recommendation_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  hive_id uuid REFERENCES hives(hive_id) ON DELETE CASCADE,
  apiary_id uuid REFERENCES apiaries(apiary_id) ON DELETE CASCADE,
  prediction_id uuid REFERENCES ai_predictions(prediction_id) ON DELETE SET NULL,
  recommendation_type text NOT NULL CHECK (recommendation_type IN (
    'inspection', 'feeding', 'treatment', 'harvest',
    'queen_replacement', 'pest_control', 'maintenance',
    'swarming_prevention', 'winter_preparation'
  )),
  title text NOT NULL,
  description text,
  action_items jsonb,
  priority text DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  urgency_score integer CHECK (urgency_score >= 0 AND urgency_score <= 100),
  estimated_impact text,
  reasoning text,
  confidence numeric CHECK (confidence >= 0 AND confidence <= 1),
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'viewed', 'accepted', 'rejected', 'completed')),
  user_feedback text,
  effectiveness_rating integer CHECK (effectiveness_rating >= 1 AND effectiveness_rating <= 5),
  created_at timestamptz DEFAULT now(),
  expires_at timestamptz,
  completed_at timestamptz
);

-- جدول سجل تدريب النماذج
CREATE TABLE IF NOT EXISTS ai_training_history (
  training_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  model_id uuid REFERENCES ai_models(model_id) ON DELETE CASCADE,
  dataset_id uuid REFERENCES ai_training_datasets(dataset_id) ON DELETE SET NULL,
  training_config jsonb,
  start_time timestamptz DEFAULT now(),
  end_time timestamptz,
  duration_seconds integer,
  epochs_completed integer DEFAULT 0,
  final_metrics jsonb,
  loss_curve jsonb,
  accuracy_curve jsonb,
  status text DEFAULT 'running' CHECK (status IN ('running', 'completed', 'failed', 'cancelled')),
  error_message text,
  created_by uuid REFERENCES users(user_id),
  created_at timestamptz DEFAULT now()
);

-- إنشاء الفهارس
CREATE INDEX IF NOT EXISTS idx_ai_models_type ON ai_models(model_type);
CREATE INDEX IF NOT EXISTS idx_ai_models_active ON ai_models(is_active);
CREATE INDEX IF NOT EXISTS idx_ai_training_datasets_type ON ai_training_datasets(dataset_type);
CREATE INDEX IF NOT EXISTS idx_ai_labeled_images_dataset ON ai_labeled_images(dataset_id);
CREATE INDEX IF NOT EXISTS idx_ai_labeled_images_hive ON ai_labeled_images(hive_id);
CREATE INDEX IF NOT EXISTS idx_ai_labeled_images_label ON ai_labeled_images(label);
CREATE INDEX IF NOT EXISTS idx_ai_predictions_hive ON ai_predictions(hive_id);
CREATE INDEX IF NOT EXISTS idx_ai_predictions_apiary ON ai_predictions(apiary_id);
CREATE INDEX IF NOT EXISTS idx_ai_predictions_type ON ai_predictions(prediction_type);
CREATE INDEX IF NOT EXISTS idx_ai_recommendations_user ON ai_recommendations(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_recommendations_hive ON ai_recommendations(hive_id);
CREATE INDEX IF NOT EXISTS idx_ai_recommendations_status ON ai_recommendations(status);
CREATE INDEX IF NOT EXISTS idx_ai_training_history_model ON ai_training_history(model_id);

-- تفعيل RLS
ALTER TABLE ai_models ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_training_datasets ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_labeled_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_training_history ENABLE ROW LEVEL SECURITY;

-- سياسات ai_models (يمكن للجميع القراءة، والمشرفين الكتابة)
CREATE POLICY "Anyone can view AI models"
  ON ai_models FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage AI models"
  ON ai_models FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN roles r ON ur.role_id = r.role_id
      WHERE ur.user_id = auth.uid() AND r.role_name = 'admin'
    )
  );

-- سياسات ai_training_datasets
CREATE POLICY "Users can view public datasets"
  ON ai_training_datasets FOR SELECT
  TO authenticated
  USING (is_public = true OR created_by = auth.uid());

CREATE POLICY "Users can create datasets"
  ON ai_training_datasets FOR INSERT
  TO authenticated
  WITH CHECK (created_by = auth.uid());

CREATE POLICY "Users can update own datasets"
  ON ai_training_datasets FOR UPDATE
  TO authenticated
  USING (created_by = auth.uid())
  WITH CHECK (created_by = auth.uid());

-- سياسات ai_labeled_images
CREATE POLICY "Users can view labeled images"
  ON ai_labeled_images FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM ai_training_datasets
      WHERE ai_training_datasets.dataset_id = ai_labeled_images.dataset_id
      AND (ai_training_datasets.is_public = true OR ai_training_datasets.created_by = auth.uid())
    )
  );

CREATE POLICY "Users can insert labeled images"
  ON ai_labeled_images FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- سياسات ai_predictions
CREATE POLICY "Users can view predictions for their apiaries"
  ON ai_predictions FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM apiaries
      WHERE apiaries.apiary_id = ai_predictions.apiary_id
      AND apiaries.owner_id = auth.uid()
    )
  );

-- سياسات ai_recommendations
CREATE POLICY "Users can view own recommendations"
  ON ai_recommendations FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own recommendations"
  ON ai_recommendations FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- سياسات ai_training_history
CREATE POLICY "Users can view training history"
  ON ai_training_history FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage training history"
  ON ai_training_history FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN roles r ON ur.role_id = r.role_id
      WHERE ur.user_id = auth.uid() AND r.role_name = 'admin'
    )
  );