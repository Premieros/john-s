import { useCallback, useEffect, useMemo, useState } from 'react';
import { ArrowRight, Car, Check, ChefHat, Minus, PackageOpen, Plus, RefreshCw, Search, Send, ShoppingBag, ShoppingCart, Store, Trash2, Truck, UsersRound, UtensilsCrossed, X } from 'lucide-react';
import { supabase } from '@/api';
import { useAuth } from '@/context/AuthContext';
import { useLanguage } from '@/context/LanguageContext';
import { useCan } from '@/lib/permissions';
import { V2AppShell } from '@/v2/components/V2AppShell';
import { V2BranchProvider, useV2Branch } from '@/v2/context/V2BranchContext';
import { useV2Can } from '@/v2/core/useV2Can';

type OrderType = 'dine_in' | 'takeaway' | 'delivery' | 'drive_thru';

type ProductRow = {
  id: string;
  name: string;
  name_en: string | null;
  category_id: string | null;
  sale_price: number;
  image_url: string | null;
};

type CategoryRow = { id: string; name: string; name_en: string | null };
type AreaRow = { id: string; name: string; sort_order: number };
type TableRow = { id: string; area_id: string | null; name: string; capacity: number; status: 'vacant' | 'occupied' | 'reserved' | 'closed' };
type OrderRow = { id: string; order_number: string; order_type: OrderType; status: 'open' | 'held'; table_id: string | null; guest_count: number | null; subtotal: number; tax_amount: number; total: number };
type OrderItemRow = { id: string; order_id: string; product_id: string | null; unit_name: string; quantity: number; unit_price: number; discount_amount: number; bonus_quantity: number; total: number; notes: string | null; modifier_option_ids: string[] | null };
type ModifierGroup = { id: string; product_id: string; name: string; name_en: string | null; min_selections: number; max_selections: number; sort_order: number };
type ModifierOption = { id: string; group_id: string; name: string; name_en: string | null; price_delta: number; is_default: boolean; sort_order: number };

type CartLine = {
  key: string;
  product: ProductRow;
  quantity: number;
  modifierOptionIds: string[];
  unitPrice: number;
  notes: string;
};

type DraftContext = {
  orderType: OrderType;
  tableId: string | null;
  guestCount: number | null;
  existingOrderId: string | null;
  existingOrderNumber: string | null;
};

type SavedOrder = { orderId: string; orderNumber: string | null };
type KitchenSendResult = { success?: boolean; error?: string; detail?: string; items_sent_count?: number; all_sent?: boolean };

const EMPTY_DRAFT: DraftContext = { orderType: 'takeaway', tableId: null, guestCount: null, existingOrderId: null, existingOrderNumber: null };

function makeCartKey(productId: string, optionIds: string[]): string {
  return `${productId}::${[...optionIds].sort().join(',')}`;
}

