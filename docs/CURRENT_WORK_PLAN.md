# CURRENT WORK PLAN — john-s

> **Source of Truth** لأي نموذج أو مطور يكمل العمل. اقرأ هذا الملف أولًا. لا تعِد فحص المشروع كله ولا تفتح عملًا مغلقًا بدون Regression مثبت.

آخر تحديث: **2026-09-03 — Africa/Cairo**

## 1) المشروع والحالة الحالية

- Repository: `Premieros/john-s`
- Branch: `main`
- Supabase Production: `azzdesuowpdcoflmyezn`
- آخر HEAD وظيفي أخضر كامل قبل مراجعة الواجهة الحالية: `d9317a68fa22360ebb9c8243788e0e762ab90eb8`
- Verify: run `33682897361` / #320 ✅
  - lint ✅
  - typecheck ✅
  - test suites typecheck ✅
  - unit ✅
  - build ✅
  - Fresh DB / canonical migrations ✅
  - integration + security/RLS ✅
  - browser-smoke ✅
- Deploy: run `33682897444` / #322 ✅ على نفس HEAD.
- مراجعة الواجهة بتاريخ 2026-09-03 أثبتت Regression واحدًا فقط في حفظ `branches.is_active` وتم إصلاحه في commit `b3121b3fc6b02273207f3f3d99a13138769a813c`.
- أضيف contract regression test للواجهات الحديثة في commit `bdfa00ae6e835a2c3503263ddeb3ff5795f4c277`.

> يجب اعتماد commit تحديث هذا السجل نفسه كـHEAD النهائي فقط بعد نجاح Verify/Deploy عليه.

---

## 2) قواعد معمارية ثابتة — لا تغيّرها

- `send_to_kitchen` لا يخصم المخزون؛ هو state/snapshot فقط.
- `process_sale` هو نقطة خصم المخزون مرة واحدة فقط.
- Refund يعكس exact inventory path الذي خصمه البيع.
- الأسعار والإجماليات وModifier component deltas مصدرها الخادم.
- لا تضعف أو تحذف أو تتخطى RLS أو الاختبارات.
- Branch isolation دائمًا server-side.
- Public registration مغلق.
- Sensitive cashier actions تحتاج permission أو manager approval.
- لا expose لـinternal/security/accounting/inventory helpers للعميل لمجرد إنجاح اختبار.
- لا Demo/Seed tools في Production UI.
- لا تغيّر حقيقة المخزون أو المحاسبة بسبب سياسات العرض؛ visibility هي read-side فقط، والعمليات الداخلية تعمل على 100% من الحقيقة.
- لا تفتح KDS أو مراحل مغلقة بدون Regression مثبت.
- حذف الفرع النهائي لا يتحول إلى soft delete أو deactivate؛ حذف الفرع المقصود من شاشة الفروع هو Hard Delete عبر RPC محمي.

---

## 3) KDS / Accounting production baseline — مغلق ✅

Production migrations المسجلة:
- `20260902154339` — `accounting_kds_station_assignments`
- `20260902154358` — `kds_queue_legacy_compat`
- `20260902154420` — `kds_empty_legacy_order_compat`

ثوابت تم التحقق منها:
- modern KDS يعتمد على `order_kitchen_sends.order_item_id` ويعرض المرسل فعليًا فقط.
- legacy compatibility ضيقة للطلبات القديمة الفارغة فقط.
- `send_to_kitchen(uuid,uuid)` لا يخصم مخزونًا.
- branch/station isolation محفوظة.
- Cash + Bank موجودان لكل فرع في baseline المحاسبي.

---

## 4) UI / POS rollout — مغلق ✅

تم إغلاق ونشر:
- Mobile DataTable cards + header/branch-menu containment.
- POS product cards أصغر وكثافة أعلى.
- إصلاح vertical scroll لمنطقة المنتجات.
- POS system quick navigation buttons بصلاحياتها الحالية.
- تكبير مساحة الطاولات والطلبات النشطة.
- إظهار الطلبات غير المرتبطة بطاولة وهي `open/held` حتى الدفع/الإغلاق.
- منع أي إضافة للسلة بدون شفت مفتوح: product click / `+` / modifiers / barcode.
- Reports de-duplication: اختيار التقرير في مكان واحد مرئي، والبيانات تظهر أعلى الصفحة.
- global fixed Back button في الهيدر مع RTL/LTR.
- Browser Smoke fixture يحاكي شفتًا مفتوحًا في سيناريوهات البيع الطبيعية؛ شرط التطبيق لم يُضعف.

