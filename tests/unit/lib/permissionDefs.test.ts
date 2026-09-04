import { describe, expect, it } from 'vitest';
import {
  ALL_PERMISSIONS,
  DEFAULT_ROLE_PERMISSIONS,
  hasPermission,
  isAdminRole,
  PERMISSION_GROUPS,
  ROLE_META,
  type Permission,
  type Role,
} from '@/lib/permissionDefs';

describe('isAdminRole', () => {
  it('treats only super_admin as implicit admin', () => {
    expect(isAdminRole('super_admin')).toBe(true);
    expect(isAdminRole('owner')).toBe(false);
  });

  it('treats other roles and undefined as non-admin', () => {
    expect(isAdminRole('cashier')).toBe(false);
    expect(isAdminRole('branch_manager')).toBe(false);
    expect(isAdminRole(null)).toBe(false);
    expect(isAdminRole(undefined)).toBe(false);
  });
});

describe('hasPermission', () => {
  it('denies when no role', () => {
    expect(hasPermission(null, null, 'pos.sell')).toBe(false);
    expect(hasPermission(undefined, undefined, 'pos.sell')).toBe(false);
  });

  it('gives only super_admin an implicit permission bypass', () => {
    expect(hasPermission('super_admin', null, 'settings.manage')).toBe(true);
    expect(hasPermission('super_admin', {}, 'branches.manage')).toBe(true);

    expect(hasPermission('owner', null, 'settings.manage')).toBe(false);
    expect(hasPermission('owner', {}, 'branches.manage')).toBe(false);
  });

  it('requires DB-backed permissions for every non-super-admin role', () => {
    expect(hasPermission('cashier', null, 'pos.sell')).toBe(false);
    expect(hasPermission('accountant', null, 'reports.financial')).toBe(false);
    expect(hasPermission('branch_manager', {}, 'users.manage')).toBe(false);

    const map: Record<string, Permission[]> = {
      owner: ['branches.manage'],
      cashier: ['pos.sell'],
      accountant: ['reports.financial'],
      branch_manager: ['users.manage'],
    };

    expect(hasPermission('owner', map, 'branches.manage')).toBe(true);
    expect(hasPermission('owner', map, 'settings.manage')).toBe(false);
    expect(hasPermission('cashier', map, 'pos.sell')).toBe(true);
    expect(hasPermission('cashier', map, 'settings.manage')).toBe(false);
    expect(hasPermission('accountant', map, 'reports.financial')).toBe(true);
    expect(hasPermission('branch_manager', map, 'users.manage')).toBe(true);
  });

  it('POS action permissions are resolved from the DB map', () => {
    const map: Record<string, Permission[]> = {
      cashier: ['pos.sell', 'pos.send_kitchen', 'pos.kds_view', 'pos.pay'],
      branch_manager: ['pos.reprint', 'pos.discount', 'pos.change_price'],
    };

    expect(hasPermission('cashier', map, 'pos.reprint')).toBe(false);
    expect(hasPermission('cashier', map, 'pos.discount')).toBe(false);
    expect(hasPermission('cashier', map, 'pos.change_price')).toBe(false);
    expect(hasPermission('cashier', map, 'pos.send_kitchen')).toBe(true);
    expect(hasPermission('cashier', map, 'pos.kds_view')).toBe(true);
    expect(hasPermission('cashier', map, 'pos.pay')).toBe(true);
    expect(hasPermission('branch_manager', map, 'pos.reprint')).toBe(true);
    expect(hasPermission('branch_manager', map, 'pos.discount')).toBe(true);
    expect(hasPermission('branch_manager', map, 'pos.change_price')).toBe(true);
    expect(hasPermission('super_admin', null, 'pos.discount')).toBe(true);
  });

  it('print/export/import permissions are resolved from the DB map', () => {
    const map: Record<string, Permission[]> = {
      cashier: ['products.print'],
      warehouse_manager: ['products.export', 'products.import'],
      accountant: ['sales.export', 'reports.print'],
      branch_manager: ['reports.export'],
      production_manager: ['products.import'],
    };

    expect(hasPermission('cashier', map, 'products.print')).toBe(true);
    expect(hasPermission('cashier', map, 'products.export')).toBe(false);
    expect(hasPermission('warehouse_manager', map, 'products.export')).toBe(true);
    expect(hasPermission('warehouse_manager', map, 'products.import')).toBe(true);
    expect(hasPermission('accountant', map, 'sales.export')).toBe(true);
    expect(hasPermission('accountant', map, 'reports.print')).toBe(true);
    expect(hasPermission('branch_manager', map, 'reports.export')).toBe(true);
    expect(hasPermission('production_manager', map, 'products.import')).toBe(true);
  });

  it('DB map is authoritative instead of code defaults', () => {
    const map: Record<string, Permission[]> = { cashier: ['pos.sell'] };
    expect(hasPermission('cashier', map, 'sales.view')).toBe(false);
    expect(hasPermission('cashier', map, 'pos.sell')).toBe(true);
  });
});

describe('permission model integrity', () => {
  it('all role defaults only reference known permissions', () => {
    const known = new Set<Permission>(ALL_PERMISSIONS);
    for (const role of Object.keys(DEFAULT_ROLE_PERMISSIONS) as Role[]) {
      for (const p of DEFAULT_ROLE_PERMISSIONS[role]) {
        expect(known.has(p), `${role} references unknown permission ${p}`).toBe(true);
      }
    }
  });

  it('every role in ROLE_META has defaults', () => {
    for (const role of Object.keys(ROLE_META) as Role[]) {
      expect(DEFAULT_ROLE_PERMISSIONS[role]).toBeDefined();
      expect(DEFAULT_ROLE_PERMISSIONS[role].length).toBeGreaterThan(0);
    }
  });

  it('every permission appears in a group (reviewable in the settings UI)', () => {
    const grouped = new Set<Permission>();
    for (const g of PERMISSION_GROUPS) {
      for (const p of g.permissions) grouped.add(p);
    }
    for (const p of ALL_PERMISSIONS) {
      expect(grouped.has(p), `${p} missing from PERMISSION_GROUPS`).toBe(true);
    }
  });

  it('reference templates for super_admin and owner cover the full permission catalog', () => {
    expect(DEFAULT_ROLE_PERMISSIONS.super_admin).toHaveLength(ALL_PERMISSIONS.length);
    expect(DEFAULT_ROLE_PERMISSIONS.owner).toHaveLength(ALL_PERMISSIONS.length);
  });
});
