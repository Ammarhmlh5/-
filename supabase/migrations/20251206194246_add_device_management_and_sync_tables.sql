/*
  # إضافة جداول إدارة الأجهزة والمزامنة
  
  ## الجداول الجديدة
  
  ### 1. `device_tokens` - أجهزة المستخدمين
    - `device_id` (uuid, primary key) - معرف الجهاز
    - `user_id` (uuid) - معرف المستخدم
    - `device_type` (text) - نوع الجهاز (ios, android, web)
    - `device_name` (text) - اسم الجهاز
    - `push_token` (text) - رمز الإشعارات Push
    - `app_version` (text) - إصدار التطبيق
    - `os_version` (text) - إصدار نظام التشغيل
    - `is_active` (boolean) - الجهاز نشط
    - `last_active_at` (timestamptz) - آخر نشاط
    - `created_at` (timestamptz) - تاريخ الإنشاء
    - `updated_at` (timestamptz) - تاريخ التحديث
  
  ### 2. `offline_sync_queue` - قائمة انتظار المزامنة
    - `sync_queue_id` (uuid, primary key) - معرف قائمة الانتظار
    - `device_id` (uuid) - معرف الجهاز
    - `user_id` (uuid) - معرف المستخدم
    - `entity_type` (text) - نوع الكيان (inspection, feeding, harvest, etc.)
    - `entity_id` (uuid) - معرف الكيان
    - `operation` (text) - العملية (create, update, delete)
    - `data` (jsonb) - البيانات
    - `sync_status` (text) - حالة المزامنة (pending, syncing, synced, failed)
    - `priority` (integer) - الأولوية
    - `retry_count` (integer) - عدد المحاولات
    - `last_error` (text) - آخر خطأ
    - `client_timestamp` (timestamptz) - وقت العميل
    - `synced_at` (timestamptz) - وقت المزامنة
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 3. `sync_conflicts` - تعارضات المزامنة
    - `conflict_id` (uuid, primary key) - معرف التعارض
    - `sync_queue_id` (uuid) - معرف قائمة الانتظار
    - `entity_type` (text) - نوع الكيان
    - `entity_id` (uuid) - معرف الكيان
    - `local_data` (jsonb) - البيانات المحلية
    - `server_data` (jsonb) - بيانات الخادم
    - `resolution_strategy` (text) - استراتيجية الحل
    - `resolved` (boolean) - تم الحل
    - `resolved_by` (uuid) - حلها بواسطة
    - `resolved_at` (timestamptz) - وقت الحل
    - `created_at` (timestamptz) - تاريخ الإنشاء
  
  ### 4. `device_sync_state` - حالة مزامنة الأجهزة
    - `state_id` (uuid, primary key) - معرف الحالة
    - `device_id` (uuid) - معرف الجهاز
    - `entity_type` (text) - نوع الكيان
    - `last_sync_at` (timestamptz) - آخر مزامنة
    - `last_sync_version` (bigint) - آخر إصدار للمزامنة
    - `pending_changes_count` (integer) - عدد التغييرات المعلقة
    - `updated_at` (timestamptz) - تاريخ التحديث
  
  ## الأمان
    - تفعيل RLS على جميع الجداول
    - إضافة سياسات للتحكم في الوصول
*/

