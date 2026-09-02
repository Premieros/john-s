-- Hard-delete a branch and every public row directly linked to it.
-- Branch deletion is an explicit destructive admin operation; do not use for soft disable.

DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT tc.table_schema, tc.table_name, tc.constraint_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
      ON tc.constraint_name = kcu.constraint_name
     AND tc.constraint_schema = kcu.constraint_schema
    JOIN information_schema.referential_constraints rc
      ON rc.constraint_name = tc.constraint_name
     AND rc.constraint_schema = tc.constraint_schema
    JOIN information_schema.constraint_column_usage ccu
      ON ccu.constraint_name = tc.constraint_name
     AND ccu.constraint_schema = tc.constraint_schema
    WHERE tc.constraint_type = 'FOREIGN KEY'
      AND tc.table_schema = 'public'
      AND ccu.table_schema = 'public'
      AND ccu.table_name = 'branches'
      AND kcu.column_name = 'branch_id'
      AND rc.delete_rule <> 'CASCADE'
  LOOP
    EXECUTE format('ALTER TABLE %I.%I DROP CONSTRAINT %I', r.table_schema, r.table_name, r.constraint_name);
    EXECUTE format(
      'ALTER TABLE %I.%I ADD CONSTRAINT %I FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE',
      r.table_schema, r.table_name, r.constraint_name
    );
  END LOOP;
END $$;

CREATE OR REPLACE FUNCTION public.delete_branch_cascade(p_branch_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_role text;
  v_user_branch uuid;
  v_org uuid;
BEGIN
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'AUTH_REQUIRED');
  END IF;

  SELECT role, branch_id
    INTO v_role, v_user_branch
  FROM public.users
  WHERE id = v_uid AND is_active = true;

  IF v_role IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'USER_NOT_FOUND');
  END IF;

  IF v_role NOT IN ('super_admin', 'owner') THEN
    RETURN jsonb_build_object('success', false, 'error', 'PERMISSION_DENIED');
  END IF;

  SELECT organization_id INTO v_org
  FROM public.branches
  WHERE id = p_branch_id
  FOR UPDATE;

  IF v_org IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'BRANCH_NOT_FOUND');
  END IF;

  IF v_role = 'owner' THEN
    IF NOT public.user_may_access_branch(p_branch_id) THEN
      RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
    END IF;
    IF v_user_branch IS NOT DISTINCT FROM p_branch_id THEN
      RETURN jsonb_build_object('success', false, 'error', 'CANNOT_DELETE_CURRENT_BRANCH');
    END IF;
  END IF;

  DELETE FROM public.branches WHERE id = p_branch_id;

  RETURN jsonb_build_object('success', true, 'branch_id', p_branch_id, 'organization_id', v_org);
EXCEPTION WHEN foreign_key_violation THEN
  RETURN jsonb_build_object('success', false, 'error', 'BRANCH_DELETE_BLOCKED', 'detail', SQLERRM);
WHEN OTHERS THEN
  RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
END;
$$;

REVOKE ALL ON FUNCTION public.delete_branch_cascade(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.delete_branch_cascade(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.delete_branch_cascade(uuid) TO authenticated;
