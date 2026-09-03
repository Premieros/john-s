import { useState } from 'react';
import {
  ArrowRightLeft,
  Banknote,
  Check,
  ChefHat,
  Clock,
  Minus,
  Pause,
  Percent,
  Plus,
  Printer,
  ShoppingCart,
  Trash2,
  User,
  UtensilsCrossed,
  X,
} from 'lucide-react';
import { useLanguage } from '@/context/LanguageContext';
import { formatCurrency } from '@/lib/format';
import type { CartItem, Customer, DiningTable, OrderItem, OrderType } from '@/lib/types';
import type { KitchenSendItem } from '../../types';
import { computeSentState } from '../../utils/sentState';
import { cartLineKey, orderItemLineKey } from '../../utils/cart';
import { formatClockTime, timeAgo } from '../../utils/timeAgo';
import { deriveCartStage } from '../../utils/orderStage';
import { ORDER_TYPES } from '../../utils/orderTypes';
import { orderTypeLabel } from '../../utils/format';
import { OrderTypePill } from './OrderTypePill';
import { OrderStageBadge } from './OrderStageBadge';
import { TransferItemModal } from '../tables/TransferItemModal';

interface CurrentOrderPanelProps {
  cart: CartItem[];
  currency: string;
  subtotal: number;
  discountValue: number;
  discountType: 'amount' | 'percent';
  discountAmount: number;
  taxRate: number;
  taxAmount: number;
  total: number;
  completing: boolean;
  orderLoading: boolean;
  kitchenSending: boolean;
  orderType: OrderType;
  activeOrderNumber: string | null;
  activeOrderId: string | null;
  activeTable: DiningTable | null;
  guestCount: number | null;
  customerId: string;
  customerById: Record<string, Customer>;
  orderNotes: string;
  activeOrderCreatedAt: string | null;
  orderItems: OrderItem[];
  sentOrderItemIds: Set<string>;
  sessionSent: KitchenSendItem[];
  canDiscount?: boolean;
  canDeleteItem?: boolean;
  onSwitchOrderType: (ot: OrderType) => void;
  onGuestCountChange: (n: number | null) => void;
  onDiscountTypeChange: (v: 'amount' | 'percent') => void;
  onDiscountAmountChange: (v: number) => void;
  onUpdateQty: (lineKey: string, delta: number) => void;
  onSetQty: (lineKey: string, qty: number) => void;
  onRemove: (lineKey: string) => void;
  onClear: () => void;
  onSetItemDiscount: (lineKey: string, discount: number) => void;
  onHold: () => void;
  onSendKitchen: () => void;
  onPrint: () => void;
  onPay: () => void;
  onAddItem?: () => void;
  onConfigureItem?: (item: CartItem) => void;
  onOpenCustomerModal?: () => void;
  onOpenTableModal?: () => void;
  onVoidItem?: (item: CartItem, sentQty: number) => void;
}

