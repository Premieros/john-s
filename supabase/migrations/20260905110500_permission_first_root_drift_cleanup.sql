-- Permission-First root reconciliation.
-- Roles are labels only. Super Admin is the only implicit bypass.

-- Neutralize the historical owner label without inventing new grants.
INSERT INTO public.roles (role, permissions, name_ar, name_en, scope, branch_id, is_active)
SELECT 'manager', permissions,
       COALESCE(NULLIF(name_ar, ''), 'مدير'),
       COALESCE(NULLIF(name_en, ''), 'Manager'),
       scope, branch_id, is_active
FROM public.roles
WHERE role = 'owner'
ON CONFLICT (role) DO NOTHING;
UPDATE public.users SET role = 'manager' WHERE role = 'owner';
UPDATE public.organization_members SET membership_role = 'admin' WHERE membership_role = 'owner';
DELETE FROM public.roles WHERE role = 'owner';

-- Historical aliases are not grants. Keep only permissions already selected by
-- the administrator under canonical names.
UPDATE public.roles
SET permissions = COALESCE(permissions, '[]'::jsonb)
  - 'pos.sell' - 'pos.pay' - 'pos.split_order' - 'pos.transfer_order'
  - 'products.manage' - 'inventory.manage' - 'inventory.transfers'
  - 'inventory.transfers.approve' - 'catalog.view' - 'procurement.view'
  - 'accounting.view' - 'admin.view';

CREATE OR REPLACE FUNCTION public.is_pos_admin()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users u
    WHERE u.id = auth.uid() AND u.is_active = true AND u.role = 'super_admin'
  );
$$;
REVOKE ALL ON FUNCTION public.is_pos_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_pos_admin() TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.can_permission(p_permission text)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT public.is_pos_admin() OR EXISTS (
    SELECT 1
    FROM public.users u
    JOIN public.roles r ON r.role = u.role AND r.is_active = true
    WHERE u.id = auth.uid() AND u.is_active = true
      AND COALESCE(r.permissions, '[]'::jsonb) ? p_permission
  );
