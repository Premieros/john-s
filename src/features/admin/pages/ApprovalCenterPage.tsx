import { useCallback, useEffect, useMemo, useState } from 'react';
import { Check, Clock3, ShieldCheck, X } from 'lucide-react';
import { supabase } from '@/api';
import { Button } from '@/components/Button';
import { Select } from '@/components/Input';
import { DesignSurface, DesignPageHeader } from '@/components/design/DesignSurface';
import { DesignPanel } from '@/components/design/DesignPanel';
import { useToast } from '@/components/Toast';
import { useLanguage } from '@/context/LanguageContext';
import { useAuth } from '@/context/AuthContext';
import { useBranches } from '@/hooks/useBranches';
import { useCan, isAdminRole } from '@/lib/permissions';

type CatalogAction = { action_key: string; domain: string; label_ar: string; label_en: string; supports_threshold: boolean };
type Policy = { id?: string; branch_id: string; action_key: string; requires_approval: boolean; approver_user_id: string | null; threshold_amount: number | null; is_active: boolean };
type ApprovalRequest = { id: string; branch_id: string; request_type: string; entity_type: string | null; entity_id: string | null; requested_by: string; payload: Record<string, unknown>; reason: string | null; status: string; created_at: string; expires_at: string | null; approved_by?: string | null; rejected_by?: string | null };
type Manager = { id: string; full_name: string | null; username: string | null; email: string; role: string; branch_id: string | null; is_active: boolean };

const DOMAIN_LABELS: Record<string, { ar: string; en: string }> = {
  pos: { ar: 'نقطة البيع', en: 'POS' }, sales: { ar: 'المبيعات', en: 'Sales' }, inventory: { ar: 'المخزون', en: 'Inventory' },
  procurement: { ar: 'المشتريات', en: 'Procurement' }, finance: { ar: 'المالية', en: 'Finance' }, accounting: { ar: 'الحسابات', en: 'Accounting' },
};

