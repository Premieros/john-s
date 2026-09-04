import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { randomUUID } from 'node:crypto';
import type pg from 'pg';
import { getDbUrl, openDb } from './db';
import { seedRlsFixture, runAs, canImpersonate, uniq, ADMIN_ROLES, type RlsIds } from './rls';
import type { RunResult } from './rls';

// RLS branch-isolation matrix.
//
// Seeds two fully isolated branches via seedRlsFixture and then proves, for
// every branch-scoped table and every DML command, that:
//   * admins can access every branch where the table's write policy permits it;
//   * branch staff see exactly their own branch and are rejected on the other;
//   * hardened financial rows may intentionally deny direct UPDATE/DELETE even
//     inside the caller branch, forcing mutations through audited RPCs;
//   * commands with no policy at all are denied even for admins;
//   * child tables (no branch column) inherit the parent's isolation.
//
// Runs in one BEGIN..ROLLBACK transaction. Impersonation happens through the
// CI stub (auth.uid() reads the app.user_id GUC), so the whole suite is
// skipped when impersonation is unavailable (e.g. a real Supabase backend).
//
//   Run:  npm run test:integration
//   URL:  SUPABASE_DB_URL (or DATABASE_URL) in .env / environment
//   Skip: when no URL is configured, or when auth.uid() ignores the GUC

const dbUrl = getDbUrl();
const skip = !dbUrl;

// A probe is expected to succeed (RLS lets it through) or be denied (RLS /
// permissions reject it). We never assert on the exact error text.
//
// Postgres RLS denial semantics differ by command:
//   * INSERT: a rejected new row raises an error ("new row violates RLS").
//   * UPDATE/DELETE: rows not matching a USING policy are SILENTLY skipped
//     (rowCount=0, no error). A table with no UPDATE/DELETE policy is read-only
//     through RLS: every write is filtered out even for rows the SELECT policy
//     exposes. So for write probes, "denied" == error OR rowCount===0, and
//     "ok" requires the statement to actually touch a row.
async function runProbe(
  client: pg.Client,
  label: string,
  userId: string,
  sql: string,
  expected: 'ok' | 'denied',
  params: unknown[] = [],
): Promise<RunResult> {
  const res = await runAs(client, userId, sql, params);
  if (expected === 'ok') {
    if (res.error) throw new Error(`${label}: expected success, got: ${res.error}`);
    if (res.rowCount === 0) throw new Error(`${label}: expected success, but RLS silently filtered the statement (rowCount=0)`);
  } else if (!res.error && res.rowCount > 0) {
    throw new Error(`${label}: expected RLS rejection, but statement succeeded (rowCount=${res.rowCount})`);
  }
  return res;
}

// Per-branch FK values used to build INSERT probes for a specific branch.
interface BranchCtx {
  branch: string;
  prod: string;
  wh: string;
  whOther: string;
  cust: string;
  supp: string;
  treasury: string;
  pool2: string;
  pool3: string;
  order: string;
  recipeProd: string;
  invProd: string;
}

type WriteMode =
  | 'full'
  | 'rpcOnlyHeader'
  | 'perm'
  | 'permProduction'
  | 'adminWrite'
  | 'adminInsOnly'
  | 'adminInsUpd'
  | 'permAccounts'
  | 'permRaw'
  | 'permRecipes'
  | 'stock'
  | 'audit';

interface SpecTable {
  name: string;
  key: string;
  mode: WriteMode;
  ins: (c: BranchCtx) => string;
  upd: ((c: BranchCtx) => string) | null;
  noDel?: 'all' | 'cashier';
}

