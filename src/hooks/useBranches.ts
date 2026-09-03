import { useCallback, useEffect, useState } from 'react';
import { supabase } from '@/api';
import type { Branch } from '@/lib/types';

let cache: Branch[] | null = null;
const BRANCHES_CHANGED_EVENT = 'premier:branches-changed';

export function notifyBranchesChanged(): void {
  cache = null;
  if (typeof window !== 'undefined') {
    window.dispatchEvent(new Event(BRANCHES_CHANGED_EVENT));
  }
}

export function useBranches() {
  const [branches, setBranches] = useState<Branch[]>(cache ?? []);
  const [loading, setLoading] = useState(cache === null);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    const { data, error } = await supabase.from('branches').select('*').order('name');
    if (error) {
      setError(error.message);
      setLoading(false);
      return;
    }
    cache = (data as Branch[]) || [];
    setBranches(cache);
    setError(null);
    setLoading(false);
  }, []);

  useEffect(() => {
    if (cache !== null) {
      setBranches(cache);
      setLoading(false);
    } else {
      void refresh();
    }

    if (typeof window === 'undefined') return;
    const onBranchesChanged = () => {
      setLoading(true);
      void refresh();
    };
    window.addEventListener(BRANCHES_CHANGED_EVENT, onBranchesChanged);
    return () => window.removeEventListener(BRANCHES_CHANGED_EVENT, onBranchesChanged);
  }, [refresh]);

  return { branches, loading, error, refresh };
}