-- جدول أجهزة المستخدمين
CREATE TABLE IF NOT EXISTS device_tokens (
  device_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  device_type text NOT NULL CHECK (device_type IN ('ios', 'android', 'web', 'tablet')),
  device_name text,
  push_token text,
  app_version text,
  os_version text,
  is_active boolean DEFAULT true,
  last_active_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- جدول قائمة انتظار المزامنة
CREATE TABLE IF NOT EXISTS offline_sync_queue (
  sync_queue_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id uuid REFERENCES device_tokens(device_id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  entity_type text NOT NULL,
  entity_id uuid,
  operation text NOT NULL CHECK (operation IN ('create', 'update', 'delete')),
  data jsonb,
  sync_status text DEFAULT 'pending' CHECK (sync_status IN ('pending', 'syncing', 'synced', 'failed', 'conflict')),
  priority integer DEFAULT 5,
  retry_count integer DEFAULT 0,
  last_error text,
  client_timestamp timestamptz NOT NULL,
  synced_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- جدول تعارضات المزامنة
CREATE TABLE IF NOT EXISTS sync_conflicts (
  conflict_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sync_queue_id uuid REFERENCES offline_sync_queue(sync_queue_id) ON DELETE CASCADE,
  entity_type text NOT NULL,
  entity_id uuid NOT NULL,
  local_data jsonb,
  server_data jsonb,
  resolution_strategy text CHECK (resolution_strategy IN ('server_wins', 'client_wins', 'manual', 'merge')),
  resolved boolean DEFAULT false,
  resolved_by uuid REFERENCES users(user_id),
  resolved_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- جدول حالة مزامنة الأجهزة
CREATE TABLE IF NOT EXISTS device_sync_state (
  state_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id uuid NOT NULL REFERENCES device_tokens(device_id) ON DELETE CASCADE,
  entity_type text NOT NULL,
  last_sync_at timestamptz,
  last_sync_version bigint DEFAULT 0,
  pending_changes_count integer DEFAULT 0,
  updated_at timestamptz DEFAULT now(),
  UNIQUE(device_id, entity_type)
);

-- إنشاء الفهارس
CREATE INDEX IF NOT EXISTS idx_device_tokens_user_id ON device_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_device_tokens_push_token ON device_tokens(push_token);
CREATE INDEX IF NOT EXISTS idx_offline_sync_queue_user_id ON offline_sync_queue(user_id);
CREATE INDEX IF NOT EXISTS idx_offline_sync_queue_device_id ON offline_sync_queue(device_id);
CREATE INDEX IF NOT EXISTS idx_offline_sync_queue_status ON offline_sync_queue(sync_status);
CREATE INDEX IF NOT EXISTS idx_offline_sync_queue_entity ON offline_sync_queue(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_sync_conflicts_resolved ON sync_conflicts(resolved);
CREATE INDEX IF NOT EXISTS idx_device_sync_state_device ON device_sync_state(device_id);

-- تفعيل RLS
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE offline_sync_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_conflicts ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_sync_state ENABLE ROW LEVEL SECURITY;

-- سياسات device_tokens
CREATE POLICY "Users can view own devices"
  ON device_tokens FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own devices"
  ON device_tokens FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own devices"
  ON device_tokens FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own devices"
  ON device_tokens FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- سياسات offline_sync_queue
CREATE POLICY "Users can view own sync queue"
  ON offline_sync_queue FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own sync queue"
  ON offline_sync_queue FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own sync queue"
  ON offline_sync_queue FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own sync queue"
  ON offline_sync_queue FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- سياسات sync_conflicts
CREATE POLICY "Users can view own sync conflicts"
  ON sync_conflicts FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM offline_sync_queue
      WHERE offline_sync_queue.sync_queue_id = sync_conflicts.sync_queue_id
      AND offline_sync_queue.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update own sync conflicts"
  ON sync_conflicts FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM offline_sync_queue
      WHERE offline_sync_queue.sync_queue_id = sync_conflicts.sync_queue_id
      AND offline_sync_queue.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM offline_sync_queue
      WHERE offline_sync_queue.sync_queue_id = sync_conflicts.sync_queue_id
      AND offline_sync_queue.user_id = auth.uid()
    )
  );

-- سياسات device_sync_state
CREATE POLICY "Users can view own device sync state"
  ON device_sync_state FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM device_tokens
      WHERE device_tokens.device_id = device_sync_state.device_id
      AND device_tokens.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert own device sync state"
  ON device_sync_state FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM device_tokens
      WHERE device_tokens.device_id = device_sync_state.device_id
      AND device_tokens.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update own device sync state"
  ON device_sync_state FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM device_tokens
      WHERE device_tokens.device_id = device_sync_state.device_id
      AND device_tokens.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM device_tokens
      WHERE device_tokens.device_id = device_sync_state.device_id
      AND device_tokens.user_id = auth.uid()
    )
  );