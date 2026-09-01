import fs from 'node:fs';

const path = 'src/features/catalog/pages/ProductsPage.tsx';
let s = fs.readFileSync(path, 'utf8');

if (s.includes('data-testid="product-operational-composition"')) {
  console.log('Product composition UI already patched.');
  process.exit(0);
}

const mustReplace = (from, to, label) => {
  if (!s.includes(from)) throw new Error(`Patch anchor not found: ${label}`);
  s = s.replace(from, to);
};

mustReplace(
  "const UNIT_NAMES = ['piece', 'carton', 'box', 'pack', 'kg', 'liter', 'meter', 'gram'];\n",
  "const UNIT_NAMES = ['piece', 'carton', 'box', 'pack', 'kg', 'liter', 'meter', 'gram'];\n\ntype OperationalIngredient = { raw_material_id: string; quantity: number; raw_material?: { name: string } | null };\ntype LinkedInventoryUnit = { unit_id: string; quantity: number; unit?: { id: string; name: string; unit_type: 'ready' | 'manufactured'; cost_price: number } | null };\n",
  'types',
);

mustReplace(
  "  const [componentQty, setComponentQty] = useState(1);\n",
  "  const [componentQty, setComponentQty] = useState(1);\n  const [recipeIngredients, setRecipeIngredients] = useState<OperationalIngredient[]>([]);\n  const [recipeYield, setRecipeYield] = useState(1);\n  const [linkedInventoryUnits, setLinkedInventoryUnits] = useState<LinkedInventoryUnit[]>([]);\n",
  'composition state',
);

mustReplace(
  "    setProductComponents(((comps.data as { component_product_id: string; quantity: number }[] | null) || []).map((c) => ({ component_product_id: c.component_product_id, quantity: Number(c.quantity) || 1 })));\n    setComponentSel('');\n",
  "    setProductComponents(((comps.data as { component_product_id: string; quantity: number }[] | null) || []).map((c) => ({ component_product_id: c.component_product_id, quantity: Number(c.quantity) || 1 })));\n\n    const effectiveProductBranch = p.branch_id || branchFilter || '';\n    let recipeRows: OperationalIngredient[] = [];\n    let currentYield = 1;\n    if (effectiveProductBranch) {\n      const { data: recipe } = await supabase\n        .from('recipes')\n        .select('id,yield_quantity')\n        .eq('product_id', p.id)\n        .eq('branch_id', effectiveProductBranch)\n        .eq('is_active', true)\n        .order('version', { ascending: false })\n        .order('created_at', { ascending: false })\n        .limit(1)\n        .maybeSingle();\n      if (recipe?.id) {\n        currentYield = Number(recipe.yield_quantity) || 1;\n        const { data: recipeItems } = await supabase\n          .from('recipe_items')\n          .select('raw_material_id,quantity,raw_material:raw_materials(name)')\n          .eq('recipe_id', recipe.id);\n        recipeRows = ((recipeItems || []) as unknown as OperationalIngredient[]).map((row) => ({ ...row, quantity: Number(row.quantity) || 0 }));\n      }\n    }\n    const { data: inventoryLinks } = await supabase\n      .from('product_unit_links')\n      .select('unit_id,quantity,unit:inventory_units(id,name,unit_type,cost_price)')\n      .eq('product_id', p.id);\n    setRecipeYield(currentYield);\n    setRecipeIngredients(recipeRows);\n    setLinkedInventoryUnits(((inventoryLinks || []) as unknown as LinkedInventoryUnit[]).map((row) => ({ ...row, quantity: Number(row.quantity) || 0 })));\n\n    setComponentSel('');\n",
  'openEdit composition load',
);

mustReplace(
  "    if (form.product_type === 'manufactured' && productComponents.length === 0) {\n      show(t('manufacturedRequiresComponents'), 'error');\n      return;\n    }\n",
  "    if (form.product_type === 'manufactured' && productComponents.length === 0 && recipeIngredients.length === 0 && linkedInventoryUnits.length === 0) {\n      show(t('manufacturedRequiresComponents'), 'error');\n      return;\n    }\n",
  'manufactured validation',
);

