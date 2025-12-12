import { supabase } from '../lib/supabase';
import { Analytics } from '../types';

export const analyticsService = {
  async getDashboardStats(userId: string): Promise<Analytics> {
    const { data: apiaries } = await supabase
      .from('apiaries')
      .select('apiary_id')
      .eq('owner_id', userId);

    const apiaryIds = apiaries?.map((a: any) => a.apiary_id) || [];

    const { data: hives } = await supabase
      .from('hives')
      .select('hive_id, status, health_status')
      .in('apiary_id', apiaryIds);

    const activeHives = hives?.filter((h: any) => h.status === 'active').length || 0;

    const avgHealth = hives && hives.length > 0
      ? hives.reduce((sum: number, h: any) => {
          const healthScore = h.health_status === 'excellent' ? 4 :
                             h.health_status === 'good' ? 3 :
                             h.health_status === 'fair' ? 2 : 1;
          return sum + healthScore;
        }, 0) / hives.length
      : 0;

    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const { data: production } = await supabase
      .from('production')
      .select('quantity_kg')
      .gte('production_date', thirtyDaysAgo.toISOString())
      .eq('product_type', 'honey');

    const monthlyProduction = production?.reduce((sum: number, p: any) => sum + p.quantity_kg, 0) || 0;

    const { data: alerts } = await supabase
      .from('smart_alerts')
      .select('id, severity')
      .eq('user_id', userId)
      .eq('is_read', false);

    const criticalAlerts = alerts?.filter((a: any) => a.severity === 'critical').length || 0;
    const inspectionsDue = alerts?.filter((a: any) => a.alert_type === 'inspection_due').length || 0;

    return {
      totalApiaries: apiaries?.length || 0,
      totalHives: hives?.length || 0,
      activeHives,
      monthlyProduction,
      productionChange: 0,
      averageHiveHealth: Math.round(avgHealth * 25),
      inspectionsDue,
      criticalAlerts,
    };
  },

  async getProductionTrend(userId: string, months: number = 6) {
    const { data: apiaries } = await supabase
      .from('apiaries')
      .select('apiary_id')
      .eq('owner_id', userId);

    const apiaryIds = apiaries?.map((a: any) => a.apiary_id) || [];

    const { data: hiveIds } = await supabase
      .from('hives')
      .select('hive_id')
      .in('apiary_id', apiaryIds);

    const hiveIdsList = hiveIds?.map((h: any) => h.hive_id) || [];

    const startDate = new Date();
    startDate.setMonth(startDate.getMonth() - months);

    const { data, error } = await supabase
      .from('production')
      .select('production_date, quantity_kg, product_type')
      .in('hive_id', hiveIdsList)
      .gte('production_date', startDate.toISOString())
      .order('production_date', { ascending: true });

    if (error) throw error;
    return data || [];
  },
};
