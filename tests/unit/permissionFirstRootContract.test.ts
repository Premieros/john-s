import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(process.cwd());
const migration = readFileSync(resolve(root, 'supabase/migrations/20260905110500_permission_first_root_drift_cleanup.sql'), 'utf8');
const userTypes = readFileSync(resolve(root, 'src/lib/domains/types/users.ts'), 'utf8');
const permissionDefs = readFileSync(resolve(root, 'src/lib/permissionDefs.ts'), 'utf8');

const legacyPermissions = [
  'pos.sell',
  'pos.pay',
  'pos.split_order',
  'pos.transfer_order',
  'products.manage',
  'inventory.manage',
  'inventory.transfers',
  'inventory.transfers.approve',
  'catalog.view',
  'procurement.view',
  'accounting.view',
  'admin.view',
];

describe('Permission-First root contract', () => {
  it('treats role as a dynamic label rather than an authorization enum', () => {
    expect(userTypes).toContain('export type Role = string;');
    expect(userTypes).not.toContain("| 'owner'");
  });

  it('keeps legacy permissions out of the canonical permission registry', () => {
    for (const permission of legacyPermissions) {
      expect(permissionDefs).not.toContain(`| '${permission}'`);
      expect(permissionDefs).not.toContain(`  '${permission}',`);
    }
  });

  it('makes Super Admin the only implicit bypass', () => {
    expect(migration).toContain("AND u.role = 'super_admin'");
    expect(migration).toContain('JOIN public.roles r ON r.role = u.role AND r.is_active = true');
    expect(migration).toContain("COALESCE(r.permissions, '[]'::jsonb) ? p_permission");
  });

  it('migrates owner away and fails closed on future authorization drift', () => {
    expect(migration).toContain("UPDATE public.users SET role = 'manager' WHERE role = 'owner';");
    expect(migration).toContain("UPDATE public.organization_members SET membership_role = 'admin' WHERE membership_role = 'owner';");
    expect(migration).toContain('PERMISSION_FIRST_DRIFT: owner users remain');
    expect(migration).toContain('PERMISSION_FIRST_DRIFT: role-based or legacy authorization remains');
  });

  it('uses the canonical modifier capability on both read and write paths', () => {
    expect(migration).toContain("public.can_permission('products.modifiers.manage')");
    expect(migration).toContain("replace(n, '''products.manage''', '''products.modifiers.manage''')");
  });
});
