import { useEffect, useMemo, useState } from 'react';
import { Search, Utensils, ShoppingBag, Bike, Zap, Clock3 } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useLanguage } from '@/context/LanguageContext';
import { supabase } from '@/api';
import { formatCurrency } from '@/lib/format';
import type { DiningTable, Order, OrderItem } from '@/lib/types';
import type { OrderKitchenSend } from '../../types';
import { TableCard } from './TableCard';

interface PosTablesSidebarProps {
  tables: DiningTable[];
  ordersByTable: Record<string, Order[]>;
  itemsByOrder: Record<string, OrderItem[]>;
  kitchenSendsByOrder: Record<string, OrderKitchenSend[]>;
  currency: string;
  activeTableId: string | null;
  activeOrderId: string | null;
  collapsed: boolean;
  onToggleCollapse: () => void;
  onSelectTable: (table: DiningTable) => void;
  onTransferOrder?: (order: Order, table: DiningTable) => void;
  onSelectTakeaway?: () => void;
  onSelectDelivery?: () => void;
  activeOrderType?: string;
}

function orderTypeLabel(type: string | null | undefined, ar: boolean) {
  if (type === 'delivery') return ar ? 'توصيل' : 'Delivery';
  if (type === 'takeaway') return ar ? 'سفري' : 'Takeaway';
  if (type === 'drive_thru') return ar ? 'درايف ثرو' : 'Drive Thru';
  if (type === 'quick') return ar ? 'طلب سريع' : 'Quick';
  return ar ? 'طلب نشط' : 'Active order';
}

function OrderTypeIcon({ type }: { type?: string | null }) {
  if (type === 'delivery') return <Bike className="h-4 w-4" />;
  if (type === 'quick') return <Zap className="h-4 w-4" />;
  return <ShoppingBag className="h-4 w-4" />;
}

