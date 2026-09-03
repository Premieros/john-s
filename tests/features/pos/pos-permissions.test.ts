import { describe, expect, it } from 'vitest';
import { hasPermission } from '@/lib/permissionDefs';

describe('granular POS permissions', () => {
  it('keeps cashier operational actions but denies privileged mutations by default', () => {
    expect(hasPermission('cashier', undefined, 'pos.sell')).toBe(true);
    expect(hasPermission('cashier', undefined, 'pos.hold')).toBe(true);
    expect(hasPermission('cashier', undefined, 'pos.send_kitchen')).toBe(true);
    expect(hasPermission('cashier', undefined, 'pos.kds_view')).toBe(true);
    expect(hasPermission('cashier', undefined, 'pos.print_kitchen')).toBe(true);
    expect(hasPermission('cashier', undefined, 'pos.pay')).toBe(true);

    expect(hasPermission('cashier', undefined, 'pos.void')).toBe(false);
    expect(hasPermission('cashier', undefined, 'pos.cancel_order')).toBe(false);
    expect(hasPermission('cashier', undefined, 'pos.transfer_order')).toBe(false);
    expect(hasPermission('cashier', undefined, 'pos.split_order')).toBe(false);
    expect(hasPermission('cashier', undefined, 'pos.change_branch')).toBe(false);
  });

  it('allows branch manager operational management without cross-branch switching by default', () => {
    expect(hasPermission('branch_manager', undefined, 'pos.void')).toBe(true);
    expect(hasPermission('branch_manager', undefined, 'pos.cancel_order')).toBe(true);
    expect(hasPermission('branch_manager', undefined, 'pos.transfer_order')).toBe(true);
    expect(hasPermission('branch_manager', undefined, 'pos.split_order')).toBe(true);
    expect(hasPermission('branch_manager', undefined, 'pos.change_branch')).toBe(false);
  });

  it('honors DB-backed role permission overrides', () => {
    const dbPermissions = {
      cashier: ['pos.sell', 'pos.pay'] as const,
    };

    expect(hasPermission('cashier', dbPermissions as never, 'pos.pay')).toBe(true);
    expect(hasPermission('cashier', dbPermissions as never, 'pos.send_kitchen')).toBe(false);
  });
});
