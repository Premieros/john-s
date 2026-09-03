import type { KitchenSendItem, KitchenSendResult } from '../types';
import { rpc } from '@/api/rpc';

// In-flight locks prevent rapid duplicate clicks. The server remains the
// authoritative idempotency boundary and send_to_kitchen is state/snapshot only.
const activeSendLocks = new Set<string>();

/**
 * The automatic kitchen ticket currently consumes product_name from the
 * authoritative send_to_kitchen snapshot. Preserve the base name but append
 * modifiers and the item note so the paper ticket cannot silently lose cooking
 * instructions that are already present in the KDS snapshot.
 */
function withKitchenInstructions(item: KitchenSendItem): KitchenSendItem {
  const parts: string[] = [];
  for (const modifier of item.modifiers || []) {
    const name = modifier.option_name || modifier.option_name_en;
    if (name) parts.push(name);
  }
  if (item.notes?.trim()) parts.push(item.notes.trim());
  if (parts.length === 0) return item;

  const baseName = item.product_name || '—';
  return {
    ...item,
    product_name: `${baseName} • ${parts.join(' • ')}`,
  };
}

/**
 * Send the persisted order to KDS.
 *
 * Hard rule: this client service never deducts, restores, or otherwise mutates
 * inventory. send_to_kitchen records kitchen state/snapshots only. Inventory is
 * consumed exactly once by process_sale.
 */
export async function sendOrderToKitchen(p: {
  p_order_id: string;
  p_sent_by?: string | null;
}): Promise<KitchenSendResult> {
  const orderId = p.p_order_id;
  if (!orderId) return { success: false, error: 'NO_ORDER_ID', detail: 'Order ID is required' };

  if (activeSendLocks.has(orderId)) {
    return { success: false, error: 'SEND_IN_PROGRESS', detail: 'Kitchen send is already in progress for this order' };
  }

  activeSendLocks.add(orderId);
  try {
    const rpcRes = await rpc<{
      success: boolean;
      error?: string;
      detail?: string;
      order_id?: string;
      sent?: KitchenSendItem[];
      items_sent_count?: number;
      items_processed?: number;
      all_sent?: boolean;
    }>('send_to_kitchen', {
      p_order_id: orderId,
      p_sent_by: p.p_sent_by || null,
    });

    if (rpcRes.error) {
      return {
        success: false,
        error: 'KITCHEN_SEND_FAILED',
        detail: rpcRes.error.message,
      };
    }

    const result = rpcRes.data;
    if (!result?.success) {
      return {
        success: false,
        error: result?.error || 'KITCHEN_SEND_FAILED',
        detail: result?.detail || result?.error || 'Kitchen send failed',
      };
    }

    const sentItems = (result.sent || []).map(withKitchenInstructions);
    return {
      success: true,
      order_id: result.order_id || orderId,
      sent: sentItems,
      items_sent_count: result.items_sent_count ?? result.items_processed ?? sentItems.length,
      all_sent: result.all_sent ?? true,
    };
  } catch (err) {
    return {
      success: false,
      error: 'KITCHEN_SEND_FAILED',
      detail: err instanceof Error ? err.message : 'Unknown error during kitchen send',
    };
  } finally {
    activeSendLocks.delete(orderId);
  }
}

/**
 * Legacy compatibility entry point. Reversal is server-only; never perform a
 * direct client inventory fallback. In the current architecture KDS does not
 * consume stock, so normal order cancellation does not need inventory reversal.
 */
export async function reverseOrderKitchenConsumption(
  orderId: string,
  reason?: string,
): Promise<{ success: boolean; error?: string }> {
  try {
    const res = await rpc<{ success: boolean; error?: string; detail?: string }>('reverse_order_kitchen_consumption', {
      p_order_id: orderId,
      p_reason: reason || null,
    });
    if (res.error) return { success: false, error: res.error.message };
    if (res.data?.success) return { success: true };
    return { success: false, error: res.data?.detail || res.data?.error || 'KITCHEN_REVERSAL_NOT_AVAILABLE' };
  } catch (err) {
    return { success: false, error: err instanceof Error ? err.message : 'KITCHEN_REVERSAL_NOT_AVAILABLE' };
  }
}
