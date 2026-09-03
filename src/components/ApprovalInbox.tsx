import { useCallback, useEffect, useMemo, useState } from 'react';
import { Bell, Check, Settings2, X } from 'lucide-react';
import { supabase } from '@/api';
import { useAuth } from '@/context/AuthContext';
import { useBranchFilter } from '@/lib/useBranchFilter';
import { useActiveBranchId } from '@/lib/activeBranch';
import { isAdminRole } from '@/lib/permissions';
import { ApprovalCenterPage } from '@/features/admin/pages/ApprovalCenterPage';

type ApprovalRequest = {
  id: string;
  branch_id: string;
  request_type: string;
  entity_type: string | null;
  entity_id: string | null;
  payload: Record<string, unknown>;
  reason: string | null;
  status: string;
  created_at: string;
  expires_at: string | null;
  requested_by: string;
};

type ApprovalPolicy = { branch_id: string; action_key: string; approver_user_id: string | null };
type CatalogAction = { action_key: string; label_ar: string; label_en: string };

export function ApprovalInbox({ ar }: { ar: boolean }) {
  const { user } = useAuth();
  const branchFilter = useBranchFilter();
  const [activeBranchId] = useActiveBranchId();
  const admin = isAdminRole(user?.role);
  const effectiveBranch = admin ? activeBranchId : (branchFilter || user?.branch_id || null);
  const [open, setOpen] = useState(false);
  const [centerOpen, setCenterOpen] = useState(false);
  const [items, setItems] = useState<ApprovalRequest[]>([]);
  const [policies, setPolicies] = useState<ApprovalPolicy[]>([]);
  const [catalog, setCatalog] = useState<CatalogAction[]>([]);
  const [busy, setBusy] = useState<string | null>(null);

  const load = useCallback(async () => {
    if (!user) return;
    let requestQuery = supabase
      .from('approval_requests')
      .select('id,branch_id,request_type,entity_type,entity_id,payload,reason,status,created_at,expires_at,requested_by')
      .eq('status', 'pending')
      .order('created_at', { ascending: false })
      .limit(50);
    let policyQuery = supabase.from('approval_policies').select('branch_id,action_key,approver_user_id').eq('is_active', true);
    if (effectiveBranch) {
      requestQuery = requestQuery.eq('branch_id', effectiveBranch);
      policyQuery = policyQuery.eq('branch_id', effectiveBranch);
    }
    const [r, p, c] = await Promise.all([
      requestQuery,
      policyQuery,
      supabase.from('approval_action_catalog').select('action_key,label_ar,label_en').eq('is_active', true),
    ]);
    if (!r.error) setItems((r.data || []) as ApprovalRequest[]);
    if (!p.error) setPolicies((p.data || []) as ApprovalPolicy[]);
    if (!c.error) setCatalog((c.data || []) as CatalogAction[]);
  }, [effectiveBranch, user]);

  useEffect(() => {
    void load();
    if (!user) return;
    const channel = supabase
      .channel(`approval-inbox-${user.id}`)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'approval_requests' }, () => void load())
      .subscribe();
    return () => { void supabase.removeChannel(channel); };
  }, [user, load]);

  const policyFor = useCallback((item: ApprovalRequest) => policies.find((p) => p.branch_id === item.branch_id && p.action_key === item.request_type), [policies]);
  const visibleItems = useMemo(() => items.filter((item) => {
    if (admin) return true;
    const assigned = policyFor(item)?.approver_user_id;
    return assigned ? assigned === user?.id : ['branch_manager', 'owner', 'super_admin'].includes(user?.role || '');
  }), [items, policyFor, admin, user?.id, user?.role]);
  const labelFor = (key: string) => {
    const row = catalog.find((c) => c.action_key === key);
    return row ? (ar ? row.label_ar : row.label_en) : key;
  };

  const decide = async (id: string, decision: 'approved' | 'rejected') => {
    setBusy(id);
    try {
      const { data, error } = await supabase.rpc('decide_manager_approval', {
        p_approval_id: id,
        p_decision: decision,
        p_reason: null,
      });
      const result = data as { success?: boolean; error?: string } | null;
      if (!error && result?.success) await load();
    } finally {
      setBusy(null);
    }
  };

  if (!user) return null;

  return (
    <>
      <div className="relative">
        <button type="button" data-testid="approval-inbox-button" onClick={() => setOpen((v) => !v)} className="relative rounded-xl p-2 text-ui-muted transition-colors hover:bg-ui-page-alt hover:text-ui-text" aria-label={ar ? 'طلبات الموافقة' : 'Approval requests'}>
          <Bell className="h-5 w-5" />
          {visibleItems.length > 0 && <span data-testid="approval-inbox-count" className="absolute -end-0.5 -top-0.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-ui-danger px-1 text-[9px] font-bold text-ui-primary-fg">{visibleItems.length}</span>}
        </button>
        {open && (
          <div data-testid="approval-inbox-panel" className="absolute end-0 top-full z-[80] mt-2 w-[min(92vw,420px)] overflow-hidden rounded-xl border border-ui-border bg-ui-surface shadow-ui-lg">
            <div className="flex items-center justify-between border-b border-ui-border px-4 py-3">
              <div><p className="font-semibold text-ui-text">{ar ? 'طلبات الموافقة' : 'Approval requests'}</p><p className="text-xs text-ui-muted">{ar ? 'كل الطلبات المخصصة لك في الفرع' : 'All requests assigned to you in this branch'}</p></div>
              <button type="button" onClick={() => { setOpen(false); setCenterOpen(true); }} className="rounded-lg p-2 text-ui-primary hover:bg-ui-primary-soft" title={ar ? 'مركز الموافقات' : 'Approval center'}><Settings2 className="h-4 w-4" /></button>
            </div>
            <div className="max-h-96 overflow-y-auto p-2">
              {visibleItems.length === 0 ? <p className="px-3 py-6 text-center text-sm text-ui-muted">{ar ? 'لا توجد طلبات معلّقة' : 'No pending requests'}</p> : visibleItems.map((item) => (
                <div key={item.id} className="mb-2 rounded-xl border border-ui-border bg-ui-page-alt p-3 last:mb-0">
                  <div className="flex items-start justify-between gap-3"><div className="min-w-0"><p className="font-semibold text-ui-text">{labelFor(item.request_type)}</p><p className="mt-1 text-sm text-ui-muted">{item.reason || (ar ? 'بدون ملاحظة' : 'No note')}</p></div><span className="shrink-0 text-[10px] text-ui-subtle">{new Date(item.created_at).toLocaleTimeString(ar ? 'ar-EG' : 'en-US', { hour: '2-digit', minute: '2-digit' })}</span></div>
                  <div className="mt-3 flex gap-2"><button type="button" disabled={busy === item.id} onClick={() => void decide(item.id, 'approved')} className="flex flex-1 items-center justify-center gap-1.5 rounded-lg bg-ui-success px-3 py-2 text-sm font-semibold text-ui-primary-fg disabled:opacity-50"><Check className="h-4 w-4" />{ar ? 'موافقة' : 'Approve'}</button><button type="button" disabled={busy === item.id} onClick={() => void decide(item.id, 'rejected')} className="flex flex-1 items-center justify-center gap-1.5 rounded-lg bg-ui-danger px-3 py-2 text-sm font-semibold text-ui-primary-fg disabled:opacity-50"><X className="h-4 w-4" />{ar ? 'رفض' : 'Reject'}</button></div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
      {centerOpen && <div className="fixed inset-0 z-[100] bg-black/55 p-3 sm:p-6"><div className="mx-auto h-full max-w-7xl overflow-y-auto rounded-2xl bg-ui-page shadow-ui-xl"><div className="sticky top-0 z-10 flex justify-end border-b border-ui-border bg-ui-surface/95 p-2"><button type="button" onClick={() => setCenterOpen(false)} className="rounded-lg p-2 text-ui-muted hover:bg-ui-page-alt" aria-label={ar ? 'إغلاق' : 'Close'}><X className="h-5 w-5" /></button></div><ApprovalCenterPage /></div></div>}
    </>
  );
}
