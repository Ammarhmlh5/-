import { supabase } from '../lib/supabase';
import { Feeding } from '../types';

export const feedingService = {
  async getAll(userId: string): Promise<Feeding[]> {
    const { data, error } = await supabase
      .from('feeding_logs')
      .select(`
        *,
        hives!inner(
          hive_id,
          hive_number,
          apiaries!inner(
            owner_id
          )
        )
      `)
      .eq('hives.apiaries.owner_id', userId)
      .order('feeding_date', { ascending: false });

    if (error) throw error;
    return data || [];
  },

  async getByHive(hiveId: string): Promise<Feeding[]> {
    const { data, error } = await supabase
      .from('feeding_logs')
      .select('*')
      .eq('hive_id', hiveId)
      .order('feeding_date', { ascending: false });

    if (error) throw error;
    return data || [];
  },

  async getById(id: string): Promise<Feeding | null> {
    const { data, error } = await supabase
      .from('feeding_logs')
      .select('*')
      .eq('feeding_id', id)
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  async create(feeding: Omit<Feeding, 'feeding_id' | 'created_at'>): Promise<Feeding> {
    const { data, error } = await supabase
      .from('feeding_logs')
      .insert([feeding])
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async update(id: string, updates: Partial<Feeding>): Promise<Feeding> {
    const { data, error } = await supabase
      .from('feeding_logs')
      .update(updates)
      .eq('feeding_id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async delete(id: string): Promise<void> {
    const { error } = await supabase
      .from('feeding_logs')
      .delete()
      .eq('feeding_id', id);

    if (error) throw error;
  },
};
