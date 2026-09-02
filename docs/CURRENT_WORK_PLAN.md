# CURRENT WORK PLAN — john-s

> **Source of truth** لأي نموذج أو مطور يكمل العمل. اقرأ هذا الملف أولًا، ولا تعِد فتح عمل مغلق إلا عند Regression مثبت.

آخر تحديث: **2026-09-02 — Africa/Cairo**

## 1) الحالة الحالية

- Repository: `Premieros/john-s`
- Branch: `main`
- Supabase Production: `azzdesuowpdcoflmyezn`
- آخر HEAD أخضر مؤكد بالكامل قبل آخر hardening: `094912179eda690107cf52c472c9fe05a1e5a317`
- Verify main run `33621976412`: **SUCCESS**
  - lint ✅
  - typecheck + all suites ✅
  - unit ✅
  - build ✅
  - Fresh DB migrations/schema ✅
  - Integration + Security/RLS ✅
  - Browser Smoke ✅
  - Responsive browser tests ✅
- Deploy run `33621976435`: **SUCCESS**

### HEAD الأحدث تحت التحقق

- آخر hardening قبل الإصلاح الحالي: `120f174b8b9841e76e0f41c41c0ff403375f0a40`.
- Verify main #245 / run `33623071027`: **FAILURE** بسبب اختبار واحد فقط في DB integration:
  - `372/373` integration tests نجحت.
  - `modifier_exact_void_refund.test.ts` اكتشف أن `authenticated` كان ما زال يملك EXECUTE على helper الداخلي `guard_sent_order_item_mutation()`.
  - `verify` كان SUCCESS، وFresh DB migrations + schema verification نجحت، و`browser-smoke` تم تخطيه لأن DB job فشل.
- الإصلاح الحالي: commit `70d7d06bd78b991842abdb31b4cabbf9a1f35d85`.
- Migration الجديدة: `20260902135000_lock_sent_order_item_mutation_guard.sql`.
- الإصلاح يسحب EXECUTE على `guard_sent_order_item_mutation()` من `PUBLIC / anon / authenticated` ويتركه داخليًا لـ`service_role` فقط.
- Verify main #246 / run `33623521362`: **قيد التشغيل** وقت هذا التحديث. لا تعتبر HEAD الحالي release-green قبل نجاح `verify + db + browser-smoke`.

---

## 2) قواعد معمارية ثابتة

- KDS / `send_to_kitchen` لا يخصم المخزون؛ state/snapshot فقط.
- `process_sale` هو نقطة خصم المخزون، مرة واحدة فقط.
- Refund يعكس نفس inventory path الذي خصمه البيع.
- الخادم هو مصدر الحقيقة للسعر والإجماليات وModifier component deltas.
- لا نضعف RLS أو الاختبارات لإصلاح CI.
- Branch isolation دائمًا server-side.
- Public registration مغلق.
- Sensitive cashier actions تحتاج permission أو manager approval.
- Internal/security/accounting/inventory helpers لا تُفتح للعميل لمجرد إنجاح اختبار.
- لا Demo/Seed tools في Production.
- لا UI شكلي لميزة Backend غير مكتملة.

---

## 3) دورة التشغيل الأساسية — مثبتة ✅

`tests/integration/pos_operational_lifecycle.test.ts` يغطي:

`cashier login → open shift → create order → KDS → sale → inventory deduction → refund approval → refund restore → approval consumed once → close shift`

مثبت:
- server-owned pricing.
- KDS stock unchanged.
- sale deduction مرة واحدة.
- cashier refund blocked قبل approval.
- manager approval يعمل ويُستهلك مرة واحدة.
- hybrid refund يعيد المخزون.
- shift close يعمل.

Production migration المطبق والمؤكد:
`20260902084000_refund_hybrid_inventory_restoration.sql` ✅

---

## 4) Product Modifiers / Variants

الهدف: Burger ونحوه يدعم تكوينات حقيقية مرتبطة بالمكونات:
- Required Size: Single / Double / Triple.
- Extras: Extra Cheese / Bacon / Sauce / Jalapeño.
- Omissions: No Onion / No Pickles / No Sauce.
- كل اختيار له server-owned `price_delta` وinventory effect.

### Backend المنفذ

1. `20260902085000_product_modifiers_inventory.sql`
   - `product_modifier_groups`
   - `product_modifier_options`
   - `product_modifier_inventory_effects`
   - snapshots على `order_items` و`sale_items`
   - `get_product_modifiers`
   - `resolve_product_modifiers`
   - `save_product_modifiers`
   - trusted modifier-aware sale deduction.

