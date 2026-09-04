# FRONTEND V2 REBUILD LOG — john-s

> هذا هو سجل التنفيذ التفصيلي لإعادة بناء الواجهة من الصفر فوق قاعدة البيانات الحالية. المرجع المختصر للمشروع هو `docs/CURRENT_WORK_PLAN.md`، وهذا الملف هو سجل العمل اليومي للفرع الجديد.

آخر تحديث: **2026-09-04 — Africa/Cairo**

## 0) القرار المعماري

- Production branch يبقى: `main`.
- فرع التطوير الوحيد من الآن: `development/frontend-v2`.
- قاعدة البيانات الحالية في Supabase Production `azzdesuowpdcoflmyezn` هي **Source of Truth للـbackend**.
- لا نعيد بناء DB من الصفر ولا نغيّر منطق مالي/مخزني لمجرد تبسيط الواجهة.
- Frontend V2 يُبنى من الصفر، لكنه يعيد استخدام RPCs والجداول والـRLS الصحيحة الموجودة بالفعل.
- لا يوجد زر شكلي: كل Action في V2 يجب أن يكون مربوطًا بـRPC/Mutation حقيقية + Permission + Error state + اختبار.
- العربية RTL هي الأساس، والإنجليزية LTR.
- لا يتم حذف الواجهة القديمة قبل اكتمال كل Module واختباره؛ الانتقال تدريجي.

## 1) نقطة البداية

- `main` عند بدء V2: `4e63ce21597958dc9ee9852ca2ff00e4e14c86a3`.
- آخر work-in-progress تم الحفاظ عليه كأساس للفرع الموحد: `cdeb587893132a6fa10f95dc767c58b02a0603a9` من PR #5.
- Verify #516 على ذلك العمل: API contract/lint/typecheck ✅، unit توقف على خطأين Navigation فقط بسبب عدم تعيين permission صريحة لعنصر `approvals`; DB/browser لم يعملا في ذلك الـrun.
- PR #3 وPR #5 يعتبران من الآن **Superseded by `development/frontend-v2`** ولا يجب إضافة تطوير جديد عليهما.

## 2) Snapshot الفروع قبل التنظيف

تم تسجيل الفروع وSHAاتها قبل أي تنظيف حتى لا يضيع أثر أي عمل:

- `feat/operations-approvals-permissions-20260904` → `cdeb587893132a6fa10f95dc767c58b02a0603a9`
- `feature/kitchen-station-printers` → `bccc6441a7aa9657c9818b45b686fd3bf446c0ae`
- `fix/dynamic-printer-stations` → `5f0cbcd96a60cb6da03137a634c529f08bf1356c`
- `fix/kitchen-modifier-permissions` → `84d94b11cc2c7052e7b41f76eb4f2bbc6942b2fa`
- `fix/kitchen-send-overload-20260904` → `d81d90cbddaa3d2f08eb442f5471c037a9c7a500`
- `fix/kitchen-station-permissions` → `84d94b11cc2c7052e7b41f76eb4f2bbc6942b2fa`
- `fix/pos-kitchen-resend-state` → `e2972db99e43c0d8dfe36c06b15f3590749f5c9e`
- `fix/pos-live-available-stock-20260904` → `d30ca0c5d0c146edca5179a7084fe7602b64941c`
- `fix/pos-product-card-buttons` → `92e13188a5c1807fd0a3a5b404f853a17c27999d`
- `fix/pos-product-options-modal` → `6aeffb76dc8ca7b99231a0b83ffcc20463640db9`
- `fix/pos-smoke-approval-center-20260904-ci` → `5e0514b329a7c16ce3a9bf4c5aa344f052077a62`
- `fix/pos-smoke-approval-center-20260904` → `547d422eb2aa28be80ddd1cf880357d0affea147`
- `fix/ready-product-sale-deduction-20260904` → `27a2ee2745f0060403cd31e78ee8f9f82f7504a6`
- `fix/xp80-kitchen-ticket-size` → `76bcce29a1d232619b99938b56488174d030c24d`
- `verify/approval-center-20260904` → `4d688fd63d3337173eb681992babc22d4dfbd28a`
- `main` → `4e63ce21597958dc9ee9852ca2ff00e4e14c86a3`

من الآن: **أي تطوير جديد يذهب فقط إلى `development/frontend-v2`.**

## 3) فحص قاعدة Production — 2026-09-04

الفحص قراءة فقط، بدون أي DDL/DML على Production.

### الحجم الحالي

- Public tables: **100**
- Public functions: **243**
- RLS policies: **331**
- Active branches: **2**
- Active users: **8**
- Active products: **335**
- Active warehouses: **2**
- Open shifts وقت الفحص: **2**
- Open orders وقت الفحص: **1**
- Pending manager approvals: **0**
- Pending waste: **0**