$$;
REVOKE ALL ON FUNCTION public.can_permission(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.can_permission(text) TO authenticated, service_role;

-- Rewrite the final runtime definitions after all historical migrations have
-- run. Matching is whitespace-tolerant because pg_get_functiondef normalizes
-- formatting; no role label may remain as an authorization capability.
DO $$
DECLARE r record; d text; n text;
BEGIN
  FOR r IN
    SELECT p.oid, p.proname, pg_get_functiondef(p.oid) def
    FROM pg_proc p JOIN pg_namespace ns ON ns.oid=p.pronamespace
    WHERE ns.nspname='public' AND p.prokind='f'
  LOOP
    d := r.def; n := d;

    n := replace(n, '''pos.pay''', '''pos.payment.take''');
    n := replace(n, '''pos.sell''', '''pos.order.create''');
    n := replace(n, '''pos.split_order''', '''pos.order.split''');
    n := replace(n, '''pos.transfer_order''', '''pos.order.transfer''');
    n := replace(n, '''inventory.transfers.approve''', '''inventory.transfer.approve''');
    n := replace(n, '''inventory.transfers''', '''inventory.transfer.create''');
    n := replace(n, '''products.manage''', '''products.modifiers.manage''');

    IF r.proname IN ('create_stock_count','add_stock_count_item','update_stock_count_item','remove_stock_count_item','submit_stock_count') THEN
      n := replace(n, '''inventory.manage''', '''inventory.count.create''');
    ELSIF r.proname IN ('approve_stock_count','reject_stock_count','apply_stock_count') THEN
      n := replace(n, '''inventory.manage''', '''inventory.count.approve''');
    ELSIF r.proname IN ('add_inventory_batch','adjust_stock','adjust_raw_stock') THEN
      n := replace(n, '''inventory.manage''', '''inventory.adjust''');
    ELSIF r.proname IN ('decide_operational_approval','get_operational_approval_queue','enforce_approval_policy_transition') THEN
      n := replace(n, '''inventory.manage''', '''approvals.review''');
    END IF;

    -- Owner is not an authorization identity. Historical paired admin lists
    -- collapse to the sole implicit exception: super_admin.
    n := replace(n, 'NOT IN (''super_admin'', ''owner'')', '<> ''super_admin''');
    n := replace(n, 'NOT IN (''super_admin'',''owner'')', '<> ''super_admin''');
    n := replace(n, 'IN (''super_admin'', ''owner'')', '= ''super_admin''');
    n := replace(n, 'IN (''super_admin'',''owner'')', '= ''super_admin''');

    -- Inventory adjustments.
    IF r.proname IN ('adjust_stock','adjust_raw_stock') THEN
      n := regexp_replace(n,
        'IF[[:space:]]+NOT[[:space:]]+(public\.)?is_pos_admin\(\)[[:space:]]+AND[[:space:]]+get_user_role\(\)[[:space:]]+NOT[[:space:]]+IN[[:space:]]*\(''warehouse_manager''[[:space:]]*,[[:space:]]*''branch_manager''\)[[:space:]]+THEN',
        'IF NOT public.can_permission(''inventory.adjust'') THEN', 'gi');
    END IF;

    -- Bank reconciliation.
    IF r.proname IN ('add_statement_line','match_bank_line','complete_bank_reconciliation','create_bank_reconciliation') THEN
      n := regexp_replace(n,
        'IF[[:space:]]+NOT[[:space:]]+(public\.)?is_pos_admin\(\)[[:space:]]+AND[[:space:]]+get_user_role\(\)[[:space:]]+NOT[[:space:]]+IN[[:space:]]*\(''accountant''[[:space:]]*,[[:space:]]*''branch_manager''\)[[:space:]]+THEN',
        'IF NOT public.can_permission(''accounting.reconciliation.manage'') THEN', 'gi');
    END IF;

    -- Treasury / accounting / procurement / receivables.
    IF r.proname = '_treasury_guard' THEN
      n := regexp_replace(n,
        'IF[[:space:]]+NOT[[:space:]]+(public\.)?is_pos_admin\(\)[[:space:]]+AND[[:space:]]+get_user_role\(\)[[:space:]]+NOT[[:space:]]+IN[[:space:]]*\(''accountant''[[:space:]]*,[[:space:]]*''branch_manager''\)[[:space:]]+THEN',
        'IF NOT public.can_permission(''accounting.treasury.transfer'') THEN', 'gi');
    ELSIF r.proname = 'post_manual_journal' THEN
      n := regexp_replace(n,
        'IF[[:space:]]+NOT[[:space:]]+(public\.)?is_pos_admin\(\)[[:space:]]+AND[[:space:]]+get_user_role\(\)[[:space:]]+NOT[[:space:]]+IN[[:space:]]*\(''accountant''[[:space:]]*,[[:space:]]*''branch_manager''\)[[:space:]]+THEN',
        'IF NOT public.can_permission(''accounting.journal.post'') THEN', 'gi');
    ELSIF r.proname = 'pay_supplier' THEN
      n := regexp_replace(n,
        'IF[[:space:]]+NOT[[:space:]]+(public\.)?is_pos_admin\(\)[[:space:]]+AND[[:space:]]+get_user_role\(\)[[:space:]]+NOT[[:space:]]+IN[[:space:]]*\(''accountant''[[:space:]]*,[[:space:]]*''branch_manager''\)[[:space:]]+THEN',
        'IF NOT public.can_permission(''procurement.payment.create'') THEN', 'gi');
    ELSIF r.proname = 'receive_payment' THEN
      n := regexp_replace(n,
        'IF[[:space:]]+NOT[[:space:]]+(public\.)?is_pos_admin\(\)[[:space:]]+AND[[:space:]]+get_user_role\(\)[[:space:]]+NOT[[:space:]]+IN[[:space:]]*\(''accountant''[[:space:]]*,[[:space:]]*''branch_manager''[[:space:]]*,[[:space:]]*''cashier''\)[[:space:]]+THEN',
        'IF NOT public.can_permission(''sales.payment.receive'') THEN', 'gi');
    ELSIF r.proname IN ('process_purchase','process_purchase_return') THEN
      n := regexp_replace(n,
        'IF[[:space:]]+NOT[[:space:]]+(public\.)?is_pos_admin\(\)[[:space:]]+AND[[:space:]]+get_user_role\(\)[[:space:]]+NOT[[:space:]]+IN[[:space:]]*\(''warehouse_manager''[[:space:]]*,[[:space:]]*''branch_manager''\)[[:space:]]+THEN',
        'IF NOT public.can_permission(''purchases.manage'') THEN', 'gi');
    END IF;

    -- Expense creation is never implied by accountant/manager labels.
    IF r.proname = 'process_expense' THEN
      n := regexp_replace(n,
        'IF[[:space:]]+NOT[[:space:]]+(public\.)?is_pos_admin\(\)[[:space:]]+AND[[:space:]]+NOT[[:space:]]+(public\.)?can_permission\(''expenses.manage''\)[[:space:]]+AND[[:space:]]+get_user_role\(\)[[:space:]]+NOT[[:space:]]+IN[[:space:]]*\(''branch_manager''[[:space:]]*,[[:space:]]*''accountant''\)[[:space:]]+THEN',
        'IF NOT public.can_permission(''expenses.manage'') THEN', 'gi');
    END IF;

    -- Explicit approval bypass capability replaces the historical manager label.
    IF r.proname IN ('authorize_open_drawer','change_sale_payment_method','force_close_shift') THEN
      n := regexp_replace(n,
        'IF[[:space:]]+NOT[[:space:]]+public\.is_pos_admin\(\)[[:space:]]+AND[[:space:]]+v_role[[:space:]]*<>[[:space:]]*''branch_manager''[[:space:]]+THEN',
        'IF NOT public.can_permission(''approvals.override'') THEN', 'gi');
    END IF;

    -- Register/shift behavior is capability-based, not cashier-label based.
    IF r.proname = '_process_sale_core' THEN
      n := regexp_replace(n,
        'IF[[:space:]]+v_role[[:space:]]*=[[:space:]]*''cashier''[[:space:]]+AND[[:space:]]+NOT[[:space:]]+(public\.)?is_pos_admin\(\)[[:space:]]+THEN',
        'IF public.can_permission(''pos.payment.take'') AND NOT public.is_pos_admin() THEN', 'gi');
    END IF;

    -- KDS assignment visibility: station administration is a capability.
    IF r.proname IN ('get_kitchen_queue','get_my_kitchen_stations') THEN
      n := regexp_replace(n,
        'v_role[[:space:]]+IN[[:space:]]*\(''super_admin''[[:space:]]*,[[:space:]]*''owner''[[:space:]]*,[[:space:]]*''branch_manager''\)',
        'public.can_permission(''settings.manage'')', 'gi');
    END IF;

    -- Modifier administration has its own canonical capability.
    IF r.proname = 'get_product_modifiers_admin' THEN
      n := regexp_replace(n,
        'v_role[[:space:]]+NOT[[:space:]]+IN[[:space:]]*\(''super_admin''[[:space:]]*,[[:space:]]*''owner''[[:space:]]*,[[:space:]]*''branch_manager''\)',
        'NOT public.can_permission(''products.modifiers.manage'')', 'gi');
    END IF;

    -- Tenant bootstrap no longer creates owner labels.
    IF r.proname = 'register_tenant' THEN
      n := replace(n, '''owner'',', '''manager'',');
      n := replace(n, ', ''owner'', true', ', ''admin'', true');
      n := replace(n, '''membership_role'', ''owner''', '''membership_role'', ''admin''');
    END IF;

    -- Demo management is a settings capability plus branch scope.
    IF r.proname IN ('seed_demo_data','delete_demo_data') THEN
      n := regexp_replace(n,
        'IF[[:space:]]+NOT[[:space:]]+(public\.)?is_pos_admin\(\)[[:space:]]+AND[[:space:]]+NOT[[:space:]]*\((public\.)?is_branch_manager\(\)[[:space:]]+AND[[:space:]]+(public\.)?get_branch_id\(\)[[:space:]]*=[[:space:]]*p_branch_id\)[[:space:]]+THEN',
        'IF NOT public.can_permission(''settings.manage'') OR NOT public.user_may_access_branch(p_branch_id) THEN', 'gi');
    END IF;

    IF n IS DISTINCT FROM d THEN EXECUTE n; END IF;
  END LOOP;
END;
$$;

-- Branch assignment is controlled by the explicit capability; organization
-- membership only limits scope and never grants the capability itself.
CREATE OR REPLACE FUNCTION public.assign_user_to_branch(p_user_id uuid, p_branch_id uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp
AS $$
BEGIN
  IF auth.uid() IS NULL OR NOT public.can_permission('users.branches.manage') THEN
    RETURN jsonb_build_object('success', false, 'error', 'PERMISSION_DENIED');
  END IF;
  IF NOT public.user_may_access_branch(p_branch_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.branches WHERE id=p_branch_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'BRANCH_NOT_FOUND');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE id=p_user_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'USER_NOT_FOUND');
  END IF;
  INSERT INTO public.user_branch_access(user_id,branch_id)
  VALUES(p_user_id,p_branch_id) ON CONFLICT(user_id,branch_id) DO NOTHING;
  PERFORM public.log_audit_action(p_branch_id,'assign_branch','user_branch_access',NULL::uuid,
    jsonb_build_object('user_id',p_user_id,'branch_id',p_branch_id));
  RETURN jsonb_build_object('success', true);
END;
$$;

CREATE OR REPLACE FUNCTION public.remove_user_from_branch(p_user_id uuid, p_branch_id uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp
AS $$
BEGIN
  IF auth.uid() IS NULL OR NOT public.can_permission('users.branches.manage') THEN
    RETURN jsonb_build_object('success', false, 'error', 'PERMISSION_DENIED');
  END IF;
  IF NOT public.user_may_access_branch(p_branch_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
  END IF;
  IF (SELECT count(*) FROM public.user_branch_access WHERE user_id=p_user_id) <= 1 THEN
    RETURN jsonb_build_object('success', false, 'error', 'LAST_BRANCH');
  END IF;
  DELETE FROM public.user_branch_access WHERE user_id=p_user_id AND branch_id=p_branch_id;
  PERFORM public.log_audit_action(p_branch_id,'remove_branch','user_branch_access',NULL::uuid,
    jsonb_build_object('user_id',p_user_id,'branch_id',p_branch_id));
  RETURN jsonb_build_object('success', true);
END;
$$;

-- User/role mutation guards use capabilities; role labels never grant access.
CREATE OR REPLACE FUNCTION public.guard_role_permissions()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp
AS $$
BEGIN
  IF public.is_pos_admin() THEN RETURN NEW; END IF;
  IF NOT public.can_permission('roles.permissions.manage') THEN
    RAISE EXCEPTION 'PERMISSION_DENIED:roles.permissions.manage';
  END IF;
  IF NEW.branch_id IS NULL OR NEW.scope='global' OR NOT public.user_may_access_branch(NEW.branch_id) THEN
    RAISE EXCEPTION 'PERMISSION_DENIED: role outside caller branch scope';
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.guard_user_role_changes()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp
AS $$
DECLARE
  v_bypass boolean := COALESCE(current_setting('app.login_guard_bypass',true),'')='on';
  v_register boolean := COALESCE(current_setting('app.register_branch',true),'')='on';
BEGIN
  IF v_register THEN RETURN NEW; END IF;
  IF NOT EXISTS(SELECT 1 FROM public.roles WHERE role=NEW.role AND is_active=true) THEN
    RAISE EXCEPTION 'UNKNOWN_ROLE';
  END IF;
  IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.users WHERE id=auth.uid() AND is_active=true) THEN
    RAISE EXCEPTION 'PERMISSION_DENIED';
  END IF;
  IF TG_OP='INSERT' AND NOT public.can_permission('users.create') THEN
    RAISE EXCEPTION 'PERMISSION_DENIED:users.create';
  ELSIF TG_OP='UPDATE' AND NOT public.can_permission('users.manage') THEN
    RAISE EXCEPTION 'PERMISSION_DENIED:users.manage';
  END IF;
  IF NEW.role='super_admin' AND NOT public.is_pos_admin() THEN
    RAISE EXCEPTION 'PERMISSION_DENIED: only Super Admin can assign super_admin';
  END IF;
  IF TG_OP='UPDATE' AND OLD.role='super_admin' AND NOT public.is_pos_admin() THEN
    RAISE EXCEPTION 'PERMISSION_DENIED: only Super Admin can modify super_admin';
  END IF;
  IF NEW.branch_id IS NOT NULL AND NOT public.user_may_access_branch(NEW.branch_id) THEN
    RAISE EXCEPTION 'PERMISSION_DENIED: branch outside caller scope';
  END IF;
  IF TG_OP='UPDATE' AND NEW.id=auth.uid() AND NOT public.is_pos_admin() THEN
    IF NEW.role IS DISTINCT FROM OLD.role OR NEW.branch_id IS DISTINCT FROM OLD.branch_id OR NEW.is_active IS DISTINCT FROM OLD.is_active THEN
      RAISE EXCEPTION 'PERMISSION_DENIED: users cannot change their own role/branch/status';
    END IF;
    IF NOT v_bypass AND (NEW.is_locked IS DISTINCT FROM OLD.is_locked OR NEW.failed_attempts IS DISTINCT FROM OLD.failed_attempts OR NEW.lock_until IS DISTINCT FROM OLD.lock_until) THEN
      RAISE EXCEPTION 'PERMISSION_DENIED: users cannot modify their own lock state';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

-- RLS policies: permissions grant capabilities; memberships/branch checks only
-- define data scope.
DROP POLICY IF EXISTS auth_write_roles ON public.roles;
DROP POLICY IF EXISTS auth_write_roles_upd ON public.roles;
DROP POLICY IF EXISTS auth_write_roles_del ON public.roles;
CREATE POLICY auth_write_roles ON public.roles FOR INSERT TO authenticated
WITH CHECK (public.is_pos_admin() OR (public.can_permission('roles.permissions.manage') AND scope='branch' AND public.user_may_access_branch(branch_id)));
CREATE POLICY auth_write_roles_upd ON public.roles FOR UPDATE TO authenticated
USING (public.is_pos_admin() OR (public.can_permission('roles.permissions.manage') AND scope='branch' AND public.user_may_access_branch(branch_id)))
WITH CHECK (public.is_pos_admin() OR (public.can_permission('roles.permissions.manage') AND scope='branch' AND public.user_may_access_branch(branch_id)));
CREATE POLICY auth_write_roles_del ON public.roles FOR DELETE TO authenticated
USING (public.is_pos_admin() OR (public.can_permission('roles.permissions.manage') AND scope='branch' AND public.user_may_access_branch(branch_id)));

DROP POLICY IF EXISTS organization_members_insert ON public.organization_members;
CREATE POLICY organization_members_insert ON public.organization_members FOR INSERT TO authenticated
WITH CHECK (
  public.is_pos_admin() OR (
    public.can_permission('users.branches.manage') AND EXISTS(
      SELECT 1 FROM public.organization_members m
      WHERE m.organization_id=organization_members.organization_id AND m.user_id=auth.uid() AND m.is_active=true
    )
  )
);

DROP POLICY IF EXISTS organizations_update ON public.organizations;
CREATE POLICY organizations_update ON public.organizations FOR UPDATE TO authenticated
USING (
  public.is_pos_admin() OR (
    public.can_permission('settings.manage') AND EXISTS(
      SELECT 1 FROM public.organization_members m
      WHERE m.organization_id=organizations.id AND m.user_id=auth.uid() AND m.is_active=true
    )
  )
)
WITH CHECK (
  public.is_pos_admin() OR (
    public.can_permission('settings.manage') AND EXISTS(
      SELECT 1 FROM public.organization_members m
      WHERE m.organization_id=organizations.id AND m.user_id=auth.uid() AND m.is_active=true
    )
  )
);

DROP POLICY IF EXISTS auth_org_admin_manage_user_branch_access ON public.user_branch_access;
CREATE POLICY auth_permission_manage_user_branch_access ON public.user_branch_access FOR ALL TO authenticated
USING (
  public.is_pos_admin() OR (
    public.can_permission('users.branches.manage') AND EXISTS(
      SELECT 1 FROM public.branches b
      JOIN public.organization_members m ON m.organization_id=b.organization_id
      WHERE b.id=user_branch_access.branch_id AND m.user_id=auth.uid() AND m.is_active=true
    )
  )
)
WITH CHECK (
  public.is_pos_admin() OR (
    public.can_permission('users.branches.manage') AND EXISTS(
      SELECT 1 FROM public.branches b
      JOIN public.organization_members m ON m.organization_id=b.organization_id
      WHERE b.id=user_branch_access.branch_id AND m.user_id=auth.uid() AND m.is_active=true
    )
  )
);

DROP POLICY IF EXISTS user_kitchen_station_select ON public.user_kitchen_station_assignments;
CREATE POLICY user_kitchen_station_select ON public.user_kitchen_station_assignments FOR SELECT TO authenticated
USING (user_id=auth.uid() OR (public.can_permission('settings.manage') AND public.user_may_access_branch(branch_id)));

-- is_branch_manager represented authorization by a label and must disappear.
DROP FUNCTION IF EXISTS public.is_branch_manager();

-- Fail closed inside the migration. Displaying a role label is allowed; only
-- role comparisons/gates are forbidden. Exact legacy permission literals are
-- checked separately to avoid matching canonical descendants.
DO $$
DECLARE v_count integer; v_objects text; v_policies text;
BEGIN
  SELECT count(*) INTO v_count FROM public.users WHERE role='owner';
  IF v_count<>0 THEN RAISE EXCEPTION 'PERMISSION_FIRST_DRIFT: owner users remain (%)',v_count; END IF;
  SELECT count(*) INTO v_count FROM public.roles WHERE role='owner';
  IF v_count<>0 THEN RAISE EXCEPTION 'PERMISSION_FIRST_DRIFT: owner role remains'; END IF;
  SELECT count(*) INTO v_count FROM public.organization_members WHERE membership_role='owner';
  IF v_count<>0 THEN RAISE EXCEPTION 'PERMISSION_FIRST_DRIFT: owner membership remains (%)',v_count; END IF;
  IF to_regprocedure('public.is_branch_manager()') IS NOT NULL THEN
    RAISE EXCEPTION 'PERMISSION_FIRST_DRIFT: is_branch_manager still exists';
  END IF;

  SELECT count(*) INTO v_count
  FROM public.roles r CROSS JOIN LATERAL jsonb_array_elements_text(COALESCE(r.permissions,'[]'::jsonb)) x(permission)
  WHERE x.permission=ANY(ARRAY['pos.sell','pos.pay','pos.split_order','pos.transfer_order','products.manage','inventory.manage','inventory.transfers','inventory.transfers.approve','catalog.view','procurement.view','accounting.view','admin.view']);
  IF v_count<>0 THEN RAISE EXCEPTION 'PERMISSION_FIRST_DRIFT: legacy role permissions remain (%)',v_count; END IF;

  SELECT string_agg(p.oid::regprocedure::text, ', ' ORDER BY p.oid::regprocedure::text) INTO v_objects
  FROM pg_proc p JOIN pg_namespace ns ON ns.oid=p.pronamespace
  WHERE ns.nspname='public' AND p.prokind='f'
    AND p.proname NOT IN ('is_pos_admin','guard_user_role_changes')
    AND (
      pg_get_functiondef(p.oid) ~ '''(pos\.sell|pos\.pay|pos\.split_order|pos\.transfer_order|products\.manage|inventory\.manage|inventory\.transfers|inventory\.transfers\.approve)'''
      OR pg_get_functiondef(p.oid) ~ 'get_user_role\(\)[[:space:]]*(=|<>|IN[[:space:]]*\(|NOT[[:space:]]+IN[[:space:]]*\()'
      OR pg_get_functiondef(p.oid) ~ 'v_role[[:space:]]*(=|<>|IN[[:space:]]*\(|NOT[[:space:]]+IN[[:space:]]*\()[^;\n]*(owner|branch_manager|accountant|warehouse_manager|cashier)'
      OR pg_get_functiondef(p.oid) ~ '(u\.role|users\.role|NEW\.role|OLD\.role)[[:space:]]*(=|<>|IN[[:space:]]*\(|NOT[[:space:]]+IN[[:space:]]*\()[^;\n]*(owner|branch_manager|accountant|warehouse_manager|cashier)'
      OR pg_get_functiondef(p.oid) ~ 'membership_role[[:space:]]*(=|<>|IN[[:space:]]*\(|NOT[[:space:]]+IN[[:space:]]*\()[^;\n]*owner'
    );
  IF v_objects IS NOT NULL THEN RAISE EXCEPTION 'PERMISSION_FIRST_DRIFT: runtime authorization remains: %',v_objects; END IF;

  SELECT string_agg(tablename||':'||policyname, ', ' ORDER BY tablename,policyname) INTO v_policies
  FROM pg_policies
  WHERE schemaname='public' AND (
    COALESCE(qual,'') ~ '(is_branch_manager|membership_role[^)]*owner|role[^)]*(owner|branch_manager|accountant|warehouse_manager|cashier)|products\.manage|inventory\.manage|pos\.sell|pos\.pay)'
    OR COALESCE(with_check,'') ~ '(is_branch_manager|membership_role[^)]*owner|role[^)]*(owner|branch_manager|accountant|warehouse_manager|cashier)|products\.manage|inventory\.manage|pos\.sell|pos\.pay)'
  );
  IF v_policies IS NOT NULL THEN RAISE EXCEPTION 'PERMISSION_FIRST_DRIFT: RLS authorization remains: %',v_policies; END IF;
END;
$$;
