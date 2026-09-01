import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { supabase } from '@/api';
import * as api from '@/api';
import { useLanguage } from '@/context/LanguageContext';
import { useAuth } from '@/context/AuthContext';
import { useToast } from '@/components/Toast';
import { computePosTotals, computeLineDiscount, type PosPaymentMethod } from '@/lib/posMath';
import { logAudit } from '@/lib/audit';
import type { CartItem, Customer, DiningTable, Order, OrderItem, OrderType, Product, RpcResult, Settings } from '@/lib/types';
import { ORDER_TYPE_KEY } from '../utils/orderTypes';
import { cartToItems, orderItemsToCart } from '../utils/cart';
import { buildReceiptHtml, buildKitchenTicketHtml, openPrintWindow, type ReceiptData } from '../utils/printing';
import { fetchOrderForWorkspace } from '../services/posOrders';
import { sendOrderToKitchen } from '../services/kitchen';
import { processSaleForOrder, nextInvoiceNumber, fetchBranchWarehouseId } from '../services/payment';
import type { KitchenSendItem } from '../types';

export interface ActiveShiftInfo {
  id: string;
  expected: number;
  opened_at: string;
  opening_amount: number;
}

export interface UsePosOrderInput {
  branchId: string;
  orderId: string | null;
  customers: Customer[];
  effSettings: Settings | null;
  isCashier: boolean;
  activeShift: ActiveShiftInfo | null;
  products: Product[];
  stockMap: Record<string, number>;
}

interface PersistResult {
  ok: boolean;
  orderId: string | null;
  orderNumber: string | null;
}

const EMPTY_CART: CartItem[] = [];

const VALID_PAYMENT_METHODS: PosPaymentMethod[] = ['cash', 'card', 'transfer', 'credit'];

