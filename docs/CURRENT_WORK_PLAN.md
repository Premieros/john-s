# CURRENT WORK PLAN — john-s

> **Source of Truth** لأي نموذج أو مطور يكمل العمل. اقرأ هذا الملف أولًا. لا تعِد فحص المشروع كله ولا تفتح عملًا مغلقًا بدون Regression مثبت.

آخر تحديث: **2026-09-02 — Africa/Cairo**

## 1) المشروع والحالة الحالية

- Repository: `Premieros/john-s`
- Branch: `main`
- Supabase Production: `azzdesuowpdcoflmyezn`
- آخر HEAD وظيفي أخضر قبل تحديث هذا السجل: `aa17b338ce5d5c3b24119f31ed2cb2bfeb89149a`
- Verify: run `33668195994` / #297 ✅
  - lint ✅
  - typecheck ✅
  - test suites typecheck ✅
  - unit ✅
  - build ✅
  - Fresh DB / canonical migrations ✅
  - integration + security/RLS ✅
  - browser-smoke ✅
- Deploy: run `33668195754` / #299 ✅ على نفس HEAD.

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

آخر تحقق لهذه المجموعة قبل بدء Financial Visibility كان أخضر بالكامل.

---

## 5) Financial Visibility Policy — مغلق ومطبق على Production ✅

### القاعدة المطلوبة

- `owner` فقط يرى **100%** من التاريخ المالي ضمن الفروع التي يحق له الوصول إليها.
- أي role آخر، بما فيه `super_admin` إذا لم يكن Owner:
  - آخر **7 أيام = 100%**.
  - الأقدم = **30% deterministic ثابتة**.
- العينة ثابتة على مستوى الفرع والـroot row ولا تتغير بين المستخدمين أو مرات فتح الصفحة.
- لا تظهر للمستخدم أي رسالة أو مؤشر يفيد بوجود بيانات مخفية أو نسبة 30%.
- Branch isolation تظل شرطًا مستقلًا ولا يمكن للعينة تجاوزها.
- الحقيقة التشغيلية للمخزون والمحاسبة والخصم والاسترجاع تظل 100%.

### 5.1 Sales root + children

Repo migration:
- `supabase/migrations/20260902180000_financial_visibility_sales.sql`

التنفيذ:
- `private.sale_read_visible(...)`
- `private.sale_read_visible_by_id(...)`
- RESTRICTIVE SELECT policies على:
  - `sales`
  - `sale_items`

اختبارات مثبتة:
- Owner يرى كل التاريخ المسموح له فرعيًا.
- non-owner يرى آخر 7 أيام كاملة.
- القديم deterministic 30/100.
- cashier وbranch_manager يحصلان على نفس العينة الثابتة.
- super_admin لا يرث Owner full history.
- sale_items ترث قرار parent sale.
- فرع آخر مرفوض حتى لو hash bucket visible.

### 5.2 Related financial reads

Repo migration:
- `supabase/migrations/20260902183000_financial_visibility_related_reads.sql`

تمت حماية read-side على:
- `purchases`
- `purchase_items`
- `expenses`
- `customer_payments`
- `supplier_payments`
- `journal_entries`
- `journal_entry_lines`
- `stock_transactions`
- `inventory_ledger`
- `inventory_unit_entries`
- `inventory_movements`
- `raw_material_movements`
- `shift_operations`

مهم: aggregate/current stock truth لم يتم أخذ عينة منه ولم يتغير.

### 5.3 Reporting RPCs

Repo migration:
- `supabase/migrations/20260902184500_financial_visibility_reporting_invoker.sql`

دوال التقارير القرائية المالية allowlist أصبحت `SECURITY INVOKER` حتى تحترم RLS الخاصة بالمستخدم.
- لا report RPC في allowlist بقي `SECURITY DEFINER`.
- `anon` لا يملك EXECUTE.
- `authenticated` يحتفظ بـEXECUTE.
- operational/posting/mutation RPCs لم يتم تغيير security mode لها ضمن هذه المرحلة.