2. `20260902121500_product_modifiers_atomic_security_hardening.sql`
   - validate-before-delete atomic save.
   - inventory effects غير مكشوفة مباشرة لـauthenticated.
   - strict target validation.

3. `20260902086000_modifier_sale_item_inventory_snapshot.sql`
   - `sale_item_inventory_effects` لكل `sale_item_id`.
   - sale يسجل بالضبط raw/unit/product quantities التي استهلكها كل سطر.
   - refund line-aware يعيد snapshot الخاص بنفس sale item بنسبة partial refund.
   - يمنع خلط نفس المنتج إذا بيع بتكوينات مختلفة.

4. `20260902130000_product_modifier_branch_consistency.sql`
   - DB triggers تفرض group branch = product branch.
   - option branch = group branch.
   - effect target branch = option/effect branch.
   - trigger helpers private.

5. `20260902133000_modifier_open_order_immutability.sql`
   - يمنع حذف Modifier option مستخدم في `open/held order_items`.
   - يمنع تغيير group/branch له أثناء وجود طلب مفتوح.
   - يمنع `save_product_modifiers` delete/recreate من كسر الطلبات المفتوحة؛ العملية ستفشل atomically بدل إفساد IDs.

6. `20260902132000_cancel_sent_item_exact_line.sql`
   - RPC جديد `cancel_sent_order_item_exact(order_id, order_item_id, qty, reason)`.
   - يستهدف `order_item_id` المحدد، وليس product فقط.
   - manager approval مربوط بالسطر نفسه وsnapshot modifiers.
   - لا يغيّر المخزون.

7. `20260902134000_legacy_sent_void_ambiguity_guard.sql`
   - يحمي clients القديمة التي ما زالت تستخدم `cancel_sent_order_item(product_id)`.
   - إذا كان للمنتج أكثر من sent line مثل Single + Double، يرجع `AMBIGUOUS_SENT_ITEM` ولا يختار سطرًا عشوائيًا.
   - يمنع إلغاء التكوين الخطأ حتى يكتمل UI cutover للـexact RPC.

8. `20260902135000_lock_sent_order_item_mutation_guard.sql`
   - يقفل helper الداخلي `guard_sent_order_item_mutation()` عن `authenticated` و`anon` و`PUBLIC`.
   - العميل يظل يستخدم RPCs العامة فقط؛ الـhelper لا يصبح client API.
   - أضيف لإغلاق آخر فشل مثبت في Verify #245 دون إضعاف الاختبار أو RLS.

### Frontend المنفذ

- `ProductConfigModal` يستخدم groups/options الحقيقية.
- لا توجد static fake modifiers.
- Required min/max/defaults enforced in UI، والخادم يعيد التحقق.
- Simple product بدون groups يُضاف مباشرة فقط بعد successful server response.
- `cartLineKey = product + sorted modifier ids + note`.
- Single وDouble لنفس المنتج لا يندمجان.
- `PosWorkspacePage` تم إصلاحه:
  - edit يستخدم `replaceCartLine(cartLineKey(configItem), item)`.
  - add يمرر modifier IDs + unit price display + item note.
  - sent/unsent matching أصبح line-configuration aware.
- `ProductConfigModal` responsive:
  - Phone bottom sheet / `100dvh` / safe area / touch targets.
  - Tablet/Desktop centered dialog.
- POS Kitchen panel يعرض `modifiers_snapshot` والملاحظات من order history.
- Receipt display يحمل أسماء modifiers.

### Tests المضافة

- `tests/unit/pos/cartModifierIdentity.test.ts`
  - Single ≠ Double.
  - modifier ordering normalized.
  - notes جزء من identity.
  - payload يحافظ على IDs/notes.

- `tests/e2e/responsive-shell.spec.ts`
  - 360×800 phone.
  - 768×1024 tablet portrait.
  - 1024×768 tablet landscape.
  - 1366×768 browser.
  - no page-level horizontal overflow + RTL shell.

- `tests/integration/product_modifiers_security.test.ts`
- `tests/integration/product_modifier_branch_consistency.test.ts`
- `tests/integration/modifier_exact_void_refund.test.ts`
  - exact order-item void contract.
  - no inventory mutation in KDS void.
  - per-sale-item inventory snapshots.
  - line-aware proportional refund helper.
  - `process_refund` passes concrete sale item id.
  - public exact RPC available لـauthenticated، والـinternal mutation guard غير متاح للعميل.
- `tests/integration/modifier_open_order_immutability.test.ts`

---

## 5) Inventory baseline

Hybrid inventory معتمد:
- Sellable products: **335**
  - Direct raw recipe: **196**
  - Manufactured-unit path: **52**
  - Ready: **87**
