import { useCallback, useEffect, useMemo, useState } from 'react';
import { CalendarDays, CheckCircle2, Clock3, RefreshCw, UserRound, WalletCards, X } from 'lucide-react';
import { supabase } from '@/api';
import { useAuth } from '@/context/AuthContext';
import { useLanguage } from '@/context/LanguageContext';
import { useCan } from '@/lib/permissions';
import { V2AppShell } from '@/v2/components/V2AppShell';
import { V2BranchProvider, useV2Branch } from '@/v2/context/V2BranchContext';

type ShiftRow = {
  id: string;
  branch_id: string;
  cashier_id: string;
  status: 'open' | 'closed';
  opened_at: string;
  closed_at: string | null;
  opening_amount: number;
  expected_amount: number | null;
  actual_amount: number | null;
  difference: number | null;
  notes: string | null;
};

type UserRow = { id: string; full_name: string | null; email: string | null };

type ActiveShift = {
  id: string;
  branch_id: string;
  cashier_id: string;
  opened_at: string;
  opening_amount: number;
  expected: number;
  cash_sales: number;
  total_sales: number;
  notes: string | null;
};

type RpcResult = {
  success?: boolean;
  open?: boolean;
  error?: string;
  detail?: string;
  shift?: ActiveShift;
  shift_id?: string;
  expected?: number;
  actual?: number;
  difference?: number;
  [key: string]: unknown;
};

function money(value: unknown, locale: string) {
  const n = Number(value ?? 0);
  return Number.isFinite(n) ? n.toLocaleString(locale, { maximumFractionDigits: 2 }) : '0';
}

