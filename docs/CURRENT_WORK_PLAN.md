# CURRENT WORK PLAN — john-s

> **Source of truth** لأي نموذج أو مطور يدخل يكمل العمل. اقرأ هذا الملف أولًا، ولا تعِد فتح أعمال أُغلقت إلا إذا ظهر Regression مثبت.

آخر تحديث: **2026-09-02 13:17 Africa/Cairo**

## 1) الحالة الحالية

- Repository: `Premieros/john-s`
- Branch: `main`
- Supabase Production: `azzdesuowpdcoflmyezn`
- آخر Release Baseline أخضر مؤكد بالكامل: `5617da55725dd7cb1a160b8b1376c6c7254e619b`
- Verify main #197 / run `33600846169`: **SUCCESS**
- Deploy #199 / run `33600846236`: **SUCCESS**

### Work-in-progress الحالي

- HEAD الحالي بعد إصلاح smoke test للوردية: `2b748b8746c3bbfc2d0b6989d5b8086afd7d35b0`
- Deploy #232 / run `33618595019`: **SUCCESS**
- Verify main #230 / run `33618594995`: **IN PROGRESS وقت تحديث هذا السجل**
  - install ✅
  - lint ✅
  - typecheck ✅
  - typecheck all suites ✅
  - unit tests: قيد التشغيل وقت التحديث
  - build / DB / browser-smoke: لم تُحسم بعد وقت التحديث

مهم: لا تعتبر HEAD الحالي Release Baseline أخضر إلا بعد نجاح jobs الثلاثة في Verify main: `verify` + `db` + `browser-smoke`.

### آخر Regression تم تتبعه

Verify #229 / run `33615782609`:
- `verify` ✅
- `db` ✅
- `browser-smoke` ❌ — 50 passed / 1 failed

الفشل الوحيد كان في `tests/e2e/cashier-shift-entry.spec.ts` بعد أن وصل الاختبار فعليًا إلى صفحة الورديات وفتح نافذة فتح الشيفت. الـassertion كان يبحث عن `رصيد الافتتاح` بينما الـlabel الحقيقي في الواجهة هو `المبلغ الافتتاحي`.

تم إصلاح fidelity للاختبار بدون تغيير الصلاحيات أو منطق فتح الوردية:
- `f737a09633c4ae0a391f2062bb1f46cf9c0ef896` — محاكاة PostgREST object/array الصحيحة لـ`.maybeSingle()`.
- `8f973d9a240018893a3a2db5a026953af552d525` — قبول مصطلحي `وردية/شيفت` في smoke test.
- `2b748b8746c3bbfc2d0b6989d5b8086afd7d35b0` — مطابقة label الفعلي `المبلغ الافتتاحي`.

---

## 2) دورة التشغيل الكاملة — مثبتة بالاختبار ✅

تم إضافة Release Gate حقيقي في:
`tests/integration/pos_operational_lifecycle.test.ts`

الدورة التي تمر فعليًا على Fresh DB:

`authenticated cashier → open shift → create order → send to KDS → process sale → inventory deduction → refund requires manager approval → manager approves → refund restores inventory → approval consumed once → close shift`

المثبت داخل الدورة:
- فتح الوردية يتم عبر RPC الحقيقي.
- إنشاء الطلب يستخدم سعر الخادم، ولا يثق في السعر المزور من العميل.
- KDS لا يخصم المخزون.
- البيع يخصم المخزون **مرة واحدة فقط**.
- Refund للكاشير يُرفض قبل موافقة المدير.
- موافقة المدير تعمل وتُستهلك مرة واحدة.
- Full refund يعيد المخزون فعليًا.
- الوردية تُغلق بنجاح بعد الدورة.

---

## 3) إصلاح Refund للمخزون الهجين ✅

Migration:
`20260902084000_refund_hybrid_inventory_restoration.sql`

المشكلة التي اكتشفها اختبار دورة التشغيل:
- `process_refund` القديم كان يعيد مخزون `inventory_batches/inventory_ledger` التقليدي فقط.
- البيع الحديث قد يكون خصم من `inventory_units` أو خامات Recipe مباشرة.
- بالتالي كان يمكن أن يتم Refund مالي ناجح بدون إعادة المخزون الحقيقي، أو إنشاء Product stock وهمي بدل المسار الذي خُصم.

