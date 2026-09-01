from pathlib import Path

p = Path('src/features/trade/pages/SalesPage.tsx')
s = p.read_text()

s = s.replace(
"  const canRequestRefundApproval = user?.role === 'cashier';\n  const canOpenRefund = can('refunds.approve') || canRequestRefundApproval;",
"  const canRequestRefundApproval = user?.role === 'cashier';\n  const canOpenRefund = can('refunds.approve') || canRequestRefundApproval;\n  const canRequestPaymentApproval = user?.role === 'cashier';\n  const canEditSale = can('refunds.approve') || canRequestPaymentApproval;"
)

old = '''  const saveSaleEdit = async () => {\n    if (!viewSale) return;\n    const { error } = await supabase.from('sales').update({\n      customer_id: editForm.customer_id || null,\n      payment_method: editForm.payment_method,\n      status: editForm.status,\n      notes: editForm.notes || null,\n    }).eq('id', viewSale.id);\n    if (error) { show(error.message, 'error'); return; }\n    await logAudit('update', 'sales', viewSale.id);\n    show(t('saveSuccess'), 'success');\n    setViewSale(null);\n    reloadSales();\n  };'''

new = '''  const saveSaleEdit = async () => {\n    if (!viewSale) return;\n\n    const paymentChanged = editForm.payment_method !== viewSale.payment_method;\n    if (paymentChanged) {\n      if (editForm.payment_method === 'credit') {\n        show(isAr ? 'التحويل إلى آجل يحتاج مسار ذمم مدينة مستقل' : 'Changing to credit requires the receivables workflow', 'error');\n        return;\n      }\n\n      const { data, error } = await supabase.rpc('change_sale_payment_method', {\n        p_sale_id: viewSale.id,\n        p_new_method: editForm.payment_method,\n        p_reason: null,\n      });\n      if (error) { show(error.message, 'error'); return; }\n\n      const result = data as { success?: boolean; error?: string; detail?: string } | null;\n      if (!result?.success) {\n        if (result?.error === 'APPROVAL_REQUIRED' && canRequestPaymentApproval) {\n          const { data: approvalData, error: approvalError } = await supabase.rpc('request_manager_approval', {\n            p_action_type: 'change_payment_method',\n            p_entity_type: 'sale',\n            p_entity_id: viewSale.id,\n            p_payload: {\n              old_method: viewSale.payment_method,\n              new_method: editForm.payment_method,\n              invoice_number: viewSale.invoice_number,\n            },\n            p_reason: isAr ? 'طلب تغيير طريقة دفع من الكاشير' : 'Cashier payment-method correction request',\n          });\n          if (approvalError) { show(approvalError.message, 'error'); return; }\n          const approvalResult = approvalData as { success?: boolean; error?: string } | null;\n          if (!approvalResult?.success) {\n            show(approvalResult?.error || (isAr ? 'تعذر إرسال طلب الموافقة' : 'Could not request approval'), 'error');\n            return;\n          }\n          show(isAr ? 'تم إرسال طلب تغيير طريقة الدفع للمدير. بعد الموافقة اضغط حفظ مرة أخرى.' : 'Payment change approval requested. After approval, save again.', 'success');\n          return;\n        }\n        show(result?.detail || result?.error || (isAr ? 'فشل تغيير طريقة الدفع' : 'Payment change failed'), 'error');\n        return;\n      }\n    }\n\n    if (user?.role !== 'cashier') {\n      const { error } = await supabase.from('sales').update({\n        customer_id: editForm.customer_id || null,\n        status: editForm.status,\n        notes: editForm.notes || null,\n      }).eq('id', viewSale.id);\n      if (error) { show(error.message, 'error'); return; }\n    }\n\n    await logAudit('update', 'sales', viewSale.id, paymentChanged ? { payment_method: editForm.payment_method } : undefined);\n    show(t('saveSuccess'), 'success');\n    setViewSale(null);\n    reloadSales();\n  };'''

if old not in s:
    raise SystemExit('saveSaleEdit marker not found')
s = s.replace(old, new, 1)

s = s.replace("        {can('refunds.approve') && (\n          <button onClick={() => openViewSale(r)}", "        {canEditSale && (\n          <button onClick={() => openViewSale(r)}", 1)

s = s.replace(
"              <Select label={t('customer')} value={editForm.customer_id} onChange={(e) => setEditForm({ ...editForm, customer_id: e.target.value })}>",
"              <Select label={t('customer')} value={editForm.customer_id} disabled={user?.role === 'cashier'} onChange={(e) => setEditForm({ ...editForm, customer_id: e.target.value })}>"
)
s = s.replace(
"              <Select label={t('status')} value={editForm.status} onChange={(e) => setEditForm({ ...editForm, status: e.target.value })}>",
"              <Select label={t('status')} value={editForm.status} disabled={user?.role === 'cashier'} onChange={(e) => setEditForm({ ...editForm, status: e.target.value })}>"
)
s = s.replace(
"            <Textarea label={t('notes')} value={editForm.notes} onChange={(e) => setEditForm({ ...editForm, notes: e.target.value })} rows={2} />",
"            <Textarea label={t('notes')} value={editForm.notes} disabled={user?.role === 'cashier'} onChange={(e) => setEditForm({ ...editForm, notes: e.target.value })} rows={2} />"
)
s = s.replace(
"                <option value=\"credit\">{t('credit')}</option>",
"                <option value=\"credit\" disabled>{t('credit')}</option>"
)

required = [
    "change_sale_payment_method",
    "p_action_type: 'change_payment_method'",
    "canEditSale",
    "disabled={user?.role === 'cashier'}",
]
for marker in required:
    if marker not in s:
        raise SystemExit(f'missing expected marker: {marker}')

p.write_text(s)