const oldComponentsStart = "          {/* Components (manufactured products) */}\n          {form.product_type === 'manufactured' && (\n";
const newOperationalSection = `          {/* Canonical operational composition: recipes + inventory unit links */}\n          {editing && (\n            <div data-testid="product-operational-composition" className="rounded-xl border border-brand-200 dark:border-brand-800/50 bg-brand-50/40 dark:bg-brand-900/10 p-4 space-y-4">\n              <div>\n                <h3 className="font-semibold text-ui-text">{lang === 'ar' ? 'مكونات التشغيل الفعلية' : 'Operational composition'}</h3>\n                <p className="mt-1 text-xs text-ui-subtle">\n                  {lang === 'ar' ? 'هذه البيانات هي التي يعتمد عليها التصنيع وخصم المخزون فعلياً.' : 'These are the components actually used by manufacturing and inventory deduction.'}\n                </p>\n              </div>\n\n              <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">\n                <div className="rounded-lg border border-ui-border bg-ui-surface p-3">\n                  <div className="flex items-center justify-between mb-2">\n                    <h4 className="text-sm font-semibold text-ui-text">{lang === 'ar' ? 'الخامات المباشرة' : 'Direct raw materials'}</h4>\n                    <span className="text-xs text-ui-subtle">{recipeIngredients.length}</span>\n                  </div>\n                  {recipeIngredients.length === 0 ? (\n                    <p className="text-sm text-ui-subtle">{lang === 'ar' ? 'لا توجد خامات مباشرة في الوصفة.' : 'No direct raw materials in the recipe.'}</p>\n                  ) : (\n                    <div className="space-y-2">\n                      {recipeIngredients.map((row) => (\n                        <div key={row.raw_material_id} className="flex items-center justify-between gap-3 rounded-md bg-ui-page-alt px-3 py-2">\n                          <span className="text-sm font-medium text-ui-text">{row.raw_material?.name || row.raw_material_id}</span>\n                          <span className="text-xs font-semibold text-ui-muted">{formatNumber(row.quantity / (recipeYield || 1))} / {lang === 'ar' ? 'وحدة بيع' : 'sale unit'}</span>\n                        </div>\n                      ))}\n                    </div>\n                  )}\n                </div>\n\n                <div className="rounded-lg border border-ui-border bg-ui-surface p-3">\n                  <div className="flex items-center justify-between mb-2">\n                    <h4 className="text-sm font-semibold text-ui-text">{lang === 'ar' ? 'الوحدات المخزنية المرتبطة' : 'Linked inventory units'}</h4>\n                    <span className="text-xs text-ui-subtle">{linkedInventoryUnits.length}</span>\n                  </div>\n                  {linkedInventoryUnits.length === 0 ? (\n                    <p className="text-sm text-ui-subtle">{lang === 'ar' ? 'لا توجد وحدات مخزنية مرتبطة بالمنتج.' : 'No inventory units are linked to this product.'}</p>\n                  ) : (\n                    <div className="space-y-2">\n                      {linkedInventoryUnits.map((row) => (\n                        <div key={row.unit_id} className="flex items-center justify-between gap-3 rounded-md bg-ui-page-alt px-3 py-2">\n                          <div className="min-w-0">\n                            <p className="truncate text-sm font-medium text-ui-text">{row.unit?.name || row.unit_id}</p>\n                            <p className="text-xs text-ui-subtle">\n                              {row.unit?.unit_type === 'manufactured'\n                                ? (lang === 'ar' ? 'وحدة مصنّعة' : 'Manufactured unit')\n                                : (lang === 'ar' ? 'وحدة جاهزة' : 'Ready unit')}\n                            </p>\n                          </div>\n                          <div className="text-end">\n                            <p className="text-xs font-semibold text-ui-muted">{formatNumber(row.quantity)} / {lang === 'ar' ? 'وحدة بيع' : 'sale unit'}</p>\n                            <p className="text-xs text-ui-subtle">{lang === 'ar' ? 'تكلفة' : 'Cost'}: {formatCurrency(Number(row.unit?.cost_price || 0), currency, lang)}</p>\n                          </div>\n                        </div>\n                      ))}\n                    </div>\n                  )}\n                </div>\n              </div>\n            </div>\n          )}\n\n          {/* Legacy product-component editor is only shown when no canonical recipe/unit links exist. */}\n          {form.product_type === 'manufactured' && recipeIngredients.length === 0 && linkedInventoryUnits.length === 0 && (\n`;
mustReplace(oldComponentsStart, newOperationalSection, 'operational composition section');

mustReplace(
  "              <h3 className=\"font-semibold text-ui-muted\">{t('units')}</h3>\n",
  "              <div>\n                <h3 className=\"font-semibold text-ui-muted\">{lang === 'ar' ? 'وحدات البيع' : 'Sales units'}</h3>\n                <p className=\"text-xs text-ui-subtle mt-0.5\">{lang === 'ar' ? 'قطعة / كرتونة / عبوة — منفصلة عن وحدات المخزون المصنّعة أعلاه.' : 'Piece / carton / pack — separate from manufactured inventory units above.'}</p>\n              </div>\n",
  'sales units heading',
);

fs.writeFileSync(path, s);
console.log('Patched ProductsPage operational composition UI.');
