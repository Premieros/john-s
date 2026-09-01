from pathlib import Path

p = Path('src/features/pos/components/shift/ShiftModal.tsx')
s = p.read_text()

s = s.replace(
"import { Timer, X, AlertCircle, CheckCircle2, Printer, FileText, ShoppingBag, Utensils, CreditCard } from 'lucide-react';",
"import { Timer, X, AlertCircle, CheckCircle2, Printer, FileText, ShoppingBag, Utensils, CreditCard, LockKeyhole, Banknote } from 'lucide-react';"
)
s = s.replace(
"import * as api from '@/api';",
"import { supabase } from '@/api';\nimport * as api from '@/api';"
)
s = s.replace(
"  const [closing, setClosing] = useState(false);",
"  const [closing, setClosing] = useState(false);\n  const [sensitiveAction, setSensitiveAction] = useState<'force_close' | 'open_drawer' | null>(null);"
)

marker = "  const handleCloseShift = async (e: React.FormEvent) => {"
insert = r'''  const requestManagerApproval = async (
    actionType: 'force_close_shift' | 'open_drawer',
    payload: Record<string, unknown>,
    reason: string,
  ) => {
    if (!activeShift) return false;
    const { data, error } = await supabase.rpc('request_manager_approval', {
      p_action_type: actionType,
      p_entity_type: 'shift',
      p_entity_id: activeShift.id,
      p_payload: payload,
      p_reason: reason,
    });
    if (error) {
      show(error.message, 'error');
      return false;
    }
    const result = data as { success?: boolean; error?: string } | null;
    if (!result?.success) {
      show(result?.error || (isAr ? 'تعذر إرسال طلب الموافقة' : 'Could not request manager approval'), 'error');
      return false;
    }
    return true;
  };

  const handleForceClose = async () => {
    if (!activeShift) return;
    if (typeof closingCash !== 'number') {
      show(isAr ? 'أدخل المبلغ الفعلي أولاً' : 'Enter the actual cash amount first', 'error');
      return;
    }
    setSensitiveAction('force_close');
    try {
      const { data, error } = await api.shifts.forceClose({
        p_shift_id: activeShift.id,
        p_actual_amount: actualAmount,
        p_reason: notes.trim() || null,
      });
      if (error) throw error;
      const result = data as { success?: boolean; error?: string; detail?: string } | null;
      if (!result?.success) {
        if (result?.error === 'APPROVAL_REQUIRED') {
          const requested = await requestManagerApproval(
            'force_close_shift',
            { actual_amount: actualAmount, expected_amount: expectedAmount },
            notes.trim() || (isAr ? 'طلب إغلاق إجباري للوردية' : 'Force-close shift request'),
          );
          if (requested) {
            show(isAr ? 'تم إرسال طلب الإغلاق الإجباري للمدير. بعد الموافقة اضغط إغلاق إجباري مرة أخرى.' : 'Force-close approval requested. After approval, press Force Close again.', 'success');
          }
          return;
        }
        show(result?.detail || result?.error || (isAr ? 'فشل الإغلاق الإجباري' : 'Force close failed'), 'error');
        return;
      }
      show(isAr ? 'تم إغلاق الوردية إجباريًا بنجاح' : 'Shift force-closed successfully', 'success');
      onShiftClosed();
      onClose();
    } catch (err: unknown) {
      show(err instanceof Error ? err.message : 'Error force-closing shift', 'error');
    } finally {
      setSensitiveAction(null);
    }
  };

  const handleOpenDrawer = async () => {
    if (!activeShift) return;
    setSensitiveAction('open_drawer');
    try {
      const reason = notes.trim() || (isAr ? 'طلب فتح درج النقدية' : 'Cash drawer open request');
      const { data, error } = await api.shifts.authorizeOpenDrawer({
        p_shift_id: activeShift.id,
        p_reason: reason,
      });
      if (error) throw error;
      const result = data as { success?: boolean; error?: string; detail?: string; hardware_action_required?: boolean } | null;
      if (!result?.success) {
        if (result?.error === 'APPROVAL_REQUIRED') {
          const requested = await requestManagerApproval('open_drawer', {}, reason);
          if (requested) {
            show(isAr ? 'تم إرسال طلب فتح الدرج للمدير. بعد الموافقة اضغط فتح الدرج مرة أخرى.' : 'Drawer approval requested. After approval, press Open Drawer again.', 'success');
          }
          return;
        }
        show(result?.detail || result?.error || (isAr ? 'فشل تفويض فتح الدرج' : 'Drawer authorization failed'), 'error');
        return;
      }
      if (result.hardware_action_required) {
        show(isAr ? 'تمت الموافقة وتسجيل فتح الدرج. يلزم ربط طابعة/جسر أجهزة لإرسال نبضة الفتح الفعلية.' : 'Drawer opening was authorized and audited. A configured printer/native bridge is required for the physical drawer kick.', 'success');
      } else {
        show(isAr ? 'تم تفويض فتح الدرج' : 'Drawer opening authorized', 'success');
      }
    } catch (err: unknown) {
      show(err instanceof Error ? err.message : 'Error authorizing drawer', 'error');
    } finally {
      setSensitiveAction(null);
    }
  };

'''
if marker not in s:
    raise SystemExit('handleCloseShift marker not found')
s = s.replace(marker, insert + marker, 1)

old = '''              {/* Submit Button */}
              <div className="flex gap-2 pt-2">'''
new = '''              {/* Sensitive manager-approved actions */}
              <div className="grid grid-cols-2 gap-2 rounded-2xl border border-ui-warning/30 bg-ui-warning/5 p-3">
                <button
                  type="button"
                  onClick={handleOpenDrawer}
                  disabled={sensitiveAction !== null}
                  className="flex items-center justify-center gap-2 rounded-xl border border-ui-border bg-ui-surface py-2.5 text-xs font-black text-ui-text hover:bg-ui-page-alt disabled:opacity-50"
                >
                  <Banknote className="h-4 w-4" />
                  {sensitiveAction === 'open_drawer' ? (isAr ? 'جاري الطلب...' : 'Requesting...') : (isAr ? 'فتح الدرج' : 'Open Drawer')}
                </button>
                <button
                  type="button"
                  onClick={handleForceClose}
                  disabled={sensitiveAction !== null || typeof closingCash !== 'number'}
                  className="flex items-center justify-center gap-2 rounded-xl border border-ui-danger/30 bg-ui-danger/5 py-2.5 text-xs font-black text-ui-danger hover:bg-ui-danger/10 disabled:opacity-50"
                >
                  <LockKeyhole className="h-4 w-4" />
                  {sensitiveAction === 'force_close' ? (isAr ? 'جاري الطلب...' : 'Requesting...') : (isAr ? 'إغلاق إجباري' : 'Force Close')}
                </button>
              </div>

              {/* Submit Button */}
              <div className="flex gap-2 pt-2">'''
if old not in s:
    raise SystemExit('submit button marker not found')
s = s.replace(old, new, 1)

required = [
    'api.shifts.forceClose',
    'api.shifts.authorizeOpenDrawer',
    "p_action_type: actionType",
    "'force_close_shift'",
    "'open_drawer'",
    'hardware_action_required',
]
for item in required:
    if item not in s:
        raise SystemExit(f'missing marker: {item}')

p.write_text(s)
