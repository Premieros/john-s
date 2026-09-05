-- Root Permission-First reconciliation.
-- Roles are labels only. Super Admin is the only implicit bypass.

-- 1) Replace the legacy owner label with a neutral manager label while preserving
-- the explicitly selected canonical permissions already stored on the role.
INSERT INTO public.roles (role, permissions, name_ar, name_en, scope, branch_id, is_active)
SELECT
  'manager',
  permissions,
  COALESCE(NULLIF(name_ar, ''), 'مدير'),
  COALESCE(NULLIF(name_en, ''), 'Manager'),
  scope,
  branch_id,
  is_active
FROM public.roles
WHERE role = 'owner'
ON CONFLICT (role) DO NOTHING;

UPDATE public.users
SET role = 'manager'
WHERE role = 'owner';

UPDATE public.organization_members
SET membership_role = 'admin'
WHERE membership_role = 'owner';

DELETE FROM public.roles
WHERE role = 'owner';

-- 2) Remove historical permission aliases from every role. Do not infer or add
-- replacement grants: the canonical permissions that were explicitly selected
-- remain untouched.
UPDATE public.roles
SET permissions = COALESCE(permissions, '[]'::jsonb)
  - 'pos.sell'
  - 'pos.pay'
  - 'pos.split_order'
  - 'pos.transfer_order'
  - 'products.manage'
  - 'inventory.manage'
  - 'inventory.transfers'
  - 'inventory.transfers.approve'
  - 'catalog.view'
  - 'procurement.view'
  - 'accounting.view'
  - 'admin.view';

-- 3) Compatibility helper now means exactly Super Admin. No role other than
-- super_admin receives implicit privileges.
CREATE OR REPLACE FUNCTION public.is_pos_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.users u
    WHERE u.id = auth.uid()
      AND u.is_active = true
      AND u.role = 'super_admin'
  );
$$;

REVOKE ALL ON FUNCTION public.is_pos_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_pos_admin() TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.can_permission(p_permission text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT public.is_pos_admin()
    OR EXISTS (
      SELECT 1
      FROM public.users u
      JOIN public.roles r ON r.role = u.role AND r.is_active = true
      WHERE u.id = auth.uid()
        AND u.is_active = true
        AND COALESCE(r.permissions, '[]'::jsonb) ? p_permission
    );
$$;

REVOKE ALL ON FUNCTION public.can_permission(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.can_permission(text) TO authenticated, service_role;

-- 4) Modifier administration is canonical permission + branch scope only.
CREATE OR REPLACE FUNCTION public.get_product_modifiers_admin(p_product_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_branch_id uuid;
  v_groups jsonb;
BEGIN
  SELECT branch_id INTO v_branch_id
  FROM public.products
  WHERE id = p_product_id;

  IF v_branch_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'PRODUCT_NOT_FOUND');
  END IF;

  IF NOT public.can_permission('products.modifiers.manage')
     OR NOT public.user_may_access_branch(v_branch_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'PERMISSION_DENIED');
  END IF;

  SELECT COALESCE(jsonb_agg(group_json ORDER BY sort_order, id), '[]'::jsonb)
  INTO v_groups
  FROM (
    SELECT g.id, g.sort_order,
      jsonb_build_object(
        'id', g.id,
        'name', g.name,
        'name_en', g.name_en,
        'min_selections', g.min_selections,
        'max_selections', g.max_selections,
        'sort_order', g.sort_order,
        'options', COALESCE((
          SELECT jsonb_agg(
            jsonb_build_object(
              'id', o.id,
              'name', o.name,
              'name_en', o.name_en,
              'price_delta', o.price_delta,
              'is_default', o.is_default,
              'sort_order', o.sort_order,
              'inventory_effects', COALESCE((
                SELECT jsonb_agg(
                  jsonb_build_object(
                    'target_type', e.target_type,
                    'target_id', CASE WHEN e.target_type = 'raw_material' THEN e.raw_material_id ELSE e.inventory_unit_id END,
                    'quantity_delta', e.quantity_delta
                  ) ORDER BY e.id
                )
                FROM public.product_modifier_inventory_effects e
                WHERE e.option_id = o.id
              ), '[]'::jsonb)
            ) ORDER BY o.sort_order, o.id
          )
          FROM public.product_modifier_options o
          WHERE o.group_id = g.id AND o.is_active = true
        ), '[]'::jsonb)
      ) AS group_json
    FROM public.product_modifier_groups g
    WHERE g.product_id = p_product_id
      AND g.branch_id = v_branch_id
      AND g.is_active = true
  ) q;

  RETURN jsonb_build_object(
    'success', true,
    'product_id', p_product_id,
    'branch_id', v_branch_id,
    'groups', v_groups
  );
END;
$$;

-- 5) Rewrite historical permission checks in current runtime definitions.
-- These replacements operate on the final function definitions after all older
-- migrations have run; historical migration files remain immutable records.
DO $$
DECLARE
  r record;
  d text;
  n text;
