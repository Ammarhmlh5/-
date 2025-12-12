export interface User {
  id: string;
  email: string;
  full_name?: string;
  phone?: string;
  created_at: string;
}

export interface Apiary {
  apiary_id: string;
  owner_id: string;
  name: string;
  description?: string;
  type: 'fixed' | 'mobile';
  latitude?: number;
  longitude?: number;
  altitude?: number;
  region?: string;
  hive_count?: number;
  created_at: string;
  updated_at: string;
}

export interface Hive {
  hive_id: string;
  apiary_id: string;
  hive_number: string;
  hive_type: string;
  queen_age_months?: number;
  frame_count?: number;
  status: 'active' | 'inactive' | 'swarmed' | 'queenless';
  health_status?: 'excellent' | 'good' | 'fair' | 'poor';
  last_inspection_date?: string;
  notes?: string;
  created_at: string;
  updated_at: string;
}

export interface Inspection {
  id: string;
  hive_id: string;
  inspection_date: string;
  inspector_name?: string;
  queen_seen: boolean;
  eggs_seen: boolean;
  larvae_seen: boolean;
  capped_brood_seen: boolean;
  temperament: 'calm' | 'defensive' | 'aggressive';
  population_estimate: 'weak' | 'medium' | 'strong' | 'very_strong';
  honey_stores: 'none' | 'low' | 'medium' | 'high' | 'full';
  pollen_stores: 'none' | 'low' | 'medium' | 'high';
  diseases_found?: string;
  pests_found?: string;
  treatments_applied?: string;
  feeding_done: boolean;
  frames_added?: number;
  frames_removed?: number;
  weather_conditions?: string;
  temperature_celsius?: number;
  notes?: string;
  overall_health: 'excellent' | 'good' | 'fair' | 'poor' | 'critical';
  created_at: string;
}

export interface Production {
  id: string;
  hive_id: string;
  production_date: string;
  product_type: 'honey' | 'wax' | 'propolis' | 'royal_jelly' | 'pollen';
  quantity_kg: number;
  quality_grade?: string;
  notes?: string;
  created_at: string;
}

export interface Feeding {
  feeding_id: string;
  hive_id: string;
  feeding_type: 'syrup' | 'pollen_sub' | 'protein' | 'vitamins' | 'candy';
  amount?: number;
  unit?: string;
  feeding_date: string;
  reason?: string;
  notes?: string;
  created_at: string;
}

export interface Alert {
  id: string;
  user_id: string;
  hive_id?: string;
  apiary_id?: string;
  alert_type: 'inspection_due' | 'health_issue' | 'weather_warning' | 'production_anomaly' | 'recommendation';
  severity: 'info' | 'warning' | 'critical';
  title: string;
  message: string;
  is_read: boolean;
  action_required: boolean;
  created_at: string;
}

export interface Flora {
  id: string;
  common_name_ar: string;
  common_name_en?: string;
  scientific_name?: string;
  description_ar?: string;
  bloom_season_start?: number;
  bloom_season_end?: number;
  nectar_quality: 'excellent' | 'good' | 'fair' | 'poor';
  pollen_quality: 'excellent' | 'good' | 'fair' | 'poor';
  region?: string;
  image_url?: string;
  created_at: string;
}

export interface WeatherData {
  id: string;
  location_id: string;
  recorded_at: string;
  temperature_celsius: number;
  humidity_percent: number;
  wind_speed_kmh: number;
  precipitation_mm: number;
  conditions: string;
}

export interface Analytics {
  totalApiaries: number;
  totalHives: number;
  activeHives: number;
  monthlyProduction: number;
  productionChange: number;
  averageHiveHealth: number;
  inspectionsDue: number;
  criticalAlerts: number;
}

export interface DashboardStats {
  label: string;
  value: string | number;
  change?: string;
  trend?: 'up' | 'down' | 'neutral';
  icon?: string;
}

export type ViewMode = 'grid' | 'list' | 'map';
export type SortOrder = 'asc' | 'desc';
