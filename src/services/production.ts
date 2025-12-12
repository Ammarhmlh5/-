import { supabase } from '../lib/supabase';
import { Production } from '../types';

export const productionService = {
  async getAll(hiveId?: string): Promise<Production[]> {
    let query = supabase
      .from('production')
      .select('*')
      .order('production_date', { ascending: false });

    if (hiveId) {
      query = query.eq('hive_id', hiveId);
    }

    const { data, error } = await query;

    if (error) throw error;
    return data || [];
  },

  async create(production: Omit<Production, 'id' | 'created_at'>): Promise<Production> {
    const { data, error } = await supabase
      .from('production')
      .insert([production])
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async getTotalByPeriod(startDate: string, endDate: string, productType?: string) {
    let query = supabase
      .from('production')
      .select('quantity_kg')
      .gte('production_date', startDate)
      .lte('production_date', endDate);

    if (productType) {
      query = query.eq('product_type', productType);
    }

    const { data, error } = await query;

    if (error) throw error;

    const total = data?.reduce((sum: number, item: any) => sum + item.quantity_kg, 0) || 0;
    return total;
  },
};
