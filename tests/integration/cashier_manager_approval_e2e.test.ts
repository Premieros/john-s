import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import type pg from 'pg';
import { getDbUrl, openDb } from './db';
import { canImpersonate, runAsPersist, seedRlsFixture, type RlsIds } from './rls';

const dbUrl = getDbUrl();
const skip = !dbUrl;

type ApprovalResult = {
  success: boolean;
  error?: string;
  request_id?: string;
  status?: string;
};

describe.skipIf(skip)('cashier / manager approval E2E', () => {
  let client: pg.Client;
  let ids: RlsIds;
  let impersonationAvailable = false;

  const rpc = async (userId: string, sql: string, params: unknown[] = []): Promise<ApprovalResult> => {
    const result = await runAsPersist(client, userId, sql, params);
    if (result.error) throw new Error(result.error);
    return result.rows[0]?.r as ApprovalResult;
  };

  const request = (userId: string, action: string, entityType: string, entityId: string, payload: Record<string, unknown> = {}) =>
    rpc(
      userId,
      `SELECT public.request_manager_approval($1, $2, $3, $4::jsonb, $5) AS r`,
      [action, entityType, entityId, JSON.stringify(payload), `E2E ${action}`],
    );

  const decide = (userId: string, requestId: string, approve: boolean) =>
    rpc(userId, `SELECT public.decide_manager_approval($1, $2, $3) AS r`, [requestId, approve, 'E2E decision']);

  const consume = (userId: string, requestId: string, action: string, entityId: string) =>
    rpc(userId, `SELECT public.consume_manager_approval($1, $2, $3) AS r`, [requestId, action, entityId]);

  beforeAll(async () => {
    client = openDb(dbUrl!);
    await client.connect();
    await client.query('BEGIN');
    ids = await seedRlsFixture(client);
    impersonationAvailable = await canImpersonate(client);
  });

  afterAll(async () => {
    if (!client) return;
    await client.query('ROLLBACK').catch(() => {});
    await client.end();
  });

  it('runs request → manager decision → one-time consumption for every sensitive action', async (ctx) => {
    if (!impersonationAvailable) return ctx.skip();

    const cases = [
      ['discount', 'order', ids.rows.orders.own, { discount_type: 'amount', discount_amount: 5, subtotal: 20 }],
      ['reprint', 'sale', ids.saleA, {}],
      ['void_order', 'order', ids.rows.orders.own, {}],
      ['cancel_sent_item', 'order', ids.rows.orders.own, { product_id: ids.prodA, quantity: 1 }],
      ['refund', 'sale', ids.saleA, { amount: 5 }],
      ['open_drawer', 'shift', ids.shiftA, {}],
      ['change_payment_method', 'sale', ids.saleA, { new_method: 'card' }],
      ['force_close_shift', 'shift', ids.shiftA, { actual_amount: 0 }],
    ] as const;

    for (const [action, entityType, entityId, payload] of cases) {
      const created = await request(ids.users.cashier, action, entityType, entityId, payload);
      expect(created.success, action).toBe(true);
      expect(created.status, action).toBe('pending');
      expect(created.request_id, action).toBeTruthy();

      const selfDecision = await decide(ids.users.cashier, created.request_id!, true);
      expect(selfDecision.success, action).toBe(false);
      expect(selfDecision.error, action).toBe('SELF_APPROVAL_FORBIDDEN');

      const approved = await decide(ids.users.branch_manager, created.request_id!, true);
      expect(approved.success, action).toBe(true);
      expect(approved.status, action).toBe('approved');

      const consumed = await consume(ids.users.cashier, created.request_id!, action, entityId);
      expect(consumed.success, action).toBe(true);

      const replay = await consume(ids.users.cashier, created.request_id!, action, entityId);
      expect(replay.success, action).toBe(false);
      expect(replay.error, action).toBe('APPROVAL_REQUIRED');
      expect(replay.status, action).toBe('consumed');
    }
  });

  it('prevents a manager from deciding another branch request', async (ctx) => {
    if (!impersonationAvailable) return ctx.skip();

    const created = await request(ids.users.cashier_b, 'open_drawer', 'shift', ids.shiftB);
    expect(created.success).toBe(true);

    const crossBranch = await decide(ids.users.branch_manager, created.request_id!, true);
    expect(crossBranch.success).toBe(false);
    expect(crossBranch.error).toBe('NOT_AUTHORIZED');

    const row = await client.query(`SELECT status, approver_id FROM public.approval_requests WHERE id = $1`, [created.request_id]);
    expect(row.rows[0]).toMatchObject({ status: 'pending', approver_id: null });
  });

  it('records requester and manager audit events with the correct branch', async (ctx) => {
    if (!impersonationAvailable) return ctx.skip();

    const created = await request(ids.users.cashier, 'reprint', 'sale', ids.saleA);
    const rejected = await decide(ids.users.branch_manager, created.request_id!, false);
    expect(rejected).toMatchObject({ success: true, status: 'rejected' });

    const audit = await client.query(
      `SELECT action, user_id, branch_id FROM public.audit_log
       WHERE entity = 'approval_request' AND entity_id = $1 ORDER BY created_at`,
      [created.request_id],
    );
    expect(audit.rows).toEqual(expect.arrayContaining([
      expect.objectContaining({ action: 'APPROVAL_REQUESTED', user_id: ids.users.cashier, branch_id: ids.branchA }),
      expect.objectContaining({ action: 'APPROVAL_REJECTED', user_id: ids.users.branch_manager, branch_id: ids.branchA }),
    ]));
  });
});
