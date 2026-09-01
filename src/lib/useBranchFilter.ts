import { useAuth } from '../context/AuthContext';
import { isAdminRole } from './permissions';

/**
 * Returns the branch_id filter for the current user.
 * - Admin (super_admin / owner): null (sees all branches)
 * - Everyone else: their assigned branch_id
 */
export function useBranchFilter(): string | null {
  const { user } = useAuth();
  if (!user) return null;
  if (isAdminRole(user.role)) return null;
  return user.branch_id || null;
}