BEGIN
  FOR r IN
    SELECT p.oid, p.proname, pg_get_functiondef(p.oid) AS def
    FROM pg_proc p
    JOIN pg_namespace ns ON ns.oid = p.pronamespace
    WHERE ns.nspname = 'public' AND p.prokind = 'f'
  LOOP
    d := r.def;
    n := d;

    -- Canonical aliases with an unambiguous one-to-one capability.
    n := replace(n, '''pos.pay''', '''pos.payment.take''');
    n := replace(n, '''pos.sell''', '''pos.order.create''');
    n := replace(n, '''pos.split_order''', '''pos.order.split''');
    n := replace(n, '''pos.transfer_order''', '''pos.order.transfer''');
    n := replace(n, '''inventory.transfers.approve''', '''inventory.transfer.approve''');
    n := replace(n, '''inventory.transfers''', '''inventory.transfer.create''');
    n := replace(n, '''products.manage''', '''products.modifiers.manage''');

    -- Inventory.manage was historically overloaded. Resolve by operation.
    IF r.proname IN ('create_stock_count','add_stock_count_item','update_stock_count_item','remove_stock_count_item','submit_stock_count') THEN
      n := replace(n, '''inventory.manage''', '''inventory.count.create''');
    ELSIF r.proname IN ('approve_stock_count','reject_stock_count','apply_stock_count') THEN
      n := replace(n, '''inventory.manage''', '''inventory.count.approve''');
    ELSIF r.proname IN ('add_inventory_batch','adjust_stock','adjust_raw_stock') THEN
      n := replace(n, '''inventory.manage''', '''inventory.adjust''');
    ELSIF r.proname IN ('decide_operational_approval','get_operational_approval_queue','enforce_approval_policy_transition') THEN
      n := replace(n, '''inventory.manage''', '''approvals.review''');
    END IF;

    -- Remove owner from old Super Admin compatibility predicates.
    n := replace(n, 'IN (''super_admin'', ''owner'')', '= ''super_admin''');
    n := replace(n, 'IN (''super_admin'',''owner'')', '= ''super_admin''');
    n := replace(n, 'NOT IN (''super_admin'', ''owner'')', '<> ''super_admin''');
    n := replace(n, 'NOT IN (''super_admin'',''owner'')', '<> ''super_admin''');

    -- Operational role gates become explicit capability checks.
    IF r.proname IN ('adjust_stock','adjust_raw_stock') THEN
      n := regexp_replace(n,
        'IF NOT (public\.)?is_pos_admin\(\) AND get_user_role\(\) NOT IN \(''warehouse_manager'',''branch_manager''\) THEN',
        'IF NOT public.can_permission(''inventory.adjust'') THEN', 'g');
    ELSIF r.proname IN ('create_bank_reconciliation','add_statement_line','match_bank_line','complete_bank_reconciliation') THEN
      n := regexp_replace(n,
        'IF NOT (public\.)?is_pos_admin\(\) AND get_user_role\(\) NOT IN \(''accountant'', ''branch_manager''\) THEN',
        'IF NOT public.can_permission(''accounting.reconciliation.manage'') THEN', 'g');
    ELSIF r.proname = '_treasury_guard' THEN
      n := regexp_replace(n,
        'IF NOT (public\.)?is_pos_admin\(\) AND get_user_role\(\) NOT IN \(''accountant'', ''branch_manager''\) THEN',
        'IF NOT public.can_permission(''accounting.treasury.transfer'') THEN', 'g');
    ELSIF r.proname = 'post_manual_journal' THEN
      n := regexp_replace(n,
        'IF NOT (public\.)?is_pos_admin\(\) AND get_user_role\(\) NOT IN \(''accountant'', ''branch_manager''\) THEN',
        'IF NOT public.can_permission(''accounting.journal.post'') THEN', 'g');
    ELSIF r.proname = 'pay_supplier' THEN
      n := regexp_replace(n,
        'IF NOT (public\.)?is_pos_admin\(\) AND get_user_role\(\) NOT IN \(''accountant'', ''branch_manager''\) THEN',
        'IF NOT public.can_permission(''procurement.payment.create'') THEN', 'g');
    ELSIF r.proname = 'receive_payment' THEN
      n := regexp_replace(n,
        'IF NOT (public\.)?is_pos_admin\(\) AND get_user_role\(\) NOT IN \(''accountant'', ''branch_manager'', ''cashier''\) THEN',
        'IF NOT public.can_permission(''sales.payment.receive'') THEN', 'g');
    ELSIF r.proname IN ('process_purchase','process_purchase_return') THEN
      n := regexp_replace(n,
        'IF NOT (public\.)?is_pos_admin\(\) AND get_user_role\(\) NOT IN \(''warehouse_manager'',''branch_manager''\) THEN',
        'IF NOT public.can_permission(''purchases.manage'') THEN', 'g');
    END IF;

    IF n IS DISTINCT FROM d THEN
      EXECUTE n;
    END IF;
  END LOOP;