الحل الحالي:
- بيع يعتمد على `inventory_units` → Refund يعيد وحدات المخزون.
- بيع يعتمد على raw recipe → Refund يعيد الخامات التي خُصمت.
- Ready/legacy product → يحتفظ بمسار استرجاع Product inventory القديم.
- الاسترجاع محدود بكمية الخصم الفعلية ويطرح ما سبق إرجاعه، لمنع Over-restoration في partial/repeated refunds.
- لا يتم إنشاء phantom product stock لبيع Hybrid.

تم تطبيق migration على **Production** بنجاح.

تحقق Production بعد التطبيق:
- `process_refund` مرتبط بـ `_restore_refund_hybrid_inventory` ✅
- `authenticated` يستطيع تشغيل `process_refund` حسب قواعده ✅
- `anon` لا يستطيع تشغيل Refund ✅
- الـhelper الداخلي غير متاح لـ`authenticated` ✅
- `service_role` يحتفظ بتنفيذ الـhelper ✅
- Negative inventory unit batches: **0**
- Negative product batches: **0**
- Negative raw-material batches: **0**
- Invalid negative sales totals/paid amounts: **0**

---

## 4) Product Modifiers / Variants — Work in Progress

طلب المستخدم الحالي: المنتج مثل ساندوتش البرجر يجب أن يدعم اختيار تكوين حقيقي مرتبط بالمكونات، مثل:
- Single / Double / Triple كمجموعة مطلوبة.
- Extra Cheese / Bacon / Sauce / Jalapeño كإضافات.
- No Onion / No Pickles / No Sauce كحذف مكونات.
- كل اختيار له `price_delta` موثوق من الخادم وInventory Component delta حقيقي.

### Backend المنفذ

Migration الأساسية:
`supabase/migrations/20260902085000_product_modifiers_inventory.sql`

الجداول:
- `product_modifier_groups`
- `product_modifier_options`
- `product_modifier_inventory_effects`

Order/Sale snapshot fields:
- `order_items.modifier_option_ids`
- `order_items.modifiers_snapshot`
- `sale_items.modifier_option_ids`
- `sale_items.modifiers_snapshot`

RPCs / helpers:
- `get_product_modifiers(uuid)`
- `resolve_product_modifiers(product_id, branch_id, option_ids jsonb)`
- `save_product_modifiers(uuid,jsonb)`
- `deduct_sale_inventory_with_modifiers(...)`

قواعد مثبتة في التصميم:
- العميل لا يحدد السعر النهائي أو component deltas كمصدر ثقة.
- الخادم يتحقق من required/min/max/group/product/branch/active.
- `send_to_kitchen` لا يخصم المخزون.
- `process_sale` هو الذي يخصم التركيب النهائي مرة واحدة.
- Modifier snapshot يجب أن يستمر في Order → KDS → Receipt → Sale → Refund.

### Hardening المنفذ

Commit `dc6976b1be85c4e069d0c16e10de050868aca1b2`:
- `save_product_modifiers` أصبح validate-first ثم mutate، لمنع حذف/تلف configuration عند payload غير صالح.
- `authenticated` لم يعد لديه direct SELECT على `product_modifier_inventory_effects`.
- Effect targets يتم التحقق من انتمائها لنفس الفرع.

Commit `fdf2279ac88ebeaabfd2096cb891526b85d4fb25`:
- إضافة `tests/integration/product_modifiers_security.test.ts`.
- اختبارات privacy/grants/atomicity/trusted resolver/negative effects.

### Frontend المنفذ جزئيًا

- `ProductConfigModal` يقرأ groups/options الحقيقية بدل static fake modifiers.
- المنتج بلا modifier groups يُضاف مباشرة بعد نجاح server response وإثبات عدم وجود groups.
- cart identity أصبح يعتمد على `product.id + sorted modifier ids + note` حتى لا يندمج Single وDouble كسطر واحد.
- `sentState` أصبح يطابق line configuration عند الإمكان.
- modifier names تظهر في receipt paths التي تستخدم cart snapshot.

### Critical frontend fix ما زال مطلوبًا

`src/features/pos/pages/PosWorkspacePage.tsx` ما زال يحتوي integration قديمًا في `ProductConfigModal.onConfirm`:
- edit يستخدم `product.id` بدل `cartLineKey`.
- edit يغير qty/discount فقط ولا يستبدل modifier configuration / price / note.
- add لا يمرر explicit `modifier_option_ids` ولا `unit_price` ولا `item_note`.