function V2ShiftsContent() {
  const { lang } = useLanguage();
  const isAr = lang === 'ar';
  const locale = isAr ? 'ar-EG' : 'en-US';
  const { user } = useAuth();
  const can = useCan();
  const { selectedBranchId, selectedBranch } = useV2Branch();

  const [shifts, setShifts] = useState<ShiftRow[]>([]);
  const [users, setUsers] = useState<UserRow[]>([]);
  const [activeShift, setActiveShift] = useState<ActiveShift | null>(null);
  const [loading, setLoading] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const today = new Date().toISOString().slice(0, 10);
  const [day, setDay] = useState(today);
  const [userId, setUserId] = useState(user?.id || '');
  const [shiftId, setShiftId] = useState('');
  const [userReport, setUserReport] = useState<RpcResult | null>(null);
  const [shiftReport, setShiftReport] = useState<RpcResult | null>(null);
  const [dayReport, setDayReport] = useState<RpcResult | null>(null);

  const [closeDialog, setCloseDialog] = useState(false);
  const [actualAmount, setActualAmount] = useState('');
  const [closeNotes, setCloseNotes] = useState('');

  const load = useCallback(async () => {
    if (!selectedBranchId || !user?.id) return;
    setLoading(true);
    setError(null);
    try {
      const [shiftRows, branchUsers, active] = await Promise.all([
        supabase
          .from('shifts')
          .select('id,branch_id,cashier_id,status,opened_at,closed_at,opening_amount,expected_amount,actual_amount,difference,notes')
          .eq('branch_id', selectedBranchId)
          .order('opened_at', { ascending: false })
          .limit(100),
        supabase
          .from('users')
          .select('id,full_name,email')
          .eq('is_active', true)
          .or(`branch_id.eq.${selectedBranchId},id.eq.${user.id}`)
          .order('full_name'),
        supabase.rpc('get_active_shift', { p_branch_id: null }),
      ]);

      const firstError = shiftRows.error || branchUsers.error || active.error;
      if (firstError) throw firstError;

      setShifts(((shiftRows.data || []) as ShiftRow[]).map((row) => ({
        ...row,
        opening_amount: Number(row.opening_amount || 0),
        expected_amount: row.expected_amount == null ? null : Number(row.expected_amount),
        actual_amount: row.actual_amount == null ? null : Number(row.actual_amount),
        difference: row.difference == null ? null : Number(row.difference),
      })));
      setUsers((branchUsers.data || []) as UserRow[]);
      const activeResult = active.data as RpcResult | null;
      setActiveShift(activeResult?.open && activeResult.shift ? activeResult.shift : null);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setLoading(false);
    }
  }, [selectedBranchId, user?.id]);

  useEffect(() => {
    setUserId(user?.id || '');
  }, [user?.id]);

  useEffect(() => {
    setShiftId('');
    setUserReport(null);
    setShiftReport(null);
    setDayReport(null);
    void load();
  }, [selectedBranchId, load]);

  const userName = useCallback((id: string) => {
    const row = users.find((item) => item.id === id);
    return row?.full_name || row?.email || id.slice(0, 8);
  }, [users]);

  const activeInSelectedBranch = activeShift?.branch_id === selectedBranchId ? activeShift : null;
  const selectedShift = useMemo(() => shifts.find((row) => row.id === shiftId) || null, [shifts, shiftId]);

  const closeShift = async () => {
    if (!activeInSelectedBranch || busy || !can('shifts.close')) return;
    const actual = Number(actualAmount);
    if (!Number.isFinite(actual) || actual < 0) {
      setError(isAr ? 'المبلغ الفعلي غير صحيح' : 'Invalid actual cash amount');
      return;
    }
    setBusy(true);
    setError(null);
    setSuccess(null);
    try {
      const { data, error: rpcError } = await supabase.rpc('close_shift', {
        p_shift_id: activeInSelectedBranch.id,
        p_actual_amount: actual,
        p_notes: closeNotes.trim() || null,
      });
      if (rpcError) throw rpcError;
      const result = data as RpcResult | null;
      if (!result?.success) throw new Error(result?.detail || result?.error || 'SHIFT_CLOSE_FAILED');
      setCloseDialog(false);
      setActualAmount('');
      setCloseNotes('');
      setSuccess(isAr ? `تم إغلاق الشفت. الفرق: ${money(result.difference, locale)}` : `Shift closed. Difference: ${money(result.difference, locale)}`);
      setShiftId(activeInSelectedBranch.id);
      const report = await supabase.rpc('get_shift_closing_report', { p_shift_id: activeInSelectedBranch.id });
      if (!report.error) setShiftReport(report.data as RpcResult);
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setBusy(false);
    }
  };

  const loadUserReport = async () => {
    if (!selectedBranchId || !userId) return;
    setBusy(true);
    setError(null);
    try {
      const from = new Date(`${day}T00:00:00`).toISOString();
      const to = new Date(`${day}T00:00:00`);
      to.setDate(to.getDate() + 1);
      const { data, error: rpcError } = await supabase.rpc('get_user_closing_report', {
        p_user_id: userId,
        p_from: from,
        p_to: to.toISOString(),
        p_branch_id: selectedBranchId,
      });
      if (rpcError) throw rpcError;
      setUserReport((data || {}) as RpcResult);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setBusy(false);
    }
  };

  const loadShiftReport = async () => {
    if (!shiftId) return;
    setBusy(true);
    setError(null);
    try {
      const { data, error: rpcError } = await supabase.rpc('get_shift_closing_report', { p_shift_id: shiftId });
      if (rpcError) throw rpcError;
      setShiftReport((data || {}) as RpcResult);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setBusy(false);
    }
  };

  const loadDayReport = async () => {
    if (!selectedBranchId) return;
    setBusy(true);
    setError(null);
    try {
      const { data, error: rpcError } = await supabase.rpc('get_day_closing_report', {
        p_branch_id: selectedBranchId,
        p_day: day,
      });
      if (rpcError) throw rpcError;
      setDayReport((data || {}) as RpcResult);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setBusy(false);
    }
  };

  const summaryCards = (report: RpcResult | null) => {
    if (!report) return null;
    const values: Array<[string, string | number]> = [
      [isAr ? 'الفواتير' : 'Invoices', Number(report.invoice_count ?? 0)],
      [isAr ? 'إجمالي المبيعات' : 'Gross sales', money(report.gross_sales, locale)],
      [isAr ? 'الخصومات' : 'Discounts', money(report.discounts, locale)],
      [isAr ? 'صافي المبيعات' : 'Net sales', money(report.net_sales, locale)],
      [isAr ? 'نقدي' : 'Cash', money(report.cash_sales, locale)],
      [isAr ? 'بطاقات' : 'Card', money(report.card_sales, locale)],
      [isAr ? 'مرتجعات' : 'Refunds', money(report.refunded_amount, locale)],
    ];
    return <div className="grid gap-2 sm:grid-cols-2 xl:grid-cols-4">{values.map(([label, value]) => <div key={label} className="rounded-xl border border-ui-border bg-ui-page-alt p-3"><div className="text-xs text-ui-muted">{label}</div><div className="mt-1 text-lg font-black tabular-nums">{String(value)}</div></div>)}</div>;
  };

  return (
    <V2AppShell activeModule="shifts">
      <div className="mx-auto max-w-[1500px] space-y-4" data-testid="v2-shifts-page">
        <section className="rounded-3xl border border-ui-border bg-ui-surface p-5 shadow-ui-sm">
          <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
            <div>
              <h1 className="text-2xl font-black">{isAr ? 'الشفتات والإغلاق' : 'Shifts & Closing'}</h1>
              <p className="mt-1 text-sm text-ui-muted">{selectedBranch?.name || ''} · {isAr ? 'كل الأرقام من تقارير قاعدة البيانات الرسمية.' : 'All figures come from authoritative database reports.'}</p>
            </div>
            <button type="button" onClick={() => void load()} disabled={loading} className="inline-flex h-10 items-center gap-2 rounded-xl border border-ui-border px-3 text-sm font-bold"><RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />{isAr ? 'تحديث' : 'Refresh'}</button>
          </div>
        </section>

        {error && <div className="flex items-start justify-between gap-3 rounded-2xl border border-ui-danger/30 bg-ui-danger-soft p-3 text-sm text-ui-danger"><span>{error}</span><button type="button" onClick={() => setError(null)}><X className="h-4 w-4" /></button></div>}
        {success && <div className="flex items-center gap-2 rounded-2xl border border-ui-success/30 bg-ui-success-soft p-3 text-sm font-bold text-ui-success"><CheckCircle2 className="h-4 w-4" />{success}</div>}

        <section className="grid gap-4 lg:grid-cols-3">
          <div className="rounded-3xl border border-ui-border bg-ui-surface p-5 shadow-ui-sm lg:col-span-2">
            <div className="flex items-center gap-2"><Clock3 className="h-5 w-5 text-ui-primary" /><h2 className="font-black">{isAr ? 'شفت المستخدم الحالي' : 'Current user shift'}</h2></div>
            {activeShift ? (
              <div className="mt-4">
                <div className={`rounded-2xl border p-4 ${activeInSelectedBranch ? 'border-ui-success/30 bg-ui-success-soft' : 'border-ui-warning/30 bg-ui-warning-soft'}`}>
                  <div className="font-black">{activeInSelectedBranch ? (isAr ? 'مفتوح في الفرع الحالي' : 'Open in current branch') : (isAr ? 'الشفت المفتوح في فرع آخر' : 'Open in another branch')}</div>
                  <div className="mt-2 grid gap-2 text-sm sm:grid-cols-3">
                    <div><span className="text-ui-muted">{isAr ? 'وقت الفتح:' : 'Opened:'}</span> {new Date(activeShift.opened_at).toLocaleString(locale)}</div>
                    <div><span className="text-ui-muted">{isAr ? 'رصيد البداية:' : 'Opening:'}</span> {money(activeShift.opening_amount, locale)}</div>
                    <div><span className="text-ui-muted">{isAr ? 'المتوقع الآن:' : 'Expected now:'}</span> {money(activeShift.expected, locale)}</div>
                  </div>
                </div>
                {activeInSelectedBranch && can('shifts.close') && <button type="button" onClick={() => { setActualAmount(String(activeShift.expected ?? 0)); setCloseDialog(true); }} className="mt-3 h-11 rounded-xl bg-ui-danger px-5 font-black text-white">{isAr ? 'إغلاق الشفت' : 'Close shift'}</button>}
              </div>
            ) : <div className="mt-4 rounded-2xl border border-dashed border-ui-border p-8 text-center text-ui-muted">{isAr ? 'لا يوجد شفت مفتوح لهذا المستخدم. يمكن فتحه من الشريط العلوي إذا كانت لديك صلاحية.' : 'No open shift for this user. Open one from the header if permitted.'}</div>}
          </div>

          <div className="rounded-3xl border border-ui-border bg-ui-surface p-5 shadow-ui-sm">
            <div className="flex items-center gap-2"><CalendarDays className="h-5 w-5 text-ui-primary" /><h2 className="font-black">{isAr ? 'تاريخ التقارير' : 'Report date'}</h2></div>
            <input type="date" value={day} onChange={(event) => setDay(event.target.value)} className="mt-4 h-11 w-full rounded-xl border border-ui-border bg-ui-page-alt px-3" />
            <button type="button" onClick={() => void loadDayReport()} disabled={busy || !selectedBranchId} className="mt-3 h-11 w-full rounded-xl bg-ui-primary font-black text-white disabled:opacity-50">{isAr ? 'تقرير إغلاق اليوم' : 'Day closing report'}</button>
          </div>
        </section>

        <section className="grid gap-4 xl:grid-cols-2">
          <div className="rounded-3xl border border-ui-border bg-ui-surface p-5 shadow-ui-sm">
            <div className="flex items-center gap-2"><UserRound className="h-5 w-5 text-ui-primary" /><h2 className="font-black">{isAr ? 'تقرير إغلاق المستخدم' : 'User closing report'}</h2></div>
            <div className="mt-4 flex flex-col gap-2 sm:flex-row">
              <select value={userId} onChange={(event) => setUserId(event.target.value)} disabled={!can('shifts.manage')} className="h-11 flex-1 rounded-xl border border-ui-border bg-ui-page-alt px-3">
                {!users.some((row) => row.id === userId) && userId && <option value={userId}>{user?.full_name || user?.email || userId}</option>}
                {users.map((row) => <option key={row.id} value={row.id}>{row.full_name || row.email || row.id}</option>)}
              </select>
              <button type="button" onClick={() => void loadUserReport()} disabled={busy || !userId} className="h-11 rounded-xl border border-ui-primary px-4 font-black text-ui-primary disabled:opacity-50">{isAr ? 'عرض' : 'Load'}</button>
            </div>
            <div className="mt-4">{summaryCards(userReport)}</div>
          </div>

          <div className="rounded-3xl border border-ui-border bg-ui-surface p-5 shadow-ui-sm">
            <div className="flex items-center gap-2"><WalletCards className="h-5 w-5 text-ui-primary" /><h2 className="font-black">{isAr ? 'تقرير شفت محدد' : 'Specific shift report'}</h2></div>
            <div className="mt-4 flex flex-col gap-2 sm:flex-row">
              <select value={shiftId} onChange={(event) => setShiftId(event.target.value)} className="h-11 min-w-0 flex-1 rounded-xl border border-ui-border bg-ui-page-alt px-3">
                <option value="">{isAr ? 'اختر الشفت' : 'Select shift'}</option>
                {shifts.map((row) => <option key={row.id} value={row.id}>{userName(row.cashier_id)} · {new Date(row.opened_at).toLocaleString(locale)} · {row.status}</option>)}
              </select>
              <button type="button" onClick={() => void loadShiftReport()} disabled={busy || !shiftId} className="h-11 rounded-xl border border-ui-primary px-4 font-black text-ui-primary disabled:opacity-50">{isAr ? 'عرض' : 'Load'}</button>
            </div>
            {selectedShift && <div className="mt-3 grid gap-2 text-xs text-ui-muted sm:grid-cols-4"><span>{isAr ? 'افتتاح:' : 'Opening:'} {money(selectedShift.opening_amount, locale)}</span><span>{isAr ? 'متوقع:' : 'Expected:'} {money(selectedShift.expected_amount, locale)}</span><span>{isAr ? 'فعلي:' : 'Actual:'} {money(selectedShift.actual_amount, locale)}</span><span>{isAr ? 'فرق:' : 'Difference:'} {money(selectedShift.difference, locale)}</span></div>}
            <div className="mt-4">{summaryCards(shiftReport)}</div>
          </div>
        </section>

        {dayReport && <section className="rounded-3xl border border-ui-border bg-ui-surface p-5 shadow-ui-sm"><div className="flex items-center justify-between gap-3"><h2 className="font-black">{isAr ? 'إغلاق اليوم — كل الشفتات' : 'Day closing — all shifts'}</h2><div className="text-sm text-ui-muted">{isAr ? `عدد الشفتات: ${String(dayReport.shift_count ?? 0)} · المغلق: ${String(dayReport.closed_shift_count ?? 0)}` : `Shifts: ${String(dayReport.shift_count ?? 0)} · closed: ${String(dayReport.closed_shift_count ?? 0)}`}</div></div><div className="mt-4">{summaryCards(dayReport)}</div></section>}
      </div>

      {closeDialog && activeInSelectedBranch && <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/40 p-4"><div className="w-full max-w-md rounded-3xl border border-ui-border bg-ui-surface p-5 shadow-2xl"><div className="flex items-start justify-between gap-3"><div><h2 className="text-xl font-black">{isAr ? 'إغلاق الشفت' : 'Close shift'}</h2><p className="mt-1 text-sm text-ui-muted">{isAr ? `المتوقع: ${money(activeInSelectedBranch.expected, locale)}` : `Expected: ${money(activeInSelectedBranch.expected, locale)}`}</p></div><button type="button" onClick={() => setCloseDialog(false)} disabled={busy} className="rounded-lg p-2"><X className="h-5 w-5" /></button></div><label className="mt-5 block text-sm font-bold">{isAr ? 'المبلغ الفعلي في الصندوق' : 'Actual cash in drawer'}</label><input type="number" min="0" step="0.01" value={actualAmount} onChange={(event) => setActualAmount(event.target.value)} className="mt-2 h-11 w-full rounded-xl border border-ui-border bg-ui-page-alt px-3" /><label className="mt-4 block text-sm font-bold">{isAr ? 'ملاحظات الإغلاق' : 'Closing notes'}</label><textarea rows={3} value={closeNotes} onChange={(event) => setCloseNotes(event.target.value)} className="mt-2 w-full rounded-xl border border-ui-border bg-ui-page-alt p-3" /><div className="mt-5 flex gap-2"><button type="button" onClick={() => setCloseDialog(false)} disabled={busy} className="h-11 flex-1 rounded-xl border border-ui-border font-bold">{isAr ? 'إلغاء' : 'Cancel'}</button><button type="button" onClick={() => void closeShift()} disabled={busy} className="h-11 flex-[2] rounded-xl bg-ui-danger font-black text-white disabled:opacity-50">{busy ? (isAr ? 'جاري الإغلاق...' : 'Closing...') : (isAr ? 'تأكيد الإغلاق' : 'Confirm close')}</button></div></div></div>}
    </V2AppShell>
  );
}

export function V2ShiftsPage() {
  return <V2BranchProvider><V2ShiftsContent /></V2BranchProvider>;
}