export function PosTablesSidebar({
  tables,
  ordersByTable,
  itemsByOrder,
  kitchenSendsByOrder,
  currency,
  activeTableId,
  activeOrderId,
  collapsed,
  onToggleCollapse,
  onSelectTable,
  onTransferOrder,
}: PosTablesSidebarProps) {
  const { lang } = useLanguage();
  const isAr = lang === 'ar';
  const navigate = useNavigate();
  const [searchQuery, setSearchQuery] = useState('');
  const [standaloneOrders, setStandaloneOrders] = useState<Order[]>([]);

  const branchId = useMemo(() => {
    const tableBranch = tables[0]?.branch_id;
    if (tableBranch) return tableBranch;
    const tableOrder = Object.values(ordersByTable).flat()[0];
    return tableOrder?.branch_id || '';
  }, [tables, ordersByTable]);

  useEffect(() => {
    let cancelled = false;
    if (!branchId) {
      setStandaloneOrders([]);
      return;
    }

    supabase
      .from('orders')
      .select('*')
      .eq('branch_id', branchId)
      .in('status', ['open', 'held'])
      .is('table_id', null)
      .order('created_at', { ascending: false })
      .then(({ data }) => {
        if (!cancelled) setStandaloneOrders((data as Order[]) || []);
      });

    return () => { cancelled = true; };
  }, [branchId, ordersByTable]);

  const tableOrdersCount = useMemo(
    () => Object.values(ordersByTable).reduce((sum, rows) => sum + rows.length, 0),
    [ordersByTable],
  );

  const filteredTables = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    if (!q) return tables;
    return tables.filter((table) => {
      const orders = ordersByTable[table.id] || [];
      return table.name.toLowerCase().includes(q) || orders.some((o) => o.order_number?.toLowerCase().includes(q));
    });
  }, [tables, ordersByTable, searchQuery]);

  const filteredStandalone = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    if (!q) return standaloneOrders;
    return standaloneOrders.filter((order) =>
      order.order_number?.toLowerCase().includes(q) || orderTypeLabel(order.order_type, isAr).toLowerCase().includes(q),
    );
  }, [standaloneOrders, searchQuery, isAr]);

  if (collapsed) {
    return (
      <aside className="flex h-full w-14 shrink-0 flex-col items-center border-e border-ui-border bg-ui-surface py-3">
        <button
          type="button"
          onClick={onToggleCollapse}
          title={isAr ? 'إظهار الطاولات والطلبات' : 'Show tables and active orders'}
          className="flex h-10 w-10 items-center justify-center rounded-xl border border-ui-border bg-ui-page text-ui-text"
        >
          <Utensils className="h-5 w-5" />
        </button>
        <span className="mt-2 rounded-full bg-ui-primary px-1.5 text-[10px] font-black text-ui-primary-fg">
          {tableOrdersCount + standaloneOrders.length}
        </span>
      </aside>
    );
  }

  return (
    <aside className="flex h-full min-h-0 w-[52vw] max-w-[760px] shrink-0 flex-col border-e border-ui-border bg-ui-surface md:min-w-[430px] lg:w-[48vw] xl:w-[40vw] 2xl:w-[42vw]">
      <div className="shrink-0 border-b border-ui-border px-3 py-2.5">
        <div className="flex items-center justify-between gap-3">
          <div className="min-w-0">
            <h2 className="truncate text-sm font-black text-ui-text">
              {isAr ? 'الطاولات والطلبات النشطة' : 'Tables & Active Orders'}
            </h2>
            <p className="text-[10px] font-bold text-ui-subtle">
              {tables.length} {isAr ? 'طاولة' : 'tables'} · {tableOrdersCount + standaloneOrders.length} {isAr ? 'طلب مفتوح' : 'open orders'}
            </p>
          </div>
          <button
            type="button"
            onClick={onToggleCollapse}
            className="rounded-lg border border-ui-border bg-ui-page px-2.5 py-1.5 text-[10px] font-black text-ui-muted hover:text-ui-text"
          >
            {isAr ? 'تصغير' : 'Collapse'}
          </button>
        </div>

        <div className="relative mt-2">
          <Search className="absolute start-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-ui-muted" />
          <input
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder={isAr ? 'بحث بالطاولة أو رقم الطلب...' : 'Search table or order...'}
            className="h-9 w-full rounded-xl border border-ui-border bg-ui-page ps-8 pe-3 text-xs font-bold text-ui-text outline-none focus:border-ui-primary"
          />
        </div>
      </div>

      <div className="min-h-0 flex-1 overflow-y-auto overscroll-y-contain p-3">
        {filteredStandalone.length > 0 && (
          <section className="mb-4">
            <div className="mb-2 flex items-center gap-2">
              <Zap className="h-4 w-4 text-ui-accent" />
              <h3 className="text-xs font-black text-ui-text">{isAr ? 'طلبات بدون طاولة' : 'Non-table orders'}</h3>
              <span className="rounded-full bg-ui-primary-soft px-2 py-0.5 text-[10px] font-black text-ui-primary">{filteredStandalone.length}</span>
            </div>
            <div className="grid grid-cols-2 gap-2 xl:grid-cols-3">
              {filteredStandalone.map((order) => {
                const selected = activeOrderId === order.id;
                return (
                  <button
                    key={order.id}
                    type="button"
                    onClick={() => navigate(`/pos/${order.id}`)}
                    className={`min-w-0 rounded-xl border p-3 text-start transition ${selected ? 'border-ui-primary bg-ui-primary/10 shadow-ui-sm' : 'border-ui-border bg-ui-page hover:border-ui-primary'}`}
                  >
                    <div className="flex items-start justify-between gap-2">
                      <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-ui-surface text-ui-accent">
                        <OrderTypeIcon type={order.order_type} />
                      </span>
                      <span className={`rounded-md px-1.5 py-0.5 text-[9px] font-black ${order.status === 'held' ? 'bg-ui-warning/15 text-ui-warning' : 'bg-ui-success/15 text-ui-success'}`}>
                        {order.status === 'held' ? (isAr ? 'معلق' : 'Held') : (isAr ? 'نشط' : 'Open')}
                      </span>
                    </div>
                    <p className="mt-2 truncate text-xs font-black text-ui-text">#{order.order_number}</p>
                    <p className="mt-0.5 truncate text-[10px] font-bold text-ui-muted">{orderTypeLabel(order.order_type, isAr)}</p>
                    <div className="mt-2 flex items-center justify-between gap-2">
                      <span className="truncate text-xs font-black text-ui-accent">{formatCurrency(order.total || 0, currency, lang)}</span>
                      <span className="flex shrink-0 items-center gap-1 text-[9px] font-bold text-ui-subtle">
                        <Clock3 className="h-3 w-3" />
                        {order.created_at ? new Date(order.created_at).toLocaleTimeString(isAr ? 'ar-EG' : 'en-US', { hour: '2-digit', minute: '2-digit' }) : ''}
                      </span>
                    </div>
                  </button>
                );
              })}
            </div>
          </section>
        )}

        <section>
          <div className="mb-2 flex items-center gap-2">
            <Utensils className="h-4 w-4 text-ui-primary" />
            <h3 className="text-xs font-black text-ui-text">{isAr ? 'الطاولات' : 'Tables'}</h3>
            <span className="rounded-full bg-ui-page-alt px-2 py-0.5 text-[10px] font-black text-ui-muted">{filteredTables.length}</span>
          </div>

          {filteredTables.length > 0 ? (
            <div className="grid grid-cols-2 gap-2 xl:grid-cols-3">
              {filteredTables.map((table) => (
                <TableCard
                  key={table.id}
                  table={table}
                  orders={ordersByTable[table.id] || []}
                  itemsByOrder={itemsByOrder}
                  kitchenSendsByOrder={kitchenSendsByOrder}
                  currency={currency}
                  isSelected={activeTableId === table.id}
                  onSelect={onSelectTable}
                  onTransfer={onTransferOrder}
                />
              ))}
            </div>
          ) : (
            <div className="py-10 text-center text-xs font-bold text-ui-muted">
              {isAr ? 'لا توجد طاولات مطابقة' : 'No matching tables'}
            </div>
          )}
        </section>
      </div>
    </aside>
  );
}