### 5.4 Historical orders

Repo migration:
- `supabase/migrations/20260902190000_financial_visibility_order_history.sql`

التنفيذ:
- `private.order_read_visible(...)`
- `private.order_read_visible_by_id(...)`
- RESTRICTIVE SELECT policies على:
  - `orders`
  - `order_items`

القواعد:
- `open/held` تظل **100% مرئية تشغيليًا** لمستخدم الفرع المصرح له مهما كان عمر الطلب أو bucket؛ POS/KDS/table workflow لا يُؤخذ منه sample.
- `completed/cancelled` التاريخية تتبع Owner / 7 days / deterministic 30%.
- order_items ترث parent order visibility.
- لا تغيير في create/update/pay/KDS/process_sale.

اختبار Integration مخصص:
- `tests/integration/financial_visibility_order_history.test.ts`
- اجتاز Fresh DB + security/RLS regression ضمن run `33668195994` ✅

---

## 6) Production rollout — Financial Visibility ✅

طبقت الأربع migrations بالترتيب على Supabase Production `azzdesuowpdcoflmyezn` بعد CI أخضر فقط.

Production migration registry:
- `20260902184106` — `financial_visibility_sales`
- `20260902184129` — `financial_visibility_related_reads`
- `20260902184138` — `financial_visibility_reporting_invoker`
- `20260902184150` — `financial_visibility_order_history`

Production read-only verification بعد التطبيق:
- عدد `financial_visibility_%` policies = **17**.
- كل الـ17 policy هي `RESTRICTIVE` ✅
- report allowlist: `SECURITY DEFINER` remaining = **0** ✅
- report allowlist: `anon` EXECUTE = **0** ✅
- report allowlist: missing `authenticated` EXECUTE = **0** ✅
- `private.order_read_visible` يحتوي guard صريح لـ`open/held` ✅
- يحتوي نافذة `7 days` ✅
- يحتوي deterministic `v_bucket < 30` ✅
- وقت الفحص كان هناك `held = 1` في Production؛ لم يتم إنشاء بيانات وهمية للاختبار.

---

## 7) أعمال مغلقة — لا تعِد فتحها بدون Regression مثبت

- KDS legacy compatibility + modern exact sends.
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
- Financial Visibility Policy بكامل طبقاتها المذكورة أعلاه.

---

## 8) ما لا يجب فعله مستقبلًا

- لا تستخدم React/CSS وحدهما كحماية مالية.
- لا تغير `process_sale` أو inventory deduction بسبب visibility.
- لا تحذف أو تعدل totals الأصلية لكي تطابق ما يراه الموظف.
- لا تستخدم sampling عشوائي متغير.
- لا تعرض نصوصًا مثل `30%`, `limited`, `hidden sales` للمستخدم المقيد.
- لا تمنح Super Admin تلقائيًا full financial history لمجرد دوره التقني.
- لا تجعل current stock أو posting logic يقرأ 30% فقط.
- لا تحول operational/write RPCs إلى سلوك جديد بلا Regression مثبت.

---

## 9) تعريف نجاح Financial Visibility

مكتمل على HEAD الوظيفي `aa17b338ce5d5c3b24119f31ed2cb2bfeb89149a`:
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
- no fake Production data ✅

الإجراء التالي: **لا يوجد عمل مفتوح في Financial Visibility**. لا تبدأ مرحلة جديدة إلا بطلب المستخدم أو Regression مثبت.

---

## 10) ملاحظات تشغيلية

- `npm install` سبق أن أبلغ عن vulnerabilities؛ لا تستخدم `npm audit fix --force` بشكل أعمى.
- Supabase Leaked Password Protection قد يحتاج Dashboard setting منفصلًا حسب الخطة.
- أي migration مستقبلية: Fresh DB + integration/RLS + browser-smoke أخضر قبل Production.