END;
$$;

-- 6) User management: permission-first, branch isolation independent from role labels.
CREATE OR REPLACE FUNCTION public.guard_role_permissions()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF public.is_pos_admin() THEN
    RETURN NEW;
  END IF;

  IF NOT public.can_permission('roles.permissions.manage') THEN
    RAISE EXCEPTION 'PERMISSION_DENIED:roles.permissions.manage';
  END IF;

  IF NEW.branch_id IS NULL OR NEW.scope = 'global' THEN
    RAISE EXCEPTION 'PERMISSION_DENIED: only Super Admin can modify global role permissions';
  END IF;

  IF NOT public.user_may_access_branch(NEW.branch_id) THEN
    RAISE EXCEPTION 'PERMISSION_DENIED: role branch is outside caller scope';
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.guard_user_role_changes()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_bypass boolean := COALESCE(current_setting('app.login_guard_bypass', true), '') = 'on';
  v_register boolean := COALESCE(current_setting('app.register_branch', true), '') = 'on';
BEGIN
  IF v_register THEN
    RETURN NEW;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.roles WHERE role = NEW.role AND is_active = true) THEN
    RAISE EXCEPTION 'UNKNOWN_ROLE';
  END IF;

  IF auth.uid() IS NULL OR NOT EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_active = true) THEN
    IF TG_OP = 'INSERT' AND NEW.id = auth.uid() AND NEW.role = 'cashier' AND NEW.branch_id IS NULL THEN
      RETURN NEW;
    END IF;
    IF TG_OP = 'UPDATE'
       AND NEW.id IS NOT DISTINCT FROM OLD.id
       AND NEW.role IS NOT DISTINCT FROM OLD.role
       AND NEW.branch_id IS NOT DISTINCT FROM OLD.branch_id
       AND NEW.is_active IS NOT DISTINCT FROM OLD.is_active
       AND NEW.email IS NOT DISTINCT FROM OLD.email
       AND NEW.username IS NOT DISTINCT FROM OLD.username
       AND NEW.full_name IS NOT DISTINCT FROM OLD.full_name
       AND NEW.phone IS NOT DISTINCT FROM OLD.phone THEN
      RETURN NEW;
    END IF;
    RAISE EXCEPTION 'PERMISSION_DENIED';
  END IF;

  IF TG_OP = 'INSERT' AND NOT public.can_permission('users.create') THEN
    RAISE EXCEPTION 'PERMISSION_DENIED:users.create';
  ELSIF TG_OP = 'UPDATE' AND NOT public.can_permission('users.manage') THEN
    RAISE EXCEPTION 'PERMISSION_DENIED:users.manage';
  END IF;

  -- Super Admin identities may only be created/modified by another Super Admin.
  IF NEW.role = 'super_admin' AND NOT public.is_pos_admin() THEN
    RAISE EXCEPTION 'PERMISSION_DENIED: only Super Admin can assign super_admin';
  END IF;
  IF TG_OP = 'UPDATE' AND OLD.role = 'super_admin' AND NOT public.is_pos_admin() THEN
    RAISE EXCEPTION 'PERMISSION_DENIED: only Super Admin can modify super_admin';
  END IF;

  IF NEW.branch_id IS NOT NULL AND NOT public.user_may_access_branch(NEW.branch_id) THEN
    RAISE EXCEPTION 'PERMISSION_DENIED: branch outside caller scope';
  END IF;

  IF TG_OP = 'UPDATE' AND NEW.id = auth.uid() AND NOT public.is_pos_admin() THEN
    IF NEW.role IS DISTINCT FROM OLD.role
       OR NEW.branch_id IS DISTINCT FROM OLD.branch_id
       OR NEW.is_active IS DISTINCT FROM OLD.is_active THEN
      RAISE EXCEPTION 'PERMISSION_DENIED: users cannot change their own role/branch/status';
    END IF;
    IF NOT v_bypass AND (
      NEW.is_locked IS DISTINCT FROM OLD.is_locked
      OR NEW.failed_attempts IS DISTINCT FROM OLD.failed_attempts
      OR NEW.lock_until IS DISTINCT FROM OLD.lock_until
    ) THEN
      RAISE EXCEPTION 'PERMISSION_DENIED: users cannot modify their own lock state';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- 7) Organization membership has no owner concept. Admin is membership scope only;
