import { supabase } from '../lib/supabase';
import { Apiary } from '../types';

export const apiariesService = {
  async getAll(userId: string): Promise<Apiary[]> {
    const { data, error } = await supabase
      .from('apiaries')
      .select('*')
      .eq('owner_id', userId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  },

  async getById(id: string): Promise<Apiary | null> {
    const { data, error } = await supabase
      .from('apiaries')
      .select('*')
      .eq('apiary_id', id)
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  async create(apiary: Omit<Apiary, 'apiary_id' | 'created_at' | 'updated_at' | 'hive_count'>): Promise<Apiary> {
    const { data, error } = await supabase
      .from('apiaries')
      .insert([apiary])
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async update(id: string, updates: Partial<Apiary>): Promise<Apiary> {
    const { data, error } = await supabase
      .from('apiaries')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('apiary_id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async delete(id: string): Promise<void> {
    const { error } = await supabase
      .from('apiaries')
      .delete()
      .eq('apiary_id', id);

    if (error) throw error;
  },

  async getHiveCount(apiaryId: string): Promise<number> {
    const { count, error } = await supabase
      .from('hives')
      .select('*', { count: 'exact', head: true })
      .eq('apiary_id', apiaryId);

    if (error) throw error;
    return count || 0;
  },
};