### 3.1 Canonical backend الذي ستُبنى عليه V2

**Identity / scope**
- `users`
- `roles`
- `branches`
- `user_branch_access`
- `organizations` / `organization_members` فقط حيث ما زالت مستخدمة في branch access.
- `user_may_access_branch(uuid)` هي Primitive العزل الأساسية.

**POS / Orders / Kitchen**
- `orders`, `order_items`
- `order_kitchen_sends`, `order_kitchen_voids`
- `approval_requests`
- `create_order`, `update_order`, `perform_pos_order_action`
- `send_to_kitchen`, `get_kitchen_queue`, `set_kitchen_status`
- `process_sale`, `process_sale_split`, `_process_sale_core`
- `sale_items`, `sale_payments`, `sale_item_inventory_effects`
- `shifts`, `shift_operations`, `open_shift`, `close_shift`, `get_active_shift`

**Catalog**
- `products`, `categories`
- `product_modifier_groups`, `product_modifier_options`, `product_modifier_inventory_effects`
- `product_components` للتكلفة/BOM وليس كواجهة تصنيع مستقلة.

**Inventory**
- ready-product inventory (`inventory`, `inventory_batches`, ledger/movements)
- `inventory_units`, `inventory_unit_batches`, `inventory_unit_entries`
- `product_unit_links`
- `stock_counts`, `stock_count_items`
- `warehouse_transfers`, `warehouse_transfer_items`
- availability and costing RPCs مثل `get_pos_product_availability`, `check_product_availability`, `get_stock_valuation`.

**Procurement**
- `purchase_requests`, `purchase_request_items`
- `rfqs`, supplier quotations
- `purchases`, `purchase_items`
- `purchase_receipts`, `purchase_receipt_items`
- الموردون والمدفوعات المرتبطة بهم.

**Waste / approvals**
- `waste_entries`, `waste_categories`, `create_waste_entry`, `approve_waste`
- `approval_requests`, `request_manager_approval`, `decide_manager_approval`, `consume_manager_approval`
- PR #5 يضيف queue موحدة للشاشات الجديدة، ولم تُطبق على Production بعد.

**Accounting**
- `chart_of_accounts`, `account_mappings`
- `journal_entries`, `journal_entry_lines`
- `treasury_accounts`, `treasury_transactions`
- `customer_payments`, `supplier_payments`
- Trial Balance / Ledger / Income Statement / Balance Sheet / AR / AP / Cash Flow RPCs الحالية.

### 3.2 Legacy / compatibility — لا يُبنى له UI جديد قبل حسمه

قاعدة Production ما زالت تحتوي على طبقات قديمة/متداخلة:

- subscription tables/functions (`subscriptions`, `plans`, `branch_subscriptions`, `subscription_*`, feature-plan paths).
- raw-material / recipes / production tables and RPCs ما زالت موجودة وتُستخدم في بعض compatibility/hybrid inventory paths.
- `inventory_unit_recipes` وما يتصل بها يحتاج فصل واضح بين "وحدات مخزون" وبين "تصنيع" قبل إظهاره للمستخدم.

قرار V2 الحالي:
- لا نحذف هذه الكيانات من Production الآن.
- لا نعرض صفحات Legacy لمجرد وجود جدول.
- أي إزالة DB لاحقة تحتاج dependency proof + migration + Fresh DB/Regression.

### 3.3 Hardening backlog المثبت من الفحص

1. توجد overloads يجب مراجعتها قبل اعتماد API V2 النهائي:
   - `send_to_kitchen(uuid)` و`send_to_kitchen(uuid, uuid)`
   - `create_user(...)` بتوقيعين
   - `_restore_refund_hybrid_inventory(...)` بتوقيعين
   لا تُحذف أي overload بدون فحص callers/tests.

2. عدد كبير من SECURITY DEFINER functions مضبوط على `search_path=public` بدون `pg_temp`.
   - هذا **Hardening backlog**، وليس مبررًا لتعديل مئات الدوال دفعة واحدة.
   - يُعالج على دفعات مع اختبارات regression، بدءًا من الوظائف التي تستدعيها V2 مباشرة.

3. `sale_payments` و`schema_migrations` عليهما RLS بدون client policies، لكن grants الحالية للـ`service_role` فقط؛ لذلك لا يُصنف هذا وحده كعيب. V2 لا يقرأ `sale_payments` مباشرة إلا عبر مسار server-authorized واضح.