مراجعة wiring بتاريخ 2026-09-03:
- POS shift gate موجود ومربوط بـ`getActiveShift` ✅
- Reports selector/context filters موجودة بدون إعادة ازدحام الواجهة ✅
- Header back button موجود خارج dashboard ✅
- branch status editor أصبح يرسل `p_is_active` فعليًا ✅

---

## 5) Financial Visibility Policy — مغلق ومطبق على Production ✅

### القاعدة

- `owner` فقط يرى **100%** من التاريخ المالي ضمن الفروع المسموح بها.
- أي role آخر، بما فيه `super_admin` إذا لم يكن Owner:
  - الفترة الحديثة = 100%.
  - ما قبلها = deterministic percentage ثابتة.
- القيم الافتراضية الحالية في Production: **7 أيام / 30%**.
- لا تظهر للمستخدم المقيد أي إشارة لوجود بيانات مخفية أو نسبة الرؤية.
- Branch isolation شرط مستقل دائمًا.
- الحقيقة التشغيلية للمخزون والمحاسبة والخصم والاسترجاع تظل 100%.

### 5.1 طبقات القراءة المحمية

Repo migrations:
- `supabase/migrations/20260902180000_financial_visibility_sales.sql`
- `supabase/migrations/20260902183000_financial_visibility_related_reads.sql`
- `supabase/migrations/20260902184500_financial_visibility_reporting_invoker.sql`
- `supabase/migrations/20260902190000_financial_visibility_order_history.sql`

محمية read-side على المبيعات وبنودها، المشتريات وبنودها، المصروفات، المدفوعات، القيود، الحركات التاريخية، الطلبات التاريخية وبنودها، وتقارير القراءة المالية.

`open/held` تظل **100% مرئية تشغيليًا** للمستخدم المصرح له في الفرع مهما كان عمر الطلب أو نسبة التاريخ؛ POS/KDS/table workflow لا يدخل في sampling.

Production registry:
- `20260902184106` — `financial_visibility_sales`
- `20260902184129` — `financial_visibility_related_reads`
- `20260902184138` — `financial_visibility_reporting_invoker`
- `20260902184150` — `financial_visibility_order_history`

Production verification السابقة:
- 17 `financial_visibility_%` policies وكلها `RESTRICTIVE` ✅
- report allowlist لا يحتوي SECURITY DEFINER متبقيًا ✅
- `anon` لا يملك EXECUTE على report allowlist ✅

---

## 6) Super Admin — إدارة Financial Visibility — مغلق ومطبق ✅

Repo migration:
- `supabase/migrations/20260902222000_financial_visibility_admin_controls.sql`

Production migration:
- `20260902194257` — `financial_visibility_admin_controls` ✅

التنفيذ:
- private singleton: `private.financial_visibility_settings`.
- default الحالي: `recent_days = 7`, `historical_percent = 30`.
- RPCs:
  - `get_financial_visibility_settings()`
  - `update_financial_visibility_settings(integer, integer)`
- القراءة/التعديل عبر RPC مقصوران منطقيًا على active `super_admin`؛ `anon` لا يملك EXECUTE.
- الأيام 1..365 والنسبة 0..100.
- `private.sale_read_visible`, `private.financial_row_visible`, `private.order_read_visible` تقرأ القيم من singleton.
- Owner full history محفوظ.
- `open/held` operational guard محفوظ ✅
- لا تغيير في write path أو stock/accounting truth.

UI:
- `src/features/admin/components/FinancialVisibilityAdminControl.tsx`
- يظهر للـSuper Admin في `/super-admin`.
- الحفظ حقيقي عبر RPC وليس UI-only.

اختبار:
- `tests/integration/financial_visibility_admin_controls.test.ts` ✅

---

## 7) Kitchen Stations — اختيار الفرع وفئات المنتجات — مغلق ومطبق ✅

