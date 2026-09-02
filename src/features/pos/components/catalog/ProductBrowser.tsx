import { useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Search,
  X,
  ShoppingCart,
  Package,
  Plus,
  ScanBarcode,
  SlidersHorizontal,
  Home,
  BarChart3,
  Boxes,
} from 'lucide-react';
import { useLanguage } from '@/context/LanguageContext';
import { formatCurrency } from '@/lib/format';
import { useCan } from '@/lib/permissions';
import { APP_ROUTES } from '@/core/navigation/routes';
import type { Category, Product, ProductComponent } from '@/lib/types';

interface ProductBrowserProps {
  products: Product[];
  categories: Category[];
  stockMap: Record<string, number>;
  sellableStock: Record<string, number>;
  recipeMap: Record<string, ProductComponent[]>;
  search: string;
  selectedCategory: string;
  currency: string;
  hasBranch: boolean;
  onSearch: (value: string) => void;
  onSelectCategory: (id: string) => void;
  onAddToCart: (product: Product) => void;
  onConfigureProduct?: (product: Product) => void;
  inputRef?: React.Ref<HTMLInputElement>;
}

export function ProductBrowser({ products, categories, stockMap, sellableStock, recipeMap, search, selectedCategory, currency, hasBranch, onSearch, onSelectCategory, onAddToCart, onConfigureProduct, inputRef }: ProductBrowserProps) {
  const { t, lang } = useLanguage();
  const isAr = lang === 'ar';
  const navigate = useNavigate();
  const can = useCan();
  const filteredProducts = useMemo(() => products.filter((p) => (!selectedCategory || p.category_id === selectedCategory) && (!search || [p.name, p.name_en, p.barcode, p.sku].some((v) => v?.toLowerCase().includes(search.toLowerCase())))), [products, search, selectedCategory]);
  const counts = useMemo(() => products.reduce<Record<string, number>>((a, p) => { const k = p.category_id || '_none'; a[k] = (a[k] || 0) + 1; return a; }, {}), [products]);
  const selectProduct = (p: Product) => onConfigureProduct ? onConfigureProduct(p) : onAddToCart(p);

  const systemLinks = [
    can('dashboard.view') ? { key: 'dashboard', label: isAr ? 'الرئيسية' : 'Home', icon: Home, route: APP_ROUTES.dashboard } : null,
    can('reports.view') ? { key: 'reports', label: isAr ? 'التقارير' : 'Reports', icon: BarChart3, route: APP_ROUTES.reports } : null,
    can('products.view') ? { key: 'products', label: isAr ? 'المنتجات' : 'Products', icon: Boxes, route: APP_ROUTES.products } : null,
  ].filter(Boolean) as Array<{ key: string; label: string; icon: typeof Home; route: string }>;

  return (
    <section className="flex h-full min-h-0 min-w-0 flex-1 flex-col overflow-hidden bg-ui-page">
      <div className="z-10 flex-shrink-0 border-b border-ui-border bg-ui-surface/95 px-3 py-2 backdrop-blur sm:px-4">
        <div className="flex gap-2">
          <div className="relative min-w-0 flex-1">
            <Search className="absolute start-3 top-1/2 h-4 w-4 -translate-y-1/2 text-ui-subtle" />
            <input ref={inputRef} value={search} onChange={(e) => onSearch(e.target.value)} onKeyDown={(e) => { if (e.key === 'Enter') { const p = products.find((x) => x.barcode === search); if (p) { selectProduct(p); onSearch(''); } } }} placeholder={isAr ? 'بحث أو باركود (F2)...' : 'Search or scan (F2)...'} className="h-10 w-full rounded-xl border border-ui-border bg-ui-page-alt ps-10 pe-9 text-sm font-bold text-ui-text outline-none transition focus:border-ui-primary focus:ring-2 focus:ring-ui-ring" autoComplete="off" />
            {search && <button onClick={() => onSearch('')} className="absolute end-2 top-1/2 -translate-y-1/2 rounded-lg p-1.5 text-ui-subtle hover:bg-ui-page-alt"><X className="h-4 w-4" /></button>}
            {!search && <ScanBarcode className="absolute end-3 top-1/2 h-4 w-4 -translate-y-1/2 text-ui-subtle" />}
          </div>
          <div className="hidden min-w-12 items-center justify-center rounded-xl border border-ui-border bg-ui-page-alt px-2 text-xs font-black text-ui-muted sm:flex">{filteredProducts.length}</div>
        </div>

        <div className="mt-2 flex gap-1.5 overflow-x-auto pb-0.5 scrollbar-none">
          {systemLinks.map((link) => {
            const Icon = link.icon;
            return (
              <button key={link.key} type="button" onClick={() => navigate(link.route)} className="flex min-h-9 shrink-0 items-center gap-1.5 rounded-lg border border-ui-border bg-ui-page-alt px-2.5 text-[11px] font-black text-ui-muted transition hover:border-ui-primary hover:text-ui-primary">
                <Icon className="h-3.5 w-3.5" />
                <span>{link.label}</span>
              </button>
            );
          })}
          {systemLinks.length > 0 && <span className="mx-0.5 w-px shrink-0 bg-ui-border" aria-hidden="true" />}
          <button onClick={() => onSelectCategory('')} className={`min-h-9 shrink-0 rounded-lg px-3 text-[11px] font-black transition ${!selectedCategory ? 'bg-ui-primary text-ui-primary-fg shadow-ui-sm' : 'border border-ui-border bg-ui-surface text-ui-muted hover:text-ui-text'}`}>{t('allCategories')} <span className="ms-1 opacity-60">{products.length}</span></button>
          {categories.map((c) => <button key={c.id} onClick={() => onSelectCategory(selectedCategory === c.id ? '' : c.id)} className={`min-h-9 shrink-0 rounded-lg px-3 text-[11px] font-black transition ${selectedCategory === c.id ? 'bg-ui-primary text-ui-primary-fg shadow-ui-sm' : 'border border-ui-border bg-ui-surface text-ui-muted hover:text-ui-text'}`}>{isAr ? c.name : c.name_en || c.name} <span className="ms-1 opacity-50">{counts[c.id] || 0}</span></button>)}
        </div>
      </div>

      <div className="min-h-0 flex-1 touch-pan-y overflow-y-auto overscroll-y-contain p-2.5 sm:p-3">
        {!hasBranch ? <div className="flex h-full flex-col items-center justify-center text-center text-ui-subtle"><ShoppingCart className="mb-3 h-10 w-10 opacity-20" /><p className="font-black">{isAr ? 'اختر الفرع أولاً' : 'Select a branch first'}</p></div> : filteredProducts.length === 0 ? <div className="flex h-full flex-col items-center justify-center text-center text-ui-subtle"><Package className="mb-3 h-10 w-10 opacity-20" /><p className="font-black">{t('noData')}</p></div> : <div className="grid grid-cols-3 gap-2 sm:grid-cols-4 lg:grid-cols-4 xl:grid-cols-5 2xl:grid-cols-6">
          {filteredProducts.map((p) => {
            const manufactured = p.product_type === 'manufactured';
            const noRecipe = manufactured && !recipeMap[p.id]?.length;
            const stock = manufactured ? sellableStock[p.id] || 0 : stockMap[p.id] || 0;
            const unavailable = stock <= 0 || noRecipe;
            const productLabel = isAr ? p.name : p.name_en || p.name;
            return <div key={p.id} className={`group relative flex min-h-32 flex-col overflow-hidden rounded-xl border bg-ui-surface text-start shadow-ui-sm transition ${unavailable ? 'cursor-not-allowed opacity-45 border-ui-border' : 'border-ui-border hover:border-ui-primary hover:shadow-ui-md'}`}>
              <div onClick={() => !unavailable && selectProduct(p)} className="relative h-20 cursor-pointer overflow-hidden bg-ui-page-alt sm:h-24">
                {p.image_url ? <img src={p.image_url} alt={p.name} className="h-full w-full object-cover transition duration-200 group-hover:scale-105" /> : <div className="flex h-full items-center justify-center"><ShoppingCart className="h-6 w-6 text-ui-subtle" /></div>}
                <span className={`absolute end-1.5 top-1.5 rounded-md px-1.5 py-0.5 text-[9px] font-black text-ui-primary-fg ${noRecipe ? 'bg-ui-danger/90' : unavailable ? 'bg-ui-danger/90' : stock <= (p.low_stock_threshold || 5) ? 'bg-ui-warning/90' : 'bg-ui-success/90'}`}>{noRecipe ? t('noRecipe') : unavailable ? (isAr ? 'غير متاح' : 'Unavailable') : stock}</span>
              </div>
              <div className="flex flex-1 flex-col p-2">
                <p onClick={() => !unavailable && selectProduct(p)} className="cursor-pointer truncate text-xs font-black text-ui-text hover:text-ui-accent" title={productLabel}>{productLabel}</p>
                <div className="mt-auto flex items-center justify-between gap-1 pt-1.5">
                  <span className="min-w-0 truncate text-xs font-black text-ui-accent sm:text-sm">{formatCurrency(p.sale_price, currency, lang)}</span>
                  {!unavailable && <div className="flex shrink-0 items-center gap-1">
                    {onConfigureProduct && <button type="button" onClick={(e) => { e.stopPropagation(); onConfigureProduct(p); }} title={isAr ? 'تخصيص الصنف' : 'Configure Item'} aria-label={isAr ? 'تخصيص الصنف' : 'Configure Item'} className="flex h-7 w-7 items-center justify-center rounded-lg border border-ui-border bg-ui-page-alt text-ui-muted transition hover:border-ui-primary hover:text-ui-accent"><SlidersHorizontal className="h-3 w-3" /></button>}
                    <button type="button" aria-label={productLabel} title={isAr ? `اختيار ${productLabel}` : `Choose ${productLabel}`} onClick={() => selectProduct(p)} className="flex h-7 w-7 items-center justify-center rounded-lg bg-ui-accent text-ui-primary-fg shadow-ui-sm transition hover:bg-ui-accent/90 active:scale-95"><Plus className="h-3.5 w-3.5" /></button>
                  </div>}
                </div>
              </div>
            </div>;
          })}
        </div>}
      </div>
    </section>
  );
}