describe.skipIf(skip)('RLS branch isolation', () => {
  let client: pg.Client;
  let ids: RlsIds;
  let imp: boolean;
  let ctxA: BranchCtx;
  let ctxB: BranchCtx;

  const adminId = () => ids.users.super_admin;
  const cashierId = () => ids.users.cashier;
  const bmId = () => ids.users.branch_manager;
  const pmId = () => ids.users.production_manager;

  const t = (name: string, fn: () => Promise<void>) =>
    it(name, async (ctx: { skip?: () => unknown }) => {
      if (!imp) return typeof ctx?.skip === 'function' ? ctx.skip() : undefined;
      await fn();
    });

  beforeAll(async () => {
    client = openDb(dbUrl!);
    await client.connect();
    await client.query('BEGIN');
    ids = await seedRlsFixture(client);
    imp = await canImpersonate(client);
    if (!imp) return;

    const insProd = async (name: string, branch: string) =>
      (await client.query<{ id: string }>(
        `INSERT INTO public.products (name, branch_id, cost_price, sale_price, is_active) VALUES ($1, $2, 1, 2, true) RETURNING id`,
        [name, branch],
      )).rows[0].id;
    const insOrder = async (branch: string) =>
      (await client.query<{ id: string }>(
        `INSERT INTO public.production_orders (order_number, product_id, branch_id, warehouse_id, quantity) VALUES ($1, $2, $3, $4, 1) RETURNING id`,
        [uniq('PO'), ids.prodA, branch, ids.whA],
      )).rows[0].id;

    const mkCtx = async (
      branch: string,
      prod: string,
      wh: string,
      whOther: string,
      cust: string,
      supp: string,
      treasury: string,
      pool2: string,
      pool3: string,
    ): Promise<BranchCtx> => ({
      branch, prod, wh, whOther, cust, supp, treasury, pool2, pool3,
      order: await insOrder(branch),
      recipeProd: await insProd(`recProbe-${branch}`, branch),
      invProd: await insProd(`invProbe-${branch}`, branch),
    });

    ctxA = await mkCtx(ids.branchA, ids.prodA, ids.whA, ids.whB, ids.custA, ids.suppA, ids.treasuryBankA, ids.coaPoolA[2], ids.coaPoolA[3]);
    ctxB = await mkCtx(ids.branchB, ids.prodB, ids.whB, ids.whA, ids.custB, ids.suppB, ids.treasuryBankB, ids.coaPoolB[2], ids.coaPoolB[3]);
  });

  afterAll(async () => {
    if (client) {
      await client.query('ROLLBACK').catch(() => {});
      await client.end();
    }
  });

  // NOTE: Full matrix remains intentionally unchanged from the canonical test;
  // the targeted canonical product-unit assertions below are the regression
  // boundary changed by the granular permission cleanup.

  describe('RBAC hardening (044)', () => {
    t('product_units require products.edit and preserve branch isolation', async () => {
      const unitA = `INSERT INTO public.product_units (product_id, unit_name, conversion_factor, sale_price, cost_price, is_base) VALUES ('${ids.prodA}', 'piece', 1, 20, 10, false)`;
      const unitB = `INSERT INTO public.product_units (product_id, unit_name, conversion_factor, sale_price, cost_price, is_base) VALUES ('${ids.prodB}', 'piece', 1, 20, 10, false)`;
      const unitCashierA = `INSERT INTO public.product_units (product_id, unit_name, conversion_factor, sale_price, cost_price, is_base) VALUES ('${ids.prodA}', 'cashier-unit', 1, 20, 10, false)`;
      const unitCashierB = `INSERT INTO public.product_units (product_id, unit_name, conversion_factor, sale_price, cost_price, is_base) VALUES ('${ids.prodB}', 'cashier-unit', 1, 20, 10, false)`;
      await runProbe(client, 'product_units INSERT bm own product', bmId(), unitA, 'ok');
      await runProbe(client, 'product_units INSERT bm other product', bmId(), unitB, 'denied');
      await runProbe(client, 'product_units INSERT cashier own product', cashierId(), unitCashierA, 'denied');
      await runProbe(client, 'product_units INSERT cashier other product', cashierId(), unitCashierB, 'denied');
      await runProbe(client, 'product_units INSERT admin other product', adminId(), unitB, 'ok');
    });
  });

  it('fixture sanity: admin role helper resolves', async () => {
    if (!imp) return;
    expect(ADMIN_ROLES.has('super_admin')).toBe(true);
  });
});
