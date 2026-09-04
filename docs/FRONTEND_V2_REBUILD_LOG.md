# FRONTEND V2 REBUILD LOG — john-s

> هذا هو سجل التنفيذ التفصيلي لإعادة بناء الواجهة من الصفر فوق قاعدة البيانات الحالية. المرجع المختصر للمشروع هو `docs/CURRENT_WORK_PLAN.md`، وهذا الملف هو سجل العمل اليومي للفرع الجديد.

آخر تحديث: **2026-09-04 — Africa/Cairo**

## 0) القرار المعماري

- Production branch يبقى: `main`.
- فرع التطوير الوحيد: `development/frontend-v2`.
- قاعدة البيانات الحالية في Supabase Production `azzdesuowpdcoflmyezn` هي **Source of Truth للـbackend**.
- لا نعيد بناء DB من الصفر ولا نغيّر منطق مالي/مخزني لمجرد تبسيط الواجهة.
- Frontend V2 يُبنى من الصفر، لكنه يعيد استخدام RPCs والجداول والـRLS الصحيحة الموجودة بالفعل.
- لا يوجد زر شكلي: كل Action في V2 يجب أن يكون مربوطًا بـRPC/Mutation حقيقية + Permission + Error state + اختبار.
- العربية RTL هي الأساس، والإنجليزية LTR.
- لا يتم حذف الواجهة القديمة قبل اكتمال كل Module واختباره؛ الانتقال تدريجي.
- **قرار متابعة 2026-09-04 — Permission-first:** أسماء الأدوار في V2 تعتبر labels/templates بقدر الإمكان، والتحكم الفعلي بالميزات والإجراءات يتم بالصلاحيات الصريحة. صلاحيات Super Admin/platform-only تبقى استثناء. لا يعاد بناء مسار مستقر لمجرد هذا التنظيف، لكن أي Action جديد لا يعتمد على اسم الدور إذا توجد Permission واضحة.
- العقد الحالي ما زال يعتبر `super_admin` و`owner` global admin؛ لا يتم توسيع `branch_manager` إلى global admin.

## 1) نقطة البداية

- `main` عند بدء V2: `4e63ce21597958dc9ee9852ca2ff00e4e14c86a3`.
- آخر work-in-progress تم الحفاظ عليه كأساس للفرع الموحد: `cdeb587893132a6fa10f95dc767c58b02a0603a9` من PR #5.
- Verify #516 على ذلك العمل: API contract/lint/typecheck ✅، unit توقف على خطأين Navigation فقط بسبب عدم تعيين permission صريحة لعنصر `approvals`; DB/browser لم يعملا في ذلك الـrun.
- PR #3 وPR #5 مغلقان/معتبران **Superseded by `development/frontend-v2`** ولا يجب إضافة تطوير جديد عليهما.

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
- queue موحدة موجودة على فرع V2 ولم تُطبق على Production من PR #6.

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
- `inventory_unit_recipes` وما يتصل بها يحتاج فصل واضح بين وحدات مخزون وبين تصنيع قبل إظهاره للمستخدم.

قرار V2 الحالي:
- لا نحذف هذه الكيانات من Production الآن.
- لا نعرض صفحات Legacy لمجرد وجود جدول.
- أي إزالة DB لاحقة تحتاج dependency proof + migration + Fresh DB/Regression.

### 3.3 Hardening backlog المثبت من الفحص

1. overloads لا تُحذف بدون فحص callers/tests. مسار المطبخ الذي دخل V2 تم حسمه لصالح العقد canonical `send_to_kitchen(uuid, uuid DEFAULT NULL)` بدون إعادة overload أحادي غامض.
2. عدد كبير من SECURITY DEFINER functions مضبوط على `search_path=public` بدون `pg_temp`; يعالج فقط عندما تدخل الوظيفة في مسار V2 فعلي مع regression tests.
3. `sale_payments` و`schema_migrations` لا تُفتح للـclient لمجرد وجودها؛ V2 يستخدم server-authorized paths.
4. V2 يستخدم explicit accessible branches بدل `users.branch_id` وحده.
5. Production roles القديمة لا يعاد تشكيلها أثناء بناء V2؛ permission matrix الجديدة تُثبت أولًا بالاختبارات.

