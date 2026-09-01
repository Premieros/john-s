from pathlib import Path

p = Path('src/features/trade/pages/SalesPage.tsx')
s = p.read_text()

marker = "import { useLanguage } from '@/context/LanguageContext';\n"
if "useAuth" not in s:
    if marker not in s:
        raise SystemExit('language import marker missing')
    s = s.replace(marker, marker + "import { useAuth } from '@/context/AuthContext';\n", 1)

marker = "  const { show } = useToast();\n  const branchFilter = useBranchFilter();"
if "const { user } = useAuth();" not in s:
    if marker not in s:
        raise SystemExit('component auth marker missing')
    s = s.replace(marker, "  const { show } = useToast();\n  const { user } = useAuth();\n  const branchFilter = useBranchFilter();", 1)

marker = "  const isAr = lang === 'ar';\n"
if "canRequestRefundApproval" not in s:
    if marker not in s:
        raise SystemExit('isAr marker missing')
    s = s.replace(marker, marker + "  const canRequestRefundApproval = user?.role === 'cashier';\n  const canOpenRefund = can('refunds.approve') || canRequestRefundApproval;\n", 1)

old = """    if (!result?.success) {
      show(`${isAr ? 'فشل المرتجع' : 'Refund failed'}: ${result?.detail || result?.error || 'unknown'}`, 'error');
      return;
    }
"""
new = """    if (!result?.success) {
      if (result?.error === 'APPROVAL_REQUIRED' && canRequestRefundApproval) {
        const { data: approvalData, error: approvalError } = await supabase.rpc('request_approval', {
          p_branch_id: refundSale.branch_id,
          p_action_type: 'refund',
          p_target_type: 'sale',
          p_target_id: refundSale.id,
          p_payload: {
            items: p_items,
            reason: refundReason.trim() || null,
            refund_total: refundTotal(),
            invoice_number: refundSale.invoice_number,
          },
          p_reason: refundReason.trim() || (isAr ? 'طلب مرتجع من الكاشير' : 'Cashier refund request'),
          p_expires_in_seconds: 600,
        });
        if (approvalError) {
          show(approvalError.message, 'error');
          return;
        }
        const approvalResult = approvalData as { success?: boolean; error?: string; request_id?: string } | null;
        if (!approvalResult?.success) {
          show(approvalResult?.error || (isAr ? 'تعذر إرسال طلب الموافقة' : 'Could not request approval'), 'error');
          return;
        }
        show(isAr ? 'تم إرسال طلب المرتجع للمدير. بعد الموافقة اضغط تنفيذ المرتجع مرة أخرى.' : 'Refund approval requested. After manager approval, submit the refund again.', 'success');
        return;
      }
      show(`${isAr ? 'فشل المرتجع' : 'Refund failed'}: ${result?.detail || result?.error || 'unknown'}`, 'error');
      return;
    }
"""
if "p_action_type: 'refund'" not in s:
    if old not in s:
        raise SystemExit('refund failure block missing')
    s = s.replace(old, new, 1)

old_button = "{can('refunds.approve') && r.status !== 'returned' && (r.refunded_amount || 0) < r.total && ("
if old_button in s:
    s = s.replace(old_button, "{canOpenRefund && r.status !== 'returned' && (r.refunded_amount || 0) < r.total && (", 1)

p.write_text(s)
