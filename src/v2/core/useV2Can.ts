import { useCallback } from 'react';
import { useAuth } from '@/context/AuthContext';
import { useRoles } from '@/context/RolesContext';

/**
 * V2 permission resolver.
 *
 * V2 introduces granular permission strings incrementally, so it must not be
 * limited by the legacy TypeScript Permission union. The DB-backed roles table
 * remains the runtime source of truth. Only super_admin and owner retain the
 * existing implicit global-admin capability.
 */
export function useV2Can(): (permission: string) => boolean {
  const { user } = useAuth();
  const { rolePermissionsMap } = useRoles();

  return useCallback((permission: string) => {
    const role = user?.role;
    if (!role) return false;
    if (role === 'super_admin' || role === 'owner') return true;
    const permissions = (rolePermissionsMap[role] || []) as readonly string[];
    return permissions.includes(permission);
  }, [rolePermissionsMap, user?.role]);
}
