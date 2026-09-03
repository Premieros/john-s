import { useMemo, useState } from 'react';
import { Search, Utensils } from 'lucide-react';
import { useLanguage } from '@/context/LanguageContext';
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

export function PosTablesSidebar(props: PosTablesSidebarProps) {
  const {
    tables,
    ordersByTable,
    itemsByOrder,
    kitchenSendsByOrder,
    currency,
    activeTableId,
    collapsed,
    onToggleCollapse,
    onSelectTable,
    onTransferOrder,
  } = props;

  const { lang } = useLanguage();
  const isAr = lang === 'ar';
  const [searchQuery, setSearchQuery] = useState('');

  const occupiedCount = useMemo(
    () => tables.filter((table) => (ordersByTable[table.id] || []).length > 0 || table.status === 'occupied').length,
    [tables, ordersByTable],
  );

  const filteredTables = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    if (!q) return tables;
    return tables.filter((table) => {
      const orders = ordersByTable[table.id] || [];
      return table.name.toLowerCase().includes(q)
        || orders.some((order) => order.order_number?.toLowerCase().includes(q));
    });
  }, [tables, ordersByTable, searchQuery]);

  if (collapsed) {
    return (
      <aside className="flex h-full w-14 shrink-0 flex-col items-center border-e border-ui-border bg-ui-surface py-3">
        <button
          type="button"
          onClick={onToggleCollapse}
          title={isAr ? 'إظهار الطاولات' : 'Show tables'}
          className="flex h-10 w-10 items-center justify-center rounded-xl border border-ui-border bg-ui-page text-ui-text"
        >
          <Utensils className="h-5 w-5" />
        </button>
        <span className="mt-2 rounded-full bg-ui-primary px-1.5 text-[10px] font-black text-ui-primary-fg">
          {occupiedCount}
        </span>
      </aside>
    );
  }

  return (
    <aside className="flex h-full min-h-0 w-[46vw] max-w-[680px] shrink-0 flex-col border-e border-ui-border bg-ui-surface md:min-w-[390px] lg:w-[42vw] xl:w-[36vw] 2xl:w-[38vw]">
      <div className="shrink-0 border-b border-ui-border px-3 py-2.5">
        <div className="flex items-center justify-between gap-3">
          <div className="min-w-0">
            <h2 className="truncate text-sm font-black text-ui-text">
              {isAr ? 'الطاولات' : 'Tables'}
            </h2>
            <p className="text-[10px] font-bold text-ui-subtle">
              {tables.length} {isAr ? 'طاولة' : 'tables'} · {occupiedCount} {isAr ? 'مشغولة' : 'occupied'}
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
            onChange={(event) => setSearchQuery(event.target.value)}
            placeholder={isAr ? 'بحث برقم الطاولة أو الطلب...' : 'Search table or order...'}
            className="h-9 w-full rounded-xl border border-ui-border bg-ui-page ps-8 pe-3 text-xs font-bold text-ui-text outline-none focus:border-ui-primary"
          />
        </div>
      </div>

      <div className="min-h-0 flex-1 overflow-y-auto overscroll-y-contain p-3">
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
      </div>
    </aside>
  );
}
