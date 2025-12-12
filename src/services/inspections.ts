import { supabase } from '../lib/supabase';
import { Inspection } from '../types';

export const inspectionsService = {
  async getAll(hiveId?: string): Promise<Inspection[]> {
    let query = supabase
      .from('inspections')
      .select('*')
      .order('inspection_date', { ascending: false });

    if (hiveId) {
      query = query.eq('hive_id', hiveId);
    }

    const { data, error } = await query;

    if (error) throw error;
    return data || [];
  },

  async getById(id: string): Promise<Inspection | null> {
    const { data, error } = await supabase
      .from('inspections')
      .select('*')
      .eq('id', id)
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  async create(inspection: Omit<Inspection, 'id' | 'created_at'>): Promise<Inspection> {
    const { data, error } = await supabase
      .from('inspections')
      .insert([inspection])
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async update(id: string, updates: Partial<Inspection>): Promise<Inspection> {
    const { data, error } = await supabase
      .from('inspections')
      .update(updates)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async delete(id: string): Promise<void> {
    const { error } = await supabase
      .from('inspections')
      .delete()
      .eq('id', id);

    if (error) throw error;
  },

  async getLatestForHive(hiveId: string): Promise<Inspection | null> {
    const { data, error } = await supabase
      .from('inspections')
      .select('*')
      .eq('hive_id', hiveId)
      .order('inspection_date', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  async getWithHive(inspectionId: string) {
    const { data, error } = await supabase
      .from('inspections')
      .select(`
        *,
        hive:hives(*, apiary:apiaries(*))
      `)
      .eq('id', inspectionId)
      .maybeSingle();

    if (error) throw error;
    return data;
  },
};
