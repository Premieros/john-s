import { useCallback, useEffect, useState } from 'react';
import { supabase } from '@/api';
import type { Branch } from '@/lib/types';

const BRANCHES_CHANGED_EVENT = 'premier:branches-changed';

export function notifyBranchesChanged(): void {
  if (typeof window !== 'undefined') {
    window.dispatchEvent(new Event(BRANCHES_CHANGED_EVENT));
  }
}

export function useBranches() {
  const [branches, setBranches] = useState<Branch[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    setLoading(true);
    const { data, error } = await supabase.from('branches').select('*').order('name');
    if (error) {
      setBranches([]);
      setError(error.message);
      setLoading(false);
      return;
    }
    setBranches((data as Branch[]) || []);
    setError(null);
    setLoading(false);
  }, []);

  useEffect(() => {
    void refresh();

    if (typeof window === 'undefined') return;
    const onBranchesChanged = () => {
      void refresh();
    };
    window.addEventListener(BRANCHES_CHANGED_EVENT, onBranchesChanged);
    return () => window.removeEventListener(BRANCHES_CHANGED_EVENT, onBranchesChanged);
  }, [refresh]);

  return { branches, loading, error, refresh };
}
