import { supabase } from '../lib/supabase';
import { Hive } from '../types';

export const hivesService = {
  async getAll(apiaryId?: string): Promise<Hive[]> {
    let query = supabase
      .from('hives')
      .select('*')
      .order('hive_number', { ascending: true });

    if (apiaryId) {
      query = query.eq('apiary_id', apiaryId);
    }

    const { data, error } = await query;

    if (error) throw error;
    return data || [];
  },

  async getById(id: string): Promise<Hive | null> {
    const { data, error } = await supabase
      .from('hives')
      .select('*')
      .eq('hive_id', id)
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  async create(hive: Omit<Hive, 'hive_id' | 'created_at' | 'updated_at'>): Promise<Hive> {
    const { data, error } = await supabase
      .from('hives')
      .insert([hive])
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async update(id: string, updates: Partial<Hive>): Promise<Hive> {
    const { data, error } = await supabase
      .from('hives')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('hive_id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async delete(id: string): Promise<void> {
    const { error } = await supabase
      .from('hives')
      .delete()
      .eq('hive_id', id);

    if (error) throw error;
  },

  async getWithApiary(hiveId: string) {
    const { data, error } = await supabase
      .from('hives')
      .select(`
        *,
        apiary:apiaries(*)
      `)
      .eq('hive_id', hiveId)
      .maybeSingle();

    if (error) throw error;
    return data;
  },
};
