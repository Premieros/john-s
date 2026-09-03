import { pos as posApi, supabase, type SplitTenderInput } from '@/api';
import type { RpcResult, OrderType } from '@/lib/types';
import type { ItemPayload } from '../utils/cart';
import { offlinePosManager } from './offlinePos';

export interface ProcessSalePayload {
  p_invoice_number: string;
  p_branch_id: string;
  p_shift_id: string | null;
  p_warehouse_id: string | null;
  p_customer_id: string | null;
  p_salesperson_id: string | null;
  p_subtotal: number;
  p_discount_amount: number;
  p_discount_type: 'percent' | 'amount';
  p_tax_amount: number;
  p_bonus_amount: number;
  p_total: number;
  p_paid_amount: number;
  p_payment_method: string;
  p_status: string;
  p_items: ItemPayload[];
  p_order_type: OrderType;
  p_table_id: string | null;
  p_order_id: string | null;
  p_guest_count: number | null;
}

export interface ProcessSplitSalePayload extends Omit<ProcessSalePayload, 'p_paid_amount' | 'p_payment_method'> {
  p_payments: SplitTenderInput[];
}

export async function processSaleForOrder(p: ProcessSalePayload): Promise<{ result: (RpcResult & { offline?: boolean }) | null; error: string | null }> {
  // Explicit offline mode is the only place where a sale may enter the outbox.
  if (typeof navigator !== 'undefined' && !navigator.onLine) {
    const queued = offlinePosManager.enqueueSale(p);
    return {
      result: {
        success: true,
        offline: true,
        sale_id: queued.localId,
        order_id: p.p_order_id || undefined,
      },
      error: null,
    };
  }

  try {
    const { data, error } = await posApi.processSale(p);
    if (!error && (data as { success?: boolean })?.success) {
      return { result: data as RpcResult, error: null };
    }

    // A server rejection (approval, stock, subscription, validation, etc.) is
    // authoritative and must never be converted into a successful offline sale.
    const result = data as RpcResult | null;
    return { result, error: error?.message || result?.detail || result?.error || 'Sale processing failed' };
  } catch (err) {
    // Do not enqueue after an ambiguous online failure: the server may have
    // committed before the response was lost, which would create a duplicate.
    return { result: null, error: err instanceof Error ? err.message : 'Network error while processing sale' };
  }
}

export async function processSplitSaleForOrder(p: ProcessSplitSalePayload): Promise<{ result: (RpcResult & { split?: boolean; payment_count?: number }) | null; error: string | null }> {
  // Do not queue split tender offline until the offline outbox has a dedicated
  // idempotent split contract. A partial local recreation would be financially unsafe.
  if (typeof navigator !== 'undefined' && !navigator.onLine) {
    return { result: null, error: 'Split payment requires an online connection.' };
  }

  try {
    const { data, error } = await posApi.processSaleSplit(p);
    const result = data as (RpcResult & { split?: boolean; payment_count?: number }) | null;
    if (!error && result?.success) return { result, error: null };

    // A server rejection from process_sale_split is authoritative too; never
    // degrade it into the normal offline queue or a second financial attempt.
    return { result, error: error?.message || result?.detail || result?.error || 'Split sale processing failed' };
  } catch (err) {
    // The server may have committed before the network response disappeared.
    return { result: null, error: err instanceof Error ? err.message : 'Network error while processing split sale' };
  }
}

export async function nextInvoiceNumber(): Promise<string | null> {
  if (typeof navigator !== 'undefined' && !navigator.onLine) {
    const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const rand = Math.floor(1000 + Math.random() * 9000);
    return `INV-OFF-${dateStr}-${rand}`;
  }

  try {
    const { data, error } = await posApi.nextDocumentNumber({ p_type: 'sale' });
    if (!error && data?.success) return (data as { number?: string }).number || null;
  } catch {
    // Network fallback.
  }

  const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  const rand = Math.floor(1000 + Math.random() * 9000);
  return `INV-${dateStr}-${rand}`;
}

export async function fetchBranchWarehouseId(branchId: string): Promise<string | null> {
  try {
    const { data } = await supabase.from('warehouses').select('id').eq('branch_id', branchId).eq('is_active', true);
    const rows = (data as { id: string }[] | null) || [];
    return rows.length > 0 ? rows[0].id : null;
  } catch {
    return null;
  }
}