الإصلاح المطلوب مباشرة:
- import `cartLineKey` من `../utils/cart`.
- عند edit: `pos.replaceCartLine(cartLineKey(configItem), item)`.
- عند add: تمرير `modifier_option_ids`, `unit_price`, `item_note` إلى `pos.addToCart(...)`.

لا تعتبر Modifier UI مكتملًا قبل إغلاق هذه النقطة واختبارها.

### مشاكل Modifier المتبقية قبل Production

1. **Open-order catalog history:** `save_product_modifiers` ما زال delete/recreate بعد validation؛ open orders التي تحمل option IDs قد تتأثر بتعديل catalog. مطلوب immutable/versioned definitions أو historical trusted composition صالح للبيع/refund.
2. **Refund exactness:** يجب إثبات/إصلاح نفس المنتج داخل نفس sale بتكوينات Modifier مختلفة مع partial refunds بحيث يرجع كل sale line مسار مخزونه الصحيح بالضبط.
3. **Sent-item cancel identity:** backend `cancel_sent_order_item` ما زال يستهدف product ID في المسار القديم؛ يجب استهداف order item/line configuration حتى لا يلتبس Single وDouble لنفس المنتج.
4. **KDS visibility:** يجب التحقق أن KDS/kitchen ticket يعرض modifier snapshot بوضوح.
5. **DB branch consistency:** إضافة hard constraints/triggers group → option → effect عند الحاجة، وليس الاعتماد على RPC فقط.
6. **Client stock precheck:** لا يجب أن يمنع البيع خطأً بناءً على base product فقط بينما modifier يغير الاستهلاك؛ الخادم يظل authoritative.
7. **Admin editor:** backend `save_product_modifiers` وحده لا يكفي؛ مطلوب واجهة إدارة modifier configuration بصلاحيات واضحة.
8. **Production migration:** Modifier migrations **لم يتم إعلان تطبيقها على Production بعد**. لا تطبقها قبل full CI green واختبارات lifecycle الدقيقة.

### Modifier lifecycle tests المطلوبة

Fixture برجر مرجعي:
- Base: bun 1 + patty 1 + cheese 1 + onion 1.
- Size required min=1/max=1: Single default، Double `+35` و`+1 patty`.
- Extras: Extra Cheese `+10` و`+1 cheese`.
- Omission: No Onion `0` و`-1 onion`.

يجب تغطية:
- branch scoped get modifiers.
- missing required option rejected.
- Single+Double rejected.
- cross-product / cross-branch option rejected.
- spoofed client price ignored.
- trusted order snapshot.
- KDS snapshot مع stock unchanged.
- exact sale stock for Double + Extra Cheese + No Onion.
- trusted totals.
- idempotent no double deduction.
- exact refund once.
- partial refunds + same product/different configs.
- catalog edit/deactivation لا يغيّر history/refund.
- RLS/helper grants.

---

## 5) قواعد معمارية ثابتة — لا تغيّرها بدون قرار صريح

- **KDS لا يخصم المخزون.** `send_to_kitchen` = state/snapshot/delta فقط.
- **البيع هو نقطة خصم المخزون**، مرة واحدة فقط.
- Refund يجب أن يعكس نفس Inventory Path الذي خصمه البيع.
- لا نثق في أسعار/إجماليات مالية قادمة من العميل؛ الخادم هو المرجع.
- لا نحذف أو نضعف RLS أو Tests لإنجاح CI.
- كل البيانات branch-scoped يجب أن تبقى معزولة Server-side.
- Public signup مغلق؛ المستخدمون/Tenant provisioning من الإدارة أو المسار الداخلي فقط.
- Internal/security/accounting/inventory helpers لا تُفتح لـ`anon` أو `authenticated` فقط لإرضاء اختبار.
- عمليات الكاشير الحساسة تمر Permission أو Manager Approval Server-side.
- لا تعرض Demo/Seed tools في Production.
- لا تضف زرًا لميزة Backend غير مكتملة.

---

## 6) Inventory الحالي ✅

Hybrid inventory هو التصميم المعتمد:
- Sellable products: **335**
  - Direct raw recipe: **196**
  - Manufactured-unit path: **52**
  - Ready products: **87**
- Internal manufactured products: **17**، ومخفية من POS كمنتجات بيع مستقلة.
- كل المنتجات القابلة للبيع لها Inventory Path: **335/335**.
- Nested manufactured units مدعومة.
- التكلفة التشغيلية تعتمد المشتريات/الدفعات الفعلية، لا تكلفة Excel ثابتة.

