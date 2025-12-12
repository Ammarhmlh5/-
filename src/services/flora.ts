import { supabase } from '../lib/supabase';
import { Flora } from '../types';

export const floraService = {
  async getAll(): Promise<Flora[]> {
    const { data, error } = await supabase
      .from('flora_library')
      .select('*')
      .order('common_name_ar', { ascending: true });

    if (error) throw error;
    return data || [];
  },

  async getById(id: string): Promise<Flora | null> {
    const { data, error } = await supabase
      .from('flora_library')
      .select('*')
      .eq('id', id)
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  async searchByName(searchTerm: string): Promise<Flora[]> {
    const { data, error } = await supabase
      .from('flora_library')
      .select('*')
      .or(`common_name_ar.ilike.%${searchTerm}%,common_name_en.ilike.%${searchTerm}%,scientific_name.ilike.%${searchTerm}%`)
      .order('common_name_ar', { ascending: true });

    if (error) throw error;
    return data || [];
  },

  async getByRegion(region: string): Promise<Flora[]> {
    const { data, error } = await supabase
      .from('flora_library')
      .select('*')
      .eq('region', region)
      .order('common_name_ar', { ascending: true });

    if (error) throw error;
    return data || [];
  },

  async getBySeason(month: number): Promise<Flora[]> {
    const { data, error } = await supabase
      .from('flora_library')
      .select('*')
      .lte('bloom_season_start', month)
      .gte('bloom_season_end', month)
      .order('common_name_ar', { ascending: true });

    if (error) throw error;
    return data || [];
  },
};
