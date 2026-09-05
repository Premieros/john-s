# PR #18 Permission-First Closure Log

> Mandatory execution log for `fix/permission-first-root-drift-v2`.
> Repository: `Premieros/johna-s`.
> Locked Supabase project ref: `azzdesuowpdcoflmyezn` only.

## 2026-09-05 — P0 closure pass

### Baseline
- PR: `#18` — `refactor: enforce permission-first authorization at the root`.
- Initial verified head for this pass: `918749d0d7f6bb19c60fa182766c151383989ca0`.
- Verify run `33972141884` / `#696`.
- Frontend API contract ✅
- Lint ✅
- TypeScript app/tests ✅
- Unit ✅
- Build ✅
- Fresh DB + canonical migrations ✅
- Schema verification ✅
- Integration / Security / RLS ❌
- Browser Smoke skipped because DB gate failed.

### Actions completed in this pass
1. Added a mandatory closure log and then aligned the shared main deviation log with `main` to avoid an add/add conflict.
2. Added integration-test output capture to PR CI so failing Vitest output is uploaded as `verify-integration-log`.
3. Synchronized the Database Identity Lock into the branch:
   - `.env.example` now pins `SUPABASE_PROJECT_REF=azzdesuowpdcoflmyezn` and the canonical Supabase URL.
   - `scripts/db/verify-database-identity.js` added.
   - `package.json` now runs `verify:db-identity` in verify commands.
   - `verify-main.yml` validates the locked project in frontend, DB and browser jobs.
4. No production database DDL was applied.
5. No RLS or tests were weakened.

### Current blocking items
- Extract exact Integration/Security/RLS failures from the next PR run artifact.
- Repair only the proven regression.
- Synchronize the remaining non-functional `main` files that are still divergent, without overwriting PR logic.
- Full Verify including Browser Smoke must be green before merge.

### Authorization invariants
- Super Admin only = implicit bypass.
- Every other role = label only.
- Effective authorization = canonical permissions from `roles.permissions` + branch/RLS scope.
- Legacy permission aliases must not return.

### Status
`IN_PROGRESS`.
