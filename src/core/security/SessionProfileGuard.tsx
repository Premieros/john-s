import { useEffect, useState, type ReactNode } from 'react';
import { supabase } from '@/api';
import { useAuth } from '@/context/AuthContext';

const VERIFIED_PROFILE_KEY = 'premier_verified_profile_id';
const LOCAL_CACHE_PREFIXES = [
  'pos_offline_products_cache_v1_',
  'pos_offline_categories_cache_v1_',
];

async function clearOfflineReadCache(): Promise<void> {
  try {
    for (let i = localStorage.length - 1; i >= 0; i -= 1) {
      const key = localStorage.key(i);
      if (key && LOCAL_CACHE_PREFIXES.some((prefix) => key.startsWith(prefix))) {
        localStorage.removeItem(key);
      }
    }
  } catch {
    // Storage may be unavailable in hardened/private browser modes.
  }

  if (typeof indexedDB === 'undefined') return;

  try {
    const request = indexedDB.open('premier_pos_offline_db', 2);
    await new Promise<void>((resolve) => {
      request.onerror = () => resolve();
      request.onupgradeneeded = () => undefined;
      request.onsuccess = () => {
        const db = request.result;
        const readableStores = [
          'products',
          'categories',
          'customers',
          'dining_tables',
          'dining_areas',
          'stock_map',
          'system_settings',
        ].filter((name) => db.objectStoreNames.contains(name));

        if (readableStores.length === 0) {
          db.close();
          resolve();
          return;
        }

        const tx = db.transaction(readableStores, 'readwrite');
        readableStores.forEach((name) => tx.objectStore(name).clear());
        tx.oncomplete = () => {
          db.close();
          resolve();
        };
        tx.onerror = () => {
          db.close();
          resolve();
        };
        tx.onabort = () => {
          db.close();
          resolve();
        };
      };
    });
  } catch {
    // Never block sign-in because a browser cache could not be cleared.
  }
}

export function SessionProfileGuard({ children }: { children: ReactNode }) {
  const { session, signOut } = useAuth();
  const [verifiedSessionId, setVerifiedSessionId] = useState<string | null>(null);
  const [checking, setChecking] = useState(false);

  useEffect(() => {
    let cancelled = false;

    if (!session?.user?.id) {
      setVerifiedSessionId(null);
      setChecking(false);
      return;
    }

    const sessionUserId = session.user.id;
    setChecking(true);

    void (async () => {
      const { data, error } = await supabase
        .from('users')
        .select('id, is_active')
        .eq('id', sessionUserId)
        .maybeSingle();

      if (cancelled) return;

      if (error || !data || data.is_active === false) {
        await clearOfflineReadCache();
        try {
          localStorage.removeItem(VERIFIED_PROFILE_KEY);
        } catch {
          // Ignore storage errors.
        }
        await signOut();
        if (!cancelled) {
          setVerifiedSessionId(null);
          setChecking(false);
        }
        return;
      }

      let previousProfileId: string | null = null;
      try {
        previousProfileId = localStorage.getItem(VERIFIED_PROFILE_KEY);
      } catch {
        previousProfileId = null;
      }

      if (previousProfileId !== sessionUserId) {
        await clearOfflineReadCache();
        try {
          localStorage.setItem(VERIFIED_PROFILE_KEY, sessionUserId);
        } catch {
          // Ignore storage errors.
        }
      }

      if (!cancelled) {
        setVerifiedSessionId(sessionUserId);
        setChecking(false);
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [session?.user?.id, signOut]);

  if (session?.user?.id && (checking || verifiedSessionId !== session.user.id)) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-ui-page text-ui-text">
        <div className="rounded-2xl border border-ui-border bg-ui-surface px-6 py-5 text-center shadow-ui-md">
          <div className="mx-auto mb-3 h-8 w-8 animate-spin rounded-full border-2 border-ui-primary border-t-transparent" />
          <p className="text-sm font-black">جاري التحقق من صلاحية الحساب...</p>
        </div>
      </div>
    );
  }

  return <>{children}</>;
}
