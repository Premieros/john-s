import { useMemo, useState } from 'react';
import { Search, Utensils } from 'lucide-react';
import { useLanguage } from '@/context/LanguageContext';
import type { DiningTable, Order, OrderItem } from '@/lib/types';
import type { OrderKitchenSend } from '../../types';
import { TableCard } from './TableCard';

type TableFilter = 'all' | 'available' | 'occupied';

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

export function PosTablesSidebar(props: PosTablesSidebarProps) {
  const {
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
  } = props;
  const { lang } = useLanguage();
  const isAr = lang === 'ar';
  const [searchQuery, setSearchQuery] = useState('');
  const [filter, setFilter] = useState<TableFilter>('all');

  const occupiedCount = useMemo(
    () => tables.filter((table) => (ordersByTable[table.id] || []).length > 0 || table.status === 'occupied').length,
    [tables, ordersByTable],
  );
  const availableCount = Math.max(0, tables.length - occupiedCount);

  const filteredTables = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    return tables.filter((table) => {
      const orders = ordersByTable[table.id] || [];
      const occupied = orders.length > 0 || table.status === 'occupied';
      if (filter === 'available' && occupied) return false;
      if (filter === 'occupied' && !occupied) return false;
      if (!q) return true;
      return table.name.toLowerCase().includes(q) || orders.some((order) => order.order_number?.toLowerCase().includes(q));
    });
  }, [tables, ordersByTable, searchQuery, filter]);

  // Keep the tables-first landing visible until a real table/order workspace
  // exists. OrderType defaults to takeaway before the operator chooses a flow,
  // so it must never be used as the signal for hiding this landing area.
  if (activeTableId || activeOrderId) return null;

  if (collapsed) {
    return (
      <aside className="flex h-full w-14 shrink-0 flex-col items-center border-e border-ui-border bg-ui-surface py-3">
        <button type="button" onClick={onToggleCollapse} title={isAr ? 'إظهار الطاولات' : 'Show tables'} className="flex h-10 w-10 items-center justify-center rounded-xl border border-ui-border bg-ui-page text-ui-text"><Utensils className="h-5 w-5" /></button>
        <span className="mt-2 rounded-full bg-ui-primary px-1.5 text-[10px] font-black text-ui-primary-fg">{occupiedCount}</span>
      </aside>
    );
  }

  const filters: Array<{ id: TableFilter; ar: string; en: string; count: number }> = [
    { id: 'all', ar: 'الكل', en: 'All', count: tables.length },
    { id: 'available', ar: 'متاحة', en: 'Available', count: availableCount },
    { id: 'occupied', ar: 'مشغولة', en: 'Occupied', count: occupiedCount },
  ];

  return (
    <aside data-testid="pos-tables-workspace" className="flex h-full min-h-0 w-[30vw] min-w-[330px] max-w-[470px] shrink-0 flex-col border-e border-ui-border bg-ui-surface 2xl:max-w-[520px]">
      <div className="shrink-0 border-b border-ui-border px-3 py-3">
        <div className="flex items-center justify-between gap-3">
          <div>
            <h2 className="text-base font-black text-ui-text">{isAr ? 'الطاولات' : 'Tables'}</h2>
            <p className="mt-0.5 text-[10px] font-bold text-ui-subtle">{isAr ? 'اختر طاولة لفتح أو استئناف الطلب' : 'Choose a table to open or resume an order'}</p>
          </div>
          <button type="button" onClick={onToggleCollapse} className="rounded-lg border border-ui-border bg-ui-page px-2.5 py-1.5 text-[10px] font-black text-ui-muted hover:text-ui-text">{isAr ? 'تصغير' : 'Collapse'}</button>
        </div>

        <div className="relative mt-3">
          <Search className="absolute start-3 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-ui-muted" />
          <input value={searchQuery} onChange={(event) => setSearchQuery(event.target.value)} placeholder={isAr ? 'ابحث برقم الطاولة أو الطلب...' : 'Search table or order...'} className="h-10 w-full rounded-xl border border-ui-border bg-ui-page ps-9 pe-3 text-xs font-bold text-ui-text outline-none focus:border-ui-primary" />
        </div>

        <div className="mt-2 grid grid-cols-3 gap-1.5" data-testid="pos-table-filters">
          {filters.map((item) => (
            <button key={item.id} type="button" onClick={() => setFilter(item.id)} className={`rounded-lg border px-2 py-2 text-[10px] font-black transition ${filter === item.id ? 'border-ui-primary bg-ui-primary text-ui-primary-fg' : 'border-ui-border bg-ui-page text-ui-muted hover:border-ui-primary'}`}>
              {isAr ? item.ar : item.en} <span className="ms-1 opacity-70">{item.count}</span>
            </button>
          ))}
        </div>
      </div>

      <div className="min-h-0 flex-1 overflow-y-auto overscroll-y-contain p-3">
        {filteredTables.length > 0 ? (
          <div className="grid grid-cols-3 gap-2">
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
        ) : <div className="py-10 text-center text-xs font-bold text-ui-muted">{isAr ? 'لا توجد طاولات مطابقة' : 'No matching tables'}</div>}
      </div>
    </aside>
  );
}
