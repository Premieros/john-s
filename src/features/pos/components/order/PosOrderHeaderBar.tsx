import { useMemo } from 'react';
import {
  Utensils,
  Clock,
  ArrowRightLeft,
  ChefHat,
  Banknote,
  Pause,
  Trash2,
  ShoppingBag,
  Bike,
  Printer,
  UserPlus,
} from 'lucide-react';
import { useLanguage } from '@/context/LanguageContext';
import { formatCurrency } from '@/lib/format';
import type { DiningTable, OrderItem, OrderType } from '@/lib/types';
import type { OrderKitchenSend } from '../../types';
import { orderTypeLabel } from '../../utils/format';

interface PosOrderHeaderBarProps {
  orderNumber: string | null;
  orderId: string | null;
  activeTable: DiningTable | null;
  orderType: OrderType;
  itemsCount: number;
  total: number;
  currency: string;
  createdAt: string | null;
  kitchenSends: OrderKitchenSend[];
  orderItems: OrderItem[];
  kitchenSending: boolean;
  completing: boolean;
  canDiscount?: boolean;
  canDeleteItem?: boolean;
  hasUnsentItems: boolean;
  onOpenTransferModal?: () => void;
  onHoldOrder: () => void;
  onSendKitchen: () => void;
  onPrint: () => void;
  onOpenCustomer: () => void;
  onPay: () => void;
  onClear: () => void;
  onNewOrder: () => void;
}

