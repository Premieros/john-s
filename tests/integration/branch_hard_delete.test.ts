import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { randomUUID } from 'node:crypto';
import { getDbUrl, openDb } from './db';
import { runAsPersist } from './rls';
import type pg from 'pg';

const dbUrl = getDbUrl();

describe.skipIf(!dbUrl)('Permanent branch deletion', () => {
  let client: pg.Client;
  let orgId: string;
  let ownerId: string;
  let currentBranchId: string;
  let targetBranchId: string;
  let targetUserId: string;
  let managerId: string;

  beforeAll(async () => {
    client = openDb(dbUrl!);
    await client.connect();
    await client.query('BEGIN');
    await client.query('ALTER TABLE public.users DISABLE TRIGGER trg_users_role_guard');

    orgId = randomUUID();
    currentBranchId = randomUUID();
    targetBranchId = randomUUID();
    ownerId = randomUUID();
    targetUserId = randomUUID();
    managerId = randomUUID();

    await client.query(`INSERT INTO public.organizations (id, name) VALUES ($1, 'Delete Test Org')`, [orgId]);
    await client.query(
      `INSERT INTO public.branches (id, organization_id, name, is_active)
       VALUES ($1,$3,'Current Branch',true),($2,$3,'Target Branch',true)`,
      [currentBranchId, targetBranchId, orgId],
    );
    await client.query(
      `INSERT INTO public.users (id,email,username,full_name,role,branch_id,is_active)
       VALUES
       ($1,$2,$3,'Owner','owner',$4,true),
       ($5,$6,$7,'Target User','cashier',$8,true),
       ($9,$10,$11,'Manager','branch_manager',$8,true)`,
      [
        ownerId, `owner-${randomUUID()}@example.test`, `owner_${randomUUID().slice(0, 8)}`, currentBranchId,
        targetUserId, `target-${randomUUID()}@example.test`, `target_${randomUUID().slice(0, 8)}`, targetBranchId,
        managerId, `manager-${randomUUID()}@example.test`, `manager_${randomUUID().slice(0, 8)}`,
      ],
    );
    await client.query(
      `INSERT INTO public.organization_members (organization_id,user_id,membership_role,is_active)
       VALUES ($1,$2,'owner',true),($1,$3,'member',true),($1,$4,'member',true)`,
      [orgId, ownerId, targetUserId, managerId],
    );
    await client.query('ALTER TABLE public.users ENABLE TRIGGER trg_users_role_guard');
  });

  afterAll(async () => {
    await client.query('ROLLBACK').catch(() => {});
    await client.end().catch(() => {});
  });

  it('converts every direct public branch_id foreign key to ON DELETE CASCADE', async () => {
    const res = await client.query(`
      SELECT tc.table_name, rc.delete_rule
      FROM information_schema.table_constraints tc
      JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name=kcu.constraint_name AND tc.constraint_schema=kcu.constraint_schema
      JOIN information_schema.referential_constraints rc
        ON rc.constraint_name=tc.constraint_name AND rc.constraint_schema=tc.constraint_schema
      JOIN information_schema.constraint_column_usage ccu
        ON ccu.constraint_name=tc.constraint_name AND ccu.constraint_schema=tc.constraint_schema
      WHERE tc.table_schema='public'
        AND tc.constraint_type='FOREIGN KEY'
        AND ccu.table_schema='public'
        AND ccu.table_name='branches'
        AND kcu.column_name='branch_id'
        AND rc.delete_rule <> 'CASCADE'
    `);
    expect(res.rows).toHaveLength(0);
  });

  it('does not allow branch_manager to permanently delete a branch', async () => {
    const res = await runAsPersist(client, managerId, `SELECT public.delete_branch_cascade($1) AS res`, [targetBranchId]);
    expect((res.rows[0] as { res: Record<string, unknown> }).res.error).toBe('PERMISSION_DENIED');
  });

  it('does not allow owner to delete the branch assigned to their own profile', async () => {
    const res = await runAsPersist(client, ownerId, `SELECT public.delete_branch_cascade($1) AS res`, [currentBranchId]);
    expect((res.rows[0] as { res: Record<string, unknown> }).res.error).toBe('CANNOT_DELETE_CURRENT_BRANCH');
  });

  it('owner can hard-delete another accessible branch and its linked public users', async () => {
    const res = await runAsPersist(client, ownerId, `SELECT public.delete_branch_cascade($1) AS res`, [targetBranchId]);
    const result = (res.rows[0] as { res: Record<string, unknown> }).res;
    expect(result.success, JSON.stringify(result)).toBe(true);

    const branch = await client.query(`SELECT id FROM public.branches WHERE id=$1`, [targetBranchId]);
    expect(branch.rows).toHaveLength(0);

    const linkedUsers = await client.query(`SELECT id FROM public.users WHERE id = ANY($1::uuid[])`, [[targetUserId, managerId]]);
    expect(linkedUsers.rows).toHaveLength(0);
  });
});
