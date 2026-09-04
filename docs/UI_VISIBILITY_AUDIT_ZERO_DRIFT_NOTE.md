# UI Visibility — Zero Drift Addendum

This addendum supersedes stale V2 visibility assumptions in older audit notes.

- Send to Kitchen deducts inventory on the positive unsent delta; payment does not deduct that inventory again.
- V2 no longer exposes a partial POS or shift implementation as a production workspace.
- All V2 gateway cards open canonical production routes protected by the same view permission recorded in the registry.
- Approval Center visibility uses `approvals.review`, not `settings.manage`.
- Waste Center visibility uses `waste.view` and Production/Fresh DB RLS enforce the same permission.