Repo migration:
- `supabase/migrations/20260902222500_kitchen_station_editor_context.sql`

Production migration:
- `20260902194308` — `kitchen_station_editor_context` ✅

RPC:
- `get_kitchen_station_editor_context(uuid)`

الحماية:
- يسمح فقط لـ`super_admin`, `owner`, `branch_manager` مع `user_may_access_branch(p_branch_id)`.
- cashier مرفوض.
- cross-branch branch_manager مرفوض.
- `anon` لا يملك EXECUTE.
- الحفظ عبر `save_kitchen_station_assignments` مع branch/category mismatch guards.

UI:
- branch selector مستقل داخل الصفحة.
- assignment modal يوضح الفرع.
- المستخدمون وفئات المنتجات مجموعتان منفصلتان.
- Select all / Clear all.
- user/category assignments branch-specific.

Production observation بدون بيانات وهمية:
- فرع **نادي سموحة**: 30 فئة منتجات.
- **الفرع الرئيسي**: 0 فئات منتجات.

اختبار:
- `tests/integration/kitchen_station_editor_context.test.ts` ✅

---

## 8) Branch Hard Delete + Costing + Permissions UI — مغلق ومطبق ✅

### 8.1 حذف الفرع نهائيًا

Repo migration:
- `supabase/migrations/20260902234000_branch_hard_delete.sql`

Production migration:
- `20260902210800` — `branch_hard_delete` ✅

التنفيذ:
- `delete_branch_cascade(uuid)` بدل `deactivate_branch` لعملية الحذف من شاشة الفروع.
- الحذف النهائي متاح فقط لـ`owner` و`super_admin`.
- لا يمكن للمستخدم حذف الفرع المرتبط بحسابه الحالي.
- Owner لا يحذف فرعًا خارج نطاقه.
- كل FK عام مباشر `branch_id -> branches(id)` أصبح `ON DELETE CASCADE`.
- تحقق Production: `non_cascade_branch_fks = []` ✅
- حمايات الحسابات النظامية والطاولات والـmodifier options تبقى فعالة في الحذف اليدوي، وتسمح فقط بالـcascade الناتج عن حذف الفرع الأب.
- لم يتم حذف أي فرع Production حقيقي أثناء الاختبار أو التحقق.

UI:
- `src/features/admin/pages/BranchesPage.tsx` يعرض تحذير حذف نهائي واضح.
- مراجعة 2026-09-03 أثبتت أن status selector كان ظاهرًا لكن `p_is_active` غير مرسل؛ تم إصلاحه في `b3121b3fc6b02273207f3f3d99a13138769a813c`.

اختبار:
- `tests/integration/branch_hard_delete.test.ts` ✅ على Fresh DB.

### 8.2 Costing summary

Repo migration:
- `supabase/migrations/20260902234500_costing_sales_summary_rls.sql`

Production migration:
- `20260902210812` — `costing_sales_summary_rls` ✅

التنفيذ:
- `get_order_margin(uuid,date,date)` أصبح `SECURITY INVOKER`.
- `get_costing_sales_summary(uuid,date,date)` يعيد `sales_count`, `net_sales`, `cogs`, `ratio`.
- COGS ÷ Net Sales يحترم RLS وسياسة Financial Visibility.
- `anon` لا يملك EXECUTE.

UI:
- `src/features/costing/pages/CostingCenterPage.tsx` يعرض **التكلفة الفعلية من المبيعات** كنسبة COGS ÷ صافي المبيعات مع القيمتين.

### 8.3 Permissions UI

- `src/features/admin/pages/RolesTab.tsx` مبسطة إلى اختيار role واحد ثم التحكم بصلاحياته.
- بحث في جميع الصلاحيات.
- مجموعات واضحة.
- Select/Clear group.
- Select all/Clear all.
- إنشاء وحذف custom roles.
- global / branch scope محفوظ.
- منطق الصلاحيات backend لم يُضعف بسبب إعادة التصميم.

### 8.4 UI regression contract

- `tests/unit/recentUiWiringContract.test.ts`
- يثبت wiring للآتي:
  - branch status + permanent delete.
  - costing sales summary card.
  - role search/group/all/save controls.
  - fixed header back button.
  - compact report selector/context filters.
  - POS no-cart-without-open-shift gate.

