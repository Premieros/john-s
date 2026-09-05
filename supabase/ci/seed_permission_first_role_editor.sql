-- CI-only permission fixture for role-management integration coverage.
-- Never applied to Production. The integration suite later grants settings.manage
-- inside its rollback-only transaction, so the branch manager can prove that a
-- role editor may delegate only capabilities it actually owns.
UPDATE public.roles
SET permissions = permissions || '["roles.permissions.manage"]'::jsonb
WHERE role = 'branch_manager'
  AND NOT COALESCE(permissions, '[]'::jsonb) ? 'roles.permissions.manage';