function V2PosContent() {
  const { lang } = useLanguage();
  const isAr = lang === 'ar';
  const { user } = useAuth();
  const can = useCan();
  const v2Can = useV2Can();
  const { selectedBranchId, selectedBranch } = useV2Branch();

  const [products, setProducts] = useState<ProductRow[]>([]);
  const [categories, setCategories] = useState<CategoryRow[]>([]);
  const [areas, setAreas] = useState<AreaRow[]>([]);
  const [tables, setTables] = useState<TableRow[]>([]);
  const [orders, setOrders] = useState<OrderRow[]>([]);
  const [orderItems, setOrderItems] = useState<OrderItemRow[]>([]);
  const [modifierGroups, setModifierGroups] = useState<ModifierGroup[]>([]);
  const [modifierOptions, setModifierOptions] = useState<ModifierOption[]>([]);
  const [stock, setStock] = useState<Record<string, number>>({});
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [sendingKitchen, setSendingKitchen] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const [stage, setStage] = useState<'start' | 'products'>('start');
  const [draft, setDraft] = useState<DraftContext>(EMPTY_DRAFT);
  const [cart, setCart] = useState<CartLine[]>([]);
  const [categoryId, setCategoryId] = useState('');
  const [search, setSearch] = useState('');
  const [modifierProduct, setModifierProduct] = useState<ProductRow | null>(null);
  const [modifierSelection, setModifierSelection] = useState<Record<string, string[]>>({});

  const productById = useMemo(() => Object.fromEntries(products.map((p) => [p.id, p])), [products]);
  const activeOrderByTable = useMemo(() => {
    const map = new Map<string, OrderRow>();
    for (const order of orders) if (order.table_id) map.set(order.table_id, order);
    return map;
  }, [orders]);

  const load = useCallback(async () => {
    if (!selectedBranchId) return;
    setLoading(true);
    setError(null);
    try {
      const [p, c, a, t, o, mg, mo, w] = await Promise.all([
        supabase.from('products').select('id,name,name_en,category_id,sale_price,image_url').eq('branch_id', selectedBranchId).eq('is_active', true).order('name'),
        supabase.from('categories').select('id,name,name_en').eq('branch_id', selectedBranchId).order('name'),
        supabase.from('dining_areas').select('id,name,sort_order').eq('branch_id', selectedBranchId).order('sort_order'),
        supabase.from('dining_tables').select('id,area_id,name,capacity,status').eq('branch_id', selectedBranchId).eq('is_active', true).order('name'),
        supabase.from('orders').select('id,order_number,order_type,status,table_id,guest_count,subtotal,tax_amount,total').eq('branch_id', selectedBranchId).in('status', ['open', 'held']).order('created_at', { ascending: false }),
        supabase.from('product_modifier_groups').select('id,product_id,name,name_en,min_selections,max_selections,sort_order').eq('branch_id', selectedBranchId).eq('is_active', true).order('sort_order'),
        supabase.from('product_modifier_options').select('id,group_id,name,name_en,price_delta,is_default,sort_order').eq('branch_id', selectedBranchId).eq('is_active', true).order('sort_order'),
        supabase.from('warehouses').select('id,is_default').eq('branch_id', selectedBranchId).eq('is_active', true).order('is_default', { ascending: false }),
      ]);
      const firstError = p.error || c.error || a.error || t.error || o.error || mg.error || mo.error || w.error;
      if (firstError) throw firstError;

      const nextOrders = (o.data || []) as OrderRow[];
      let nextItems: OrderItemRow[] = [];
      if (nextOrders.length > 0) {
        const itemsRes = await supabase.from('order_items').select('id,order_id,product_id,unit_name,quantity,unit_price,discount_amount,bonus_quantity,total,notes,modifier_option_ids').in('order_id', nextOrders.map((row) => row.id));
        if (itemsRes.error) throw itemsRes.error;
        nextItems = (itemsRes.data || []) as OrderItemRow[];
      }

      const warehouseId = ((w.data || []) as { id: string; is_default: boolean }[])[0]?.id;
      let availability: Record<string, number> = {};
      if (warehouseId) {
        const stockRes = await supabase.rpc('get_pos_product_availability', { p_branch_id: selectedBranchId, p_warehouse_id: warehouseId, p_cap: 100000 });
        if (!stockRes.error) {
          availability = Object.fromEntries(((stockRes.data || []) as { product_id: string; available_quantity: number | string }[]).map((row) => [row.product_id, Number(row.available_quantity) || 0]));
        }
      }

      setProducts((p.data || []).map((row) => ({ ...row, sale_price: Number(row.sale_price) })) as ProductRow[]);
      setCategories((c.data || []) as CategoryRow[]);
      setAreas((a.data || []) as AreaRow[]);
      setTables((t.data || []) as TableRow[]);
      setOrders(nextOrders.map((row) => ({ ...row, subtotal: Number(row.subtotal), tax_amount: Number(row.tax_amount), total: Number(row.total) })));
      setOrderItems(nextItems.map((row) => ({ ...row, quantity: Number(row.quantity), unit_price: Number(row.unit_price), discount_amount: Number(row.discount_amount), bonus_quantity: Number(row.bonus_quantity), total: Number(row.total) })));
      setModifierGroups((mg.data || []) as ModifierGroup[]);
      setModifierOptions((mo.data || []).map((row) => ({ ...row, price_delta: Number(row.price_delta) })) as ModifierOption[]);
      setStock(availability);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setLoading(false);
    }
  }, [selectedBranchId]);

  useEffect(() => {
    setStage('start');
    setDraft(EMPTY_DRAFT);
    setCart([]);
    setSearch('');
    setCategoryId('');
    setSuccess(null);
    void load();
  }, [selectedBranchId, load]);

  const startNew = (orderType: OrderType, tableId: string | null = null) => {
    setDraft({ orderType, tableId, guestCount: orderType === 'dine_in' ? 1 : null, existingOrderId: null, existingOrderNumber: null });
    setCart([]);
    setStage('products');
    setSuccess(null);
  };

  const resumeOrder = (order: OrderRow) => {
    const lines = orderItems.filter((item) => item.order_id === order.id).flatMap<CartLine>((item) => {
      if (!item.product_id) return [];
      const product = productById[item.product_id];
      if (!product) return [];
      const optionIds = item.modifier_option_ids || [];
      return [{
        key: makeCartKey(product.id, optionIds),
        product,
        quantity: item.quantity,
        modifierOptionIds: optionIds,
        unitPrice: item.unit_price,
        notes: item.notes || '',
      }];
    });
    setDraft({ orderType: order.order_type, tableId: order.table_id, guestCount: order.guest_count, existingOrderId: order.id, existingOrderNumber: order.order_number });
    setCart(lines);
    setStage('products');
    setSuccess(null);
  };

  const handleTable = (table: TableRow) => {
    if (table.status === 'closed') return;
    const existing = activeOrderByTable.get(table.id);
    if (existing) resumeOrder(existing);
    else if (table.status === 'vacant' || table.status === 'reserved') startNew('dine_in', table.id);
  };

  const groupsForProduct = useCallback((productId: string) => modifierGroups.filter((group) => group.product_id === productId), [modifierGroups]);
  const optionsForGroup = useCallback((groupId: string) => modifierOptions.filter((option) => option.group_id === groupId), [modifierOptions]);

  const openProduct = (product: ProductRow) => {
    const available = stock[product.id] ?? 0;
    if (available <= 0) {
      setError(isAr ? `المنتج غير متاح حاليًا: ${product.name}` : `Product is currently unavailable: ${product.name_en || product.name}`);
      return;
    }
    const groups = groupsForProduct(product.id);
    if (groups.length === 0) {
      addLine(product, []);
      return;
    }
    const defaults: Record<string, string[]> = {};
    for (const group of groups) defaults[group.id] = optionsForGroup(group.id).filter((option) => option.is_default).slice(0, group.max_selections).map((option) => option.id);
    setModifierSelection(defaults);
    setModifierProduct(product);
  };

  const addLine = (product: ProductRow, optionIds: string[]) => {
    const key = makeCartKey(product.id, optionIds);
    const delta = optionIds.reduce((sum, id) => sum + (modifierOptions.find((option) => option.id === id)?.price_delta || 0), 0);
    const unitPrice = Math.max(0, Number(product.sale_price) + delta);
    setCart((current) => {
      const existing = current.find((line) => line.key === key);
      if (existing) {
        const nextQty = existing.quantity + 1;
        if (nextQty > (stock[product.id] ?? 0)) return current;
        return current.map((line) => line.key === key ? { ...line, quantity: nextQty } : line);
      }
      return [...current, { key, product, quantity: 1, modifierOptionIds: optionIds, unitPrice, notes: '' }];
    });
    setError(null);
  };

  const confirmModifiers = () => {
    if (!modifierProduct) return;
    const groups = groupsForProduct(modifierProduct.id);
    for (const group of groups) {
      const selected = modifierSelection[group.id] || [];
      if (selected.length < group.min_selections || selected.length > group.max_selections) {
        setError(isAr ? `اختيارات ${group.name}: المطلوب من ${group.min_selections} إلى ${group.max_selections}` : `${group.name_en || group.name}: choose ${group.min_selections}-${group.max_selections}`);
        return;
      }
    }
    const ids = groups.flatMap((group) => modifierSelection[group.id] || []);
    addLine(modifierProduct, ids);
    setModifierProduct(null);
    setModifierSelection({});
  };

  const changeQty = (key: string, delta: number) => {
    setCart((current) => current.flatMap((line) => {
      if (line.key !== key) return [line];
      const quantity = line.quantity + delta;
      if (quantity <= 0) return [];
      if (quantity > (stock[line.product.id] ?? 0)) return [line];
      return [{ ...line, quantity }];
    }));
  };

  const cartSubtotal = useMemo(() => cart.reduce((sum, line) => sum + line.unitPrice * line.quantity, 0), [cart]);
  const visibleProducts = useMemo(() => {
    const q = search.trim().toLocaleLowerCase();
    return [...products]
      .filter((product) => !categoryId || product.category_id === categoryId)
      .filter((product) => !q || product.name.toLocaleLowerCase().includes(q) || (product.name_en || '').toLocaleLowerCase().includes(q))
      .sort((a, b) => Number((stock[b.id] ?? 0) > 0) - Number((stock[a.id] ?? 0) > 0));
  }, [products, categoryId, search, stock]);

  const saveOrder = async (): Promise<SavedOrder | null> => {
    if (!selectedBranchId || !user?.id || cart.length === 0 || saving) return null;
    if (!can('pos.sell')) {
      setError(isAr ? 'لا توجد صلاحية إنشاء طلب' : 'Missing POS sell permission');
      return null;
    }
    setSaving(true);
    setError(null);
    setSuccess(null);
    const items = cart.map((line) => ({
      product_id: line.product.id,
      unit_name: 'piece',
      quantity: line.quantity,
      unit_price: line.unitPrice,
      discount_amount: 0,
      bonus_quantity: 0,
      total: line.unitPrice * line.quantity,
      modifier_option_ids: line.modifierOptionIds,
      notes: line.notes || null,
    }));
    try {
      const args = {
        p_order_type: draft.orderType,
        p_table_id: draft.tableId,
        p_customer_id: null,
        p_guest_count: draft.guestCount,
        p_notes: null,
        p_items: items,
        p_subtotal: cartSubtotal,
        p_discount_amount: 0,
        p_discount_type: 'amount',
        p_tax_amount: 0,
        p_total: cartSubtotal,
      };
      const result = draft.existingOrderId
        ? await supabase.rpc('update_order', { p_order_id: draft.existingOrderId, ...args, p_status: 'open' })
        : await supabase.rpc('create_order', { p_branch_id: selectedBranchId, ...args, p_cashier_id: user.id });
      if (result.error) throw result.error;
      const payload = result.data as { success?: boolean; error?: string; detail?: string; order_id?: string; order_number?: string } | null;
      if (!payload?.success) throw new Error(payload?.detail || payload?.error || 'ORDER_SAVE_FAILED');
      const orderId = payload.order_id || draft.existingOrderId;
      if (!orderId) throw new Error('ORDER_ID_MISSING');
      const orderNumber = payload.order_number || draft.existingOrderNumber || null;
      setSuccess(draft.existingOrderId
        ? (isAr ? `تم تحديث الطلب ${draft.existingOrderNumber || ''}` : `Order ${draft.existingOrderNumber || ''} updated`)
        : (isAr ? `تم إنشاء الطلب ${payload.order_number || ''}` : `Order ${payload.order_number || ''} created`));
      await load();
      if (!draft.existingOrderId && payload.order_id) {
        setDraft((current) => ({ ...current, existingOrderId: payload.order_id || null, existingOrderNumber: payload.order_number || null }));
      }
      return { orderId, orderNumber };
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
      return null;
    } finally {
      setSaving(false);
    }
  };

  const canSendKitchen = v2Can('pos.send_kitchen');

  const sendToKitchen = async () => {
    if (!user?.id || cart.length === 0 || saving || sendingKitchen) return;
    if (!canSendKitchen) {
      setError(isAr ? 'لا توجد صلاحية إرسال الطلب للمطبخ' : 'Missing kitchen-send permission');
      return;
    }
    setSendingKitchen(true);
    setError(null);
    setSuccess(null);
    try {
      const saved = await saveOrder();
      if (!saved) return;
      const result = await supabase.rpc('send_to_kitchen', { p_order_id: saved.orderId, p_sent_by: user.id });
      if (result.error) throw result.error;
      const payload = result.data as KitchenSendResult | null;
      if (!payload?.success) throw new Error(payload?.detail || payload?.error || 'KITCHEN_SEND_FAILED');
      const count = Number(payload.items_sent_count || 0);
      setSuccess(count > 0
        ? (isAr ? `تم حفظ الطلب وإرسال ${count} بند للمطبخ` : `Order saved and ${count} item${count === 1 ? '' : 's'} sent to kitchen`)
        : (isAr ? 'تم حفظ الطلب ولا توجد إضافات جديدة للإرسال للمطبخ' : 'Order saved; there are no new kitchen changes to send'));
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setSendingKitchen(false);
    }
  };

  const tableSections = areas.length > 0 ? areas : [{ id: '__all', name: isAr ? 'كل الطاولات' : 'All tables', sort_order: 0 }];

  return (
    <V2AppShell activeModule="pos">
      <div className="mx-auto max-w-[1800px]" data-testid="v2-pos-page">
        {error && <div className="mb-3 flex items-start justify-between gap-3 rounded-2xl border border-ui-danger/30 bg-ui-danger-soft p-3 text-sm text-ui-danger"><span>{error}</span><button type="button" onClick={() => setError(null)}><X className="h-4 w-4" /></button></div>}
        {success && <div className="mb-3 flex items-center gap-2 rounded-2xl border border-ui-success/30 bg-ui-success-soft p-3 text-sm font-bold text-ui-success"><Check className="h-4 w-4" />{success}</div>}

        {stage === 'start' ? (
          <div className="space-y-5">
            <section className="rounded-3xl border border-ui-border bg-ui-surface p-5 shadow-ui-sm">
              <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
                <div>
                  <h1 className="text-2xl font-black">{isAr ? 'ابدأ الطلب' : 'Start order'}</h1>
                  <p className="mt-1 text-sm text-ui-muted">{selectedBranch?.name || ''} · {isAr ? 'اختر نوع الطلب أو طاولة' : 'Choose an order type or table'}</p>
                </div>
                <button type="button" onClick={() => void load()} disabled={loading} className="inline-flex h-10 items-center gap-2 rounded-xl border border-ui-border px-3 text-sm font-bold"><RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />{isAr ? 'تحديث' : 'Refresh'}</button>
              </div>
              <div className="mt-5 grid gap-3 sm:grid-cols-3">
                <button type="button" onClick={() => startNew('takeaway')} className="rounded-2xl border border-ui-border bg-ui-page-alt p-5 text-start transition hover:border-ui-primary hover:bg-ui-primary-soft"><ShoppingBag className="h-7 w-7 text-ui-primary" /><div className="mt-3 text-lg font-black">{isAr ? 'طلب سريع / تيك أواي' : 'Quick / Takeaway'}</div></button>
                <button type="button" onClick={() => startNew('delivery')} className="rounded-2xl border border-ui-border bg-ui-page-alt p-5 text-start transition hover:border-ui-primary hover:bg-ui-primary-soft"><Truck className="h-7 w-7 text-ui-primary" /><div className="mt-3 text-lg font-black">{isAr ? 'دليفري' : 'Delivery'}</div></button>
                <button type="button" onClick={() => startNew('drive_thru')} className="rounded-2xl border border-ui-border bg-ui-page-alt p-5 text-start transition hover:border-ui-primary hover:bg-ui-primary-soft"><Car className="h-7 w-7 text-ui-primary" /><div className="mt-3 text-lg font-black">{isAr ? 'درايف ثرو' : 'Drive thru'}</div></button>
              </div>
            </section>

            <section className="rounded-3xl border border-ui-border bg-ui-surface p-5 shadow-ui-sm">
              <div className="flex items-center gap-2"><UtensilsCrossed className="h-5 w-5 text-ui-primary" /><h2 className="text-lg font-black">{isAr ? 'الصالة والطاولات' : 'Dining tables'}</h2></div>
              <div className="mt-4 space-y-5">
                {tableSections.map((area) => {
                  const areaTables = tables.filter((table) => area.id === '__all' || table.area_id === area.id);
                  if (areaTables.length === 0) return null;
                  return <div key={area.id}><div className="mb-2 text-sm font-bold text-ui-muted">{area.name}</div><div className="grid grid-cols-2 gap-2 sm:grid-cols-4 lg:grid-cols-6 xl:grid-cols-8">{areaTables.map((table) => {
                    const order = activeOrderByTable.get(table.id);
                    const occupied = !!order;
                    return <button key={table.id} type="button" disabled={table.status === 'closed'} onClick={() => handleTable(table)} className={`min-h-24 rounded-2xl border p-3 text-start transition ${occupied ? 'border-ui-warning/40 bg-ui-warning-soft' : table.status === 'closed' ? 'cursor-not-allowed border-ui-border bg-ui-page opacity-50' : 'border-ui-border bg-ui-page-alt hover:border-ui-primary hover:bg-ui-primary-soft'}`}>
                      <div className="flex items-center justify-between gap-2"><span className="font-black">{table.name}</span><UsersRound className="h-4 w-4 text-ui-muted" /></div>
                      <div className="mt-2 text-xs text-ui-muted">{isAr ? `السعة ${table.capacity}` : `Capacity ${table.capacity}`}</div>
                      <div className="mt-2 text-xs font-bold">{occupied ? (isAr ? `طلب ${order.order_number}` : `Order ${order.order_number}`) : table.status === 'reserved' ? (isAr ? 'محجوزة' : 'Reserved') : table.status === 'closed' ? (isAr ? 'مغلقة' : 'Closed') : (isAr ? 'متاحة' : 'Available')}</div>
                    </button>;
                  })}</div></div>;
                })}
              </div>
            </section>
          </div>
        ) : (
          <div className="grid min-h-[calc(100vh-7rem)] gap-4 xl:grid-cols-[1fr_390px]">
            <section className="min-w-0 space-y-3">
              <div className="flex flex-wrap items-center gap-2 rounded-2xl border border-ui-border bg-ui-surface p-3 shadow-ui-sm">
                <button type="button" onClick={() => { setStage('start'); setCart([]); setDraft(EMPTY_DRAFT); }} className="inline-flex h-10 items-center gap-2 rounded-xl border border-ui-border px-3 text-sm font-bold"><ArrowRight className={`h-4 w-4 ${isAr ? '' : 'rotate-180'}`} />{isAr ? 'الطلبات والطاولات' : 'Orders & tables'}</button>
                <span className="rounded-xl bg-ui-primary-soft px-3 py-2 text-sm font-black text-ui-primary">{draft.orderType === 'dine_in' ? (isAr ? 'صالة' : 'Dine in') : draft.orderType === 'takeaway' ? (isAr ? 'تيك أواي' : 'Takeaway') : draft.orderType === 'delivery' ? (isAr ? 'دليفري' : 'Delivery') : (isAr ? 'درايف ثرو' : 'Drive thru')}</span>
                {draft.tableId && <span className="rounded-xl bg-ui-page-alt px-3 py-2 text-sm font-bold">{tables.find((table) => table.id === draft.tableId)?.name}</span>}
                {draft.existingOrderNumber && <span className="text-sm font-bold text-ui-warning">#{draft.existingOrderNumber}</span>}
                <div className="ms-auto flex min-w-56 flex-1 items-center gap-2 rounded-xl border border-ui-border bg-ui-page-alt px-3 sm:max-w-md"><Search className="h-4 w-4 text-ui-subtle" /><input value={search} onChange={(event) => setSearch(event.target.value)} className="h-10 w-full bg-transparent text-sm outline-none" placeholder={isAr ? 'بحث بالمنتج...' : 'Search products...'} /></div>
              </div>

              <div className="flex gap-2 overflow-x-auto rounded-2xl border border-ui-border bg-ui-surface p-2 shadow-ui-sm">
                <button type="button" onClick={() => setCategoryId('')} className={`whitespace-nowrap rounded-xl px-3 py-2 text-sm font-bold ${!categoryId ? 'bg-ui-primary text-white' : 'bg-ui-page-alt'}`}>{isAr ? 'الكل' : 'All'}</button>
                {categories.map((category) => <button key={category.id} type="button" onClick={() => setCategoryId(category.id)} className={`whitespace-nowrap rounded-xl px-3 py-2 text-sm font-bold ${categoryId === category.id ? 'bg-ui-primary text-white' : 'bg-ui-page-alt'}`}>{isAr ? category.name : category.name_en || category.name}</button>)}
              </div>

              <div className="grid grid-cols-2 gap-2 sm:grid-cols-3 md:grid-cols-4 2xl:grid-cols-5">
                {visibleProducts.map((product) => {
                  const available = stock[product.id] ?? 0;
                  return <button key={product.id} type="button" onClick={() => openProduct(product)} className={`group relative min-h-36 overflow-hidden rounded-2xl border bg-ui-surface p-3 text-start shadow-ui-sm transition ${available > 0 ? 'border-ui-border hover:border-ui-primary hover:-translate-y-0.5' : 'border-ui-border opacity-55'}`}>
                    <div className="flex h-16 items-center justify-center overflow-hidden rounded-xl bg-ui-page-alt">{product.image_url ? <img src={product.image_url} alt="" className="h-full w-full object-cover" /> : <PackageOpen className="h-8 w-8 text-ui-subtle" />}</div>
                    <div className="mt-2 truncate font-black">{isAr ? product.name : product.name_en || product.name}</div>
                    <div className="mt-1 flex items-center justify-between gap-2 text-xs"><span className="font-bold text-ui-primary">{Number(product.sale_price).toLocaleString(isAr ? 'ar-EG' : 'en-US')}</span><span className={available > 0 ? 'text-ui-success' : 'text-ui-danger'}>{isAr ? `متاح ${available}` : `${available} available`}</span></div>
                    <span className="absolute end-2 top-2 flex h-8 w-8 items-center justify-center rounded-full bg-ui-primary text-white shadow"><Plus className="h-4 w-4" /></span>
                  </button>;
                })}
              </div>
              {!loading && visibleProducts.length === 0 && <div className="rounded-2xl border border-dashed border-ui-border p-10 text-center text-ui-muted">{isAr ? 'لا توجد منتجات مطابقة في هذا الفرع.' : 'No matching products in this branch.'}</div>}
            </section>

            <aside className="flex min-h-0 flex-col rounded-3xl border border-ui-border bg-ui-surface shadow-ui-sm xl:sticky xl:top-20 xl:h-[calc(100vh-6rem)]">
              <div className="border-b border-ui-border p-4"><div className="flex items-center gap-2"><ShoppingCart className="h-5 w-5 text-ui-primary" /><h2 className="text-lg font-black">{isAr ? 'الطلب الحالي' : 'Current order'}</h2><span className="ms-auto rounded-full bg-ui-page-alt px-2 py-1 text-xs font-bold">{cart.reduce((sum, line) => sum + line.quantity, 0)}</span></div></div>
              <div className="flex-1 space-y-2 overflow-y-auto p-3">
                {cart.map((line) => <div key={line.key} className="rounded-2xl border border-ui-border bg-ui-page-alt p-3"><div className="flex items-start gap-2"><div className="min-w-0 flex-1"><div className="truncate font-black">{isAr ? line.product.name : line.product.name_en || line.product.name}</div>{line.modifierOptionIds.length > 0 && <div className="mt-1 text-xs text-ui-muted">{line.modifierOptionIds.map((id) => { const option = modifierOptions.find((item) => item.id === id); return option ? (isAr ? option.name : option.name_en || option.name) : ''; }).filter(Boolean).join(' · ')}</div>}<div className="mt-1 text-sm font-bold text-ui-primary">{(line.unitPrice * line.quantity).toLocaleString(isAr ? 'ar-EG' : 'en-US')}</div></div><button type="button" onClick={() => setCart((current) => current.filter((item) => item.key !== line.key))} className="rounded-lg p-1.5 text-ui-danger hover:bg-ui-danger-soft" aria-label={isAr ? 'حذف' : 'Delete'}><Trash2 className="h-4 w-4" /></button></div><div className="mt-3 flex items-center gap-2"><button type="button" onClick={() => changeQty(line.key, -1)} className="flex h-8 w-8 items-center justify-center rounded-lg border border-ui-border"><Minus className="h-4 w-4" /></button><span className="min-w-8 text-center font-black tabular-nums">{line.quantity}</span><button type="button" onClick={() => changeQty(line.key, 1)} className="flex h-8 w-8 items-center justify-center rounded-lg border border-ui-border"><Plus className="h-4 w-4" /></button></div></div>)}
                {cart.length === 0 && <div className="flex min-h-52 flex-col items-center justify-center text-center text-ui-muted"><ShoppingCart className="mb-3 h-9 w-9 text-ui-subtle" /><div className="font-bold">{isAr ? 'أضف المنتجات للطلب' : 'Add products to the order'}</div><div className="mt-1 text-xs">{isAr ? 'لا يتم إنشاء سجل Order فارغ.' : 'No empty order record is created.'}</div></div>}
              </div>
              <div className="border-t border-ui-border p-4"><div className="mb-3 flex items-center justify-between"><span className="text-sm text-ui-muted">{isAr ? 'الإجمالي المبدئي' : 'Draft subtotal'}</span><span className="text-xl font-black">{cartSubtotal.toLocaleString(isAr ? 'ar-EG' : 'en-US')}</span></div><div className={`grid gap-2 ${canSendKitchen ? 'sm:grid-cols-2' : ''}`}><button type="button" onClick={() => void saveOrder()} disabled={cart.length === 0 || saving || sendingKitchen} className="flex h-12 w-full items-center justify-center gap-2 rounded-xl bg-ui-primary px-4 font-black text-white disabled:opacity-50"><Store className="h-5 w-5" />{saving ? (isAr ? 'جاري الحفظ...' : 'Saving...') : draft.existingOrderId ? (isAr ? 'حفظ تعديلات الطلب' : 'Save order changes') : (isAr ? 'إنشاء الطلب' : 'Create order')}</button>{canSendKitchen && <button type="button" data-testid="v2-pos-send-kitchen" onClick={() => void sendToKitchen()} disabled={cart.length === 0 || saving || sendingKitchen} className="flex h-12 w-full items-center justify-center gap-2 rounded-xl border border-ui-primary bg-ui-primary-soft px-4 font-black text-ui-primary disabled:opacity-50"><Send className="h-5 w-5" />{sendingKitchen ? (isAr ? 'جاري الإرسال...' : 'Sending...') : (isAr ? 'حفظ وإرسال للمطبخ' : 'Save & send to kitchen')}</button>}</div><div className="mt-2 text-center text-[11px] text-ui-subtle">{isAr ? 'يُحفظ الطلب أولًا، والإرسال للمطبخ يرسل التغييرات الجديدة فقط. لا يتم خصم المخزون هنا.' : 'The order is saved first; kitchen send transmits only new changes. Inventory is not deducted here.'}</div></div>
            </aside>
          </div>
        )}
      </div>

      {modifierProduct && <div className="fixed inset-0 z-[80] flex items-center justify-center bg-black/40 p-3"><div className="max-h-[90vh] w-full max-w-xl overflow-y-auto rounded-3xl border border-ui-border bg-ui-surface shadow-2xl"><div className="sticky top-0 flex items-center gap-3 border-b border-ui-border bg-ui-surface p-4"><ChefHat className="h-5 w-5 text-ui-primary" /><div className="min-w-0 flex-1"><div className="font-black">{isAr ? modifierProduct.name : modifierProduct.name_en || modifierProduct.name}</div><div className="text-xs text-ui-muted">{isAr ? 'اختر الخيارات المطلوبة' : 'Choose required options'}</div></div><button type="button" onClick={() => setModifierProduct(null)} className="rounded-lg p-2"><X className="h-5 w-5" /></button></div><div className="space-y-4 p-4">{groupsForProduct(modifierProduct.id).map((group) => { const selected = modifierSelection[group.id] || []; return <div key={group.id} className="rounded-2xl border border-ui-border p-3"><div className="mb-2 flex items-center justify-between gap-3"><div className="font-black">{isAr ? group.name : group.name_en || group.name}</div><div className="text-xs text-ui-muted">{group.min_selections}-{group.max_selections}</div></div><div className="grid gap-2 sm:grid-cols-2">{optionsForGroup(group.id).map((option) => { const checked = selected.includes(option.id); return <button key={option.id} type="button" onClick={() => setModifierSelection((current) => { const now = current[group.id] || []; if (checked) return { ...current, [group.id]: now.filter((id) => id !== option.id) }; if (now.length >= group.max_selections) return group.max_selections === 1 ? { ...current, [group.id]: [option.id] } : current; return { ...current, [group.id]: [...now, option.id] }; })} className={`flex items-center gap-2 rounded-xl border p-3 text-start ${checked ? 'border-ui-primary bg-ui-primary-soft' : 'border-ui-border bg-ui-page-alt'}`}><span className={`flex h-5 w-5 items-center justify-center rounded-md border ${checked ? 'border-ui-primary bg-ui-primary text-white' : 'border-ui-border'}`}>{checked && <Check className="h-3.5 w-3.5" />}</span><span className="min-w-0 flex-1 truncate font-semibold">{isAr ? option.name : option.name_en || option.name}</span>{option.price_delta !== 0 && <span className="text-xs font-bold text-ui-primary">{option.price_delta > 0 ? '+' : ''}{option.price_delta}</span>}</button>; })}</div></div>; })}</div><div className="sticky bottom-0 flex gap-2 border-t border-ui-border bg-ui-surface p-4"><button type="button" onClick={() => setModifierProduct(null)} className="h-11 flex-1 rounded-xl border border-ui-border font-bold">{isAr ? 'إلغاء' : 'Cancel'}</button><button type="button" onClick={confirmModifiers} className="h-11 flex-[2] rounded-xl bg-ui-primary font-black text-white">{isAr ? 'إضافة للطلب' : 'Add to order'}</button></div></div></div>}
    </V2AppShell>
  );
}

export function V2PosPage() {
  return <V2BranchProvider><V2PosContent /></V2BranchProvider>;
}