export function usePosOrder(input: UsePosOrderInput) {
  const { branchId, orderId, customers, effSettings, isCashier, activeShift, products, stockMap } = input;
  const { t, lang } = useLanguage();
  const isAr = lang === 'ar';
  const { user } = useAuth();
  const { show } = useToast();

  const [cart, setCart] = useState<CartItem[]>(EMPTY_CART);
  const [customerId, setCustomerId] = useState('');
  const [orderNotes, setOrderNotes] = useState('');
  const paymentTouched = useRef(false);
  const defaultPayment = VALID_PAYMENT_METHODS.includes(effSettings?.pos_default_payment_method as PosPaymentMethod)
    ? (effSettings?.pos_default_payment_method as PosPaymentMethod)
    : 'cash';
  const [paymentMethod, setPaymentMethod] = useState<PosPaymentMethod>(defaultPayment);
  const setPaymentMethodSafe = useCallback((m: PosPaymentMethod) => {
    paymentTouched.current = true;
    setPaymentMethod(m);
  }, []);
  const [discountAmount, setDiscountAmount] = useState(0);
  const [discountType, setDiscountType] = useState<'amount' | 'percent'>('amount');
  const [paidAmount, setPaidAmount] = useState(0);

  const [orderType, setOrderType] = useState<OrderType>('takeaway');
  const [tableId, setTableId] = useState<string | null>(null);
  const [guestCount, setGuestCount] = useState<number | null>(null);
  const [activeOrderId, setActiveOrderId] = useState<string | null>(orderId);
  const [activeOrderNumber, setActiveOrderNumber] = useState<string | null>(null);
  const [activeTable, setActiveTable] = useState<DiningTable | null>(null);
  const [checkoutOpen, setCheckoutOpen] = useState(false);
  const [completing, setCompleting] = useState(false);
  const [orderLoading, setOrderLoading] = useState(false);
  const [kitchenSending, setKitchenSending] = useState(false);
  const [kitchenSentItems, setKitchenSentItems] = useState<KitchenSendItem[]>([]);
  const [lastReceipt, setLastReceipt] = useState<ReceiptData | null>(null);
  const [receiptSaleId, setReceiptSaleId] = useState<string | null>(null);

  const effCurrency = effSettings?.currency || 'EGP';

  // Apply the configured default payment method once settings are loaded,
  // unless the cashier already picked a method this session.
  useEffect(() => {
    if (paymentTouched.current) return;
    const dm = effSettings?.pos_default_payment_method as PosPaymentMethod;
    if (VALID_PAYMENT_METHODS.includes(dm)) setPaymentMethod(dm);
  }, [effSettings?.pos_default_payment_method]);

  useEffect(() => {
    setActiveOrderId(orderId);
    if (!orderId) {
      setActiveOrderNumber(null);
      setTableId(null);
      setGuestCount(null);
      setOrderType('takeaway');
      setCart(EMPTY_CART);
      setOrderNotes('');
      return;
    }
    let cancelled = false;
    setOrderLoading(true);
    fetchOrderForWorkspace(orderId)
      .then(({ order, items, products: orderProducts }) => {
        if (cancelled) return;
        if (!order) { setOrderLoading(false); return; }
        if (order.status !== 'open' && order.status !== 'held') {
          show(isAr ? 'لا يمكن استئناف طلب منتهي' : 'Cannot resume a completed order', 'error');
          setActiveOrderId(null);
          setActiveOrderNumber(null);
          setOrderLoading(false);
          return;
        }
        setOrderType(order.order_type as OrderType);
        setTableId(order.table_id);
        setActiveOrderId(order.id);
        setActiveOrderNumber(order.order_number);
        setGuestCount(order.guest_count);
        setOrderNotes(order.notes || '');
        // Repair a legacy 'vacant' row left under an open order, but never
        // overwrite a manager's 'reserved'/'closed' status.
        if (order.table_id) {
          supabase.from('dining_tables').select('status').eq('id', order.table_id).maybeSingle().then(({ data: tbl }) => {
            if (!cancelled && tbl && (tbl as { status: string }).status === 'vacant') {
              api.floorPlan.setTableStatus({ p_table_id: order.table_id as string, p_status: 'occupied' }).catch(() => {});
            }
          });
        }
        const cartItems = orderItemsToCart(items, orderProducts);
        if (cartItems.length > 0) setCart(cartItems);
        show(t('orderResumed'), 'success');
        setOrderLoading(false);
      })
      .catch(() => { if (!cancelled) setOrderLoading(false); });
    return () => { cancelled = true; };
  }, [orderId, t, show, isAr]);

  useEffect(() => {
    if (!tableId) { setActiveTable(null); return; }
    let cancelled = false;
    supabase.from('dining_tables').select('*').eq('id', tableId).maybeSingle().then(({ data }) => {
      if (!cancelled) setActiveTable((data as DiningTable | null) || null);
    });
    return () => { cancelled = true; };
  }, [tableId]);

  const getStock = useCallback((productId: string) => stockMap[productId] || 0, [stockMap]);

  const addToCart = useCallback((
    product: Product,
    quantity = 1,
    modifiers: { name: string; price?: number }[] = [],
    discount = 0
  ) => {
    const stock = getStock(product.id);
    const inCart = cart.find((i) => i.product.id === product.id)?.quantity || 0;
    if (inCart + quantity > stock) {
      show(`${product.name}: ${t('insufficientStock')} (${stock})`, 'error');
      return;
    }
    setCart((prev) => {
      const existing = prev.find((i) => i.product.id === product.id && (!modifiers.length));
      if (existing && !modifiers.length) {
        return prev.map((i) => (i.product.id === product.id ? { ...i, quantity: i.quantity + quantity } : i));
      }
      return [
        ...prev,
        {
          product,
          unit_name: 'piece',
          quantity,
          unit_price: product.sale_price,
          discount_amount: discount,
          bonus_quantity: 0,
          modifiers: modifiers.map((m) => ({ name: m.name })),
        },
      ];
    });
  }, [getStock, cart, show, t]);

  const updateQty = useCallback((productId: string, delta: number) => {
    const stock = getStock(productId);
    if (delta > 0) {
      const inCart = cart.find((i) => i.product.id === productId)?.quantity || 0;
      if (inCart + delta > stock) { show(`${t('insufficientStock')} (${stock})`, 'error'); return; }
    }
    setCart((prev) => prev.map((i) => (i.product.id === productId ? { ...i, quantity: Math.max(0, i.quantity + delta) } : i)).filter((i) => i.quantity > 0));
  }, [getStock, cart, show, t]);

  const setQty = useCallback((productId: string, qty: number) => {
    const stock = getStock(productId);
    if (qty > stock) { show(`${t('insufficientStock')} (${stock})`, 'error'); qty = stock; }
    setCart((prev) => prev.map((i) => (i.product.id === productId ? { ...i, quantity: Math.max(1, qty) } : i)));
  }, [getStock, show, t]);

  const removeFromCart = useCallback((productId: string) => setCart((prev) => prev.filter((i) => i.product.id !== productId)), []);
  const clearCart = useCallback(() => setCart(EMPTY_CART), []);

  const setItemDiscount = useCallback((productId: string, discount: number) => {
    const item = cart.find((i) => i.product.id === productId);
    if (!item) return;
    const lineTotal = item.quantity * item.unit_price;
    const d = computeLineDiscount(lineTotal, discount || 0);
    setCart((prev) => prev.map((i) => (i.product.id === productId ? { ...i, discount_amount: d } : i)));
  }, [cart]);

  const taxRate = effSettings?.tax_enabled ? (effSettings?.tax_rate || 0) : 0;
  const totals = useMemo(
    () => computePosTotals({
      items: cart,
      discountType,
      discountAmount,
      taxRate,
      taxEnabled: !!effSettings?.tax_enabled,
      paidAmount,
      paymentMethod,
    }),
    [cart, discountType, discountAmount, taxRate, effSettings?.tax_enabled, paidAmount, paymentMethod]
  );
  const { subtotal, discountValue, taxAmount, total, change } = totals;

  const switchOrderType = useCallback(async (ot: OrderType) => {
    if (ot === orderType) return;
    if (activeOrderNumber) {
      show(isAr ? `لا يمكن تغيير نوع طلب نشط (${activeOrderNumber})` : `Cannot change order type of active order (${activeOrderNumber})`, 'error');
      return;
    }
    if (ot === 'dine_in' && !tableId && !activeTable) {
      show(isAr ? 'اختر طاولة أولاً لطلب داخل الصالة' : 'Select a table first for dine-in orders', 'error');
      return;
    }
    if (activeTable && ot !== 'dine_in') {
      const ok = window.confirm(isAr
        ? `التبديل إلى ${t(ORDER_TYPE_KEY[ot])} سيفصل الطاولة ${activeTable.name} ويحررها. متابعة؟`
        : `Switching to ${t(ORDER_TYPE_KEY[ot])} will detach and free table ${activeTable.name}. Continue?`);
      if (!ok) return;
      const res = await api.floorPlan.setTableStatus({ p_table_id: tableId || activeTable.id, p_status: 'vacant' });
      if (res.error || !(res.data as RpcResult | null)?.success) {
        const r = res.data as RpcResult | null;
        show(r?.detail || r?.error || res.error?.message || t('error'), 'error');
        return;
      }
      setTableId(null);
      setActiveTable(null);
    }
    setOrderType(ot);
  }, [orderType, activeOrderNumber, tableId, activeTable, show, t, isAr]);

  const performDetach = useCallback(async () => {
    if (activeOrderId) {
      const res = await api.floorPlan.detachOrder({ p_order_id: activeOrderId });
      if (res.error || !(res.data as RpcResult | null)?.success) {
        const r = res.data as RpcResult | null;
        show(r?.detail || r?.error || res.error?.message || t('error'), 'error');
        return;
      }
    } else if (tableId) {
      const res = await api.floorPlan.setTableStatus({ p_table_id: tableId, p_status: 'vacant' });
      if (res.error || !(res.data as RpcResult | null)?.success) {
        const r = res.data as RpcResult | null;
        show(r?.detail || r?.error || res.error?.message || t('error'), 'error');
        return;
      }
    }
    setActiveOrderId(null);
    setActiveOrderNumber(null);
    setTableId(null);
    setActiveTable(null);
    setGuestCount(null);
  }, [activeOrderId, tableId, show, t]);

  const detachTable = useCallback(async () => {
    if (!activeTable) return;
    const ok = window.confirm(isAr
      ? `فصل الطلب عن الطاولة ${activeTable.name}؟ سيتم تحرير الطاولة.`
      : `Detach order from table ${activeTable.name}? The table will be freed.`);
    if (!ok) return;
    await performDetach();
  }, [activeTable, isAr, performDetach]);

  const detachOrder = useCallback(async () => {
    const ok = window.confirm(isAr ? 'فصل الطلب الحالي؟' : 'Detach the current order?');
    if (!ok) return;
    await performDetach();
  }, [isAr, performDetach]);

  // Seamlessly resume an existing table's order without losing any state or creating duplicates
  const resumeTableOrder = useCallback((order: Order, items: OrderItem[], orderProducts: Product[], table: DiningTable) => {
    setActiveOrderId(order.id);
    setActiveOrderNumber(order.order_number);
    setOrderType(order.order_type as OrderType);
    setTableId(table.id);
    setActiveTable(table);
    setGuestCount(order.guest_count || null);
    setOrderNotes(order.notes || '');
    setCustomerId(order.customer_id || '');
    const cartItems = orderItemsToCart(items, orderProducts);
    setCart(cartItems);
  }, []);

  // Initialize a new order directly on a selected table
  const startTableOrder = useCallback((table: DiningTable, guests = 2) => {
    setCart(EMPTY_CART);
    setActiveOrderId(null);
    setActiveOrderNumber(null);
    setOrderType('dine_in');
    setTableId(table.id);
    setActiveTable(table);
    setGuestCount(guests || table.capacity || 2);
    setOrderNotes('');
    setDiscountAmount(0);
    setPaidAmount(0);
  }, []);

  // Move / Transfer order between tables
  const transferOrderToTable = useCallback(async (targetOrderId: string, fromTableId: string, toTableId: string): Promise<boolean> => {
    try {
      // Update order table_id
      const { error: ordErr } = await supabase
        .from('orders')
        .update({ table_id: toTableId, updated_at: new Date().toISOString() })
        .eq('id', targetOrderId);

      if (ordErr) {
        show(ordErr.message, 'error');
        return false;
      }

      // Free old table
      await supabase
        .from('dining_tables')
        .update({ status: 'vacant', updated_at: new Date().toISOString() })
        .eq('id', fromTableId);

      // Occupy target table
      await supabase
        .from('dining_tables')
        .update({ status: 'occupied', updated_at: new Date().toISOString() })
        .eq('id', toTableId);

      // Fetch new table details
      const { data: newTable } = await supabase
        .from('dining_tables')
        .select('*')
        .eq('id', toTableId)
        .maybeSingle();

      if (activeOrderId === targetOrderId) {
        setTableId(toTableId);
        setActiveTable((newTable as DiningTable) || null);
      }

      show(isAr ? 'تم تحويل الطلب إلى الطاولة الجديدة بنجاح' : 'Order transferred successfully', 'success');
      return true;
    } catch (err) {
      show(err instanceof Error ? err.message : 'Transfer failed', 'error');
      return false;
    }
  }, [activeOrderId, isAr, show]);

  // Cancelling a sent kitchen line is a server-side approval operation. KDS is
  // state-only, so this path must never restore/increase inventory.
  const voidSentItem = useCallback(async (productId: string, voidQuantity: number, reason: string): Promise<boolean> => {
    if (!activeOrderId) return false;
    try {
      const item = cart.find((i) => i.product.id === productId);
      if (!item) return false;

      const { data, error } = await supabase.rpc('cancel_sent_order_item', {
        p_order_id: activeOrderId,
        p_product_id: productId,
        p_quantity: voidQuantity,
        p_reason: reason,
      });

      if (error) {
        show(error.message, 'error');
        return false;
      }

      const result = (data ?? {}) as RpcResult & {
        remaining_quantity?: number;
        voided_quantity?: number;
        inventory_changed?: boolean;
        request_id?: string;
        status?: string;
        action?: string;
      };

      if (!result.success) {
        if (result.error === 'MANAGER_APPROVAL_REQUIRED') {
          show(
            isAr
              ? 'تم إرسال طلب إلغاء الصنف للمدير. بعد الموافقة أعد تنفيذ الإلغاء.'
              : 'Manager approval request sent. Retry the void after approval.',
            'success'
          );
          return false;
        }
        show(result.detail || result.error || (isAr ? 'تعذر إلغاء الصنف' : 'Failed to void item'), 'error');
        return false;
      }

      const remaining = Number(result.remaining_quantity ?? Math.max(0, item.quantity - voidQuantity));
      setCart((prev) =>
        remaining <= 0
          ? prev.filter((i) => i.product.id !== productId)
          : prev.map((i) => (i.product.id === productId ? { ...i, quantity: remaining } : i))
      );

      // Keep the current-session sent snapshot visually aligned. Persistent KDS
      // state/history remains authoritative in order_kitchen_sends/voids.
      setKitchenSentItems((prev) =>
        prev
          .map((i) => {
            if (i.product_id !== productId) return i;
            const qty = Number(i.quantity || 0) - voidQuantity;
            return { ...i, quantity: Math.max(0, qty) };
          })
          .filter((i) => Number(i.quantity || 0) > 0)
      );

      const cancelNote = `[إلغاء مطبخ: ${voidQuantity} × ${item.product.name} - السبب: ${reason}]`;
      setOrderNotes((prev) => (prev ? `${prev}\n${cancelNote}` : cancelNote));

      show(
        isAr
          ? `تم إلغاء الصنف (${item.product.name}) بدون أي تعديل على المخزون`
          : `Item voided without changing inventory`,
        'success'
      );
      return true;
    } catch (err) {
      show(err instanceof Error ? err.message : 'Failed to void item', 'error');
      return false;
    }
  }, [activeOrderId, cart, isAr, show]);

  // Creates or updates the persisted order from the current cart.
  const persistCart = useCallback(async (status: 'open' | 'held'): Promise<PersistResult> => {
    if (!branchId) { show(t('selectBranchFirst'), 'error'); return { ok: false, orderId: null, orderNumber: null }; }
    const itemRows = cartToItems(cart);
    const targetTable = orderType === 'dine_in' ? tableId : null;

    if (activeOrderId) {
      const { data, error } = await api.floorPlan.updateOrder({
        p_order_id: activeOrderId,
        p_order_type: orderType,
        p_table_id: targetTable,
        p_customer_id: customerId || null,
        p_guest_count: guestCount,
        p_notes: orderNotes || null,
        p_items: itemRows,
        p_subtotal: subtotal,
        p_discount_amount: discountValue,
        p_discount_type: discountType === 'percent' ? 'percent' : 'amount',
        p_tax_amount: taxAmount,
        p_total: total,
        p_status: status,
      });
      if (error) { show(error.message, 'error'); return { ok: false, orderId: null, orderNumber: null }; }
      const r = data as RpcResult | null;
      if (!r?.success) { show(r?.detail || r?.error || t('error'), 'error'); return { ok: false, orderId: null, orderNumber: null }; }
      return { ok: true, orderId: activeOrderId, orderNumber: activeOrderNumber };
    }

    const { data, error } = await api.floorPlan.createOrder({
      p_branch_id: branchId,
      p_order_type: orderType,
      p_table_id: targetTable,
      p_customer_id: customerId || null,
      p_guest_count: guestCount,
      p_notes: orderNotes || null,
      p_items: itemRows,
      p_subtotal: subtotal,
      p_discount_amount: discountValue,
      p_discount_type: discountType === 'percent' ? 'percent' : 'amount',
      p_tax_amount: taxAmount,
      p_total: total,
      p_cashier_id: user?.id || null,
    });
    if (error) { show(error.message, 'error'); return { ok: false, orderId: null, orderNumber: null }; }
    const r = data as RpcResult | null;
    if (!r?.success) { show(r?.detail || r?.error || t('error'), 'error'); return { ok: false, orderId: null, orderNumber: null }; }
    return { ok: true, orderId: r.order_id || null, orderNumber: (r as RpcResult & { order_number?: string }).order_number || null };
  }, [branchId, activeOrderId, activeOrderNumber, orderType, tableId, customerId, guestCount, orderNotes, cart, subtotal, discountValue, discountType, taxAmount, total, user?.id, show, t]);

  // Holds the current cart: updates the SAME order when resuming (audit C2),
  // never creating a duplicate.
  const holdOrder = useCallback(async (): Promise<boolean> => {
    if (cart.length === 0 || completing || orderLoading) return false;
    if (!branchId) { show(t('selectBranchFirst'), 'error'); return false; }
    if (orderType === 'dine_in' && !tableId) {
      show(isAr ? 'اختر طاولة لطلب داخل الصالة' : 'Select a table for dine-in orders', 'error');
      return false;
    }
    setCompleting(true);
    try {
      if (activeOrderId) {
        const { ok } = await persistCart('held');
        if (!ok) return false;
      } else {
        const { ok, orderId: newId, orderNumber: newNum } = await persistCart('open');
        if (!ok) return false;
        if (newId) {
          // New orders are created 'open'; flip to 'held' and verify the flip so a
          // failure does not silently leave an open order (audit M3). On failure
          // keep the id so a retry updates it instead of duplicating (audit C2).
          const heldRes = await api.floorPlan.setOrderStatus({ p_order_id: newId, p_status: 'held' });
          if (heldRes.error || !(heldRes.data as RpcResult | null)?.success) {
            show(t('orderHeld') + ': ' + (heldRes.error?.message || (heldRes.data as RpcResult | null)?.detail || (heldRes.data as RpcResult | null)?.error || ''), 'error');
            setActiveOrderId(newId);
            setActiveOrderNumber(newNum);
            return false;
          }
        }
      }
      show(t('orderHeld'), 'success');
      return true;
    } finally {
      setCompleting(false);
    }
  }, [cart.length, completing, orderLoading, branchId, orderType, tableId, activeOrderId, persistCart, show, t, isAr]);

  // Sends unsent cart lines to the kitchen. The first send persists the cart as
  // an open order so kitchen-send state has an order to attach to; later sends
  // only snapshot the new lines (idempotent server-side).
  const sendToKitchen = useCallback(async (): Promise<boolean> => {
    if (cart.length === 0 || completing || orderLoading || kitchenSending) return false;
    if (!branchId) { show(t('selectBranchFirst'), 'error'); return false; }
    if (orderType === 'dine_in' && !tableId) {
      show(isAr ? 'اختر طاولة لطلب داخل الصالة' : 'Select a table for dine-in orders', 'error');
      return false;
    }
    setKitchenSending(true);
    try {
      const { ok, orderId: targetOrderId, orderNumber: targetOrderNumber } = await persistCart('open');
      if (!ok || !targetOrderId) return false;

      const res = await sendOrderToKitchen({ p_order_id: targetOrderId, p_sent_by: null });
      if (!res.success) {
        show(res.detail || res.error || t('error'), 'error');
        return false;
      }
      setActiveOrderId(targetOrderId);
      if (targetOrderNumber) setActiveOrderNumber(targetOrderNumber);
      setKitchenSentItems(res.sent || []);
      const sentCount = res.items_sent_count || 0;
      if (sentCount > 0) {
        show(`${t('sendToKitchen')} (${sentCount})`, 'success');
        if (effSettings) {
          const html = buildKitchenTicketHtml({
            orderNumber: targetOrderNumber || activeOrderNumber,
            tableName: activeTable?.name || null,
            orderTypeLabel: t(ORDER_TYPE_KEY[orderType]),
            guestCount,
            items: (res.sent || []).map((i) => ({ name: i.product_name || '—', qty: Number(i.quantity), unit_name: i.unit_name })),
            s: effSettings,
            isAr,
          });
          openPrintWindow(html, effSettings.receipt_width_mm || 80);
        }
      } else {
        show(isAr ? 'تم إرسال جميع الأصناف مسبقاً' : 'All items already sent to kitchen', 'success');
      }
      return true;
    } finally {
      setKitchenSending(false);
    }
  }, [cart.length, completing, orderLoading, kitchenSending, branchId, orderType, tableId, activeOrderNumber, persistCart, effSettings, activeTable, guestCount, t, isAr, show]);

  const printKitchenTicket = useCallback(() => {
    if (cart.length === 0 || !effSettings) return;
    const html = buildKitchenTicketHtml({
      orderNumber: activeOrderNumber,
      tableName: activeTable?.name || null,
      orderTypeLabel: t(ORDER_TYPE_KEY[orderType]),
      guestCount,
      items: cart.map((i) => ({ name: i.product.name, qty: i.quantity, unit_name: i.unit_name })),
      s: effSettings,
      isAr,
    });
    openPrintWindow(html, effSettings.receipt_width_mm || 80);
  }, [cart, effSettings, activeOrderNumber, activeTable, orderType, guestCount, t, isAr]);

  const completeSale = useCallback(async (): Promise<boolean> => {
    if (cart.length === 0 || completing) return false;
    if (!branchId) { show(t('selectBranchFirst'), 'error'); return false; }
    if (isCashier && !activeShift) { show(t('shiftRequired'), 'error'); return false; }
    if (orderType === 'dine_in' && !tableId) {
      show(isAr ? 'اختر طاولة لطلب داخل الصالة' : 'Select a table for dine-in orders', 'error');
      return false;
    }
    setCompleting(true);
    try {
      for (const item of cart) {
        const stock = getStock(item.product.id);
        if (stock < item.quantity) { show(`${item.product.name}: ${t('insufficientStock')} (${stock})`, 'error'); return false; }
      }

      const warehouseId = await fetchBranchWarehouseId(branchId);
      const invoiceNumber = (await nextInvoiceNumber()) || `INV-${Date.now()}`;
      const itemsPayload = cartToItems(cart);
      const paidAmountToUse = paymentMethod === 'credit' ? 0 : paidAmount || total;

      const { result, error: saleError } = await processSaleForOrder({
        p_invoice_number: invoiceNumber,
        p_branch_id: branchId,
        p_shift_id: activeShift?.id || null,
        p_warehouse_id: warehouseId,
        p_customer_id: customerId || null,
        p_salesperson_id: null,
        p_subtotal: subtotal,
        p_discount_amount: discountValue,
        p_discount_type: discountType === 'percent' ? 'percent' : 'amount',
        p_tax_amount: taxAmount,
        p_bonus_amount: 0,
        p_total: total,
        p_paid_amount: paidAmountToUse,
        p_payment_method: paymentMethod,
        p_status: 'completed',
        p_items: itemsPayload,
        p_order_type: orderType,
        p_table_id: orderType === 'dine_in' ? tableId : null,
        p_order_id: activeOrderId,
        p_guest_count: guestCount,
      });
      if (saleError) { show(saleError, 'error'); return false; }
      if (!result?.success) { show(result?.detail || result?.error || t('error'), 'error'); return false; }
      const saleId = result.sale_id || '';

      await logAudit('create', 'sales', saleId, { invoice: invoiceNumber, total });

      const receiptPayload: ReceiptData = {
        invoice: invoiceNumber,
        items: cart.map((i) => ({ name: i.product.name, qty: i.quantity, price: i.unit_price, total: i.quantity * i.unit_price - i.discount_amount })),
        subtotal, discount: discountValue, tax: taxAmount, total,
        paid: paidAmountToUse, change, date: new Date().toISOString(),
        customerName: customers.find((c) => c.id === customerId)?.name || '',
        orderNumber: activeOrderNumber || undefined,
        tableName: activeTable?.name || undefined,
        orderTypeLabel: t(ORDER_TYPE_KEY[orderType]),
        guestCount: guestCount || undefined,
      };
      setLastReceipt(receiptPayload);
      setReceiptSaleId(saleId);
      setCheckoutOpen(false);
      setCart(EMPTY_CART);
      setDiscountAmount(0);
      setPaidAmount(0);
      setCustomerId('');
      setOrderNotes('');
      setActiveOrderId(null);
      setActiveOrderNumber(null);
      setTableId(null);
      setActiveTable(null);
      setGuestCount(null);
      show(t('saleCompleted'), 'success');

      if (effSettings?.receipt_auto_print) {
        const html = await buildReceiptHtml(receiptPayload, effSettings, lang, isAr);
        openPrintWindow(html, effSettings.receipt_width_mm || 80);
      }
      return true;
    } finally {
      setCompleting(false);
    }
  }, [cart, completing, branchId, isCashier, activeShift, orderType, tableId, getStock, paymentMethod, total, paidAmount, customerId, subtotal, discountValue, discountType, taxAmount, change, activeOrderId, activeOrderNumber, guestCount, customers, activeTable, effSettings, lang, isAr, show, t]);

  const printReceipt = useCallback(async () => {
    if (!lastReceipt || !effSettings) return;
    const html = await buildReceiptHtml(lastReceipt, effSettings, lang, isAr);
    openPrintWindow(html, effSettings.receipt_width_mm || 80);
  }, [lastReceipt, effSettings, lang, isAr]);

  const closeReceipt = useCallback(() => setReceiptSaleId(null), []);

  // Full workspace reset: used when switching branches so no order/cart state
  // from the previous branch leaks into the new one.
  const resetWorkspace = useCallback(() => {
    setCart(EMPTY_CART);
    setCustomerId('');
    setOrderNotes('');
    setDiscountAmount(0);
    setPaidAmount(0);
    setOrderType('takeaway');
    setTableId(null);
    setGuestCount(null);
    setActiveOrderId(null);
    setActiveOrderNumber(null);
    setActiveTable(null);
    setCheckoutOpen(false);
  }, []);

  return {
    cart,
    customerId, setCustomerId,
    orderNotes, setOrderNotes,
    paymentMethod, setPaymentMethod: setPaymentMethodSafe,
    discountAmount, setDiscountAmount,
    discountType, setDiscountType,
    paidAmount, setPaidAmount,
    orderType, setOrderType,
    tableId, setTableId,
    guestCount, setGuestCount,
    activeOrderId, activeOrderNumber, activeTable,
    checkoutOpen, setCheckoutOpen,
    completing, orderLoading, kitchenSending, kitchenSentItems,
    lastReceipt, receiptSaleId, closeReceipt,
    subtotal, discountValue, taxAmount, total, change,
    effCurrency,
    addToCart, updateQty, setQty, removeFromCart, clearCart, setItemDiscount,
    switchOrderType, holdOrder, sendToKitchen, printKitchenTicket, completeSale, printReceipt,
    detachTable, detachOrder, resetWorkspace,
    resumeTableOrder, startTableOrder, transferOrderToTable, voidSentItem,
  };
}

export type UsePosOrder = ReturnType<typeof usePosOrder>;
