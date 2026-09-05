import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(process.cwd());
const baseMigration = readFileSync(resolve(root, 'supabase/migrations/20260905110500_permission_first_root_drift_cleanup.sql'), 'utf8');
const runtimeMigration = readFileSync(resolve(root, 'supabase/migrations/20260905110600_permission_first_runtime_reconcile.sql'), 'utf8');
const compactRuntimeMigration = runtimeMigration.replace(/\s+/g, '');
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
    expect(baseMigration).toContain("AND u.role = 'super_admin'");
    expect(baseMigration).toContain('JOIN public.roles r ON r.role = u.role AND r.is_active = true');
    expect(baseMigration).toContain("COALESCE(r.permissions, '[]'::jsonb) ? p_permission");
    expect(baseMigration).not.toContain("u.role IN ('super_admin', 'owner')");
  });

  it('preserves owner as a normal permission-bearing label', () => {
    expect(baseMigration).toContain('`owner` remains a valid tenant role label');
    expect(baseMigration).not.toContain("UPDATE public.users SET role = 'manager' WHERE role = 'owner';");
    expect(baseMigration).not.toContain("DELETE FROM public.roles WHERE role = 'owner';");
    expect(runtimeMigration).not.toContain("PERMISSION_FIRST_DRIFT: owner users remain");
    expect(runtimeMigration).not.toContain("n:=replace(n,'''owner'',','''manager'',');");
    expect(runtimeMigration).toContain('PERMISSION_FIRST_DRIFT: runtime authorization remains');
    expect(runtimeMigration).toContain('PERMISSION_FIRST_DRIFT: RLS authorization remains');
  });

  it('uses canonical capabilities for legacy runtime paths', () => {
    expect(compactRuntimeMigration).toContain("n:=replace(n,'''products.manage''','''products.modifiers.manage''');");
    expect(runtimeMigration).toContain("public.can_permission(''inventory.adjust'')");
    expect(runtimeMigration).toContain("public.can_permission(''accounting.reconciliation.manage'')");
    expect(runtimeMigration).toContain("public.can_permission(''approvals.override'')");
    expect(permissionDefs).toContain("'products.modifiers.manage'");
    expect(permissionDefs).not.toContain("| 'products.manage'");
  });

  it('keeps DB maintenance seeding outside end-user role authorization', () => {
    expect(runtimeMigration).toContain('IF auth.uid() IS NULL THEN RETURN NEW; END IF;');
  });
});
