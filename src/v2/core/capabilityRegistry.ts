import type { Permission } from '@/lib/permissions';

export type V2ModuleKey =
  | 'pos'
  | 'shifts'
  | 'approvals'
  | 'waste'
  | 'inventory'
  | 'catalog'
  | 'procurement'
  | 'sales'
  | 'accounting'
  | 'reports'
  | 'admin';

export type V2ModuleStatus = 'foundation' | 'building' | 'planned';

export interface V2CapabilityAction {
  key: string;
  labelAr: string;
  labelEn: string;
  permission: string;
  backend: string[];
  approval?: string;
}

export interface V2ModuleDefinition {
  key: V2ModuleKey;
  labelAr: string;
  labelEn: string;
  descriptionAr: string;
  descriptionEn: string;
  legacyViewPermission: Permission;
  targetViewPermission: string;
  branchScoped: boolean;
  status: V2ModuleStatus;
  backend: string[];
  actions: V2CapabilityAction[];
}

/**
 * V2 contract registry.
 *
 * `legacyViewPermission` is the currently available typed permission used only
 * while V2 is being introduced beside the existing application.
 * `targetViewPermission` / action permission strings are the granular contract
 * V2 will enforce server-side as modules are migrated.
 */
export const V2_MODULES: V2ModuleDefinition[] = [
  {
    key: 'pos',
    labelAr: 'نقطة البيع',
    labelEn: 'Point of Sale',
    descriptionAr: 'الطلبات والطاولات والمطبخ والدفع والطباعة من مساحة واحدة.',
    descriptionEn: 'Orders, tables, kitchen, payment and printing in one workspace.',
    legacyViewPermission: 'pos.sell',
    targetViewPermission: 'pos.view',
    branchScoped: true,
    status: 'building',
    backend: ['orders', 'order_items', 'order_kitchen_sends', 'sales', 'sale_items', 'shifts'],
    actions: [
      { key: 'create_order', labelAr: 'إنشاء طلب', labelEn: 'Create order', permission: 'pos.order.create', backend: ['create_order'] },
      { key: 'edit_order', labelAr: 'تعديل طلب', labelEn: 'Edit order', permission: 'pos.order.edit', backend: ['update_order'] },
      { key: 'send_kitchen', labelAr: 'إرسال للمطبخ', labelEn: 'Send to kitchen', permission: 'pos.kitchen.send', backend: ['send_to_kitchen'] },
      { key: 'discount', labelAr: 'خصم', labelEn: 'Discount', permission: 'pos.discount', backend: ['update_order', 'guard_sale_discount'], approval: 'manager policy when configured' },
      { key: 'split_order', labelAr: 'تقسيم طلب', labelEn: 'Split order', permission: 'pos.order.split', backend: ['perform_pos_order_action'], approval: 'manager approval' },
      { key: 'transfer_order', labelAr: 'نقل/دمج طلب', labelEn: 'Transfer / merge order', permission: 'pos.order.transfer', backend: ['perform_pos_order_action'], approval: 'manager approval' },
      { key: 'pay', labelAr: 'تحصيل', labelEn: 'Take payment', permission: 'pos.payment.take', backend: ['process_sale', 'process_sale_split'] },
      { key: 'refund', labelAr: 'مرتجع', labelEn: 'Refund', permission: 'sales.refund.create', backend: ['process_refund'], approval: 'refund approval when configured' },
      { key: 'print', labelAr: 'طباعة', labelEn: 'Print', permission: 'pos.receipt.print', backend: ['authorize_sale_print', 'sale_print_events'] },
    ],
  },
  {
    key: 'shifts',
    labelAr: 'الشفتات والإغلاق',
    labelEn: 'Shifts & Closing',
    descriptionAr: 'الشفت الفردي، تقرير المستخدم، تقرير الوردية وإغلاق اليوم.',
    descriptionEn: 'User shift, user closing, shift report and day closing.',
    legacyViewPermission: 'shifts.view',
    targetViewPermission: 'shifts.view',
    branchScoped: true,
    status: 'building',
    backend: ['shifts', 'shift_operations', 'sales'],
    actions: [
      { key: 'open', labelAr: 'فتح شفت', labelEn: 'Open shift', permission: 'shifts.open', backend: ['open_shift'] },
      { key: 'close', labelAr: 'إغلاق شفت', labelEn: 'Close shift', permission: 'shifts.close', backend: ['close_shift'] },
      { key: 'user_report', labelAr: 'تقرير مستخدم', labelEn: 'User report', permission: 'shifts.report.user', backend: ['get_user_closing_report'] },
      { key: 'shift_report', labelAr: 'تقرير شفت', labelEn: 'Shift report', permission: 'shifts.report.shift', backend: ['get_shift_closing_report'] },
      { key: 'day_close', labelAr: 'إغلاق اليوم', labelEn: 'Day close', permission: 'shifts.day_close', backend: ['get_day_closing_report'] },
    ],
  },
  {
    key: 'approvals',
    labelAr: 'الموافقات',
    labelEn: 'Approvals',
    descriptionAr: 'كل ما هو معلق أو يحتاج اعتماد في Queue واحدة قابلة للتنفيذ.',
    descriptionEn: 'One actionable queue for pending and approval-required work.',
    legacyViewPermission: 'settings.manage',
    targetViewPermission: 'approvals.review',
    branchScoped: true,
    status: 'building',
    backend: ['approval_requests', 'waste_entries', 'stock_counts', 'warehouse_transfers'],
    actions: [
      { key: 'review', labelAr: 'اعتماد/رفض', labelEn: 'Approve / reject', permission: 'approvals.review', backend: ['decide_operational_approval'] },
      { key: 'override', labelAr: 'تجاوز موافقة طلب المدير نفسه', labelEn: 'Self-approval override', permission: 'approvals.override', backend: ['decide_manager_approval'] },
      { key: 'policy', labelAr: 'سياسات الموافقة', labelEn: 'Approval policies', permission: 'approvals.policy.manage', backend: ['approval policy configuration'] },
    ],
  },
  {
    key: 'waste',
    labelAr: 'الهالك',
    labelEn: 'Waste',
    descriptionAr: 'هالك المنتجات والوحدات مع السبب والتكلفة والاعتماد.',
    descriptionEn: 'Product/unit waste with reason, cost and approval.',
    legacyViewPermission: 'production.waste',
    targetViewPermission: 'waste.view',
    branchScoped: true,
    status: 'building',
    backend: ['waste_entries', 'waste_categories'],
    actions: [
      { key: 'create', labelAr: 'تسجيل هالك', labelEn: 'Record waste', permission: 'waste.create', backend: ['create_waste_entry'] },
      { key: 'approve', labelAr: 'اعتماد هالك', labelEn: 'Approve waste', permission: 'waste.approve', backend: ['approve_waste'] },
      { key: 'report', labelAr: 'تقرير الهالك', labelEn: 'Waste report', permission: 'waste.report', backend: ['get_waste_report'] },
    ],
  },
  {
    key: 'inventory',
    labelAr: 'المخزون',
    labelEn: 'Inventory',
    descriptionAr: 'الرصيد والوحدات والجرد والتحويلات والتقييم والحركات.',
    descriptionEn: 'Stock, units, counts, transfers, valuation and ledger.',
    legacyViewPermission: 'inventory.view',
    targetViewPermission: 'inventory.view',
    branchScoped: true,
    status: 'planned',
    backend: ['inventory', 'inventory_units', 'stock_counts', 'warehouse_transfers', 'inventory_ledger'],
    actions: [
      { key: 'adjust', labelAr: 'تسوية مخزون', labelEn: 'Adjust stock', permission: 'inventory.adjust', backend: ['adjust_stock'] },
      { key: 'count', labelAr: 'جرد', labelEn: 'Stock count', permission: 'inventory.count.create', backend: ['create_stock_count', 'submit_stock_count'] },
      { key: 'count_approve', labelAr: 'اعتماد الجرد', labelEn: 'Approve stock count', permission: 'inventory.count.approve', backend: ['approve_stock_count', 'apply_stock_count'] },
      { key: 'transfer', labelAr: 'تحويل مخزني', labelEn: 'Warehouse transfer', permission: 'inventory.transfer.create', backend: ['create_warehouse_transfer'] },
      { key: 'transfer_approve', labelAr: 'اعتماد التحويل', labelEn: 'Approve transfer', permission: 'inventory.transfer.approve', backend: ['approve_warehouse_transfer'] },
    ],
  },
  {
    key: 'catalog',
    labelAr: 'المنتجات',
    labelEn: 'Catalog',
    descriptionAr: 'المنتجات والتصنيفات والموديفاير وربط وحدات المخزون.',
    descriptionEn: 'Products, categories, modifiers and inventory-unit links.',
    legacyViewPermission: 'products.view',
    targetViewPermission: 'catalog.view',
    branchScoped: true,
    status: 'planned',
    backend: ['products', 'categories', 'product_modifier_groups', 'product_modifier_options', 'product_unit_links'],
    actions: [
      { key: 'product_create', labelAr: 'إضافة منتج', labelEn: 'Create product', permission: 'products.create', backend: ['products'] },
      { key: 'product_edit', labelAr: 'تعديل منتج', labelEn: 'Edit product', permission: 'products.edit', backend: ['products'] },
      { key: 'modifiers', labelAr: 'الموديفاير', labelEn: 'Modifiers', permission: 'products.modifiers.manage', backend: ['save_product_modifiers'] },
    ],
  },
  {
    key: 'procurement',
    labelAr: 'المشتريات',
    labelEn: 'Procurement',
    descriptionAr: 'طلب شراء، عروض أسعار، أمر شراء، استلام ومدفوعات المورد.',
    descriptionEn: 'Requests, RFQs, purchase orders, receiving and supplier payments.',
    legacyViewPermission: 'purchases.view',
    targetViewPermission: 'procurement.view',
    branchScoped: true,
    status: 'planned',
    backend: ['purchase_requests', 'rfqs', 'purchases', 'purchase_receipts', 'suppliers'],
    actions: [
      { key: 'request', labelAr: 'طلب شراء', labelEn: 'Purchase request', permission: 'procurement.request.create', backend: ['create_purchase_request'] },
      { key: 'purchase', labelAr: 'أمر شراء', labelEn: 'Purchase order', permission: 'procurement.order.create', backend: ['create_purchase_order', 'process_purchase'] },
      { key: 'receive', labelAr: 'استلام', labelEn: 'Receive', permission: 'procurement.receive', backend: ['receive_purchase_order'] },
      { key: 'pay', labelAr: 'دفع مورد', labelEn: 'Pay supplier', permission: 'procurement.payment.create', backend: ['pay_supplier'] },
    ],
  },
  {
    key: 'sales',
    labelAr: 'المبيعات والعملاء',
    labelEn: 'Sales & Customers',
    descriptionAr: 'الفواتير والعملاء والمدفوعات والمرتجعات.',
    descriptionEn: 'Invoices, customers, payments and refunds.',
    legacyViewPermission: 'sales.view',
    targetViewPermission: 'sales.view',
    branchScoped: true,
    status: 'planned',
    backend: ['sales', 'sale_items', 'customers', 'customer_payments'],
    actions: [
      { key: 'refund', labelAr: 'مرتجع', labelEn: 'Refund', permission: 'sales.refund.create', backend: ['process_refund'] },
      { key: 'receive_payment', labelAr: 'تحصيل عميل', labelEn: 'Receive customer payment', permission: 'sales.payment.receive', backend: ['receive_payment'] },
      { key: 'export', labelAr: 'تصدير', labelEn: 'Export', permission: 'sales.export', backend: ['sales'] },
    ],
  },
  {
    key: 'accounting',
    labelAr: 'الحسابات',
    labelEn: 'Accounting',
    descriptionAr: 'دليل الحسابات والقيود والخزينة والتسويات البنكية.',
    descriptionEn: 'Chart of accounts, journals, treasury and reconciliation.',
    legacyViewPermission: 'accounts.view',
    targetViewPermission: 'accounting.view',
    branchScoped: true,
    status: 'planned',
    backend: ['chart_of_accounts', 'journal_entries', 'treasury_accounts', 'bank_reconciliations'],
    actions: [
      { key: 'journal_post', labelAr: 'ترحيل قيد', labelEn: 'Post journal', permission: 'accounting.journal.post', backend: ['post_manual_journal'] },
      { key: 'treasury_transfer', labelAr: 'تحويل خزينة', labelEn: 'Treasury transfer', permission: 'accounting.treasury.transfer', backend: ['process_transfer'] },
      { key: 'reconcile', labelAr: 'تسوية بنكية', labelEn: 'Bank reconcile', permission: 'accounting.reconciliation.manage', backend: ['create_bank_reconciliation', 'complete_bank_reconciliation'] },
    ],
  },
  {
    key: 'reports',
    labelAr: 'التقارير',
    labelEn: 'Reports',
    descriptionAr: 'تقارير موحدة جدولية مع فلاتر وطباعة وتصدير.',
    descriptionEn: 'Unified table-first reports with filters, print and export.',
    legacyViewPermission: 'reports.view',
    targetViewPermission: 'reports.view',
    branchScoped: true,
    status: 'planned',
    backend: ['sales', 'inventory_ledger', 'journal_entries', 'financial report RPCs'],
    actions: [
      { key: 'print', labelAr: 'طباعة', labelEn: 'Print', permission: 'reports.print', backend: ['report result'] },
      { key: 'export', labelAr: 'تصدير', labelEn: 'Export', permission: 'reports.export', backend: ['report result'] },
    ],
  },
  {
    key: 'admin',
    labelAr: 'الإدارة والصلاحيات',
    labelEn: 'Administration',
    descriptionAr: 'المستخدمون والفروع والأدوار والصلاحيات والإعدادات والتدقيق.',
    descriptionEn: 'Users, branches, roles, permissions, settings and audit.',
    legacyViewPermission: 'users.view',
    targetViewPermission: 'admin.view',
    branchScoped: false,
    status: 'planned',
    backend: ['users', 'roles', 'branches', 'user_branch_access', 'audit_log', 'settings'],
    actions: [
      { key: 'user_create', labelAr: 'إضافة مستخدم', labelEn: 'Create user', permission: 'users.create', backend: ['create_user'] },
      { key: 'branch_assign', labelAr: 'تعيين فروع المستخدم', labelEn: 'Assign user branches', permission: 'users.branches.manage', backend: ['set_user_branch_access'] },
      { key: 'permissions', labelAr: 'إدارة الصلاحيات', labelEn: 'Manage permissions', permission: 'roles.permissions.manage', backend: ['roles', 'guard_role_permissions'] },
      { key: 'audit', labelAr: 'سجل العمليات', labelEn: 'Audit log', permission: 'audit.view', backend: ['get_audit_trail'] },
    ],
  },
];

export function getV2Module(key: V2ModuleKey): V2ModuleDefinition {
  const module = V2_MODULES.find((item) => item.key === key);
  if (!module) throw new Error(`Unknown V2 module: ${key}`);
  return module;
}
