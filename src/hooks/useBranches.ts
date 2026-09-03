import { useCallback, useEffect, useState } from 'react';
import { supabase } from '@/api';
import type { Branch } from '@/lib/types';

let cache: Branch[] | null = null;

export function useBranches() {
  const [branches, setBranches] = useState<Branch[]>(cache ?? []);
  const [loading, setLoading] = useState(cache === null);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    const { data, error } = await supabase
      .from('branches')
      .select('*')
      .eq('is_active', true)
      .order('name');

    if (error) {
      setError(error.message);
      setLoading(false);
      return;
    }

    cache = ((data as Branch[]) || []).filter((branch) => branch.is_active !== false);
    setBranches(cache);
    setError(null);
    setLoading(false);
  }, []);

  useEffect(() => {
    if (cache !== null) {
      setBranches(cache.filter((branch) => branch.is_active !== false));
      setLoading(false);
    }

    // Always revalidate on mount so a deleted/deactivated branch can never stay
    // in the selector just because it was present in the in-memory cache.
    void refresh();

    const channel = supabase
      .channel('active-branches-selector')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'branches' },
        () => { void refresh(); },
      )
      .subscribe();

    return () => {
      void supabase.removeChannel(channel);
    };
  }, [refresh]);

  return { branches, loading, error, refresh };
}
