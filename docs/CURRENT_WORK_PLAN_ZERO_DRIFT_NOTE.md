# Current Zero-Drift Checkpoint

- Branch: `fix/zero-ui-backend-drift`
- Base: current `main` after Production parity/deploy success.
- No Supabase Production changes are part of this branch.
- V2 is converted from a parallel partial implementation into a gateway to the canonical tested workspaces.
- Registry permissions and routes are canonical, approval/waste-only landing is supported, and V2 branch selection shares the global active-branch context.
- Required gate before merge: API contract, lint, full typecheck, unit, build, Fresh DB/schema, integration/security/RLS, Browser Smoke.
