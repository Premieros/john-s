import { useCallback, useEffect, useState } from 'react';
import { Check, Clock3, RefreshCw, ShieldCheck, X } from 'lucide-react';
import { supabase } from '@/api';
import { Button } from '@/components/Button';
import { Select } from '@/components/Input';
import { DesignSurface, DesignPageHeader } from '@/components/design/DesignSurface';
import { DesignPanel } from '@/components/design/DesignPanel';
import { useToast } from '@/components/Toast';
import { useLanguage } from '@/context/LanguageContext';
import { useBranches } from '@/hooks/useBranches';
import { useBranchFilter } from '@/lib/useBranchFilter';
import { isAdminRole } from '@/lib/permissions';
import { useAuth } from '@/context/AuthContext';
import { useV2Can } from '@/v2/core/useV2Can';

type QueueItem = {
  source_type: 'manager_approval' | 'waste' | 'stock_count' | 'warehouse_transfer';
  source_id: string;
  branch_id: string;
  title: string;
  status: string;
  requested_by: string | null;
  requested_at: string;
  required_permission: string;
  payload: Record<string, unknown>;
};

const sourceLabels: Record<string, { ar: string; en: string }> = {
  manager_approval: { ar: 'طلب موافقة مدير', en: 'Manager approval' },
  waste: { ar: 'هالك', en: 'Waste' },
  stock_count: { ar: 'جرد مخزون', en: 'Stock count' },
  warehouse_transfer: { ar: 'تحويل مخزني', en: 'Warehouse transfer' },
};

export function ApprovalCenterPage() {
  const { lang } = useLanguage();
  const ar = lang === 'ar';
  const { user } = useAuth();
  const v2Can = useV2Can();
  const { branches } = useBranches();
  const activeBranch = useBranchFilter();
  const { show } = useToast();
  const admin = isAdminRole(user?.role);
  const [branchId, setBranchId] = useState(activeBranch || user?.branch_id || '');
  const [rows, setRows] = useState<QueueItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [deciding, setDeciding] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    const { data, error } = await supabase.rpc('get_operational_approval_queue', {
      p_branch_id: branchId || null,
    });
    if (error) show(error.message, 'error');
    setRows((data || []) as QueueItem[]);
    setLoading(false);
  }, [branchId, show]);

  useEffect(() => { void load(); }, [load]);

  const mayDecide = (row: QueueItem) => admin || v2Can(row.required_permission);

  const decide = async (row: QueueItem, approve: boolean) => {
    let reason: string | null = null;
    if (!approve) {
      reason = window.prompt(ar ? 'سبب الرفض:' : 'Rejection reason:');
      if (reason === null) return;
    }
    setDeciding(row.source_id);
    const { data, error } = await supabase.rpc('decide_operational_approval', {
      p_source_type: row.source_type,
      p_source_id: row.source_id,
      p_approve: approve,
      p_reason: reason,
    });
    const result = data as { success?: boolean; error?: string; detail?: string } | null;
    if (error || !result?.success) show(error?.message || result?.detail || result?.error || 'Approval failed', 'error');
    else show(approve ? (ar ? 'تمت الموافقة' : 'Approved') : (ar ? 'تم الرفض' : 'Rejected'), 'success');
    setDeciding(null);
    await load();
  };

  return (
    <DesignSurface testId="approval-center-page">
      <DesignPageHeader
        title={ar ? 'مركز الموافقات والاعتمادات' : 'Approvals & Authorizations Center'}
        subtitle={ar ? 'كل ما هو معلق أو يحتاج اعتماد في مكان واحد، مع تطبيق صلاحية الاعتماد حسب نوع العملية.' : 'All pending approvals in one place, with server-enforced permissions per operation.'}
        actions={<Button variant="outline" onClick={() => void load()} disabled={loading}><RefreshCw className="w-4 h-4" />{ar ? 'تحديث' : 'Refresh'}</Button>}
      />
      <div className="space-y-4">
        <DesignPanel testId="approval-center-filter-panel">
          <div className="flex flex-wrap items-center gap-3">
            <ShieldCheck className="w-5 h-5 text-ui-primary" />
            <span className="font-semibold">{ar ? 'الفرع' : 'Branch'}</span>
            <Select value={branchId} onChange={(e) => setBranchId(e.target.value)} className="max-w-xs">
              {admin && <option value="">{ar ? 'كل الفروع المصرح بها' : 'All accessible branches'}</option>}
              {branches.map((b) => <option key={b.id} value={b.id}>{b.name}</option>)}
            </Select>
            <span className="ms-auto text-sm text-ui-muted">{ar ? `معلق: ${rows.length}` : `Pending: ${rows.length}`}</span>
          </div>
        </DesignPanel>

        <DesignPanel testId="approval-center-queue-panel" title={ar ? 'قائمة الاعتماد' : 'Approval Queue'}>
          {loading ? <div className="p-8 text-center text-ui-muted">{ar ? 'جاري التحميل...' : 'Loading...'}</div> : rows.length === 0 ? (
            <div className="p-8 text-center text-ui-muted">{ar ? 'لا توجد عمليات معلقة تحتاج اعتمادًا' : 'No pending approvals'}</div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead><tr className="border-b border-ui-border text-ui-muted">
                  <th className="p-3 text-start">{ar ? 'النوع' : 'Type'}</th>
                  <th className="p-3 text-start">{ar ? 'الطلب' : 'Request'}</th>
                  <th className="p-3 text-start">{ar ? 'الوقت' : 'Time'}</th>
                  <th className="p-3 text-start">{ar ? 'التفاصيل' : 'Details'}</th>
                  <th className="p-3 text-end">{ar ? 'الإجراء' : 'Action'}</th>
                </tr></thead>
                <tbody>{rows.map((row) => {
                  const permitted = mayDecide(row);
                  return (
                    <tr key={`${row.source_type}-${row.source_id}`} className="border-b border-ui-border/60">
                      <td className="p-3 font-semibold">{sourceLabels[row.source_type]?.[ar ? 'ar' : 'en'] || row.source_type}</td>
                      <td className="p-3">{row.title}</td>
                      <td className="p-3 whitespace-nowrap"><Clock3 className="inline w-4 h-4 me-1" />{new Date(row.requested_at).toLocaleString(ar ? 'ar-EG' : 'en')}</td>
                      <td className="p-3 max-w-md"><pre className="whitespace-pre-wrap text-xs text-ui-muted">{JSON.stringify(row.payload, null, 1)}</pre></td>
                      <td className="p-3"><div className="flex justify-end gap-2">
                        <Button size="sm" disabled={!permitted || deciding === row.source_id} onClick={() => void decide(row, true)}><Check className="w-4 h-4" />{ar ? 'موافقة' : 'Approve'}</Button>
                        <Button size="sm" variant="secondary" disabled={!permitted || deciding === row.source_id} onClick={() => void decide(row, false)}><X className="w-4 h-4" />{ar ? 'رفض' : 'Reject'}</Button>
                      </div></td>
                    </tr>
                  );
                })}</tbody>
              </table>
            </div>
          )}
        </DesignPanel>
      </div>
    </DesignSurface>
  );
}
