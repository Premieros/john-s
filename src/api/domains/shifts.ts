import type { ApiResult } from '../types';
import type { RpcResult } from '@/lib/types';
import { rpc } from '../rpc';

/**
 * Shift mutations are intentionally server-authoritative.
 * Do not add direct table-write fallbacks here: open/close/force-close actions
 * must always pass the database permission, branch and approval checks.
 */
export const shifts = {
  open(p: { p_branch_id: string; p_opening_amount: number; p_notes: string | null }): ApiResult<RpcResult & { shift_id?: string }> {
    return rpc<RpcResult & { shift_id?: string }>('open_shift', p);
  },

  close(p: { p_shift_id: string; p_actual_amount: number; p_notes: string | null }): ApiResult<RpcResult> {
    return rpc<RpcResult>('close_shift', p);
  },
};
