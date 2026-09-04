-- V2 POS permission contract: creating an order and sending it to the kitchen
-- are separate capabilities. Keep branch isolation and delta-send behavior intact.

CREATE OR REPLACE FUNCTION public.send_to_kitchen(p_order_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_order public.orders%ROWTYPE;
  v_item record;
  v_sent numeric;
  v_delta numeric;
  v_items_sent int := 0;
  v_all_sent boolean := true;
  v_uid uuid := auth.uid();
  v_first_sent_at timestamptz;
BEGIN
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'AUTH_REQUIRED');
  END IF;

  SELECT * INTO v_order
  FROM public.orders
  WHERE id = p_order_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'ORDER_NOT_FOUND');
  END IF;

  IF NOT public.user_may_access_branch(v_order.branch_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'BRANCH_DENIED');
  END IF;

  IF NOT (public.is_pos_admin() OR public.can_permission('pos.send_kitchen')) THEN
    RETURN jsonb_build_object('success', false, 'error', 'PERMISSION_DENIED');
  END IF;

  IF v_order.status IN ('completed','cancelled')
     OR COALESCE(v_order.payment_status,'unpaid') = 'void' THEN
    RETURN jsonb_build_object('success', false, 'error', 'ORDER_CLOSED');
  END IF;

  FOR v_item IN
    SELECT oi.id, oi.quantity
    FROM public.order_items oi
    WHERE oi.order_id = p_order_id
    ORDER BY oi.created_at, oi.id
  LOOP
    SELECT COALESCE(oks.sent_quantity,0)
      INTO v_sent
    FROM public.order_kitchen_sends oks
    WHERE oks.order_item_id = v_item.id;

    v_delta := GREATEST(COALESCE(v_item.quantity,0) - COALESCE(v_sent,0), 0);

    IF v_delta > 0 THEN
      INSERT INTO public.order_kitchen_sends(order_id, order_item_id, sent_quantity, sent_at, sent_by)
      VALUES (p_order_id, v_item.id, v_delta, now(), v_uid)
      ON CONFLICT (order_item_id)
      DO UPDATE SET
        sent_quantity = public.order_kitchen_sends.sent_quantity + EXCLUDED.sent_quantity,
        sent_at = EXCLUDED.sent_at,
        sent_by = EXCLUDED.sent_by;

      v_items_sent := v_items_sent + 1;
    END IF;

    SELECT COALESCE(oks.sent_quantity,0)
      INTO v_sent
    FROM public.order_kitchen_sends oks
    WHERE oks.order_item_id = v_item.id;

    IF COALESCE(v_sent,0) < COALESCE(v_item.quantity,0) THEN
      v_all_sent := false;
    END IF;
  END LOOP;

  SELECT MIN(oks.sent_at)
    INTO v_first_sent_at
  FROM public.order_kitchen_sends oks
  WHERE oks.order_id = p_order_id;

  IF v_first_sent_at IS NOT NULL THEN
    UPDATE public.orders
    SET
      kitchen_status = CASE
        WHEN kitchen_status = 'pending' THEN 'sent'
        ELSE kitchen_status
      END,
      kitchen_sent_at = COALESCE(kitchen_sent_at, v_first_sent_at)
    WHERE id = p_order_id;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'items_sent', v_items_sent,
    'all_sent', v_all_sent
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.send_to_kitchen(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.send_to_kitchen(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.send_to_kitchen(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.send_to_kitchen(uuid) TO service_role;
