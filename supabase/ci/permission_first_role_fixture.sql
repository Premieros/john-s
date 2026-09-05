-- CI-only fixture for permission-first authorization tests.
-- This does NOT run on Supabase Production. It makes the branch_manager test
-- principal explicitly permission-bearing, so tests prove capabilities rather
-- than relying on the role label itself.
UPDATE public.roles
SET permissions = COALESCE(permissions, '[]'::jsonb)
  || '["settings.manage","roles.permissions.manage"]'::jsonb
WHERE role = 'branch_manager';