export function CurrentOrderPanel({
  cart,
  currency,
  subtotal,
  discountValue,
  discountType,
  discountAmount,
  total,
  completing,
  orderLoading,
  kitchenSending,
  orderType,
  activeOrderNumber,
  activeOrderId,
  activeTable,
  guestCount,
  customerId,
  customerById,
  orderNotes,
  activeOrderCreatedAt,
  orderItems,
  sentOrderItemIds,
  sessionSent,
  canDiscount = true,
  canDeleteItem = true,
  onSwitchOrderType,
  onGuestCountChange,
  onDiscountTypeChange,
  onDiscountAmountChange,
  onUpdateQty,
  onRemove,
  onClear,
  onHold,
  onSendKitchen,
  onPrint,
  onPay,
  onConfigureItem,
  onOpenCustomerModal,
  onOpenTableModal,
  onVoidItem,
}: CurrentOrderPanelProps) {
  const { t, lang } = useLanguage();
  const isAr = lang === 'ar';
  const [showDiscount, setShowDiscount] = useState(false);
  const [splitItem, setSplitItem] = useState<CartItem | null>(null);

  const sentState = computeSentState(cart, orderItems, sentOrderItemIds, sessionSent);
  const newCount = cart.filter((item) => (sentState[cartLineKey(item)]?.newQty || 0) > 0).length;
  const allSent = cart.length > 0 && newCount === 0;
  const ago = activeOrderCreatedAt ? timeAgo(activeOrderCreatedAt) : null;
  const stage = deriveCartStage(cart, sentState, false);
  const empty = cart.length === 0;
  const currentCustomer = customerId ? customerById[customerId] : null;
  const splitLineKey = splitItem ? cartLineKey(splitItem) : null;
  const splitOrderItemMatches = splitLineKey ? orderItems.filter((row) => orderItemLineKey(row) === splitLineKey) : [];
  const splitOrderItemId = splitOrderItemMatches.length === 1 ? splitOrderItemMatches[0].id : null;

  const applyCompletedSplit = (quantity: number) => {
    if (!splitItem) return;
    const lineKey = cartLineKey(splitItem);
    if (quantity >= splitItem.quantity) onRemove(lineKey);
    else onUpdateQty(lineKey, -quantity);
    setSplitItem(null);
  };

  return (
    <div className="flex h-full min-h-0 flex-col bg-ui-surface">
      <div className="shrink-0 border-b border-ui-border px-3 py-2.5">
        <div className="flex items-center gap-2">
          <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-ui-primary-soft">
            <ShoppingCart className="h-4 w-4 text-ui-accent" />
          </div>
          <div className="min-w-0 flex-1">
            <div className="flex items-center gap-2">
              <p className="truncate text-sm font-black text-ui-text">{activeOrderNumber ? `#${activeOrderNumber}` : t('newOrder')}</p>
              <OrderStageBadge stage={stage} />
            </div>
            <p className="text-[10px] font-bold text-ui-subtle">{cart.length} {isAr ? 'صنف' : 'items'}</p>
          </div>
          {activeOrderId && !empty && canDeleteItem && (
            <button type="button" onClick={onClear} aria-label={isAr ? 'مسح الطلب' : 'Clear order'} className="rounded-lg p-2 text-ui-subtle transition hover:bg-ui-danger/10 hover:text-ui-danger">
              <Trash2 className="h-4 w-4" />
            </button>
          )}
        </div>

        <div className="mt-2 flex flex-wrap items-center gap-1.5">
          {activeOrderNumber ? (
            <OrderTypePill type={orderType} />
          ) : (
            <div className="flex items-center gap-1 rounded-xl bg-ui-page-alt p-1">
              {ORDER_TYPES.map((type) => (
                <button
                  key={type}
                  type="button"
                  data-testid={`pos-switch-type-${type}`}
                  aria-pressed={type === orderType}
                  onClick={() => onSwitchOrderType(type)}
                  className={`rounded-lg px-2.5 py-1 text-[10px] font-black transition ${type === orderType ? 'bg-ui-primary text-ui-primary-fg shadow-ui-sm' : 'text-ui-muted hover:text-ui-text'}`}
                >
                  {orderTypeLabel(t, type)}
                </button>
              ))}
            </div>
          )}

          {orderType === 'dine_in' && (
            <button type="button" onClick={onOpenTableModal} className="flex items-center gap-1 rounded-lg bg-ui-page-alt px-2 py-1 text-[10px] font-black text-ui-muted transition hover:text-ui-text">
              <UtensilsCrossed className="h-3 w-3 text-ui-success" />
              <span className="max-w-[100px] truncate">{activeTable?.name || (isAr ? 'اختر طاولة' : 'Select table')}</span>
            </button>
          )}

          <button type="button" onClick={onOpenCustomerModal} className="flex items-center gap-1 rounded-lg bg-ui-page-alt px-2 py-1 text-[10px] font-black text-ui-muted transition hover:text-ui-text">
            <User className="h-3 w-3 text-ui-accent" />
            <span className="max-w-[100px] truncate">{currentCustomer?.name || (isAr ? 'عميل عام' : 'General')}</span>
          </button>

          {orderType === 'dine_in' && (
            <label className="flex items-center gap-1 text-[10px] font-bold text-ui-muted">
              {isAr ? 'أفراد' : 'Guests'}
              <input type="number" min={1} value={guestCount || ''} onChange={(event) => onGuestCountChange(parseInt(event.target.value) || null)} className="w-12 rounded-lg border border-ui-border bg-ui-surface-raised px-1.5 py-1 text-center text-xs font-black text-ui-text outline-none focus:border-ui-primary" />
            </label>
          )}

          {activeOrderCreatedAt && (
            <span className="ms-auto flex items-center gap-1 text-[10px] font-bold text-ui-subtle">
              <Clock className="h-3 w-3" />
              {formatClockTime(activeOrderCreatedAt, lang)}
              {ago && <span className="hidden 2xl:inline">· {ago.n != null ? `${ago.n} ${t(ago.key)}` : t(ago.key)}</span>}
            </span>
          )}
        </div>

        {orderNotes && <p className="mt-2 truncate rounded-lg bg-ui-page-alt px-2 py-1 text-[10px] font-bold text-ui-subtle">{orderNotes}</p>}
      </div>

      <div className="min-h-0 flex-1 overflow-y-auto p-2.5">
        {empty ? (
          <div className="flex h-full flex-col items-center justify-center text-center text-ui-subtle">
            <div className="mb-3 flex h-16 w-16 items-center justify-center rounded-2xl bg-ui-page-alt"><ShoppingCart className="h-8 w-8 opacity-30" /></div>
            <p className="text-sm font-black">{t('emptyCart')}</p>
            <p className="mt-1 text-[10px] font-bold">{isAr ? 'اختر منتجًا من القائمة' : 'Choose a product from the catalog'}</p>
          </div>
        ) : (
          <div className="space-y-2">
            {cart.map((item) => {
              const lineKey = cartLineKey(item);
              const sent = sentState[lineKey] || { sentQty: 0, newQty: item.quantity, sent: false, partial: false };
              const matches = orderItems.filter((row) => orderItemLineKey(row) === lineKey);
              const canSplit = !!activeOrderId && sent.sentQty === 0 && matches.length === 1;
              return (
                <div key={lineKey} data-testid={`pos-cart-line-${item.product.id}`} className="rounded-2xl border border-ui-border bg-ui-page-alt p-2.5 transition hover:border-ui-border-strong">
                  <div className="flex items-center gap-2">
                    <button type="button" onClick={() => onConfigureItem?.(item)} className="min-w-0 flex-1 text-start">
                      <div className="flex items-center gap-1.5">
                        <p className="truncate text-xs font-black text-ui-text">{item.product.name}</p>
                        {sent.sent && <Check className="h-3 w-3 shrink-0 text-ui-success" />}
                      </div>
                      {item.modifiers?.length ? <p className="mt-0.5 truncate text-[9px] font-bold text-ui-subtle">{item.modifiers.map((modifier) => modifier.name).join(' · ')}</p> : null}
                      {item.item_note ? <p className="mt-0.5 truncate text-[9px] font-bold text-ui-subtle">📝 {item.item_note}</p> : null}
                    </button>
                    <span className="shrink-0 text-xs font-black text-ui-accent">{formatCurrency(item.quantity * item.unit_price - (item.discount_amount || 0), currency, lang)}</span>
                  </div>

                  <div className="mt-2 flex items-center gap-1.5 border-t border-ui-border/70 pt-2">
                    <button data-testid={`pos-cart-qty-decrease-${item.product.id}`} aria-label={isAr ? `تقليل كمية ${item.product.name}` : `Decrease quantity ${item.product.name}`} onClick={() => sent.sentQty > 0 && item.quantity <= sent.sentQty && onVoidItem ? onVoidItem(item, sent.sentQty) : onUpdateQty(lineKey, -1)} className="flex h-7 w-7 items-center justify-center rounded-lg border border-ui-border bg-ui-surface text-ui-text"><Minus className="h-3.5 w-3.5" /></button>
                    <span data-testid={`pos-cart-qty-${item.product.id}`} className="w-7 text-center text-xs font-black text-ui-text">{item.quantity}</span>
                    <button data-testid={`pos-cart-qty-increase-${item.product.id}`} aria-label={isAr ? `زيادة كمية ${item.product.name}` : `Increase quantity ${item.product.name}`} onClick={() => onUpdateQty(lineKey, 1)} className="flex h-7 w-7 items-center justify-center rounded-lg bg-ui-primary text-ui-primary-fg"><Plus className="h-3.5 w-3.5" /></button>

                    <div className="ms-auto flex items-center gap-1">
                      {canSplit && (
                        <button
                          type="button"
                          data-testid={`pos-split-item-${item.product.id}`}
                          onClick={() => setSplitItem(item)}
                          aria-label={isAr ? `فصل ${item.product.name} إلى طلب آخر` : `Split ${item.product.name} to another order`}
                          title={isAr ? 'Split — فصل الصنف إلى طلب سريع أو طاولة' : 'Split item to quick order or table'}
                          className="flex h-7 items-center justify-center gap-1 rounded-lg border border-ui-border bg-ui-surface px-2 text-[9px] font-black text-ui-muted transition hover:border-ui-primary hover:text-ui-accent"
                        >
                          <ArrowRightLeft className="h-3.5 w-3.5" />
                          <span>Split</span>
                        </button>
                      )}
                      {canDeleteItem && (
                        <button type="button" onClick={() => sent.sentQty > 0 && onVoidItem ? onVoidItem(item, sent.sentQty) : onRemove(lineKey)} aria-label={isAr ? `حذف ${item.product.name}` : `Remove ${item.product.name}`} className="flex h-7 w-7 items-center justify-center rounded-lg border border-ui-border bg-ui-surface text-ui-subtle transition hover:border-ui-danger hover:text-ui-danger"><X className="h-3.5 w-3.5" /></button>
                      )}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      <div className="shrink-0 space-y-2 border-t border-ui-border p-3">
        <div className="grid grid-cols-3 gap-2">
          <div className="rounded-xl bg-ui-page-alt p-2"><p className="text-[9px] font-bold text-ui-subtle">{t('subtotal')}</p><p className="mt-0.5 truncate text-xs font-black text-ui-text">{formatCurrency(subtotal, currency, lang)}</p></div>
          <div className="rounded-xl bg-ui-page-alt p-2"><p className="text-[9px] font-bold text-ui-subtle">{t('discount')}</p><p data-testid="pos-discount-value" className="mt-0.5 truncate text-xs font-black text-ui-text">{formatCurrency(discountValue, currency, lang)}</p></div>
          <div className="rounded-xl bg-ui-primary-soft p-2"><p className="text-[9px] font-bold text-ui-subtle">{t('total')}</p><p data-testid="pos-total-value" className="mt-0.5 truncate text-sm font-black text-ui-accent">{formatCurrency(total, currency, lang)}</p></div>
        </div>

        <div className="grid grid-cols-5 gap-1.5">
          {canDiscount && <button data-testid="pos-action-discount" aria-label={isAr ? 'الخصم (F6)' : 'Discount (F6)'} title={isAr ? 'الخصم (F6)' : 'Discount (F6)'} onClick={() => setShowDiscount((value) => !value)} className={`flex h-10 items-center justify-center rounded-xl ${showDiscount ? 'bg-ui-primary text-ui-primary-fg' : 'bg-ui-page-alt text-ui-text'}`}><Percent className="h-4 w-4" /></button>}
          <button data-testid="pos-action-hold" aria-label={isAr ? 'تعليق الطلب (F4)' : 'Hold order (F4)'} title={isAr ? 'تعليق الطلب (F4)' : 'Hold order (F4)'} onClick={onHold} disabled={empty || orderLoading} className="flex h-10 items-center justify-center rounded-xl bg-ui-page-alt text-ui-text disabled:opacity-40"><Pause className="h-4 w-4" /></button>
          <button data-testid="pos-action-send-kitchen" aria-label={isAr ? 'إرسال للمطبخ' : 'Send to kitchen'} title={isAr ? 'إرسال للمطبخ' : 'Send to kitchen'} onClick={onSendKitchen} disabled={empty || kitchenSending || allSent} className="flex h-10 items-center justify-center rounded-xl bg-ui-page-alt text-ui-text disabled:opacity-40"><ChefHat className="h-4 w-4" /></button>
          <button data-testid="pos-action-print" aria-label={isAr ? 'طباعة (F9)' : 'Print (F9)'} title={isAr ? 'طباعة (F9)' : 'Print (F9)'} onClick={onPrint} disabled={empty} className="flex h-10 items-center justify-center rounded-xl bg-ui-page-alt text-ui-text disabled:opacity-40"><Printer className="h-4 w-4" /></button>
          <button data-testid="pos-action-pay" aria-label={isAr ? 'الدفع (F8)' : 'Pay (F8)'} onClick={onPay} disabled={empty || completing} className="flex h-10 items-center justify-center gap-1 rounded-xl bg-ui-success px-2 text-[10px] font-black text-ui-primary-fg shadow-ui-sm disabled:opacity-40"><Banknote className="h-4 w-4" /><span className="hidden xl:inline">{isAr ? 'دفع' : 'Pay'}</span></button>
        </div>

        {showDiscount && (
          <div data-testid="pos-discount-editor" className="rounded-xl border border-ui-border bg-ui-page-alt p-2">
            <div className="flex gap-2">
              <button data-testid="pos-discount-percent" type="button" onClick={() => onDiscountTypeChange('percent')} className={`flex-1 rounded-lg p-2 text-xs font-black ${discountType === 'percent' ? 'bg-ui-primary text-ui-primary-fg' : 'bg-ui-surface text-ui-muted'}`}>%</button>
              <button data-testid="pos-discount-amount" type="button" onClick={() => onDiscountTypeChange('amount')} className={`flex-1 rounded-lg p-2 text-xs font-black ${discountType === 'amount' ? 'bg-ui-primary text-ui-primary-fg' : 'bg-ui-surface text-ui-muted'}`}>{currency}</button>
              <input data-testid="pos-discount-input" aria-label={isAr ? 'قيمة الخصم' : 'Discount value'} type="number" min={0} value={discountAmount || ''} onChange={(event) => onDiscountAmountChange(parseFloat(event.target.value) || 0)} className="w-24 rounded-lg border border-ui-border bg-ui-surface p-2 text-center text-xs font-black text-ui-text" />
            </div>
          </div>
        )}
      </div>

      <TransferItemModal
        open={!!splitItem}
        onClose={() => setSplitItem(null)}
        item={splitItem}
        orderId={activeOrderId}
        orderItemId={splitOrderItemId}
        sourceTable={activeTable}
        onCompleted={applyCompletedSplit}
      />
    </div>
  );
}