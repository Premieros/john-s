import { useMemo, useState, type ReactNode } from 'react';
import { Link } from 'react-router-dom';
import { Bell, Building2, ChevronLeft, ChevronRight, Menu, ShieldCheck, UserCircle2, X } from 'lucide-react';
import { useAuth } from '@/context/AuthContext';
import { useLanguage } from '@/context/LanguageContext';
import { useCan } from '@/lib/permissions';
import { APP_ROUTES } from '@/core/navigation/routes';
import { V2_MODULES, type V2ModuleKey } from '@/v2/core/capabilityRegistry';
import { useV2Branch } from '@/v2/context/V2BranchContext';

type Props = {
  activeModule?: V2ModuleKey;
  children: ReactNode;
};

export function V2AppShell({ activeModule, children }: Props) {
  const { lang } = useLanguage();
  const { user } = useAuth();
  const can = useCan();
  const { branches, selectedBranchId, selectedBranch, setSelectedBranchId, loading: branchesLoading } = useV2Branch();
  const [collapsed, setCollapsed] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);
  const isAr = lang === 'ar';

  const visibleModules = useMemo(
    () => V2_MODULES.filter((module) => can(module.legacyViewPermission)),
    [can],
  );

  const moduleContent = (module: (typeof V2_MODULES)[number], active: boolean) => (
    <div className={`rounded-xl border px-3 py-2.5 ${active ? 'border-ui-primary bg-ui-primary-soft text-ui-primary' : 'border-transparent text-ui-muted'} ${module.key === 'pos' ? 'hover:bg-ui-page-alt' : ''}`} title={collapsed ? (isAr ? module.labelAr : module.labelEn) : undefined}>
      <div className="flex items-center gap-3">
        <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-ui-page-alt text-xs font-black uppercase">{module.key.slice(0, 2)}</div>
        {!collapsed && (
          <div className="min-w-0 flex-1">
            <div className="truncate text-sm font-semibold">{isAr ? module.labelAr : module.labelEn}</div>
            <div className="mt-0.5 text-[11px] text-ui-subtle">{module.key === 'pos' ? (isAr ? 'فتح المساحة' : 'Open workspace') : module.status === 'building' ? (isAr ? 'قيد البناء — غير قابل للنقر بعد' : 'Building — not clickable yet') : module.status === 'foundation' ? (isAr ? 'أساس النظام' : 'Foundation') : (isAr ? 'مخطط — غير قابل للنقر بعد' : 'Planned — not clickable yet')}</div>
          </div>
        )}
      </div>
    </div>
  );

  const sidebar = (
    <div className="flex h-full flex-col bg-ui-surface">
      <div className="flex h-16 items-center gap-3 border-b border-ui-border px-4">
        <Link to={APP_ROUTES.frontendV2} className="flex h-10 w-10 items-center justify-center rounded-xl bg-ui-primary font-black text-white" aria-label={isAr ? 'واجهة V2 الرئيسية' : 'V2 home'}>P</Link>
        {!collapsed && (
          <Link to={APP_ROUTES.frontendV2} className="min-w-0">
            <div className="font-black text-ui-text">Premier V2</div>
            <div className="text-xs text-ui-muted">Database-driven workspace</div>
          </Link>
        )}
        <button type="button" className="ms-auto hidden rounded-lg p-2 text-ui-muted hover:bg-ui-page-alt lg:inline-flex" onClick={() => setCollapsed((value) => !value)} aria-label={isAr ? 'طي القائمة' : 'Collapse sidebar'}>
          {collapsed ? (isAr ? <ChevronLeft className="h-4 w-4" /> : <ChevronRight className="h-4 w-4" />) : (isAr ? <ChevronRight className="h-4 w-4" /> : <ChevronLeft className="h-4 w-4" />)}
        </button>
        <button type="button" className="ms-auto rounded-lg p-2 lg:hidden" onClick={() => setMobileOpen(false)} aria-label={isAr ? 'إغلاق القائمة' : 'Close menu'}><X className="h-5 w-5" /></button>
      </div>

      <nav className="flex-1 overflow-y-auto p-3">
        <div className="mb-2 px-2 text-xs font-bold uppercase tracking-wide text-ui-subtle">{!collapsed && (isAr ? 'مساحات العمل' : 'Workspaces')}</div>
        <div className="space-y-1">
          {visibleModules.map((module) => {
            const active = module.key === activeModule;
            if (module.key === 'pos') {
              return <Link key={module.key} to={`${APP_ROUTES.frontendV2}/pos`} onClick={() => setMobileOpen(false)}>{moduleContent(module, active)}</Link>;
            }
            return <div key={module.key} aria-disabled="true">{moduleContent(module, active)}</div>;
          })}
        </div>
      </nav>

      {!collapsed && (
        <div className="border-t border-ui-border p-3">
          <div className="rounded-xl bg-ui-page-alt p-3 text-xs text-ui-muted">
            <div className="font-bold text-ui-text">{isAr ? 'قاعدة البناء' : 'Build rule'}</div>
            <div className="mt-1">{isAr ? 'لا زر بدون Backend + Permission + Test.' : 'No button without backend + permission + test.'}</div>
          </div>
        </div>
      )}
    </div>
  );

  return (
    <div dir={isAr ? 'rtl' : 'ltr'} className="min-h-screen bg-ui-page text-ui-text">
      <aside className={`fixed inset-y-0 z-40 hidden border-ui-border bg-ui-surface transition-[width] lg:block ${isAr ? 'right-0 border-l' : 'left-0 border-r'} ${collapsed ? 'w-20' : 'w-72'}`}>{sidebar}</aside>

      {mobileOpen && (
        <div className="fixed inset-0 z-50 lg:hidden">
          <button type="button" className="absolute inset-0 bg-black/30" onClick={() => setMobileOpen(false)} aria-label={isAr ? 'إغلاق القائمة' : 'Close menu'} />
          <aside className={`absolute inset-y-0 w-80 max-w-[88vw] border-ui-border bg-ui-surface shadow-xl ${isAr ? 'right-0 border-l' : 'left-0 border-r'}`}>{sidebar}</aside>
        </div>
      )}

      <div className={`min-h-screen transition-[margin] ${isAr ? (collapsed ? 'lg:mr-20' : 'lg:mr-72') : (collapsed ? 'lg:ml-20' : 'lg:ml-72')}`}>
        <header className="sticky top-0 z-30 border-b border-ui-border bg-ui-surface/95 backdrop-blur">
          <div className="flex min-h-16 flex-wrap items-center gap-2 px-3 py-2 sm:px-5">
            <button type="button" className="rounded-xl border border-ui-border p-2 lg:hidden" onClick={() => setMobileOpen(true)} aria-label={isAr ? 'فتح القائمة' : 'Open menu'}><Menu className="h-5 w-5" /></button>

            <div className="flex min-w-0 items-center gap-2">
              <Building2 className="h-4 w-4 text-ui-primary" />
              <select value={selectedBranchId ?? ''} onChange={(event) => setSelectedBranchId(event.target.value)} disabled={branchesLoading || branches.length === 0} className="h-10 max-w-[220px] rounded-xl border border-ui-border bg-ui-surface px-3 text-sm font-semibold outline-none focus:border-ui-primary" aria-label={isAr ? 'الفرع الحالي' : 'Current branch'}>
                {branches.length === 0 && <option value="">{isAr ? 'لا يوجد فرع متاح' : 'No accessible branch'}</option>}
                {branches.map((branch) => <option key={branch.id} value={branch.id}>{branch.name || branch.name_en || branch.id}</option>)}
              </select>
            </div>

            <div className="ms-auto flex items-center gap-2">
              <div className="hidden items-center gap-2 rounded-xl border border-ui-border px-3 py-2 text-xs sm:flex"><ShieldCheck className="h-4 w-4 text-ui-success" /><span className="font-semibold">{selectedBranch?.name || (isAr ? 'بدون فرع' : 'No branch')}</span></div>
              {can('settings.manage') ? (
                <Link to={APP_ROUTES.approvals} className="relative rounded-xl border border-ui-border p-2 hover:bg-ui-page-alt" aria-label={isAr ? 'الموافقات' : 'Approvals'}><Bell className="h-5 w-5" /></Link>
              ) : (
                <div className="rounded-xl border border-ui-border p-2 text-ui-subtle" title={isAr ? 'لا توجد صلاحية لفتح مركز الموافقات بعد' : 'Approval Center permission not available yet'}><Bell className="h-5 w-5" /></div>
              )}
              <div className="flex items-center gap-2 rounded-xl border border-ui-border px-2.5 py-1.5"><UserCircle2 className="h-5 w-5 text-ui-muted" /><div className="hidden text-xs sm:block"><div className="max-w-36 truncate font-bold">{user?.full_name || user?.email || '-'}</div><div className="text-ui-subtle">{user?.role || '-'}</div></div></div>
            </div>
          </div>
        </header>

        <main className="p-3 sm:p-5 lg:p-6">{children}</main>
      </div>
    </div>
  );
}
