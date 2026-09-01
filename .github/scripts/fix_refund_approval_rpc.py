from pathlib import Path

p = Path('src/features/trade/pages/SalesPage.tsx')
s = p.read_text()
s = s.replace("supabase.rpc('request_approval', {", "supabase.rpc('request_manager_approval', {", 1)
s = s.replace("          p_branch_id: refundSale.branch_id,\n", "", 1)
s = s.replace("          p_target_type: 'sale',", "          p_entity_type: 'sale',", 1)
s = s.replace("          p_target_id: refundSale.id,", "          p_entity_id: refundSale.id,", 1)
s = s.replace("          p_expires_in_seconds: 600,\n", "", 1)
if "request_manager_approval" not in s or "p_entity_type: 'sale'" not in s or "p_entity_id: refundSale.id" not in s:
    raise SystemExit('refund approval RPC patch failed')
if "request_approval" in s or "p_target_type: 'sale'" in s or "p_target_id: refundSale.id" in s:
    raise SystemExit('legacy refund approval RPC markers remain')
p.write_text(s)
