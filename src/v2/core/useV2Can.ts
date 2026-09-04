import { useCallback } from 'react';
import { useAuth } from '@/context/AuthContext';
import { useRoles } from '@/context/RolesContext';

/**
 * V2 permission resolver.
 *
 * V2 introduces granular permission strings incrementally, so it must not be
 * limited by the legacy TypeScript Permission union. The DB-backed roles table
 * is the runtime source of truth for every non-platform role. Super Admin is
 * the only implicit platform-wide bypass; owner and every other role are
 * labels/templates whose capabilities come from explicit permissions.
 */
export function useV2Can(): (permission: string) => boolean {
  const { user } = useAuth();
  const { rolePermissionsMap } = useRoles();

  return useCallback((permission: string) => {
    const role = user?.role;
    if (!role) return false;
    if (role === 'super_admin') return true;
    const permissions = (rolePermissionsMap[role] || []) as readonly string[];
    return permissions.includes(permission);
  }, [rolePermissionsMap, user?.role]);
}