export function PosOrderHeaderBar({
  orderNumber,
  activeTable,
  orderType,
  itemsCount,
  total,
  currency,
  createdAt,
  kitchenSends,
  kitchenSending,
  completing,
  canDeleteItem = true,
  hasUnsentItems,
  onOpenTransferModal,
  onHoldOrder,
  onSendKitchen,
  onPrint,
  onOpenCustomer,
  onPay,
  onClear,
}: PosOrderHeaderBarProps) {
  const { t, lang } = useLanguage();
  const isAr = lang === 'ar';

  const elapsedText = useMemo(() => {
    if (!createdAt) return null;
    const diff = Math.max(1, Math.round((Date.now() - new Date(createdAt).getTime()) / (1000 * 60)));
    return isAr ? `منذ ${diff} دقيقة` : `${diff}m ago`;
  }, [createdAt, isAr]);

  const hasSent = kitchenSends.length > 0;
  const actionClass = 'flex min-h-11 items-center gap-1.5 rounded-xl border border-ui-border bg-ui-surface px-3 text-xs font-black text-ui-text shadow-ui-xs transition hover:border-ui-primary hover:bg-ui-primary-soft active:scale-95';

  return (
    <div className="flex flex-wrap items-center justify-between gap-2 border-b border-ui-border bg-ui-surface px-3 py-2.5 text-xs select-none shadow-ui-xs">
      <div className="flex min-w-0 flex-wrap items-center gap-2">
        {activeTable ? (
          <div className="flex items-center gap-1.5 rounded-xl bg-ui-primary px-2.5 py-1 text-ui-primary-fg font-black shadow-ui-xs shrink-0">
            <Utensils className="h-3.5 w-3.5" />
            <span>{activeTable.name}</span>
          </div>
        ) : (
          <div className="flex items-center gap-1.5 rounded-xl bg-ui-page-alt border border-ui-border px-2.5 py-1 text-ui-text font-black shrink-0">
            {orderType === 'delivery' ? <Bike className="h-3.5 w-3.5" /> : <ShoppingBag className="h-3.5 w-3.5" />}
            <span>{orderTypeLabel(t, orderType)}</span>
          </div>
        )}
        <div className="flex items-center gap-1 font-black text-ui-text"><span>{orderNumber ? `#${orderNumber}` : t('newOrder')}</span></div>
        <span className="text-ui-muted">·</span>
        <span className="font-bold text-ui-muted">{itemsCount} {isAr ? 'صنف' : 'items'}</span>
        <span className="text-ui-muted">·</span>
        <span className="font-black tabular-nums text-ui-text">{formatCurrency(total, currency, lang)}</span>
        {elapsedText && <><span className="text-ui-muted">·</span><span className="flex items-center gap-1 font-semibold text-ui-subtle"><Clock className="h-3 w-3" />{elapsedText}</span></>}
        {hasSent && (
          <span className={`flex items-center gap-1 rounded-lg border px-2 py-0.5 text-[10px] font-black ${hasUnsentItems ? 'border-amber-500/30 bg-amber-500/15 text-amber-700 animate-pulse' : 'border-sky-500/20 bg-sky-500/10 text-sky-600'}`}>
            <ChefHat className="h-3 w-3" />
            {hasUnsentItems ? (isAr ? 'تعديلات جديدة' : 'New additions') : (isAr ? 'تم الإرسال' : 'Sent to kitchen')}
          </span>
        )}
      </div>

      <div data-testid="pos-order-primary-actions" className="flex shrink-0 flex-wrap items-center gap-1.5">
        <button type="button" data-testid="pos-header-customer" onClick={onOpenCustomer} className={actionClass}>
          <UserPlus className="h-4 w-4 text-ui-accent" />
          <span>{isAr ? 'عميل' : 'Customer'}</span>
        </button>

        {activeTable && onOpenTransferModal && (
          <button type="button" data-testid="pos-header-transfer" onClick={onOpenTransferModal} className={actionClass}>
            <ArrowRightLeft className="h-4 w-4 text-ui-primary" />
            <span>{isAr ? 'نقل' : 'Transfer'}</span>
          </button>
        )}

        {itemsCount > 0 && (
          <button type="button" data-testid="pos-header-hold" onClick={onHoldOrder} className={actionClass}>
            <Pause className="h-4 w-4 text-ui-warning" />
            <span>{isAr ? 'تعليق' : 'Hold'}</span>
          </button>
        )}

        {itemsCount > 0 && (
          <button
            type="button"
            data-testid="pos-header-kitchen"
            onClick={onSendKitchen}
            disabled={kitchenSending || (!hasUnsentItems && hasSent)}
            className={`flex min-h-11 items-center gap-1.5 rounded-xl px-3 text-xs font-black shadow-ui-xs transition active:scale-95 ${hasUnsentItems || !hasSent ? 'bg-amber-500 text-white hover:bg-amber-600' : 'cursor-not-allowed bg-ui-page-alt text-ui-muted'}`}
          >
            <ChefHat className="h-4 w-4" />
            <span>{kitchenSending ? (isAr ? 'إرسال...' : 'Sending...') : hasSent && hasUnsentItems ? (isAr ? 'إرسال الجديد' : 'Send new') : (isAr ? 'المطبخ' : 'Kitchen')}</span>
          </button>
        )}

        {itemsCount > 0 && (
          <button type="button" data-testid="pos-header-print" onClick={onPrint} className={actionClass}>
            <Printer className="h-4 w-4 text-ui-info" />
            <span>{isAr ? 'طباعة' : 'Print'}</span>
          </button>
        )}

        {itemsCount > 0 && (
          <button type="button" data-testid="pos-header-pay" onClick={onPay} disabled={completing} className="flex min-h-11 items-center gap-1.5 rounded-xl bg-ui-success px-3 text-xs font-black text-ui-primary-fg shadow-ui-sm transition hover:brightness-95 active:scale-95 disabled:opacity-50">
            <Banknote className="h-4 w-4" />
            <span>{isAr ? 'دفع' : 'Pay'}</span>
          </button>
        )}

        {itemsCount > 0 && canDeleteItem && (
          <button type="button" data-testid="pos-header-clear" onClick={onClear} aria-label={isAr ? 'مسح الطلب' : 'Clear order'} className="flex h-11 w-11 items-center justify-center rounded-xl border border-ui-danger/20 text-ui-danger transition hover:bg-ui-danger/10">
            <Trash2 className="h-4 w-4" />
          </button>
        )}
      </div>
    </div>
  );
}
