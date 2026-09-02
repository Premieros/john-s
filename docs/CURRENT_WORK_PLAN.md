# CURRENT WORK PLAN — john-s

> **Source of truth** لأي نموذج أو مطور يكمل العمل. اقرأ هذا الملف أولًا. لا تعِد فحص المشروع كله ولا تفتح عملًا مغلقًا بدون Regression مثبت.

آخر تحديث: **2026-09-02 — Africa/Cairo**

## 1) المشروع والحالة الحالية

- Repository: `Premieros/john-s`
- Branch: `main`
- Supabase Production project ref: `azzdesuowpdcoflmyezn`
- آخر HEAD أخضر قبل تحديث هذا السجل: `5d4d52ea57bad5b48049dabfe1fa49fcea218c9b`
- Verify: run `33661763731` / #287 ✅
  - lint ✅
  - typecheck ✅
  - unit ✅
  - build ✅
  - db / integration / security / RLS ✅
  - browser-smoke ✅
- Deploy: run `33661763678` / #289 ✅ على نفس HEAD.

> بعد هذا التحديث يجب اعتماد commit تحديث السجل نفسه كـHEAD النهائي السابق، بعد نجاح Verify/Deploy عليه، قبل بدء المرحلة الجديدة.

---

## 2) KDS legacy compatibility — مغلق ✅

تم إصلاح `get_kitchen_queue()` للتوافق الضيق مع fixture/طلب قديم بالشكل التالي فقط:
- `status IN ('open','held')`
- `kitchen_status IN ('sent','cooking','ready')`
- لا يوجد `order_items`.
- لا يوجد `order_kitchen_sends`.
- `station` يؤخذ من `orders.station`.
- `elapsed_seconds >= 0`.
- station filtering ما زال دقيقًا.

الطلبات الحديثة لم تُضعف: المسار الحديث يعتمد على `order_kitchen_sends.order_item_id` ويعرض العناصر المرسلة فعليًا فقط.

سبب آخر فشل CI كان أن auth stub في Fresh DB يترك `auth.uid()` أثناء `SET ROLE service_role`. تم السماح فقط للـPostgreSQL `service_role` الموثوق به داخل RPC المقيد أصلًا بـEXECUTE، باستخدام `current_setting('role', true) = 'service_role'`. لم يتم توسيع bypass لأي role آخر ولم تتغير RLS policies.

---

## 3) Production migrations — مطبقة ومتحقق منها ✅

تم تطبيقها بالترتيب على Supabase Production `azzdesuowpdcoflmyezn`:

1. `accounting_kds_station_assignments` ✅
2. `kds_queue_legacy_compat` ✅
3. `kds_empty_legacy_order_compat` ✅

سجل Production:
- `20260902154339` — `accounting_kds_station_assignments`
- `20260902154358` — `kds_queue_legacy_compat`
- `20260902154420` — `kds_empty_legacy_order_compat`

---

## 4) Production verification — KDS/accounting baseline ✅

- `get_kitchen_queue(text,uuid)` موجود ✅
- exact modern send join موجود ✅
- legacy empty-order guard موجود ✅
- `get_my_kitchen_stations` assignment filter موجود ✅
- `send_to_kitchen(uuid,uuid)` لا يخصم المخزون ✅
- assignment branch mismatches: `0` ✅
- category → station orphan references: `0` ✅
- عدد الفروع: `2`
- Treasury accounts: `4`
- الفروع الناقصة Cash أو Bank: `0` ✅
- Chart of Accounts: `54` ✅

عدم وجود active KDS orders وقت الفحص كان حالة بيانات فقط، ولم يتم إنشاء بيانات وهمية في Production.

---

## 5) قواعد معمارية ثابتة — لا تغيّرها

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
- لا تغيّر حقيقة المخزون/المحاسبة لمجرد تغيير ما يراه المستخدم؛ أي visibility policy يجب أن تكون read-side فقط وتظل العمليات الداخلية تعمل على 100% من الحقيقة.

---

## 6) أعمال مغلقة — لا تعِد فتحها بدون Regression مثبت

- Product Modifiers: Single / Double / Triple / Extras / Omissions.
- server-owned modifier pricing and inventory effects.
- exact sale-item inventory snapshots / exact partial refund.
- exact sent-item void.
- open-order modifier immutability.
- Burger lifecycle.
- accounting/treasury bootstrap الحالي.
- Cash + Bank لكل فرع.
- mobile notifications containment.
- mobile Modifier/Components sizing.
- KDS active-state contract.
- Kitchen Stations schema + Category → Station → User linkage.
- branch isolation baseline.
- manager approval lifecycle.
- hybrid inventory deduction/refund baseline.
- shared responsive modal/table work.
- mobile DataTable cards + header/branch-menu containment.
- POS product-grid density + product-area vertical scroll containment.
- POS system quick navigation buttons.
- POS primary tables/active-orders workspace enlargement.
- POS active non-table orders visible while `open/held`.
- Reports page de-duplication and active-report-first layout.
- global fixed Back button in application header.
- POS cart guard: no product/cart addition without an open shift.
- Browser Smoke fixture updated to model an open shift for normal POS sale scenarios; application guard was not weakened.

---

## 7) آخر UI/POS rollout — مغلق ✅

التعديلات الأخيرة نُشرت واختُبرت على `main` وتشمل:

