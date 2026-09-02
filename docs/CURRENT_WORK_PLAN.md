# CURRENT WORK PLAN — john-s

> **Source of truth** لأي نموذج أو مطور يكمل العمل. اقرأ هذا الملف أولًا. لا تعِد فحص المشروع كله ولا تفتح عملًا مغلقًا بدون Regression مثبت.

آخر تحديث: **2026-09-02 — Africa/Cairo**

## 1) المشروع والحالة الحالية

- Repository: `Premieros/john-s`
- Branch: `main`
- Supabase Production project ref: `azzdesuowpdcoflmyezn`
- أحدث HEAD حالي: `0351ce7d3b8deea63ae1184adfc531d2be30f8ef`
- آخر Verify main قيد الاعتماد: run `33644778404` / #272.

### نتيجة Verify #272

- `verify` ✅ SUCCESS
  - lint ✅
  - typecheck ✅
  - unit tests ✅
  - build ✅
- `db` ❌ FAILURE
  - جميع migrations تطبقت على Fresh DB بنجاح: **159 applied, 0 skipped**.
  - Schema verification ✅:
    - Tables: 60/60
    - Functions: 65/65
    - Contract RPCs: 95/95
    - Contract tables: 55/55
  - Integration tests: **374 passed / 376**, وفشل اختباران فقط في `tests/integration/phase2_kitchen_routing.test.ts`.
- `browser-smoke` ⏭️ skipped لأن DB job فشل.

### الفشل الوحيد الحالي

الاختباران الفاشلان:
1. `get_kitchen_queue returns orders with kitchen_status sent or cooking`
2. `get_kitchen_queue includes elapsed_seconds`

الـfixture القديم ينشئ Order مباشرة بحالة:
- `status='open'`
- `kitchen_status='sent'`
- بدون `order_items`
- وبدون `order_kitchen_sends`

ثم يغيّر `orders.station='grill'` عبر `route_to_station` ويتوقع أن `get_kitchen_queue(NULL, branch_id)` يعيد الطلب.

الـRPC الحالي لا يعيد هذا الطلب القديم الفارغ، لذلك يرجع 0 rows. يجب إصلاح **التوافق الخلفي داخل `get_kitchen_queue` فقط** بدون إضعاف دقة الطلبات الحديثة أو الاختبارات.

---

## 2) قواعد معمارية ثابتة — لا تغيّرها

- KDS / `send_to_kitchen` لا يخصم المخزون؛ state/snapshot فقط.
- `process_sale` هو نقطة خصم المخزون، مرة واحدة فقط.
- Refund يعكس exact inventory path الذي خصمه البيع.
- الأسعار والإجماليات وModifier component deltas مصدرها الخادم فقط.
- لا نضعف أو نحذف أو نتخطى RLS أو الاختبارات.
- Branch isolation دائمًا server-side.
- Public registration مغلق.
- Sensitive cashier actions تحتاج permission أو manager approval.
- لا expose لـinternal/security/accounting/inventory helpers للعميل لمجرد إنجاح اختبار.
- لا Demo/Seed tools في Production UI.
- لا UI شكلي بدون Backend حقيقي.

---

## 3) Product Modifiers — مكتملة ومطبقة Production ✅

تم تنفيذ واختبار:
- Single / Double / Triple.
- Extras مثل Extra Cheese.
- Omissions مثل No Onion.
- server-owned price delta + inventory effects.
- snapshots على order/sale items.
- exact sale-item inventory snapshots.
- exact partial refund per sale item.
- exact sent-item void بواسطة `order_item_id`.
- open-order modifier immutability.
- branch consistency triggers.
- Admin Modifier Editor.
- KDS/receipt modifier display.
- Burger lifecycle integration test يمر ✅.

المigrations الخاصة بالـModifiers حتى `20260902141000_fix_order_modifier_authoritative_pricing.sql` تم تطبيقها والتحقق منها على Production سابقًا.

---

## 4) المشاكل التي أبلغ عنها المستخدم في آخر مرحلة

المستخدم أبلغ عن:
1. الحسابات لا تعمل/لا تظهر أرصدة افتتاحية أو حساب خزينة.
2. إشعارات الهاتف تظهر خارج الشاشة.
3. مكونات/Modifiers شاشة البيع كبيرة جدًا على الهاتف.
4. شاشة المطبخ لا تعرض الطلبات النشطة.
5. يريد تعيين محطات المطبخ لكل مستخدم حسب فئات المنتجات المسموح له بها.

### ما تم تنفيذه في الكود

#### Accounting / Treasury
- إضافة/إصلاح إنشاء حسابات خزينة افتراضية لكل فرع.
- إصلاح اختيار الفرع في صفحات الحسابات والخزينة حتى لا يفتح Super Admin على `all branches` ويجد الصفحة فارغة.
- توحيد صلاحيات الأرصدة الافتتاحية مع `accounts.manage` وعزل الفرع.
- تم إصلاح بيانات Production الحالية بحيث أصبح للفروع حسابات Cash + Bank موجودة.

#### Mobile / Responsive
- احتواء notifications داخل viewport واحترام safe-area.
- تصغير Product Modifier / component UI على الهاتف وتقليل المساحة المستخدمة.
- الحفاظ على touch targets وعدم إخفاء الوظائف المطلوبة.

