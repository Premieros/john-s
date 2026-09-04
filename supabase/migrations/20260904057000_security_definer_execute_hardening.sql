-- Harden SECURITY DEFINER execution without changing authenticated application RPC behavior.

-- Internal trigger functions must never be callable directly from API roles.
REVOKE EXECUTE ON FUNCTION public._price_order_item_modifiers() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.delete_unposted_purchase_on_cancel() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.sync_kitchen_sent_quantity_after_void() FROM PUBLIC, anon, authenticated;

-- send_to_kitchen is an authenticated operational RPC only.
REVOKE EXECUTE ON FUNCTION public.send_to_kitchen(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.send_to_kitchen(uuid) TO authenticated, service_role;

-- Pre-auth login helpers intentionally remain available to anon.
REVOKE EXECUTE ON FUNCTION public.get_login_email(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_login_email(text) TO anon, authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.record_login_failure(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.record_login_failure(text) TO anon, authenticated, service_role;

-- These tables were already deny-by-default because RLS was enabled with no policies.
-- Make that intent explicit for API roles without changing service/postgres access.
DROP POLICY IF EXISTS sale_payments_api_deny_all ON public.sale_payments;
CREATE POLICY sale_payments_api_deny_all
ON public.sale_payments
AS RESTRICTIVE
FOR ALL
TO anon, authenticated
USING (false)
WITH CHECK (false);

DROP POLICY IF EXISTS schema_migrations_api_deny_all ON public.schema_migrations;
CREATE POLICY schema_migrations_api_deny_all
ON public.schema_migrations
AS RESTRICTIVE
FOR ALL
TO anon, authenticated
USING (false)
WITH CHECK (false);
