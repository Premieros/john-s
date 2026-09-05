-- Permission-First root base.
-- Roles are labels only. Super Admin is the only implicit bypass.
-- `owner` remains a valid tenant role label; it has no implicit authorization.

-- Legacy aliases are not authorization capabilities. Do not infer new grants
-- from an old role or permission name.
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
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT public.is_pos_admin() OR EXISTS (
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
