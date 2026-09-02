import { useEffect, useMemo, useState } from 'react';
import { Minus, Plus, X, Check, Tag } from 'lucide-react';
import * as api from '@/api';
import { useLanguage } from '@/context/LanguageContext';
import { formatCurrency } from '@/lib/format';
import type { CartItem, Product, ProductModifierGroup } from '@/lib/types';

interface ProductConfigModalProps {
  product: Product | null;
  initialItem?: CartItem | null;
  currency: string;
  isOpen: boolean;
  onClose: () => void;
  onConfirm: (item: CartItem) => void;
  canDiscount?: boolean;
}

interface ModifierResponse {
  success?: boolean;
  error?: string;
  groups?: ProductModifierGroup[];
}

export function ProductConfigModal({
  product,
  initialItem,
  currency,
  isOpen,
  onClose,
  onConfirm,
  canDiscount = true,
}: ProductConfigModalProps) {
  const { t, lang } = useLanguage();
  const isAr = lang === 'ar';
  const [quantity, setQuantity] = useState(1);
  const [groups, setGroups] = useState<ProductModifierGroup[]>([]);
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const [itemNotes, setItemNotes] = useState('');
  const [itemDiscount, setItemDiscount] = useState(0);
  const [loadingModifiers, setLoadingModifiers] = useState(false);
  const [modifierError, setModifierError] = useState('');

  useEffect(() => {
    if (!isOpen || !product) return;
    let cancelled = false;
    setQuantity(initialItem?.quantity || 1);
    setSelectedIds(initialItem?.modifier_option_ids || []);
    setItemNotes(initialItem?.item_note || '');
    setItemDiscount(initialItem?.discount_amount || 0);
    setModifierError('');
    setLoadingModifiers(true);

    api.catalog.getProductModifiers(product.id).then(({ data, error }) => {
      if (cancelled) return;
      if (error) {
        setGroups([]);
        setModifierError(error.message);
        return;
      }
      const res = (data || {}) as ModifierResponse;
      if (!res.success) {
        setGroups([]);
        setModifierError(res.error || (isAr ? 'تعذر تحميل التعديلات' : 'Could not load modifiers'));
        return;
      }
      const loaded = res.groups || [];
      setGroups(loaded);
      if (!initialItem?.modifier_option_ids?.length) {
        const defaults: string[] = [];
        for (const group of loaded) {
          const defaultOptions = group.options.filter((o) => o.is_default).slice(0, group.max_selections);
          defaults.push(...defaultOptions.map((o) => o.id));
        }
        setSelectedIds(defaults);
      }
    }).finally(() => {
      if (!cancelled) setLoadingModifiers(false);
    });

    return () => { cancelled = true; };
  }, [isOpen, product?.id, initialItem, isAr]);

  const optionById = useMemo(() => {
    const map = new Map<string, { group: ProductModifierGroup; option: ProductModifierGroup['options'][number] }>();
    for (const group of groups) for (const option of group.options) map.set(option.id, { group, option });
    return map;
  }, [groups]);

  if (!isOpen || !product) return null;

  const toggleOption = (group: ProductModifierGroup, optionId: string) => {
    setModifierError('');
    setSelectedIds((prev) => {
      const groupOptionIds = new Set(group.options.map((o) => o.id));
      const selectedInGroup = prev.filter((id) => groupOptionIds.has(id));
      if (prev.includes(optionId)) {
        return prev.filter((id) => id !== optionId);
      }
      if (group.max_selections === 1) {
        return [...prev.filter((id) => !groupOptionIds.has(id)), optionId];
      }
      if (selectedInGroup.length >= group.max_selections) return prev;
      return [...prev, optionId];
    });
  };

  const modifierExtra = selectedIds.reduce((sum, id) => sum + Number(optionById.get(id)?.option.price_delta || 0), 0);
  const unitPrice = Math.max(0, Number(product.sale_price || 0) + modifierExtra);
  const lineSubtotal = unitPrice * quantity;
  const lineTotal = Math.max(0, lineSubtotal - itemDiscount);

  const handleSave = () => {
    for (const group of groups) {
      const ids = new Set(group.options.map((o) => o.id));
      const count = selectedIds.filter((id) => ids.has(id)).length;
      if (count < group.min_selections) {
        setModifierError(isAr
          ? `يجب اختيار ${group.min_selections} على الأقل من ${group.name}`
          : `Choose at least ${group.min_selections} from ${group.name_en || group.name}`);
        return;
      }
      if (count > group.max_selections) {
        setModifierError(isAr
          ? `الحد الأقصى ${group.max_selections} في ${group.name}`
          : `Maximum ${group.max_selections} in ${group.name_en || group.name}`);
        return;
      }
    }

    const modifiers = selectedIds.flatMap((id) => {
      const found = optionById.get(id);
      if (!found) return [];
      return [{
        id,
        group_name: isAr ? found.group.name : found.group.name_en || found.group.name,
        name: isAr ? found.option.name : found.option.name_en || found.option.name,
        price_delta: Number(found.option.price_delta || 0),
      }];
    });

    onConfirm({
      product,
      unit_name: initialItem?.unit_name || 'piece',
      quantity,
      unit_price: unitPrice,
      discount_amount: Math.min(Math.max(itemDiscount, 0), lineSubtotal),
      bonus_quantity: initialItem?.bonus_quantity || 0,
      modifier_option_ids: selectedIds,
      modifiers,
      item_note: itemNotes.trim() || undefined,
    });
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-ui-text/50 p-4 backdrop-blur-sm">
      <div className="flex max-h-[90vh] w-full max-w-lg flex-col overflow-hidden rounded-3xl border border-ui-border bg-ui-surface shadow-ui-2xl">
        <div className="flex items-center justify-between border-b border-ui-border px-6 py-4">
          <div className="flex items-center gap-3">
            {product.image_url ? (
              <img src={product.image_url} alt={product.name} className="h-12 w-12 rounded-2xl object-cover" />
            ) : (
              <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-ui-primary-soft text-ui-accent">
                <Tag className="h-6 w-6" />
              </div>
            )}
            <div>
              <h3 className="text-base font-black text-ui-text">{isAr ? product.name : product.name_en || product.name}</h3>
              <p className="text-xs font-bold text-ui-accent">{formatCurrency(product.sale_price, currency, lang)}</p>
            </div>
          </div>
          <button onClick={onClose} aria-label={isAr ? 'إغلاق' : 'Close'} className="flex h-9 w-9 items-center justify-center rounded-xl text-ui-subtle hover:bg-ui-page-alt hover:text-ui-text">
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-6 space-y-6">
          <div>
            <label className="mb-2 block text-xs font-black text-ui-muted">{isAr ? 'الكمية' : 'Quantity'}</label>
            <div className="flex items-center justify-center gap-4 rounded-2xl border border-ui-border bg-ui-page-alt p-3">
              <button type="button" onClick={() => setQuantity((q) => Math.max(1, q - 1))} aria-label={isAr ? 'تقليل' : 'Decrease'} className="flex h-11 w-11 items-center justify-center rounded-xl border border-ui-border bg-ui-surface text-ui-text shadow-ui-sm active:scale-95">
                <Minus className="h-5 w-5" />
              </button>
              <span className="w-16 text-center text-2xl font-black text-ui-text">{quantity}</span>
              <button type="button" onClick={() => setQuantity((q) => q + 1)} aria-label={isAr ? 'زيادة' : 'Increase'} className="flex h-11 w-11 items-center justify-center rounded-xl bg-ui-accent text-ui-primary-fg shadow-ui-sm active:scale-95">
                <Plus className="h-5 w-5" />
              </button>
            </div>
          </div>

          {loadingModifiers && <p className="text-xs font-bold text-ui-muted">{isAr ? 'جاري تحميل الاختيارات...' : 'Loading options...'}</p>}

          {!loadingModifiers && groups.map((group) => {
            const selectedCount = selectedIds.filter((id) => group.options.some((o) => o.id === id)).length;
            return (
              <div key={group.id} data-testid={`modifier-group-${group.id}`}>
                <div className="mb-2 flex items-center justify-between gap-2">
                  <label className="text-xs font-black text-ui-muted">{isAr ? group.name : group.name_en || group.name}</label>
                  <span className="text-[10px] font-bold text-ui-subtle">
                    {group.min_selections > 0 ? (isAr ? 'مطلوب' : 'Required') : (isAr ? 'اختياري' : 'Optional')}
                    {' · '}{selectedCount}/{group.max_selections}
                  </span>
                </div>
                <div className="grid grid-cols-2 gap-2">
                  {group.options.map((option) => {
                    const active = selectedIds.includes(option.id);
                    const delta = Number(option.price_delta || 0);
                    return (
                      <button
                        key={option.id}
                        type="button"
                        data-testid={`modifier-option-${option.id}`}
                        aria-pressed={active}
                        onClick={() => toggleOption(group, option.id)}
                        className={`flex min-h-12 items-center justify-between rounded-xl border p-3 text-xs font-bold transition ${active ? 'border-ui-primary bg-ui-primary-soft text-ui-accent shadow-ui-sm' : 'border-ui-border bg-ui-page-alt text-ui-muted hover:bg-ui-surface'}`}
                      >
                        <span className="flex items-center gap-1.5 text-start">
                          {active && <Check className="h-3.5 w-3.5 shrink-0 text-ui-accent" />}
                          {isAr ? option.name : option.name_en || option.name}
                        </span>
                        {delta !== 0 && <span className="text-[10px] font-black opacity-80">{delta > 0 ? '+' : ''}{formatCurrency(delta, currency, lang)}</span>}
                      </button>
                    );
                  })}
                </div>
              </div>
            );
          })}

          <div>
            <label className="mb-2 block text-xs font-black text-ui-muted">{isAr ? 'ملاحظات خاصة للصنف' : 'Item Notes / Special Instructions'}</label>
            <input type="text" value={itemNotes} onChange={(e) => setItemNotes(e.target.value)} placeholder={isAr ? 'مثال: تسوية خفيفة...' : 'e.g., Well done...'} className="h-11 w-full rounded-xl border border-ui-border bg-ui-page-alt px-4 text-xs font-bold text-ui-text outline-none focus:border-ui-primary focus:ring-2 focus:ring-ui-ring" />
          </div>

          {canDiscount && (
            <div>
              <label className="mb-2 block text-xs font-black text-ui-muted">{isAr ? 'خصم على الصنف' : 'Item Discount'} ({currency})</label>
              <input type="number" min={0} max={lineSubtotal} value={itemDiscount || ''} onChange={(e) => setItemDiscount(parseFloat(e.target.value) || 0)} placeholder="0" className="h-11 w-full rounded-xl border border-ui-border bg-ui-page-alt px-4 text-xs font-bold text-ui-text outline-none focus:border-ui-primary focus:ring-2 focus:ring-ui-ring" />
            </div>
          )}

          {modifierError && <div className="rounded-xl border border-ui-danger/30 bg-ui-danger/10 px-3 py-2 text-xs font-bold text-ui-danger">{modifierError}</div>}
        </div>

        <div className="flex items-center justify-between border-t border-ui-border bg-ui-page-alt px-6 py-4">
          <div>
            <p className="text-[11px] font-bold text-ui-subtle">{isAr ? 'إجمالي الصنف' : 'Line Total'}</p>
            <p className="text-xl font-black text-ui-accent">{formatCurrency(lineTotal, currency, lang)}</p>
          </div>
          <div className="flex gap-2">
            <button type="button" onClick={onClose} className="rounded-xl border border-ui-border bg-ui-surface px-5 py-2.5 text-xs font-black text-ui-muted hover:bg-ui-page-alt">{t('cancel')}</button>
            <button type="button" disabled={loadingModifiers} onClick={handleSave} className="rounded-xl bg-ui-primary px-6 py-2.5 text-xs font-black text-ui-primary-fg shadow-ui-md hover:bg-ui-primary-hover disabled:opacity-50">
              {initialItem ? (isAr ? 'تحديث الصنف' : 'Update Item') : (isAr ? 'إضافة للطلب' : 'Add to Order')}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