بيانات الاستيراد المرجعية:
- Products: **352**
- Categories: **30**
- Raw materials: **215**
- Products with recipes: **265**
- Recipe lines: **1205**
- Empty recipes: **0**

---

## 7) Security / Permissions — مغلق أساسيًا ✅

الحالة المطلوبة والمثبتة:
- `anon` بلا وصول مباشر لجداول `public`.
- الاستثناءات الضرورية قبل Login فقط: `get_login_email(text)` و`record_login_failure(text)`.
- `register_tenant` و`bootstrap_initial_super_admin` غير متاحين لـ`anon/authenticated`.
- Direct inventory mutation/internal accounting/audit/legacy KDS helpers ليست Client RPCs عامة.
- Branch isolation مغطى بـRLS/Integration tests.
- Manager Approval مغطى للعمليات الحساسة، ومنها Refund، Discount، Reprint، Cancel sent item، Change payment method، Open drawer، Force close shift.
- التسجيل العام في الواجهة محذوف.

إعداد خارجي متبقٍ وليس migration:
- **Supabase Leaked Password Protection** يحتاج تفعيلًا من Auth settings إذا كان متاحًا للحساب/الخطة.

---

## 8) User-facing UI — المراجعة الأساسية مكتملة ✅

المرجع التفصيلي: `docs/UI_VISIBILITY_AUDIT.md`

الحالة الأساسية:
- POS يعرض Counters للطلبات النشطة، Delivery، الطاولات المشغولة، وKDS.
- Discount / Hold-Resume / Send to Kitchen / Print / Pay / Table transfer ومسارات الموافقة ظاهرة حسب السياق والصلاحية.
- Approval Inbox ظاهر في Header.
- Refund وChange Payment Method ظاهرين من Sales.
- Open Drawer وForce Close Shift موجودان في Shift UI.
- Kitchen top navigation يفتح KDS الحقيقي.
- Kitchen Stations لها مدخل إداري واضح.
- Public Register UI ورابط Create Account محذوفان.
- Demo/Seed button محذوف من Super Admin.
- Placeholder `Premier Assistant — Coming soon` وعلامة `New` الوهمية محذوفان.

ميزات **غير منفذة بالكامل** وليست مجرد أزرار مخفية:
- `Split Bill`
- `Merge Tables`

لا تضف لهما UI شكليًا؛ إذا طُلبتا يجب تنفيذهما Backend + UI + tests كميزة كاملة.

---

## 9) الخطوة التالية — بالترتيب

1. انتظار/فحص نتيجة Verify main #230؛ أي failure حقيقي يُصلح بدون إضعاف الاختبار/RLS.
2. إصلاح `PosWorkspacePage.tsx` لتمرير واستبدال Modifier line configuration باستخدام `cartLineKey` و`replaceCartLine`.
3. إضافة modifier lifecycle DB integration tests الكاملة المذكورة أعلاه.
4. حل immutability/versioning للـmodifier catalog مع open orders/history.
5. تثبيت exact per-sale-item refund path للتكوينات المختلفة والـpartial refund.
6. إصلاح backend cancel sent item ليعمل على line/order_item identity، لا product ID فقط.
7. التحقق من KDS/kitchen ticket modifier rendering.
8. إضافة Admin Modifier Editor بصلاحيات مناسبة.
9. Full Verify: `verify` + `db` + `browser-smoke` = green.
10. بعدها فقط تطبيق Modifier migrations على Supabase Production والتحقق من integrity/security.
11. تحديث هذا السجل بعد كل إصلاح/نتيجة CI مهمة.
12. مراجعة `npm audit` وترقية التبعيات عالية الخطورة بشكل مدروس؛ **لا تستخدم `npm audit fix --force` عشوائيًا**.
13. تفعيل Leaked Password Protection من Supabase Auth إن أمكن.

### قاعدة تسليم لأي نموذج جديد

ابدأ من هذا الملف وليس من افتراض أن آخر commit Release-ready. فرّق دائمًا بين:
- **آخر baseline أخضر مؤكد**.
- **HEAD الحالي Work-in-progress**.

اقرأ أيضًا `docs/UI_VISIBILITY_AUDIT.md`. لا تعيد بناء أو فحص أجزاء مغلقة إلا إذا ظهر فشل CI أو Regression قابل لإعادة الإنتاج.