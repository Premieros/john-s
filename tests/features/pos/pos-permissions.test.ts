import { describe, expect, it } from 'vitest';
import { hasPermission, type Permission } from '@/lib/permissionDefs';

describe('granular POS permissions', () => {
  it('keeps cashier operational and approval-gated actions while denying direct manager authority', () => {
    expect(hasPermission('cashier', undefined, 'pos.sell')).toBe(true);
    expect(hasPermission('cashier', undefined, 'pos.hold')).toBe(true);
    expect(hasPermission('cashier', undefined, 'pos.send_kitchen')).toBe(true);
    expect(hasPermission('cashier', undefined, 'pos.kds_view')).toBe(true);
    expect(hasPermission('cashier', undefined, 'pos.print_kitchen')).toBe(true);
    expect(hasPermission('cashier', undefined, 'pos.pay')).toBe(true);

    // These actions are visible/initiable for the cashier, but the existing
    // structural/sent-item RPCs still require single-use manager approval.
    expect(hasPermission('cashier', undefined, 'pos.void')).toBe(true);
    expect(hasPermission('cashier', undefined, 'pos.transfer_order')).toBe(true);
    expect(hasPermission('cashier', undefined, 'pos.split_order')).toBe(true);

    // These permissions represent direct authority and stay manager-only by default.
    expect(hasPermission('cashier', undefined, 'pos.discount')).toBe(false);
    expect(hasPermission('cashier', undefined, 'pos.change_price')).toBe(false);
    expect(hasPermission('cashier', undefined, 'pos.reprint')).toBe(false);
    expect(hasPermission('cashier', undefined, 'pos.cancel_order')).toBe(false);
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
    const dbPermissions: Record<string, Permission[]> = {
      cashier: ['pos.sell', 'pos.pay'],
    };

    expect(hasPermission('cashier', dbPermissions, 'pos.pay')).toBe(true);
    expect(hasPermission('cashier', dbPermissions, 'pos.send_kitchen')).toBe(false);
  });
});
