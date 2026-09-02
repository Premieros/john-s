# CURRENT WORK PLAN — john-s

> **Source of Truth** لأي نموذج أو مطور يكمل العمل. اقرأ هذا الملف أولًا. لا تعِد فحص المشروع كله ولا تفتح عملًا مغلقًا بدون Regression مثبت.

آخر تحديث: **2026-09-02 — Africa/Cairo**

## 1) المشروع والحالة الحالية

- Repository: `Premieros/john-s`
- Branch: `main`
- Supabase Production: `azzdesuowpdcoflmyezn`
- آخر HEAD وظيفي أخضر قبل تحديث هذا السجل: `5d37212b72c8a1b633955fa136f1c31c1856baa7`
- Verify: run `33674450546` / #308 ✅
  - lint ✅
  - typecheck ✅
  - test suites typecheck ✅
  - unit ✅
  - build ✅
  - Fresh DB / canonical migrations ✅
  - integration + security/RLS ✅
  - browser-smoke ✅
- Deploy: run `33674450523` / #310 ✅ على نفس HEAD.

> بعد هذا التحديث يجب اعتماد commit تحديث السجل نفسه كـHEAD النهائي فقط بعد نجاح Verify/Deploy عليه.

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

## 4) UI / POS rollout الأخير — مغلق ✅

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

طلب المستخدم: جعل 7 أيام / 30% قابلة للإدارة من داخل النظام بدل أن تكون hard-coded فقط.

### Backend

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
- التحقق من الحدود:
  - الأيام 1..365.
  - النسبة 0..100.
- `private.sale_read_visible`, `private.financial_row_visible`, `private.order_read_visible` أصبحت تقرأ القيم من singleton بدل hard-code.
- Owner full history محفوظ.
- `open/held` operational guard محفوظ ✅
- لا تغيير في write path أو stock/accounting truth.

### UI

- `src/features/admin/components/FinancialVisibilityAdminControl.tsx`
- يظهر فقط عندما:
  - `user.role === 'super_admin'`
  - المسار `/super-admin`
- زر واضح داخل Super Admin بعنوان **سياسة عرض البيانات**.
- Modal لتعديل:
  - الأيام الأخيرة المعروضة بالكامل.
  - نسبة التاريخ الأقدم المعروضة.
- الحفظ حقيقي عبر RPC وليس local/UI-only.

اختبار مخصص:
- `tests/integration/financial_visibility_admin_controls.test.ts`
- يثبت permission denial لغير Super Admin، التعديل الديناميكي، بقاء Owner كاملًا، وبقاء `held` مرئيًا حتى عند historical_percent=0.

---

## 7) Kitchen Stations — اختيار الفرع وفئات المنتجات — مغلق ومطبق ✅

المشكلة المثبتة:
- صفحة محطات المطبخ كانت تعتمد على branch selector العام في الهيدر.
- عندما يكون Super Admin على **كل الفروع** لا يوجد branch context داخل الصفحة، فيتعذر تحميل/تعيين المستخدمين والفئات بصورة واضحة.

### Backend

Repo migration:
- `supabase/migrations/20260902222500_kitchen_station_editor_context.sql`

Production migration:
- `20260902194308` — `kitchen_station_editor_context` ✅

RPC جديد read-only:
- `get_kitchen_station_editor_context(uuid)`

يرجع للفرع المحدد فقط:
- branch identity.
- active users.
- product categories + current `kitchen_station_id`.

الحماية:
- يسمح فقط لـ`super_admin`, `owner`, `branch_manager` مع `user_may_access_branch(p_branch_id)`.
- cashier مرفوض.
- cross-branch branch_manager مرفوض.
- `anon` لا يملك EXECUTE.
- الحفظ ما زال عبر `save_kitchen_station_assignments` الموجود مسبقًا وبنفس branch/category mismatch guards.

### UI

`src/features/catalog/pages/KitchenStationsPage.tsx` أصبح يحتوي:
- branch selector مستقل داخل الصفحة (`kitchen-station-branch-select`).
- إذا كان global branch محددًا يتم مزامنته.
- إذا كان Super Admin على All Branches يطلب منه اختيار فرع صراحة.
- يعرض counts للمستخدمين والفئات لكل محطة في الفرع المختار.
- assignment modal يعرض اسم الفرع صراحة.
- يعرض **المستخدمين** و**فئات المنتجات** في مجموعتين منفصلتين.
- Select all / Clear all للمستخدمين والفئات.
- الحفظ مرتبط بالفرع المحدد فقط.
- تعريف station نفسه يظل shared، بينما user/category assignments branch-specific.

Production data observation وقت التحقق، بدون إنشاء بيانات وهمية:
- فرع **نادي سموحة**: 30 فئة منتجات.
- **الفرع الرئيسي**: 0 فئات منتجات.

هذا يفسر لماذا قد يرى المستخدم قائمة فئات فارغة عند اختيار الفرع الرئيسي؛ الصفحة الآن توضح الفرع وتمنع الالتباس بين الفروع.

اختبار مخصص:
- `tests/integration/kitchen_station_editor_context.test.ts`
- branch manager يرى مستخدمي/فئات فرعه فقط ✅
- branch manager لا يقرأ فرعًا آخر ✅
- cashier denied ✅
- super admin allowed for accessible branch ✅

---

## 8) آخر تحقق كامل لهذه المرحلة

HEAD الوظيفي:
- `5d37212b72c8a1b633955fa136f1c31c1856baa7`

Verify:
- run `33674450546` / #308 ✅
- lint ✅
- typecheck ✅
- unit ✅
- build ✅
- Fresh DB migrations ✅
- integration/security/RLS ✅
- browser-smoke ✅

Deploy:
- run `33674450523` / #310 ✅

Production:
- `financial_visibility_admin_controls` applied ✅
- `kitchen_station_editor_context` applied ✅
- defaults 7/30 verified ✅
- three root visibility helpers read configurable limits ✅
- active `open/held` order guard verified ✅
- admin/kitchen RPCs unavailable to anon ✅
- no fake Production data created ✅

---

## 9) أعمال مغلقة — لا تعِد فتحها بدون Regression مثبت

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

---

## 10) ما لا يجب فعله مستقبلًا

- لا تستخدم React/CSS وحدهما كحماية مالية.
- لا تغير `process_sale` أو inventory deduction بسبب visibility.
- لا تحذف أو تعدل totals الأصلية لكي تطابق ما يراه الموظف.
- لا تستخدم sampling عشوائي متغير.
- لا تعرض للمستخدم المقيد أن هناك نسبة مخفية أو مبيعات مخفية.
- لا تمنح Super Admin تلقائيًا full financial history لمجرد دوره التقني.
- لا تجعل current stock أو posting logic يعمل على sample.
- لا تعدل KDS runtime أو send-to-kitchen inventory behavior بسبب editor UI.

---

## 11) تعريف النجاح الحالي

مكتمل وظيفيًا على `5d37212b72c8a1b633955fa136f1c31c1856baa7`:
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
- Source of Truth updated بهذا السجل ✅

الإجراء التالي: لا يوجد عمل مفتوح في **Financial Visibility Admin** أو **Kitchen Stations branch/category editor**. لا تفتحها من جديد إلا بطلب جديد أو Regression مثبت.

---

## 12) ملاحظات تشغيلية

- `npm install` سبق أن أبلغ عن vulnerabilities؛ لا تستخدم `npm audit fix --force` بشكل أعمى.
- Supabase Leaked Password Protection قد يحتاج Dashboard setting منفصلًا حسب الخطة.
- أي migration مستقبلية: Fresh DB + integration/RLS + browser-smoke أخضر قبل Production.
