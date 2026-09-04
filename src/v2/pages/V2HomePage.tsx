import { useCallback, useEffect, useMemo, useState } from 'react';
import { AlertCircle, Boxes, CheckCircle2, ClipboardList, Clock3, Database, GitBranch, RefreshCw, ShieldCheck, Store, Users } from 'lucide-react';
import { supabase } from '@/api';
import { useLanguage } from '@/context/LanguageContext';
import { useCan } from '@/lib/permissions';
import { V2AppShell } from '@/v2/components/V2AppShell';
import { V2BranchProvider, useV2Branch } from '@/v2/context/V2BranchContext';
import { V2_MODULES } from '@/v2/core/capabilityRegistry';

type LiveStats = {
  products: number;
  openOrders: number;
  openShifts: number;
  pendingApprovals: number;
  warehouses: number;
};

const EMPTY_STATS: LiveStats = { products: 0, openOrders: 0, openShifts: 0, pendingApprovals: 0, warehouses: 0 };

function V2HomeContent() {
  const { lang } = useLanguage();
  const isAr = lang === 'ar';
  const can = useCan();
  const { selectedBranchId, selectedBranch, branches, loading: branchLoading, error: branchError, refresh: refreshBranches } = useV2Branch();
  const [stats, setStats] = useState<LiveStats>(EMPTY_STATS);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const visibleModules = useMemo(() => V2_MODULES.filter((module) => can(module.legacyViewPermission)), [can]);

  const loadStats = useCallback(async () => {
    if (!selectedBranchId) {
      setStats(EMPTY_STATS);
      setError(null);
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const [products, orders, shifts, approvals, warehouses] = await Promise.all([
        supabase.from('products').select('id', { count: 'exact', head: true }).eq('branch_id', selectedBranchId).eq('is_active', true),
        supabase.from('orders').select('id', { count: 'exact', head: true }).eq('branch_id', selectedBranchId).not('status', 'in', '(completed,cancelled,voided)'),
        supabase.from('shifts').select('id', { count: 'exact', head: true }).eq('branch_id', selectedBranchId).eq('status', 'open'),
        supabase.from('approval_requests').select('id', { count: 'exact', head: true }).eq('branch_id', selectedBranchId).eq('status', 'pending'),
        supabase.from('warehouses').select('id', { count: 'exact', head: true }).eq('branch_id', selectedBranchId).eq('is_active', true),
      ]);
      const firstError = products.error || orders.error || shifts.error || approvals.error || warehouses.error;
      if (firstError) throw firstError;
      setStats({
        products: products.count ?? 0,
        openOrders: orders.count ?? 0,
        openShifts: shifts.count ?? 0,
        pendingApprovals: approvals.count ?? 0,
        warehouses: warehouses.count ?? 0,
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setLoading(false);
    }
  }, [selectedBranchId]);

  useEffect(() => { void loadStats(); }, [loadStats]);

  const statCards = [
    { key: 'products', label: isAr ? 'منتجات نشطة' : 'Active products', value: stats.products, icon: Boxes },
    { key: 'orders', label: isAr ? 'طلبات مفتوحة' : 'Open orders', value: stats.openOrders, icon: ClipboardList },
    { key: 'shifts', label: isAr ? 'شفتات مفتوحة' : 'Open shifts', value: stats.openShifts, icon: Clock3 },
    { key: 'approvals', label: isAr ? 'موافقات معلقة' : 'Pending approvals', value: stats.pendingApprovals, icon: ShieldCheck },
    { key: 'warehouses', label: isAr ? 'مخازن نشطة' : 'Active warehouses', value: stats.warehouses, icon: Store },
  ];

  return (
    <V2AppShell>
      <div className="mx-auto max-w-[1600px] space-y-5" data-testid="v2-home-page">
        <section className="rounded-3xl border border-ui-border bg-ui-surface p-5 shadow-ui-sm sm:p-6">
          <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
            <div>
              <div className="mb-2 inline-flex items-center gap-2 rounded-full bg-ui-primary-soft px-3 py-1 text-xs font-bold text-ui-primary">
                <Database className="h-4 w-4" />
                {isAr ? 'Frontend V2 — مبني على قاعدة البيانات' : 'Frontend V2 — Database driven'}
              </div>
              <h1 className="text-2xl font-black sm:text-3xl">{isAr ? 'مساحة التشغيل الجديدة' : 'New Operations Workspace'}</h1>
              <p className="mt-2 max-w-3xl text-sm leading-6 text-ui-muted">
                {isAr
                  ? 'هذه الواجهة لا تفترض وظائف غير موجودة. كل Module موثق بصلاحيته والـBackend الذي ينفذه، ويتم تفعيل الشاشات بالتدريج بعد الاختبار.'
                  : 'This interface does not assume unsupported features. Every module is mapped to its permission and backend contract, then enabled after verification.'}
              </p>
            </div>
            <button
              type="button"
              onClick={() => { void refreshBranches(); void loadStats(); }}
              disabled={loading || branchLoading}
              className="inline-flex h-11 items-center justify-center gap-2 rounded-xl border border-ui-border bg-ui-surface px-4 text-sm font-bold hover:bg-ui-page-alt disabled:opacity-50"
            >
              <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
              {isAr ? 'تحديث الحالة' : 'Refresh status'}
            </button>
          </div>
        </section>

        {(branchError || error) && (
          <section className="flex items-start gap-3 rounded-2xl border border-ui-danger/30 bg-ui-danger-soft p-4 text-sm text-ui-danger">
            <AlertCircle className="mt-0.5 h-5 w-5 shrink-0" />
            <div>
              <div className="font-bold">{isAr ? 'تعذر تحميل جزء من حالة النظام' : 'Could not load part of system status'}</div>
              <div className="mt-1 break-all">{branchError || error}</div>
            </div>
          </section>
        )}

        <section className="grid gap-3 sm:grid-cols-2 xl:grid-cols-5">
          {statCards.map(({ key, label, value, icon: Icon }) => (
            <div key={key} className="rounded-2xl border border-ui-border bg-ui-surface p-4 shadow-ui-sm">
              <div className="flex items-center justify-between gap-3">
                <div className="text-sm font-semibold text-ui-muted">{label}</div>
                <Icon className="h-5 w-5 text-ui-primary" />
              </div>
              <div className="mt-3 text-3xl font-black tabular-nums">{loading ? '…' : value.toLocaleString(isAr ? 'ar-EG' : 'en-US')}</div>
            </div>
          ))}
        </section>

        <section className="grid gap-4 xl:grid-cols-[1.4fr_0.6fr]">
          <div className="rounded-3xl border border-ui-border bg-ui-surface p-5 shadow-ui-sm">
            <div className="mb-4 flex items-center justify-between gap-3">
              <div>
                <h2 className="text-lg font-black">{isAr ? 'خريطة بناء النظام' : 'System build map'}</h2>
                <p className="mt-1 text-sm text-ui-muted">{isAr ? 'تظهر فقط الوحدات التي تسمح بها صلاحيات المستخدم الحالية.' : 'Only modules allowed by the current user permissions are shown.'}</p>
              </div>
              <GitBranch className="h-5 w-5 text-ui-primary" />
            </div>
            <div className="grid gap-3 md:grid-cols-2">
              {visibleModules.map((module) => (
                <article key={module.key} className="rounded-2xl border border-ui-border bg-ui-page-alt/60 p-4">
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <h3 className="font-black">{isAr ? module.labelAr : module.labelEn}</h3>
                      <p className="mt-1 text-xs leading-5 text-ui-muted">{isAr ? module.descriptionAr : module.descriptionEn}</p>
                    </div>
                    <span className={`shrink-0 rounded-full px-2.5 py-1 text-[11px] font-bold ${module.status === 'building' ? 'bg-ui-warning-soft text-ui-warning' : module.status === 'foundation' ? 'bg-ui-success-soft text-ui-success' : 'bg-ui-page text-ui-subtle'}`}>
                      {module.status === 'building' ? (isAr ? 'قيد البناء' : 'Building') : module.status === 'foundation' ? (isAr ? 'جاهز كأساس' : 'Foundation') : (isAr ? 'التالي' : 'Planned')}
                    </span>
                  </div>
                  <div className="mt-3 flex flex-wrap gap-1.5">
                    {module.backend.slice(0, 4).map((item) => <span key={item} className="rounded-lg border border-ui-border bg-ui-surface px-2 py-1 text-[10px] text-ui-subtle">{item}</span>)}
                  </div>
                  <div className="mt-3 text-[11px] text-ui-muted">
                    {isAr ? 'صلاحية الهدف:' : 'Target permission:'} <code>{module.targetViewPermission}</code>
                  </div>
                </article>
              ))}
            </div>
          </div>

          <div className="space-y-4">
            <div className="rounded-3xl border border-ui-border bg-ui-surface p-5 shadow-ui-sm">
              <div className="flex items-center gap-2"><Store className="h-5 w-5 text-ui-primary" /><h2 className="font-black">{isAr ? 'نطاق التشغيل' : 'Operating scope'}</h2></div>
              <dl className="mt-4 space-y-3 text-sm">
                <div className="flex items-center justify-between gap-3"><dt className="text-ui-muted">{isAr ? 'الفرع الحالي' : 'Current branch'}</dt><dd className="font-bold">{selectedBranch?.name || '—'}</dd></div>
                <div className="flex items-center justify-between gap-3"><dt className="text-ui-muted">{isAr ? 'الفروع المتاحة' : 'Accessible branches'}</dt><dd className="font-bold">{branches.length}</dd></div>
              </dl>
            </div>

            <div className="rounded-3xl border border-ui-border bg-ui-surface p-5 shadow-ui-sm">
              <div className="flex items-center gap-2"><CheckCircle2 className="h-5 w-5 text-ui-success" /><h2 className="font-black">{isAr ? 'عقد V2' : 'V2 contract'}</h2></div>
              <div className="mt-4 space-y-2 text-sm text-ui-muted">
                <div className="flex gap-2"><span>•</span><span>{isAr ? 'الفروع من RLS، لا من branch_id ثابت فقط.' : 'Branches come from RLS, not only a fixed branch_id.'}</span></div>
                <div className="flex gap-2"><span>•</span><span>{isAr ? 'لا زر بدون Backend حقيقي.' : 'No button without a real backend action.'}</span></div>
                <div className="flex gap-2"><span>•</span><span>{isAr ? 'الصلاحيات الحساسة تُفرض على الخادم.' : 'Sensitive permissions are server enforced.'}</span></div>
                <div className="flex gap-2"><span>•</span><span>{isAr ? 'التقارير المالية من RPCs الرسمية.' : 'Financial reports use authoritative RPCs.'}</span></div>
              </div>
            </div>

            <div className="rounded-3xl border border-ui-border bg-ui-surface p-5 shadow-ui-sm">
              <div className="flex items-center gap-2"><Users className="h-5 w-5 text-ui-primary" /><h2 className="font-black">{isAr ? 'المرحلة الحالية' : 'Current phase'}</h2></div>
              <p className="mt-3 text-sm leading-6 text-ui-muted">{isAr ? 'Foundation يعمل الآن. الخطوة التالية داخل نفس الفرع هي POS V2، ثم الشفتات والموافقات والهالك.' : 'Foundation is now in place. Next on the same branch: POS V2, then shifts, approvals and waste.'}</p>
            </div>
          </div>
        </section>
      </div>
    </V2AppShell>
  );
}

export function V2HomePage() {
  return <V2BranchProvider><V2HomeContent /></V2BranchProvider>;
}
