-- Final audit: internal inventory mutators are service-only; client-facing
-- branch readers must enforce branch access even under SECURITY DEFINER.

REVOKE EXECUTE ON FUNCTION public.deduct_raw_material_inventory(uuid,numeric,uuid,uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.deduct_raw_material_inventory(uuid,numeric,uuid,uuid) TO service_role;

REVOKE EXECUTE ON FUNCTION public.deduct_sale_unit_inventory(uuid,uuid,jsonb,uuid,text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.deduct_sale_unit_inventory(uuid,uuid,jsonb,uuid,text) TO service_role;

REVOKE EXECUTE ON FUNCTION public.log_audit_action(uuid,text,text,uuid,jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.log_audit_action(uuid,text,text,uuid,jsonb) TO service_role;

REVOKE EXECUTE ON FUNCTION public.system_integrity_audit() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.system_integrity_audit() TO service_role;

REVOKE EXECUTE ON FUNCTION public.check_product_availability(uuid,uuid,uuid,numeric) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.check_product_availability(uuid,uuid,uuid,numeric) TO service_role;

DO $do$
DECLARE v_src text; v_old text; v_new text;
BEGIN
  SELECT pg_get_functiondef(p.oid) INTO v_src
  FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public' AND p.proname='get_pos_product_availability'
    AND pg_get_function_identity_arguments(p.oid)='p_branch_id uuid, p_warehouse_id uuid, p_cap integer';
  IF v_src IS NULL THEN RAISE EXCEPTION 'get_pos_product_availability target not found'; END IF;
  v_old := $old$BEGIN
  FOR v_product IN$old$;
  v_new := $new$BEGIN
  IF auth.uid() IS NOT NULL AND NOT public.user_may_access_branch(p_branch_id) THEN
    RAISE EXCEPTION 'BRANCH_ACCESS_DENIED';
  END IF;
  FOR v_product IN$new$;
  IF position(v_new IN v_src)=0 THEN
    IF position(v_old IN v_src)=0 THEN RAISE EXCEPTION 'get_pos_product_availability entry block changed'; END IF;
    EXECUTE replace(v_src,v_old,v_new);
  END IF;
END $do$;

DO $do$
DECLARE v_src text; v_old text; v_new text;
BEGIN
  SELECT pg_get_functiondef(p.oid) INTO v_src
  FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public' AND p.proname='subscription_status'
    AND pg_get_function_identity_arguments(p.oid)='p_branch_id uuid';
  IF v_src IS NULL THEN RAISE EXCEPTION 'subscription_status target not found'; END IF;
  v_old := $old$BEGIN
 SELECT * INTO r FROM public.branch_subscriptions WHERE branch_id=p_branch_id;$old$;
  v_new := $new$BEGIN
 IF auth.uid() IS NOT NULL AND NOT public.user_may_access_branch(p_branch_id) THEN
   RETURN jsonb_build_object('status','denied','expired',true,'error','BRANCH_ACCESS_DENIED');
 END IF;
 SELECT * INTO r FROM public.branch_subscriptions WHERE branch_id=p_branch_id;$new$;
  IF position(v_new IN v_src)=0 THEN
    IF position(v_old IN v_src)=0 THEN RAISE EXCEPTION 'subscription_status entry block changed'; END IF;
    EXECUTE replace(v_src,v_old,v_new);
  END IF;
END $do$;

DO $do$
DECLARE v_src text; v_old text; v_new text;
BEGIN
  SELECT pg_get_functiondef(p.oid) INTO v_src
  FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public' AND p.proname='get_feature_access'
    AND pg_get_function_identity_arguments(p.oid)='p_feature_key text, p_branch_id uuid';
  IF v_src IS NULL THEN RAISE EXCEPTION 'get_feature_access target not found'; END IF;
  v_old := $old$BEGIN
  IF v_bid IS NULL THEN$old$;
  v_new := $new$BEGIN
  IF v_bid IS NOT NULL AND auth.uid() IS NOT NULL AND NOT public.user_may_access_branch(v_bid) THEN
    RETURN jsonb_build_object('allowed',false,'feature_key',p_feature_key,'error','BRANCH_ACCESS_DENIED');
  END IF;
  IF v_bid IS NULL THEN$new$;
  IF position(v_new IN v_src)=0 THEN
    IF position(v_old IN v_src)=0 THEN RAISE EXCEPTION 'get_feature_access entry block changed'; END IF;
    EXECUTE replace(v_src,v_old,v_new);
  END IF;
END $do$;

NOTIFY pgrst, 'reload schema';