-- operational authorization still comes from roles.permissions.
DROP POLICY IF EXISTS organization_members_insert ON public.organization_members;
CREATE POLICY organization_members_insert ON public.organization_members
FOR INSERT TO authenticated
WITH CHECK (
  public.is_pos_admin()
  OR EXISTS (
    SELECT 1
    FROM public.organization_members current_member
    WHERE current_member.organization_id = organization_members.organization_id
      AND current_member.user_id = auth.uid()
      AND current_member.membership_role = 'admin'
      AND current_member.is_active = true
  )
);

-- 8) Tenant registration stores manager/admin, never owner.
DO $$
DECLARE
  r record;
  d text;
  n text;
BEGIN
  FOR r IN
    SELECT p.oid, pg_get_functiondef(p.oid) AS def
    FROM pg_proc p
    JOIN pg_namespace ns ON ns.oid = p.pronamespace
    WHERE ns.nspname = 'public' AND p.prokind = 'f' AND p.proname = 'register_tenant'
  LOOP
    d := r.def;
    n := replace(d, '''owner'',', '''manager'',');
    n := replace(n, ', ''owner'', true', ', ''admin'', true');
    n := replace(n, '''membership_role'', ''owner''', '''membership_role'', ''admin''');
    IF n IS DISTINCT FROM d THEN EXECUTE n; END IF;
  END LOOP;
END;
$$;

-- 9) Demo helpers no longer rely on a branch-manager role label.
DO $$
DECLARE
  r record;
  d text;
  n text;
BEGIN
  FOR r IN
    SELECT p.oid, pg_get_functiondef(p.oid) AS def
    FROM pg_proc p
    JOIN pg_namespace ns ON ns.oid = p.pronamespace
    WHERE ns.nspname = 'public' AND p.prokind = 'f'
      AND p.proname IN ('seed_demo_data','delete_demo_data')
  LOOP
    d := r.def;
    n := replace(d,
      'IF NOT is_pos_admin() AND NOT (is_branch_manager() AND get_branch_id() = p_branch_id) THEN',
      'IF NOT public.can_permission(''settings.manage'') OR NOT public.user_may_access_branch(p_branch_id) THEN');
    IF n IS DISTINCT FROM d THEN EXECUTE n; END IF;
  END LOOP;
END;
$$;

-- 10) Self-audit: fail the migration if the root contract is not achieved.
DO $$
DECLARE
  v_count integer;
BEGIN
  SELECT count(*) INTO v_count FROM public.users WHERE role = 'owner';
  IF v_count <> 0 THEN RAISE EXCEPTION 'PERMISSION_FIRST_DRIFT: owner users remain (%)', v_count; END IF;

  SELECT count(*) INTO v_count FROM public.roles WHERE role = 'owner';
  IF v_count <> 0 THEN RAISE EXCEPTION 'PERMISSION_FIRST_DRIFT: owner role remains'; END IF;

  SELECT count(*) INTO v_count FROM public.organization_members WHERE membership_role = 'owner';
  IF v_count <> 0 THEN RAISE EXCEPTION 'PERMISSION_FIRST_DRIFT: owner organization membership remains (%)', v_count; END IF;

  SELECT count(*) INTO v_count
  FROM public.roles r
  CROSS JOIN LATERAL jsonb_array_elements_text(COALESCE(r.permissions, '[]'::jsonb)) p(permission)
  WHERE p.permission = ANY (ARRAY[
    'pos.sell','pos.pay','pos.split_order','pos.transfer_order','products.manage',
    'inventory.manage','inventory.transfers','inventory.transfers.approve',
    'catalog.view','procurement.view','accounting.view','admin.view'
  ]);
  IF v_count <> 0 THEN RAISE EXCEPTION 'PERMISSION_FIRST_DRIFT: legacy role permissions remain (%)', v_count; END IF;

  SELECT count(*) INTO v_count
  FROM pg_proc p
  JOIN pg_namespace ns ON ns.oid = p.pronamespace
  WHERE ns.nspname = 'public' AND p.prokind = 'f'
    AND (
      pg_get_functiondef(p.oid) ~ '''(pos.sell|pos.pay|pos.split_order|pos.transfer_order|products.manage|inventory.manage|inventory.transfers|inventory.transfers.approve)'''
      OR pg_get_functiondef(p.oid) ~ 'role[[:space:]]*(=|IN|NOT IN)[[:space:]]*\([^)]*(owner|branch_manager|accountant|warehouse_manager|cashier)'
      OR pg_get_functiondef(p.oid) ~ 'role[[:space:]]*=[[:space:]]*''(owner|branch_manager|accountant|warehouse_manager|cashier)'''
      OR pg_get_functiondef(p.oid) ~ 'get_user_role\(\)[[:space:]]*(=|<>|IN|NOT IN)'
    );
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'PERMISSION_FIRST_DRIFT: role-based or legacy authorization remains in % runtime functions', v_count;
  END IF;
END;
$$;
