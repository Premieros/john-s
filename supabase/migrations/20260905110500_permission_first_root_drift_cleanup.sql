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

UPDATE public.roles r
SET permissions = (
  SELECT COALESCE(jsonb_agg(v ORDER BY v), '[]'::jsonb)
  FROM (SELECT DISTINCT value AS v FROM jsonb_array_elements_text(COALESCE(r.permissions,'[]'::jsonb))) s
);

-- Create/merge the neutral replacement label with the owner's explicit grants.
INSERT INTO public.roles (role, name_ar, name_en, permissions, scope, branch_id, is_active)
SELECT 'manager', 'مدير', 'Manager', permissions, scope, branch_id, is_active
FROM public.roles
WHERE role='owner'
ON CONFLICT (role) DO UPDATE
SET permissions = (
  SELECT COALESCE(jsonb_agg(v ORDER BY v), '[]'::jsonb)
  FROM (
    SELECT DISTINCT value AS v
    FROM jsonb_array_elements_text(COALESCE(public.roles.permissions,'[]'::jsonb) || COALESCE(EXCLUDED.permissions,'[]'::jsonb))
  ) merged
), is_active=true;

UPDATE public.users SET role='manager' WHERE role='owner';
UPDATE public.organization_members SET membership_role='admin' WHERE membership_role='owner';
DELETE FROM public.roles WHERE role='owner';

-- Old clients cannot recreate the retired role label.
CREATE OR REPLACE FUNCTION public.normalize_retired_owner_role()
RETURNS trigger LANGUAGE plpgsql SET search_path=public,pg_temp AS $$
BEGIN
  IF NEW.role='owner' THEN NEW.role:='manager'; END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trg_00_normalize_retired_owner_role ON public.users;
CREATE TRIGGER trg_00_normalize_retired_owner_role
BEFORE INSERT OR UPDATE OF role ON public.users
FOR EACH ROW EXECUTE FUNCTION public.normalize_retired_owner_role();

-- Normalize future role-permission writes at the database boundary as well.
-- This prevents legacy clients/imports from reintroducing aliases.
CREATE OR REPLACE FUNCTION public.normalize_legacy_role_permissions()
RETURNS trigger LANGUAGE plpgsql SET search_path=public,pg_temp AS $$
DECLARE p jsonb := COALESCE(NEW.permissions,'[]'::jsonb);
BEGIN
  IF p ? 'pos.sell' THEN p:=p||'["pos.order.create"]'::jsonb; END IF;
  IF p ? 'pos.pay' THEN p:=p||'["pos.payment.take"]'::jsonb; END IF;
  IF p ? 'pos.split_order' THEN p:=p||'["pos.order.split"]'::jsonb; END IF;
  IF p ? 'pos.transfer_order' THEN p:=p||'["pos.order.transfer"]'::jsonb; END IF;
  IF p ? 'products.manage' THEN p:=p||'["products.modifiers.manage"]'::jsonb; END IF;
  IF p ? 'inventory.manage' THEN p:=p||'["inventory.adjust","inventory.count.create","inventory.count.approve"]'::jsonb; END IF;
  IF p ? 'inventory.transfers' THEN p:=p||'["inventory.transfer.create"]'::jsonb; END IF;
  IF p ? 'inventory.transfers.approve' THEN p:=p||'["inventory.transfer.approve"]'::jsonb; END IF;
  p:=p-'pos.sell'-'pos.pay'-'pos.split_order'-'pos.transfer_order'
       -'products.manage'-'inventory.manage'-'inventory.transfers'-'inventory.transfers.approve'
       -'catalog.view'-'procurement.view'-'accounting.view'-'admin.view';
  SELECT COALESCE(jsonb_agg(v ORDER BY v),'[]'::jsonb) INTO NEW.permissions
  FROM (SELECT DISTINCT value AS v FROM jsonb_array_elements_text(p)) d;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trg_00_normalize_legacy_role_permissions ON public.roles;
CREATE TRIGGER trg_00_normalize_legacy_role_permissions
BEFORE INSERT OR UPDATE OF permissions ON public.roles
FOR EACH ROW EXECUTE FUNCTION public.normalize_legacy_role_permissions();

-- Normalize existing arrays after installing the write boundary.
UPDATE public.roles SET permissions=permissions;

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