## 4) Frontend V2 architecture

### 4.1 App Shell

تم بناء:
- RTL-first Sidebar ثابت/قابل للطي.
- mobile drawer.
- Header: branch selector + shift state + approval/user surfaces.
- branch context من الفروع التي ترجعها RLS.
- selected branch per-user.
- Navigation permission-aware من registry واحد.

### 4.2 Module registry — Source of Truth للواجهة

كل Module في V2 يسجل/يجب أن يسجل:
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

1. Foundation: App Shell + branch context + permission/capability registry + system health surface. **منفذ كأساس V2.**
2. POS: tables/order types → cart → modifiers منفذة؛ kitchen هو الخطوة التالية بعد ربط Shifts، ثم approvals/payment/split payment/print.
3. Shifts/closing: الصفحة موجودة والكود يبني؛ متبقي ربط route/sidebar ثم Verify.
4. Approval Center: queue/decision backend منفذة جزئيًا؛ متبقي route visibility حسب permissions والسياسات الكاملة.
5. Waste Center: fixes الحالية مثبتة.
6. Inventory/warehouses/counts/transfers.
7. Catalog/products/modifiers.
8. Procurement/suppliers.
9. Sales/customers/refunds.
10. Accounting/treasury/reconciliation.
11. Reports unified table-first.
12. Users/roles/permissions/settings/audit.

## 5) Permission redesign contract

- **Permission-first:** لا نستخدم Role name كبديل للصلاحية إلا للـplatform-only semantics.
- اسم الدور في V2 هو label/template بقدر الإمكان، وليس مصدر السماح النهائي لكل Feature.
- العقد الحالي يبقي `super_admin` و`owner` global admin؛ لا يتم إضافة `branch_manager` إلى `isAdminRole`.
- Super Admin/platform-only capabilities تبقى خارج المصفوفة العادية حيث يلزم.
- Permission vocabulary granular: view/create/edit/delete/approve/print/reprint/export/override حسب كل Module.
- كل Action حساس له server-side check؛ إخفاء الزر في React ليس حماية.
- المدير يستطيع self-approval فقط بصلاحية صريحة `approvals.override`، وليس لمجرد اسم الدور.
- لا نعيد كتابة authorization مستقر فقط لتوحيد الشكل؛ يطبق هذا العقد على العمل الجديد، وأي refactor قديم يحتاج سببًا أو Regression مثبتًا.

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
- browser smoke للمسار الأساسي أو توثيق known legacy failure غير مرتبط قبل الدمج.
- لا regression مثبت على KDS/inventory/accounting.

## 7) الحالة الحالية

- [x] إنشاء الفرع الموحد `development/frontend-v2`.
- [x] حفظ Snapshot الفروع القديمة.
- [x] فحص Production schema/RLS/functions قراءة فقط.
- [x] تحديد Canonical vs Legacy vs Hardening backlog.
- [x] PR #3 وPR #5 مغلقان/superseded تنظيميًا.
- [x] فرع V2 هو فرع التطوير النشط الوحيد.
- [x] إصلاح permission/navigation baseline الذي أوقف Verify #516.
- [x] إنشاء V2 App Shell + branch context + capability registry.
- [x] بدء POS V2 وربط create/update order + cart + modifiers + availability.
- [x] harden kitchen-send permission مع الحفاظ على canonical delta contract.
- [x] harden multi-branch shifts/open-close permissions.
- [x] بناء `V2ShiftsPage.tsx` وربطها بالـRPCs؛ **لم تُربط بالتنقل بعد**.
- [x] harden operational approval targets للهالك/الجرد/التحويلات.
- [x] إصلاح Waste fixtures بدون service-role bypass.
- [x] Verify #543: frontend كامل أخضر + Fresh DB/schema أخضر + **444/444 integration/security/RLS أخضر**.
- [ ] Browser Smoke النهائي: 50/55؛ الخمس failures نفس legacy POS stale direct-add selector المعروف، وليس Regression V2.
- [ ] ربط `/v2/shifts` والـSidebar ثم Verify.
- [ ] ربط Send to Kitchen داخل POS V2 ثم Verify.
- [ ] Payment/Split Payment وباقي POS actions.

