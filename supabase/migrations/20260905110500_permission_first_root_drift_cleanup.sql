-- Permission-First root base.
-- Roles are labels only. Super Admin is the only implicit bypass.
-- Retire the historical `owner` role completely. Existing owner users are
-- relabelled to `manager`; their authorization remains the explicit role
-- permission set, normalized from legacy permission keys below.

-- Preserve explicitly selected legacy grants by translating them to their
-- canonical capabilities before deleting the aliases. This is permission-key
-- migration only; no grants are inferred from a role name.
UPDATE public.roles SET permissions = permissions || '["pos.order.create"]'::jsonb
WHERE COALESCE(permissions,'[]'::jsonb) ? 'pos.sell' AND NOT COALESCE(permissions,'[]'::jsonb) ? 'pos.order.create';
UPDATE public.roles SET permissions = permissions || '["pos.payment.take"]'::jsonb
WHERE COALESCE(permissions,'[]'::jsonb) ? 'pos.pay' AND NOT COALESCE(permissions,'[]'::jsonb) ? 'pos.payment.take';
UPDATE public.roles SET permissions = permissions || '["pos.order.split"]'::jsonb
WHERE COALESCE(permissions,'[]'::jsonb) ? 'pos.split_order' AND NOT COALESCE(permissions,'[]'::jsonb) ? 'pos.order.split';
UPDATE public.roles SET permissions = permissions || '["pos.order.transfer"]'::jsonb
WHERE COALESCE(permissions,'[]'::jsonb) ? 'pos.transfer_order' AND NOT COALESCE(permissions,'[]'::jsonb) ? 'pos.order.transfer';
UPDATE public.roles SET permissions = permissions || '["products.modifiers.manage"]'::jsonb
WHERE COALESCE(permissions,'[]'::jsonb) ? 'products.manage' AND NOT COALESCE(permissions,'[]'::jsonb) ? 'products.modifiers.manage';
UPDATE public.roles SET permissions = permissions || '["inventory.adjust","inventory.count.create","inventory.count.approve"]'::jsonb
WHERE COALESCE(permissions,'[]'::jsonb) ? 'inventory.manage';
UPDATE public.roles SET permissions = permissions || '["inventory.transfer.create"]'::jsonb
WHERE COALESCE(permissions,'[]'::jsonb) ? 'inventory.transfers' AND NOT COALESCE(permissions,'[]'::jsonb) ? 'inventory.transfer.create';
UPDATE public.roles SET permissions = permissions || '["inventory.transfer.approve"]'::jsonb
WHERE COALESCE(permissions,'[]'::jsonb) ? 'inventory.transfers.approve' AND NOT COALESCE(permissions,'[]'::jsonb) ? 'inventory.transfer.approve';

-- Collapse duplicate JSON-array values that may result from broad legacy grants.
UPDATE public.roles r
SET permissions = (
  SELECT COALESCE(jsonb_agg(v ORDER BY v), '[]'::jsonb)
  FROM (SELECT DISTINCT value AS v FROM jsonb_array_elements_text(COALESCE(r.permissions,'[]'::jsonb))) s
);

-- Create the neutral replacement label with the owner's explicit permission
-- set, then move users/memberships and delete owner. No implicit privileges are
-- attached to manager.
INSERT INTO public.roles (role, name_ar, name_en, permissions, scope, branch_id, is_active)
SELECT 'manager', 'مدير', 'Manager', permissions, scope, branch_id, is_active
FROM public.roles
WHERE role='owner'
ON CONFLICT (role) DO NOTHING;

UPDATE public.users SET role='manager' WHERE role='owner';
UPDATE public.organization_members SET membership_role='admin' WHERE membership_role='owner';
DELETE FROM public.roles WHERE role='owner';

-- Legacy aliases are not authorization capabilities after normalization.
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