1. **Mobile responsiveness**
   - DataTable cards على الهاتف.
   - احتواء الهيدر وقائمة اختيار الفرع داخل viewport.

2. **POS layout**
   - بطاقات منتجات أصغر ومساحة عرض أكثر كفاءة.
   - إصلاح scroll الداخلي لمنطقة المنتجات.
   - أزرار تنقل سريعة للنظام بدون تغيير permissions.
   - تكبير منطقة الطاولات/الطلبات النشطة.
   - عرض الطلبات غير المرتبطة بطاولة وهي `open/held` حتى الدفع/الإغلاق.

3. **Reports UX**
   - التقرير النشط وبياناته تظهر أولًا.
   - إزالة التكرار المرئي لاختيار التقرير.
   - الحفاظ على عقود navigation/deep-link المطلوبة للاختبارات بدون إعادة الازدحام للواجهة.

4. **Global navigation**
   - زر رجوع ثابت في الهيدر العام؛ RTL/LTR صحيح.

5. **Shift enforcement**
   - ممنوع إضافة منتج للسلة بدون شفت مفتوح، بما يشمل الضغط على المنتج، `+`، modifiers والباركود.
   - شرط التطبيق بقي كما هو؛ تم تعديل fixture الاختبار فقط لتمثيل شفت مفتوح في سيناريوهات البيع الطبيعية.

آخر تحقق كامل قبل تحديث السجل:
- HEAD `5d4d52ea57bad5b48049dabfe1fa49fcea218c9b`
- Verify `33661763731 / #287` ✅
- Deploy `33661763678 / #289` ✅

---

## 8) المرحلة الجديدة المفتوحة — Financial Visibility Policy

طلب المستخدم الجديد:

- المستخدم الذي يملك صلاحية **Owner** فقط يرى 100% من المبيعات التاريخية ضمن نطاق فروعه.
- أي مستخدم آخر داخل الفرع يرى:
  - آخر **7 أيام = 100%**.
  - ما قبل ذلك = **30% ثابتة deterministic** من المبيعات، لا تتغير بين كل فتح وآخر.
- المستخدم غير الـOwner لا يجب أن تظهر له أي إشارة بأن هناك بيانات مخفية أو نسبة رؤية.
- العلاقات التابعة لبيع مخفي يجب ألا تكشف البيع الأصل: items/payments/refunds/discounts/voids/employee/product/payment-method aggregates وغيرها.
- Dashboard / Reports / exports يجب أن تحسب أرقام المستخدم من نفس مجموعة البيانات المسموح بها فقط.
- المخزون، التكلفة، المحاسبة، الخصم والاسترجاع داخليًا تستمر على **100% من البيانات الحقيقية**؛ السياسة تخص القراءة/الرؤية فقط.
- التنفيذ يجب أن يكون **server-side أولًا** ولا يعتمد على React/CSS كحماية.

### ترتيب التنفيذ الإلزامي

1. حصر نقاط قراءة المبيعات الحالية فقط، بدون Full Project Audit.
2. تحديد primitive واحدة مركزية لامتلاك full financial history، مبنية على permission/owner semantics الحالية.
3. بناء deterministic visibility primitive للـSale/Order root.
4. تطبيقها أولًا على read APIs/RPCs الرئيسية للمبيعات والعلاقات التابعة.
5. إضافة negative tests: owner 100%، non-owner آخر 7 أيام 100%، والقديم deterministic 30%، وعدم وجود bypass عبر REST/RPC.
6. بعد CI أخضر فقط: ربط Reports/Dashboard/Export بنفس السياسة.
7. لا يتم تطبيق migration على Production قبل Fresh DB + integration/RLS + browser-smoke الأخضر.

---

## 9) ما لا يجب فعله في المرحلة الجديدة

- لا تخفِ صفوفًا فقط في React.
- لا تغيّر `process_sale` أو inventory deduction بسبب visibility.
- لا تحذف بيانات أو تعدل إجماليات أصلية في قاعدة البيانات.
- لا تستخدم sampling عشوائي يتغير بين الطلبات.
- لا تعرض للمستخدم نصوصًا مثل `30%`, `limited`, `hidden sales`.
- لا تمنح Super Admin تلقائيًا full financial history إلا إذا كانت owner/permission semantics الحالية تقتضي ذلك صراحة؛ يجب أولًا قراءة نموذج الصلاحيات الحالي قبل القرار.
- لا تفتح KDS أو مراحل مغلقة إلا مع Regression مثبت.

---

## 10) تعريف النجاح للمرحلة السابقة

مكتمل:
- lint ✅
- typecheck ✅
- unit ✅
- build ✅
- Fresh DB / migrations ✅
- integration/security/RLS ✅
- browser-smoke ✅
- Deploy ✅
- POS shift guard محفوظ ✅
- Source of Truth محدث بهذا السجل ✅

الإجراء التالي: انتظر نجاح Verify/Deploy على commit تحديث هذا الملف، ثم ابدأ `Financial Visibility Policy` فقط.

---

## 11) ملاحظات تشغيلية

- npm install سبق أن أبلغ عن 3 vulnerabilities (1 moderate, 2 high). لا تشغّل `npm audit fix --force` بشكل أعمى.
- Supabase Leaked Password Protection قد يحتاج Dashboard setting حسب الخطة.
- لا تطبق Production DB changes مستقبلًا قبل CI أخضر لأي migration جديدة.
