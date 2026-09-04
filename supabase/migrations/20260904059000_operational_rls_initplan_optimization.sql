-- Preserve RLS semantics while evaluating auth.uid() once per statement.
ALTER POLICY approval_requests_insert ON public.approval_requests
  WITH CHECK ((requester_id = (SELECT auth.uid())) AND user_may_access_branch(branch_id));

ALTER POLICY approval_requests_select ON public.approval_requests
  USING ((requester_id = (SELECT auth.uid())) OR (user_may_access_branch(branch_id) AND (is_pos_admin() OR can_permission('approvals.review'::text))));

ALTER POLICY approval_policies_insert ON public.approval_policies
  WITH CHECK (can_permission('approvals.policy.manage'::text)
    AND (((branch_id IS NULL) AND is_platform_admin()) OR user_may_access_branch(branch_id))
    AND (created_by = (SELECT auth.uid())));

ALTER POLICY auth_insert_users ON public.users
  WITH CHECK (is_platform_admin() OR ((id = (SELECT auth.uid())) AND user_may_access_branch(branch_id)));

ALTER POLICY auth_select_users ON public.users
  USING ((id = (SELECT auth.uid())) OR is_platform_admin() OR (can_permission('users.view'::text) AND user_may_access_branch(branch_id)));

ALTER POLICY auth_update_users ON public.users
  USING ((id = (SELECT auth.uid())) OR is_platform_admin() OR (can_permission('users.manage'::text) AND user_may_access_branch(branch_id)))
  WITH CHECK ((id = (SELECT auth.uid())) OR is_platform_admin() OR (can_permission('users.manage'::text) AND user_may_access_branch(branch_id)));

ALTER POLICY auth_select_own_user_branch_access ON public.user_branch_access
  USING (user_id = (SELECT auth.uid()));

ALTER POLICY auth_org_admin_manage_user_branch_access ON public.user_branch_access
  USING (is_platform_admin() OR (EXISTS (
    SELECT 1 FROM public.branches b
    WHERE b.id = user_branch_access.branch_id
      AND b.organization_id IN (SELECT user_organization_ids())
      AND EXISTS (
        SELECT 1 FROM public.organization_members om
        WHERE om.user_id = (SELECT auth.uid())
          AND om.organization_id = b.organization_id
          AND om.membership_role = ANY (ARRAY['owner'::text,'admin'::text])
          AND om.is_active = true
      )
  )));

ALTER POLICY user_kitchen_station_select ON public.user_kitchen_station_assignments
  USING ((user_id = (SELECT auth.uid())) OR (user_may_access_branch(branch_id) AND EXISTS (
    SELECT 1 FROM public.users u
    WHERE u.id = (SELECT auth.uid())
      AND u.role = ANY (ARRAY['super_admin'::text,'owner'::text,'branch_manager'::text])
  )));

ALTER POLICY ks_manage_by_permission ON public.kitchen_stations
  USING (can_permission('settings.manage'::text) AND EXISTS (
    SELECT 1 FROM public.users u WHERE u.id = (SELECT auth.uid()) AND u.is_active = true
  ))
  WITH CHECK (can_permission('settings.manage'::text) AND EXISTS (
    SELECT 1 FROM public.users u WHERE u.id = (SELECT auth.uid()) AND u.is_active = true
  ));
