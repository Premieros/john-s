import { useEffect, useMemo, useState } from 'react';
import { ArrowRightLeft, CheckCircle2, Search, UtensilsCrossed } from 'lucide-react';
import { supabase } from '@/api';
import { Modal } from '@/components/Modal';
import { Button } from '@/components/Button';
import { useLanguage } from '@/context/LanguageContext';
import type { CartItem, DiningTable } from '@/lib/types';

interface TransferItemModalProps {
  open: boolean;
  onClose: () => void;
  item: CartItem | null;
  sourceTable: DiningTable | null;
  onConfirm: (targetTableId: string) => Promise<boolean>;
}

export function TransferItemModal({ open, onClose, item, sourceTable, onConfirm }: TransferItemModalProps) {
  const { lang } = useLanguage();
  const isAr = lang === 'ar';
  const [tables, setTables] = useState<DiningTable[]>([]);
  const [query, setQuery] = useState('');
  const [selectedTableId, setSelectedTableId] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [loadingTables, setLoadingTables] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!open || !sourceTable?.branch_id) return;
    let cancelled = false;
    setLoadingTables(true);
    supabase
      .from('dining_tables')
      .select('*')
      .eq('branch_id', sourceTable.branch_id)
      .eq('is_active', true)
      .order('name')
      .then(({ data, error: fetchError }) => {
        if (cancelled) return;
        if (fetchError) {
          setError(fetchError.message);
          setTables([]);
        } else {
          setTables((data as DiningTable[]) || []);
        }
        setLoadingTables(false);
      });
    return () => { cancelled = true; };
  }, [open, sourceTable?.branch_id]);

  const targets = useMemo(() => {
    const q = query.trim().toLowerCase();
    return tables.filter((table) => table.id !== sourceTable?.id && (!q || table.name.toLowerCase().includes(q)));
  }, [tables, sourceTable?.id, query]);

  const execute = async () => {
    if (!selectedTableId || loading) return;
    setLoading(true);
    setError('');
    try {
      const ok = await onConfirm(selectedTableId);
      if (ok) {
        setSelectedTableId(null);
        setQuery('');
        onClose();
      } else {
        setError(isAr ? 'تعذر نقل الصنف. حدّث الطلب وحاول مرة أخرى.' : 'Could not transfer the item. Refresh the order and try again.');
      }
    } finally {
      setLoading(false);
    }
  };

  if (!open || !item || !sourceTable) return null;

  return (
    <Modal open={open} onClose={onClose} title={isAr ? 'نقل الصنف إلى طاولة أخرى' : 'Move item to another table'} size="lg">
      <div className="space-y-4">
        <div className="rounded-2xl border border-ui-border bg-ui-page-alt p-3">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-ui-primary-soft text-ui-accent">
              <ArrowRightLeft className="h-5 w-5" />
            </div>
            <div className="min-w-0 flex-1">
              <p className="truncate text-sm font-black text-ui-text">{item.product.name}</p>
              <p className="text-[11px] font-bold text-ui-subtle">
                {isAr ? `من ${sourceTable.name} · الكمية ${item.quantity}` : `From ${sourceTable.name} · Qty ${item.quantity}`}
              </p>
            </div>
          </div>
          <p className="mt-2 text-[11px] font-bold text-ui-muted">
            {isAr
              ? 'يسمح بالنقل فقط قبل إرسال هذا السطر للمطبخ. لا يتم خصم أو إعادة أي مخزون أثناء النقل.'
              : 'Only unsent lines can be moved. This action never deducts or restores inventory.'}
          </p>
        </div>

        <div className="relative">
          <Search className="absolute start-3 top-1/2 h-4 w-4 -translate-y-1/2 text-ui-subtle" />
          <input
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder={isAr ? 'ابحث عن طاولة...' : 'Search table...'}
            className="h-11 w-full rounded-xl border border-ui-border bg-ui-surface ps-10 pe-3 text-sm font-bold text-ui-text outline-none focus:border-ui-primary"
          />
        </div>

        <div className="max-h-[360px] overflow-y-auto pr-1">
          {loadingTables ? (
            <div className="py-10 text-center text-xs font-bold text-ui-muted">{isAr ? 'جاري تحميل الطاولات...' : 'Loading tables...'}</div>
          ) : (
            <div className="grid grid-cols-2 gap-2 sm:grid-cols-3 md:grid-cols-4">
              {targets.map((table) => {
                const selected = selectedTableId === table.id;
                const occupied = table.status === 'occupied';
                return (
                  <button
                    key={table.id}
                    type="button"
                    data-testid={`transfer-item-target-${table.id}`}
                    onClick={() => {
                      setSelectedTableId(table.id);
                      setError('');
                    }}
                    className={`rounded-xl border p-3 text-start transition ${selected ? 'border-ui-primary bg-ui-primary-soft ring-2 ring-ui-ring' : 'border-ui-border bg-ui-surface hover:border-ui-primary'}`}
                  >
                    <div className="flex items-center justify-between gap-2">
                      <span className="truncate text-xs font-black text-ui-text">{table.name}</span>
                      {selected ? <CheckCircle2 className="h-4 w-4 shrink-0 text-ui-success" /> : <UtensilsCrossed className="h-4 w-4 shrink-0 text-ui-subtle" />}
                    </div>
                    <p className={`mt-2 truncate text-[10px] font-black ${occupied ? 'text-ui-warning' : 'text-ui-success'}`}>
                      {occupied ? (isAr ? 'طلب قائم — سيُضاف إليه' : 'Active order — item will join it') : (isAr ? 'متاحة — سيُفتح طلب جديد' : 'Available — new order will open')}
                    </p>
                  </button>
                );
              })}
            </div>
          )}
          {!loadingTables && targets.length === 0 && (
            <div className="py-10 text-center text-xs font-bold text-ui-muted">{isAr ? 'لا توجد طاولات مطابقة' : 'No matching tables'}</div>
          )}
        </div>

        {error && <div className="rounded-xl border border-ui-danger/20 bg-ui-danger/10 p-3 text-xs font-bold text-ui-danger">{error}</div>}

        <div className="flex items-center justify-end gap-2 border-t border-ui-border pt-3">
          <Button variant="secondary" onClick={onClose} disabled={loading}>{isAr ? 'إلغاء' : 'Cancel'}</Button>
          <Button variant="primary" onClick={() => void execute()} disabled={!selectedTableId || loading || loadingTables}>
            <ArrowRightLeft className="h-4 w-4" />
            {isAr ? 'نقل الصنف' : 'Move item'}
          </Button>
        </div>
      </div>
    </Modal>
  );
}