4. Production الحالي لديه 8 explicit `user_branch_access` grants، وكل المستخدمين النشطين الثمانية ما زال لديهم أيضًا legacy `users.branch_id`.
   - V2 سيستخدم explicit accessible branches للاختيار.
   - `users.branch_id` يبقى compatibility/default branch حتى يتم إثبات إمكانية تقليصه.

5. Production roles: 9 active roles؛ 5 فقط حاليًا تحتوي `pos.sell`، و2 فقط تحتوي `approvals.review`، ولا يوجد دور يحتوي `approvals.override` حاليًا.
   - تغييرات PR #5 الخاصة بتوسيع POS/approvals ليست مطبقة على Production بعد.

## 4) Frontend V2 architecture

### 4.1 App Shell

يبنى أولًا ويتضمن:
- RTL-first Sidebar ثابت/قابل للطي.
- Header واحد: branch selector + shift state + approval badge + user menu + global search.
- اختيار الفرع من الفروع التي ترجعها RLS للمستخدم، وليس من `users.branch_id` فقط.
- selected branch محفوظ per-user ولا يُشارك cache بين المستخدمين.
- Navigation permission-aware من registry واحد.

### 4.2 Module registry — Source of Truth للواجهة

كل Module في V2 يجب أن يسجل:
- route
- label/icon
- required view permission
- actions
- RPC/table backing لكل action
- approval requirement
- branch scope
- test IDs

إذا لم يوجد backend Action حقيقي: لا يظهر زر Action في Production-ready V2.

### 4.3 ترتيب البناء

1. Foundation: App Shell + branch context + permission/capability registry + system health surface.
2. POS: tables/order types → cart → modifiers → kitchen → approvals → payment/split payment → print.
3. Shifts/closing: user report + shift report + day close all shifts.
4. Approval Center: manager approvals + waste + stock counts + transfers + أي queue حقيقية لها decision RPC.
5. Waste Center.
6. Inventory/warehouses/counts/transfers.
7. Catalog/products/modifiers.
8. Procurement/suppliers.
9. Sales/customers/refunds.
10. Accounting/treasury/reconciliation.
11. Reports unified table-first.
12. Users/roles/permissions/settings/audit.

## 5) Permission redesign contract

- لا نستخدم Role name كبديل للصلاحية إلا للـplatform-only semantics.
- `super_admin` و`owner` فقط يظلان global admin حسب العقد الحالي؛ لا يتم إضافة `branch_manager` إلى `isAdminRole`.
- Permission vocabulary يصبح granular: view/create/edit/delete/approve/print/reprint/export/override حسب كل Module.
- كل Action حساس له server-side check؛ إخفاء الزر في React ليس حماية.
- المدير يستطيع self-approval فقط بصلاحية صريحة `approvals.override`، وليس لمجرد اسم الدور.

## 6) Definition of Done لكل شاشة V2

الشاشة لا تعتبر منتهية حتى يتحقق:

- Query/Mutation حقيقية تعمل على Fresh DB.
- كل زر له نتيجة مثبتة أو لا يظهر.
- loading/empty/error/success states.
- branch scope صحيح.
- permission gate على UI + server where required.
- RTL/LTR + desktop/tablet/mobile.
- unit/contract test.
- integration test للعمليات التي تغير DB.
- browser smoke للمسار الأساسي.
- لا regression مثبت على KDS/inventory/accounting.

## 7) الحالة الحالية

- [x] إنشاء الفرع الموحد `development/frontend-v2`.
- [x] حفظ Snapshot الفروع القديمة.
- [x] فحص Production schema/RLS/functions قراءة فقط.
- [x] تحديد Canonical vs Legacy vs Hardening backlog.
- [ ] إغلاق PR #3 وPR #5 كـsuperseded بعد تثبيت هذا السجل.
- [ ] جعل فرع V2 هو فرع التطوير النشط الوحيد تنظيميًا.
- [ ] إصلاح permission عنصر `approvals` الذي أوقف Verify #516.
- [ ] إنشاء V2 App Shell + branch context + capability registry.
- [ ] بدء POS V2 contract mapping وربط أول flow حقيقي.
- [ ] تشغيل Verify كامل على V2 baseline.

## 8) ممنوعات خلال إعادة البناء

- ممنوع تعديل Production مباشرة أثناء بناء UI إلا بطلب صريح وبعد Verify.
- ممنوع حذف Legacy DB لمجرد أنه غير ظاهر في V2.
- ممنوع bypass لـRLS أو `user_may_access_branch`.
- ممنوع زر Placeholder يوحي بأنه يعمل.
- ممنوع نسخ حسابات مالية إلى client؛ التقارير المالية تعتمد على RPCs الرسمية.
- ممنوع استخدام `users.branch_id` وحده كقائمة فروع المستخدم في V2.
- ممنوع إعادة فتح Regression مغلق دون دليل.