---

## 9) آخر تحقق كامل قبل commit السجل الحالي

HEAD الوظيفي الأخضر:
- `d9317a68fa22360ebb9c8243788e0e762ab90eb8`

Verify:
- run `33682897361` / #320 ✅
- lint ✅
- typecheck ✅
- unit ✅
- build ✅
- Fresh DB migrations ✅
- integration/security/RLS ✅
- browser-smoke ✅

Deploy:
- run `33682897444` / #322 ✅

Production:
- `branch_hard_delete` applied ✅
- `costing_sales_summary_rls` applied ✅
- all direct branch FKs cascade ✅
- costing/order-margin functions are SECURITY INVOKER ✅
- delete RPC unavailable to anon ✅
- no real Production branch deleted during verification ✅

مراجعة الواجهة اللاحقة أضافت فقط:
- `b3121b3...` إصلاح حفظ حالة الفرع.
- `bdfa00ae...` UI wiring regression contract.

يجب أن ينجح Verify/Deploy على commit هذا السجل قبل اعتباره checkpoint النهائي الجديد.

---

## 10) أعمال مغلقة — لا تعِد فتحها بدون Regression مثبت

- KDS legacy compatibility + modern exact sends.
- Kitchen station branch/category assignment editor.
- Product Modifiers + authoritative pricing/inventory effects.
- exact sale-item inventory snapshots / partial refund.
- exact sent-item void + sent-item mutation guards.
- open-order modifier immutability.
- Burger lifecycle.
- accounting/treasury bootstrap baseline.
- manager approval lifecycle.
- branch isolation baseline.
- hybrid inventory deduction/refund baseline.
- responsive modal/table/mobile work.
- POS layout/scroll/system navigation/tables workspace.
- Reports UX de-duplication.
- fixed global Back button.
- no-cart-without-open-shift enforcement.
- Financial Visibility Policy + Super Admin controls.
- Branch hard delete + cascade contract.
- Costing COGS/Net Sales summary.
- Simplified comprehensive Roles/Permissions UI.

---

## 11) ما لا يجب فعله مستقبلًا

- لا تستخدم React/CSS وحدهما كحماية مالية.
- لا تغير `process_sale` أو inventory deduction بسبب visibility.
- لا تحذف أو تعدل totals الأصلية لكي تطابق ما يراه الموظف.
- لا تستخدم sampling عشوائي متغير.
- لا تعرض للمستخدم المقيد أن هناك نسبة مخفية أو مبيعات مخفية.
- لا تمنح Super Admin تلقائيًا full financial history لمجرد دوره التقني.
- لا تجعل current stock أو posting logic يعمل على sample.
- لا تعدل KDS runtime أو send-to-kitchen inventory behavior بسبب editor UI.
- لا تعِد الحذف النهائي للفرع إلى soft delete أو تترك rows مرتبطة به بـSET NULL/RESTRICT على `branch_id`.

---

## 12) تعريف النجاح الحالي

آخر baseline مثبت بالكامل هو `d9317a68fa22360ebb9c8243788e0e762ab90eb8`:
- lint ✅
- typecheck ✅
- unit ✅
- build ✅
- Fresh DB / migrations ✅
- integration/security/RLS ✅
- browser-smoke ✅
- Deploy ✅
- Production migrations applied ✅
- Production structural verification ✅

الـcheckpoint الجديد بعد مراجعة الواجهة لا يُغلق نهائيًا إلا بعد نجاح Verify/Deploy على commit هذا السجل الذي يحتوي أيضًا على إصلاح `p_is_active` واختبار UI wiring.

---

## 13) ملاحظات تشغيلية

- `npm install` سبق أن أبلغ عن vulnerabilities؛ لا تستخدم `npm audit fix --force` بشكل أعمى.
- Supabase Leaked Password Protection قد يحتاج Dashboard setting منفصلًا حسب الخطة.
- أي migration مستقبلية: Fresh DB + integration/RLS + browser-smoke أخضر قبل Production.
- مراجعة الواجهة هنا هي code/wiring review + automated browser-smoke؛ لا تدّعِ manual authenticated Production visual inspection بدون جلسة فعلية مصرح بها.
