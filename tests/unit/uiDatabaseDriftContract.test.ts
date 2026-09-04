import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const read = (path: string) => readFileSync(resolve(process.cwd(), path), 'utf8');

describe('UI and production database drift guards', () => {
  it('loads recipe products from the active branch without the removed manufactured-only filter', () => {
    const source = read('src/features/manufacturing/pages/RecipesPage.tsx');
    expect(source).not.toContain(".eq('product_type', 'manufactured')");
    expect(source).toContain("productQuery = productQuery.eq('branch_id', branchFilter)");
    expect(source).toContain(".from('raw_material_inventory')");
    expect(source).toContain('materialCosts[item.raw_material_id]');
  });

  it('loads component products from the active branch without the removed manufactured-only filter', () => {
    const source = read('src/features/catalog/pages/ComponentsPage.tsx');
    expect(source).not.toContain("product_type === 'manufactured'");
    expect(source).not.toContain(".eq('product_type', 'manufactured')");
    expect(source).toContain("productQuery = productQuery.eq('branch_id', branchFilter)");
  });

  it('fails production parity when the kitchen inventory warehouse contract is absent', () => {
    const source = read('scripts/db/check-production-parity.js');
    expect(source).toContain("orders: ['inventory_warehouse_id']");
    expect(source).toContain("text.includes('PGRST204')");
    expect(source).toContain('missingColumns.length === 0');
  });
});