export function ApprovalCenterPage() {
  const { lang } = useLanguage();
  const isAr = lang === 'ar';
  const { user } = useAuth();
  const can = useCan();
  const { branches } = useBranches();
  const { show } = useToast();
  const admin = isAdminRole(user?.role);
  const canManage = admin || can('settings.manage');
  const [branchId, setBranchId] = useState(user?.branch_id || '');
  const [catalog, setCatalog] = useState<CatalogAction[]>([]);
  const [policies, setPolicies] = useState<Policy[]>([]);
  const [requests, setRequests] = useState<ApprovalRequest[]>([]);
  const [managers, setManagers] = useState<Manager[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState<string | null>(null);

  useEffect(() => {
    if (!branchId && branches.length === 1) setBranchId(branches[0].id);
    if (!branchId && !admin && user?.branch_id) setBranchId(user.branch_id);
  }, [branchId, branches, admin, user?.branch_id]);

  const load = useCallback(async () => {
    if (!branchId) return;
    setLoading(true);
    const [c, p, r, u] = await Promise.all([
      supabase.from('approval_action_catalog').select('action_key,domain,label_ar,label_en,supports_threshold').eq('is_active', true).order('domain').order('action_key'),
      supabase.from('approval_policies').select('id,branch_id,action_key,requires_approval,approver_user_id,threshold_amount,is_active').eq('branch_id', branchId).eq('is_active', true),
      supabase.from('approval_requests').select('*').eq('branch_id', branchId).order('created_at', { ascending: false }).limit(250),
      supabase.from('users').select('id,full_name,username,email,role,branch_id,is_active').eq('is_active', true).or(`branch_id.eq.${branchId},role.eq.super_admin,role.eq.owner`).order('full_name'),
    ]);
    const err = c.error || p.error || r.error || u.error;
    if (err) show(err.message, 'error');
    setCatalog((c.data || []) as CatalogAction[]);
    setPolicies((p.data || []) as Policy[]);
    setRequests((r.data || []) as ApprovalRequest[]);
    setManagers((u.data || []) as Manager[]);
    setLoading(false);
  }, [branchId, show]);

  useEffect(() => { void load(); }, [load]);

  const policyMap = useMemo(() => Object.fromEntries(policies.map((p) => [p.action_key, p])), [policies]);
  const names = useMemo(() => Object.fromEntries(managers.map((m) => [m.id, m.full_name || m.username || m.email])), [managers]);
  const pending = requests.filter((r) => r.status === 'pending');

  const patchPolicy = async (action: CatalogAction, patch: Partial<Policy>) => {
    if (!canManage || !branchId) return;
    setSaving(action.action_key);
    const current = policyMap[action.action_key];
    const payload = {
      branch_id: branchId,
      action_key: action.action_key,
      requires_approval: current?.requires_approval ?? false,
      approver_user_id: current?.approver_user_id ?? null,
      threshold_amount: current?.threshold_amount ?? null,
      is_active: true,
      updated_by: user?.id || null,
      ...patch,
    };
    const { error } = await supabase.from('approval_policies').upsert(payload, { onConflict: 'branch_id,action_key' });
    if (error) show(error.message, 'error'); else { show(isAr ? 'تم حفظ سياسة الموافقة' : 'Approval policy saved', 'success'); await load(); }
    setSaving(null);
  };

  const decide = async (id: string, decision: 'approved' | 'rejected') => {
    const reason = window.prompt(isAr ? 'ملاحظة القرار (اختياري)' : 'Decision note (optional)') || null;
    const { data, error } = await supabase.rpc('decide_manager_approval', { p_approval_id: id, p_decision: decision, p_reason: reason });
    const result = data as { success?: boolean; error?: string } | null;
    if (error || !result?.success) show(error?.message || result?.error || 'Approval failed', 'error');
    else { show(decision === 'approved' ? (isAr ? 'تمت الموافقة' : 'Approved') : (isAr ? 'تم الرفض' : 'Rejected'), 'success'); await load(); }
  };

  return (
    <DesignSurface>
      <DesignPageHeader title={isAr ? 'مركز موافقات المدير' : 'Manager Approval Center'} subtitle={isAr ? 'حدد ما يحتاج موافقة، المدير المسؤول، وراجع كل الطلبات من مكان واحد.' : 'Configure approval rules, assign responsible managers, and review every request in one place.'} />
      <div className="space-y-4">
        <DesignPanel testId="approval-center-branch-panel">
          <div className="flex flex-wrap items-center gap-3">
            <ShieldCheck className="w-5 h-5 text-ui-primary" />
            <span className="font-bold">{isAr ? 'الفرع' : 'Branch'}</span>
            <Select value={branchId} onChange={(e) => setBranchId(e.target.value)} disabled={!admin && !!user?.branch_id} className="max-w-xs">
              <option value="">{isAr ? 'اختر الفرع' : 'Select branch'}</option>
              {branches.map((b) => <option key={b.id} value={b.id}>{b.name}</option>)}
            </Select>
            <span className="ms-auto text-sm text-ui-muted">{isAr ? `طلبات معلقة: ${pending.length}` : `Pending: ${pending.length}`}</span>
          </div>
        </DesignPanel>

        <DesignPanel testId="approval-center-requests-panel" title={isAr ? 'طلبات الموافقة' : 'Approval Requests'}>
          {loading ? <div className="p-6 text-ui-muted">{isAr ? 'جاري التحميل...' : 'Loading...'}</div> : pending.length === 0 ? (
            <div className="p-6 text-center text-ui-muted">{isAr ? 'لا توجد طلبات موافقة معلقة' : 'No pending approval requests'}</div>
          ) : <div className="overflow-x-auto"><table className="w-full text-sm"><thead><tr className="border-b border-ui-border text-ui-muted"><th className="p-3 text-start">{isAr ? 'الطلب' : 'Request'}</th><th className="p-3 text-start">{isAr ? 'طالب الموافقة' : 'Requested by'}</th><th className="p-3 text-start">{isAr ? 'الوقت' : 'Time'}</th><th className="p-3 text-start">{isAr ? 'السبب' : 'Reason'}</th><th className="p-3" /></tr></thead><tbody>{pending.map((r) => { const a = catalog.find((x) => x.action_key === r.request_type); const assigned = policyMap[r.request_type]?.approver_user_id; const mayDecide = admin || canManage || assigned === user?.id; return <tr key={r.id} className="border-b border-ui-border/60"><td className="p-3 font-semibold">{a ? (isAr ? a.label_ar : a.label_en) : r.request_type}</td><td className="p-3">{names[r.requested_by] || r.requested_by.slice(0,8)}</td><td className="p-3 whitespace-nowrap"><Clock3 className="inline w-4 h-4 me-1" />{new Date(r.created_at).toLocaleString(isAr ? 'ar-EG' : 'en')}</td><td className="p-3 max-w-xs truncate">{r.reason || '—'}</td><td className="p-3"><div className="flex justify-end gap-2"><Button size="sm" disabled={!mayDecide} onClick={() => void decide(r.id,'approved')}><Check className="w-4 h-4" />{isAr ? 'موافقة' : 'Approve'}</Button><Button size="sm" variant="secondary" disabled={!mayDecide} onClick={() => void decide(r.id,'rejected')}><X className="w-4 h-4" />{isAr ? 'رفض' : 'Reject'}</Button></div></td></tr>; })}</tbody></table></div>}
        </DesignPanel>

        <DesignPanel testId="approval-center-policies-panel" title={isAr ? 'ما الذي يحتاج موافقة ومن يديره' : 'Approval Rules & Responsible Manager'}>
          {!canManage && <div className="mb-3 rounded-xl border border-ui-border bg-ui-page-alt p-3 text-sm text-ui-muted">{isAr ? 'يمكنك متابعة الطلبات المخصصة لك. تعديل السياسات يحتاج صلاحية إدارة الإعدادات.' : 'You can review requests assigned to you. Editing policies requires Settings permission.'}</div>}
          <div className="grid gap-3 xl:grid-cols-2">{catalog.map((a) => { const p = policyMap[a.action_key]; return <div key={a.action_key} className="rounded-xl border border-ui-border p-4 bg-ui-surface"><div className="flex items-start gap-3"><input type="checkbox" className="mt-1 h-5 w-5" checked={!!p?.requires_approval} disabled={!canManage || saving === a.action_key} onChange={(e) => void patchPolicy(a,{ requires_approval:e.target.checked })} /><div className="min-w-0 flex-1"><div className="font-bold">{isAr ? a.label_ar : a.label_en}</div><div className="text-xs text-ui-muted">{isAr ? DOMAIN_LABELS[a.domain]?.ar : DOMAIN_LABELS[a.domain]?.en}</div><div className="mt-3 grid gap-2 sm:grid-cols-2"><Select value={p?.approver_user_id || ''} disabled={!canManage || saving === a.action_key} onChange={(e) => void patchPolicy(a,{ approver_user_id:e.target.value || null })}><option value="">{isAr ? 'أي مدير مخول' : 'Any authorized manager'}</option>{managers.filter((m) => ['super_admin','owner','branch_manager','accountant','warehouse_manager','production_manager'].includes(m.role)).map((m) => <option key={m.id} value={m.id}>{m.full_name || m.username || m.email}</option>)}</Select>{a.supports_threshold && <input type="number" min="0" step="0.01" value={p?.threshold_amount ?? ''} disabled={!canManage || saving === a.action_key} placeholder={isAr ? 'حد يبدأ بعده طلب الموافقة' : 'Approval threshold'} onChange={(e) => void patchPolicy(a,{ threshold_amount:e.target.value === '' ? null : Number(e.target.value) })} className="h-10 rounded-lg border border-ui-border bg-ui-page px-3 text-sm" />}</div></div></div></div>; })}</div>
        </DesignPanel>

        <DesignPanel testId="approval-center-history-panel" title={isAr ? 'السجل' : 'History'}>
          <div className="overflow-x-auto"><table className="w-full text-sm"><tbody>{requests.filter((r) => r.status !== 'pending').slice(0,100).map((r) => <tr key={r.id} className="border-b border-ui-border/60"><td className="p-3">{catalog.find((x) => x.action_key === r.request_type)?.[isAr ? 'label_ar' : 'label_en'] || r.request_type}</td><td className="p-3">{r.status}</td><td className="p-3">{new Date(r.created_at).toLocaleString(isAr ? 'ar-EG' : 'en')}</td></tr>)}</tbody></table></div>
        </DesignPanel>
      </div>
    </DesignSurface>
  );
}
