import React from 'react';
import { useLanguage } from '@/context/LanguageContext';
import { Card } from '@/components/PageHeader';
import { Input } from '@/components/Input';
import { formatCurrency } from '@/lib/format';
import type { Language } from '@/lib/types';
import type { ReportFilterKey, ReportFilters } from './reportFilters';

interface FilterOption {
  value: string;
  label: string;
}

export interface ReportFilterBarProps {
  reportType: string;
  filters: ReportFilters;
  onFilterChange: (dim: ReportFilterKey, value: string) => void;
  showDate: boolean;
  period: string;
  onPeriodChange: (key: string) => void;
  from: string;
  to: string;
  onFromChange: (value: string) => void;
  onToChange: (value: string) => void;
  showBranchFilter: boolean;
  branches: Array<{ id: string; name: string; name_en: string | null }>;
  branchFilterValue: string;
  onBranchFilterChange: (value: string) => void;
  filterOptions: (dim: ReportFilterKey) => FilterOption[];
  filterLabel: (dim: ReportFilterKey) => string;
  allLabel: (dim: ReportFilterKey) => string;
  filterDimensions: ReportFilterKey[];
  total: number;
  count: number;
  currency: string;
  lang: Language;
  financialTypes?: Array<{ key: string; label: string }>;
  canFinancial?: boolean;
  onFinancialSelect?: (key: string) => void;
  reportTypes?: Array<{ key: string; label: string; icon: React.ReactNode }>;
  onReportTypeChange?: (key: string) => void;
}

export function ReportFilterBar({
  filters,
  onFilterChange,
  showDate,
  period,
  onPeriodChange,
  from,
  to,
  onFromChange,
  onToChange,
  showBranchFilter,
  branches,
  branchFilterValue,
  onBranchFilterChange,
  filterOptions,
  filterLabel,
  allLabel,
  filterDimensions,
  total,
  count,
  currency,
  lang,
}: ReportFilterBarProps) {
  const { t } = useLanguage();

  return (
    <Card className="mb-3 border-ui-border bg-ui-surface p-3 shadow-ui-sm">
      <div className="flex flex-col gap-3">
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4 xl:grid-cols-6">
          {showDate && (
            <div>
              <label className="mb-1 block text-xs font-medium text-ui-muted">{t('filterByPeriod')}</label>
              <select
                data-testid="report-context-filter"
                value={period}
                onChange={(e) => onPeriodChange(e.target.value)}
                className="h-9 w-full rounded-ui border border-ui-border bg-ui-surface-raised px-2.5 text-xs font-semibold text-ui-text focus:outline-none focus-visible:ring-2 focus-visible:ring-ui-ring"
              >
                <option value="custom">{lang === 'ar' ? 'مخصص' : 'Custom'}</option>
                <option value="today">{lang === 'ar' ? 'اليوم' : 'Today'}</option>
                <option value="yesterday">{lang === 'ar' ? 'أمس' : 'Yesterday'}</option>
                <option value="last7">{lang === 'ar' ? 'آخر 7 أيام' : 'Last 7 days'}</option>
                <option value="last30">{lang === 'ar' ? 'آخر 30 يومًا' : 'Last 30 days'}</option>
                <option value="this_month">{lang === 'ar' ? 'هذا الشهر' : 'This month'}</option>
                <option value="last_month">{lang === 'ar' ? 'الشهر الماضي' : 'Last month'}</option>
                <option value="this_year">{lang === 'ar' ? 'هذه السنة' : 'This year'}</option>
              </select>
            </div>
          )}

          {showDate && (
            <Input
              label={t('from')}
              type="date"
              value={from}
              onChange={(e) => onFromChange(e.target.value)}
            />
          )}

          {showDate && (
            <Input
              label={t('to')}
              type="date"
              value={to}
              onChange={(e) => onToChange(e.target.value)}
            />
          )}

          {showBranchFilter && (
            <div>
              <label className="mb-1 block text-xs font-medium text-ui-muted">{t('filterByBranch')}</label>
              <select
                value={branchFilterValue}
                onChange={(e) => onBranchFilterChange(e.target.value)}
                className="h-9 w-full rounded-ui border border-ui-border bg-ui-surface-raised px-2.5 text-xs font-semibold text-ui-text focus:outline-none focus-visible:ring-2 focus-visible:ring-ui-ring"
              >
                <option value="">{t('allBranches')}</option>
                {branches.map((b) => (
                  <option key={b.id} value={b.id}>
                    {lang === 'ar' ? b.name : (b.name_en || b.name)}
                  </option>
                ))}
              </select>
            </div>
          )}

          {filterDimensions.map((dim) => (
            <div key={dim} data-testid="report-contextual-filters">
              <label className="mb-1 block text-xs font-medium text-ui-muted">{filterLabel(dim)}</label>
              <select
                data-filter-dim={dim}
                value={filters[dim] || ''}
                onChange={(e) => onFilterChange(dim, e.target.value)}
                className="h-9 w-full rounded-ui border border-ui-border bg-ui-surface-raised px-2.5 text-xs font-semibold text-ui-text focus:outline-none focus-visible:ring-2 focus-visible:ring-ui-ring"
              >
                <option value="">{allLabel(dim)}</option>
                {filterOptions(dim).map((opt) => (
                  <option key={opt.value} value={opt.value}>{opt.label}</option>
                ))}
              </select>
            </div>
          ))}
        </div>

        <div className="flex flex-wrap items-center gap-2 border-t border-ui-border pt-2 text-xs">
          <div className="rounded-lg bg-ui-page-alt px-3 py-1.5 border border-ui-border">
            <span className="text-ui-muted">{t('total')}: </span>
            <span className="font-black text-ui-accent">{formatCurrency(total, currency, lang)}</span>
          </div>
          <div className="rounded-lg bg-ui-page-alt px-3 py-1.5 border border-ui-border">
            <span className="text-ui-muted">{t('count')}: </span>
            <span className="font-black text-ui-text">{count}</span>
          </div>
        </div>
      </div>
    </Card>
  );
}
