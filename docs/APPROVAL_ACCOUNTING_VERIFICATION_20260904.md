# Approval + accounting verification — 2026-09-04

## POS browser regression
- Root cause: E2E clicked the product configure card while direct add is the `+` action.
- Test helper now targets the actual direct-add button.

## Approval workflow findings
- Existing canonical table: `approval_requests`.
- Existing RPCs: `request_manager_approval`, `decide_manager_approval`, `consume_manager_approval`.
- Existing header `ApprovalInbox` was stale: it queried `action_type/requester_id` and called an obsolete decision signature.
- Added branch-scoped `approval_action_catalog` + `approval_policies`.
- Policies support require/not-require, assigned approver, optional threshold, and self-approval prevention.
- Approval center exposes pending requests, policy assignment, decisions, and history.

## Financial/reporting verification (Production, read-only)
- Journal entries checked: 10.
- Unbalanced journal entries: 0.
- Active branch trial balances are balanced.
- Smoha trial balance: debit 102,213 / credit 102,213.
- Smoha balance sheet: assets 100,011 / liabilities 0 / equity 100,011 / balanced=true.
- Cleopatra trial balance and balance sheet: balanced=true.
- Financial report RPCs are SECURITY INVOKER (`prosecdef=false`), so table RLS remains in force; no SECURITY DEFINER branch bypass was found in these reporting RPCs.

No accounting formula was changed because no numeric inconsistency was proven in this verification pass.