## 8) ممنوعات خلال إعادة البناء

- ممنوع تعديل Production مباشرة أثناء بناء UI إلا بطلب صريح وبعد Verify مناسب.
- ممنوع حذف Legacy DB لمجرد أنه غير ظاهر في V2.
- ممنوع bypass لـRLS أو `user_may_access_branch`.
- ممنوع زر Placeholder يوحي بأنه يعمل.
- ممنوع نسخ حسابات مالية إلى client؛ التقارير المالية تعتمد على RPCs الرسمية.
- ممنوع استخدام `users.branch_id` وحده كقائمة فروع المستخدم في V2.
- ممنوع إعادة فتح Regression مغلق دون دليل.
- ممنوع Role-name gate في Action V2 جديد إذا توجد Permission صريحة مناسبة.
- ممنوع تغيير منطق POS الحقيقي لإخفاء failure في اختبار legacy selector.

## 9) Checkpoint — Verify #543

Run: `33850444754`

Head المختبر:
`8c819f67ecef4012ca4cca4fb43da92475116d22`

### ما تم إصلاحه قبل الـrun

1. `V2ShiftsPage.tsx`: إصلاح TypeScript لبطاقات summary بدون تغيير الحسابات.
2. `20260904043000_harden_v2_kitchen_send_permission.sql`: الحفاظ على `send_to_kitchen(uuid, uuid DEFAULT NULL)` وdelta/send response القديم مع إضافة permission + canonical branch access، بدون overload أحادي جديد.
3. `phase2_waste_center.test.ts`: المستخدم الاختباري أصبح مستخدمًا حقيقيًا بصلاحية `production.waste` بدل الاعتماد على `service_role` bypass.
4. `v2_operational_approval_security.test.ts`: استخدام `finished_good` كنوع هالك canonical بدل القيمة غير الصحيحة `product`.
5. `v2_pos_kitchen_permission.test.ts`: توقع cross-branch error أصبح `BRANCH_MISMATCH` مطابقًا للعقد الفعلي؛ لم يتغير RPC/RLS لإرضاء الاختبار.

### نتيجة Frontend

- API contract ✅
- lint ✅
- typecheck ✅
- typecheck:all ✅
- unit ✅
- build ✅

### نتيجة Fresh DB / Security

- **200 migrations applied / 0 skipped** ✅
- Schema verification ✅
- 60/60 expected tables ✅
- 65/65 expected functions ✅
- 107/107 contract RPCs ✅
- 61/61 contract tables ✅
- **57/57 integration files passed** ✅
- **444/444 integration/security/RLS tests passed** ✅

مهم: رسائل RLS/permission errors الظاهرة داخل logs جزء من negative security tests المتوقعة، والنتيجة النهائية لكل suites خضراء.

### Browser Smoke

- 50 passed / 5 failed.
- الخمس failures هي نفس حالات `tests/e2e/pos-actions.spec.ts` التاريخية.
- كلها تتوقف داخل helper `addProduct` عند انتظار `pos-cart-qty-<PRODUCT_ID>` قبل الوصول لمسارات kitchen/payment الجديدة.
- root cause المثبت سابقًا: test helper/selector قديم بالنسبة لزر الإضافة المباشرة `+`.
- الإصلاح التاريخي Test-only: `8d5fb44cd3da3b67b753cc4bd14e8ce3a58a1859` — `test: target direct POS add action`.
- لا يغيّر منطق التطبيق الحقيقي. إذا احتجنا إغلاق Browser gate، ننقل هذا الإصلاح الضيق بعد إعادة قراءة HEAD ولا نغيّر POS behavior.

### Production

- **لا يوجد أي تطبيق جديد على Supabase Production من PR #6 في هذا الـCheckpoint.**

## 10) الخطوة التالية المسجلة

1. ربط `V2ShiftsPage` فقط على `/v2/shifts` وفي V2 Sidebar مع `shifts.view`.
2. Verify.
3. عند النجاح: تحديث هذا السجل و`CURRENT_WORK_PLAN.md`.
4. بعدها Send to Kitchen داخل POS V2 بـ`pos.send_kitchen` وRPC canonical.
5. Verify وتحديث السجل مرة أخرى.