- Internal manufactured hidden: **17**
- Inventory path: **335/335**.

Reference import:
- Products **352**
- Categories **30**
- Raw materials **215**
- Products with recipes **265**
- Recipe lines **1205**

---

## 6) Security baseline

- `anon` بلا direct table access.
- pre-login RPCs الضرورية فقط حسب baseline.
- internal inventory/accounting/security helpers غير client RPCs.
- RLS branch isolation covered by integration tests.
- manager approval covers sensitive POS actions.
- public registration UI removed.

خارجي فقط:
- Supabase Leaked Password Protection يحتاج Dashboard setting إذا متاح بالخطة.

---

## 7) Responsive / Device compatibility

المعيار: `docs/RESPONSIVE_UI_STANDARD.md`.

الهدف الثابت:
- small phones from ~320px.
- modern phones.
- tablets portrait/landscape.
- laptop/browser.
- desktop/POS screens 1920+.
- Arabic RTL + English LTR.
- Modals/tables/sidebar/header/POS touch-friendly.

Browser regression proof موجود للمقاسات الأساسية، وHEAD `094912...` مر به كاملًا بنجاح.

---

## 8) المتبقي قبل Modifier Production rollout

### P0 — يجب إغلاقه

1. **Frontend exact sent-void cutover:**
   - `usePosOrder.voidSentItem` ما زال يستدعي legacy `cancel_sent_order_item(product_id)`.
   - backend exact RPC جاهز، والlegacy آمن ويرفض ambiguity.
   - المطلوب تمرير exact `order_item_id` من `orderItemsForActive` ثم استدعاء `cancel_sent_order_item_exact`.
   - لا يوجد خطر إلغاء Single بدل Double بعد ambiguity guard، لكن UX لن ينفذ الإلغاء في حالة متعددة حتى cutover.

2. **Admin Modifier Editor:**
   - backend `save_product_modifiers` موجود.
   - لم يُثبت وجود UI إداري كامل لإضافة groups/options/effects من Products.
   - يجب توفير user-facing editor قبل اعتبار الميزة قابلة للإدارة من النظام نفسه.

3. **Latest CI:**
   - Verify #245 فشل فقط بسبب exposed internal guard وتم إصلاحه في `20260902135000_lock_sent_order_item_mutation_guard.sql`.
   - انتظر Verify #246؛ يلزم نجاح `verify + db + browser-smoke` قبل Production rollout.

### P1 — زيادة الإثبات قبل Production

4. إضافة seeded transactional integration لبرجر فعلي:
   - Single + Double لنفس product في sale واحدة.
   - Extra Cheese + No Onion.
   - KDS stock unchanged.
   - exact final component deduction.
   - partial refund لكل line وإثبات restoration exact.

5. التحقق من standalone KDS page/kitchen ticket أنه يعرض modifier snapshot، وليس فقط POS Kitchen panel.

6. Client stock precheck ما زال base-product oriented؛ لا يجب الاعتماد عليه كمرجع. Server remains authoritative. تحسينه لاحقًا لمنع false block/allow.

---

## 9) Production migration status

**مطبق Production:**
- hybrid refund baseline `20260902084000_refund_hybrid_inventory_restoration.sql` ✅

**غير مؤكد/غير مطبق Production حتى الآن — لا تدّعِ عكس ذلك:**
- `20260902085000_product_modifiers_inventory.sql`
- `20260902086000_modifier_sale_item_inventory_snapshot.sql`
- `20260902121500_product_modifiers_atomic_security_hardening.sql`
- `20260902130000_product_modifier_branch_consistency.sql`
- `20260902132000_cancel_sent_item_exact_line.sql`
- `20260902133000_modifier_open_order_immutability.sql`
- `20260902134000_legacy_sent_void_ambiguity_guard.sql`
- `20260902135000_lock_sent_order_item_mutation_guard.sql`

لا تطبق Modifier migrations على Production إلا بعد:
1. latest full CI green.
2. exact sent-void frontend cutover أو قرار واضح بالإبقاء على ambiguity-safe legacy behavior مؤقتًا.
3. seeded modifier lifecycle proof.
4. التأكد من user-facing configuration path.

---

## 10) أعمال غير مكتملة أصلًا وليست Regression

- Split Bill.
- Merge Tables.

لا تضف لهما أزرارًا وهمية؛ يلزم Backend + UI + tests عند طلب التنفيذ.

### قاعدة التسليم

ابدأ من هذا السجل. لا تعِد مراجعة أجزاء مغلقة بدون سبب. افصل دائمًا بين:
- **آخر HEAD أخضر مؤكد**.
- **HEAD أحدث تحت CI**.
- **ما طُبق Production فعليًا**.
