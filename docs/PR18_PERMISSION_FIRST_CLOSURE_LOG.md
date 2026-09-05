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
   - `.env.example` pins `SUPABASE_PROJECT_REF=azzdesuowpdcoflmyezn` and the canonical Supabase URL.
   - `scripts/db/verify-database-identity.js` is present.
   - `package.json` runs `verify:db-identity` in verify commands.
   - `verify-main.yml` validates the locked project in frontend, DB and browser jobs.
4. Verified the repository identity again before continuing:
   - repository: `Premieros/johna-s`
   - default branch: `main`
   - current `main` at verification time: `a31dc4293fc4b5b24b5a272de2c6d1466b7a0de5`
5. Verified the live Supabase project again before continuing:
   - project ref: `azzdesuowpdcoflmyezn`
   - project name: `john's`
   - region: `eu-west-1`
   - status: `ACTIVE_HEALTHY`
   - database host: `db.azzdesuowpdcoflmyezn.supabase.co`
6. Root cause found and fixed in the Permission-First migration/tests:
   - `owner` must remain an ordinary role label.
   - removed the attempted `owner -> manager` semantic conversion/deletion behavior.
   - `owner` receives no implicit bypass.
   - effective authority remains `roles.permissions` + branch/RLS scope.
   - regression coverage was added/updated to lock this invariant.
   - relevant commits include `94cbdbc99618ef9ae9bdabc3cb3103f8475fe90e`, `a30bdf599e9e89c6e8824200ec950174ea20b12f`, and `d40cb6f3995c659da261d2f8dd0837ac98e5e048`.
7. PR #18 was refreshed against current `main` metadata without merging; its base now resolves to current `main` for the open PR.
8. No production database DDL was applied.
9. No RLS or tests were weakened.

### Current blocking items
- Run Verify against the current PR head after the owner-label fix.
- If Integration/Security/RLS still fails, use the new uploaded `verify-integration-log` and repair only the proven regression.
- Full Verify including Browser Smoke must be green before merge.

### Authorization invariants
- Super Admin only = implicit bypass.
- Every other role, including `owner`, = label only.
- Effective authorization = canonical permissions from `roles.permissions` + branch/RLS scope.
- Legacy permission aliases must not return.

### Status
`IN_PROGRESS — ROOT CAUSE FIXED, CURRENT-HEAD VERIFY REQUIRED`.
