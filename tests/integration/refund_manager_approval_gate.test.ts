import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import type pg from 'pg';
import { getDbUrl, openDb } from './db';

let client: pg.Client;
let canRun = false;

beforeAll(async () => {
  const dbUrl = getDbUrl();
  if (!dbUrl) return;
  try {
    client = openDb(dbUrl);
    await client.connect();
    canRun = true;
  } catch {
    canRun = false;
  }
}, 30_000);

afterAll(async () => {
  if (client) await client.end().catch(() => {});
});

describe('refund manager approval gate', () => {
  it('process_refund contains the approval gate and one-time consumption guard', async () => {
    if (!canRun) return;
    const r = await client.query(`
      SELECT pg_get_functiondef(p.oid) AS def
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'public'
        AND p.proname = 'process_refund'
        AND p.oid::regprocedure::text = 'process_refund(uuid,jsonb,text)'
    `);
    expect(r.rowCount).toBe(1);
    const def = String(r.rows[0].def || '');
    expect(def).toContain("action_type = 'refund'");
    expect(def).toContain("target_type = 'sale'");
    expect(def).toContain('APPROVAL_REQUIRED');
    expect(def).toContain('FOR UPDATE SKIP LOCKED');
    expect(def).toContain("status = 'consumed'");
    expect(def).toContain('REFUND_APPROVAL_CONSUME_FAILED');
  });

  it('approval_requests accepts refund as a controlled action type', async () => {
    if (!canRun) return;
    const r = await client.query(`
      SELECT pg_get_constraintdef(c.oid) AS def
      FROM pg_constraint c
      JOIN pg_class t ON t.oid = c.conrelid
      JOIN pg_namespace n ON n.oid = t.relnamespace
      WHERE n.nspname = 'public'
        AND t.relname = 'approval_requests'
        AND c.contype = 'c'
    `);
    const defs = r.rows.map((row) => String(row.def || '')).join('\n');
    expect(defs).toContain('refund');
  });
});