#### KDS
- تم تحديد سبب رئيسي: `send_to_kitchen` كان يسجل الإرسال لكن لا يحدّث `kitchen_status` بصورة تجعل الـKDS يعرض الطلب كما هو متوقع.
- تم تعديل دورة الحالة وإظهار `sent / cooking / ready`.
- تم إزالة أي client-side inventory fallback من Kitchen؛ المطبخ لا يلمس المخزون.
- تم إضافة عرض modifiers/snapshots في KDS.

#### Kitchen Stations / User Routing
- إضافة ربط: **Category → Kitchen Station → Users**.
- المستخدم يرى المحطات المخصصة له فقط.
- المحطات معزولة بالفرع.
- شاشة إدارة المحطات تسمح بتحديد المستخدمين والفئات لكل محطة.

---

## 5) Migrations الجديدة تحت التحقق

المigrations الحالية بعد Modifier rollout:
- `20260902143000_accounting_kds_station_assignments.sql`
- `20260902143500_kds_queue_legacy_compat.sql`
- `20260902144000_kds_empty_legacy_order_compat.sql`

كلها **تطبقت بنجاح على Fresh CI DB** وSchema verification مر.

### مهم جدًا — Production

لا تدّعِ أن هذه الثلاث migrations مطبقة Production ما لم يتم التحقق من ذلك مباشرة بعد نجاح CI النهائي.

- إصلاح بيانات حسابات الخزينة الحالية تم على Production بالفعل.
- أما schema الخاص بتعيين المستخدمين/الفئات للمحطات وتوافق KDS الأخير فلا يُعتبر Production Live حتى:
  1. إصلاح `get_kitchen_queue`.
  2. Verify أخضر بالكامل (`verify + db + browser-smoke`).
  3. تطبيق migrations الناقصة على Supabase Production.
  4. فحص Production بعد التطبيق.

---

## 6) المهمة التالية — P0 فقط

### P0.1 إصلاح `get_kitchen_queue`

ابدأ هنا فقط. لا تعمل Full Project Audit.

المطلوب:
- راجع تعريف `get_kitchen_queue` في آخر migrations الثلاثة.
- حافظ على behavior الحديث الدقيق للطلبات التي لديها `order_items`/`order_kitchen_sends`.
- أضف legacy compatibility ضيق للطلب الذي:
  - `kitchen_status IN ('sent','cooking','ready')` حسب العقد الحالي.
  - لا يحتوي أي `order_items`.
  - لا يحتوي `order_kitchen_sends`.
- يجب أن يعود كسطر Queue واحد حتى يمر `phase2_kitchen_routing.test.ts`.
- `station` يجب أن يأتي من `orders.station` في legacy empty-order case.
- `elapsed_seconds` يجب أن يكون >= 0.
- station filtering يجب أن يظل يعمل؛ طلب station=`grill` لا يظهر عند filter=`salad`.
- لا تستخدم fake order item ولا تضف بيانات للـfixture.
- لا تعدّل الاختبار لمجرد تمريره.

### P0.2 بعد الإصلاح

شغّل/راقب Verify main حتى يصبح:
- verify ✅
- db ✅ — 376/376 أو أكثر حسب الاختبارات الحالية
- browser-smoke ✅

إذا ظهر فشل جديد: أصلح السبب الحقيقي فقط.

### P0.3 Production rollout

بعد CI أخضر فقط:
- قارن `schema_migrations` على Production بالمستودع.
- طبّق فقط migrations الناقصة بالترتيب.
- تحقق من:
  - وجود station/category/user assignment objects.
  - RLS على جداول الربط.
  - RPC permissions.
  - `get_kitchen_queue` يعمل للطلبات الحديثة.
  - الطلبات النشطة تظهر في KDS.
  - KDS لا يغيّر المخزون.
  - لكل فرع حساب Cash + Bank.

### P0.4 تحديث هذا الملف

بعد النجاح حدث `docs/CURRENT_WORK_PLAN.md` مع:
- HEAD النهائي.
- Verify run النهائي.
- Deploy run النهائي.
- Production migrations المطبقة فعلًا.
- نتائج فحص KDS/accounting/treasury.

---

## 7) لا تعِد فتح هذه الأعمال إلا عند Regression مثبت

- Modifier pricing/security/refund lifecycle.
- exact sent-item void.
- Burger lifecycle.
- branch isolation baseline.
- manager approval lifecycle.
- hybrid inventory deduction/refund baseline.
- shared responsive modal/table work.

---

## 8) ملاحظات تشغيلية

- npm install ما زال يبلغ عن 3 vulnerabilities (1 moderate, 2 high). لا تشغّل `npm audit fix --force` بشكل أعمى.
- Supabase Leaked Password Protection قد يحتاج Dashboard setting حسب الخطة.
- لا تطبق Production DB changes قبل CI أخضر إذا كانت migration جديدة غير مثبتة.

---

## 9) تعريف النجاح للمرحلة الحالية

المرحلة الحالية تعتبر منتهية فقط عند تحقق الآتي كله:

1. `phase2_kitchen_routing.test.ts` أخضر بالكامل.
2. Verify main: `verify + db + browser-smoke` كلها SUCCESS.
3. Deploy SUCCESS على نفس HEAD.
4. migrations الجديدة مطبقة ومثبتة على Supabase Production.
5. KDS يعرض الطلبات النشطة فعليًا.
6. user/category station assignments موجودة وتعمل بعزل الفرع.
7. صفحات الحسابات والخزينة تفتح على فرع صالح وتعرض الحسابات.
8. لكل فرع Cash + Bank treasury accounts.
9. الهاتف لا يعاني page-level overflow في notifications وPOS modifier dialog.
10. هذا السجل محدث بالنتيجة النهائية.
