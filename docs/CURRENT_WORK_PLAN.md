# CURRENT WORK PLAN — john-s

> **Source of truth** لأي نموذج أو مطور يكمل العمل. اقرأ هذا الملف أولًا. لا تعِد فحص المشروع كله ولا تفتح عملًا مغلقًا بدون Regression مثبت.

آخر تحديث: **2026-09-02 — Africa/Cairo**

## 1) المشروع والحالة الحالية

- Repository: `Premieros/john-s`
- Branch: `main`
- Supabase Production project ref: `azzdesuowpdcoflmyezn`
- آخر HEAD للكود الذي أُغلق عليه إصلاح KDS: `29e837d607278248d90cd56068e87031f188c254`
- Verify: run `33648538552` / #275 ✅
  - verify ✅
  - db ✅
  - browser-smoke ✅
- Deploy: run `33648538560` / #277 ✅ على نفس HEAD.

> هذا الملف نفسه تم تحديثه بعد إغلاق Production rollout، لذلك يجب اعتماد commit هذا التحديث كـHEAD النهائي بعد نجاح Verify/Deploy الناتجين عنه.

---

## 2) المرحلة التي أُغلقت الآن — KDS legacy compatibility ✅

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

قبل التطبيق تمت مقارنة سجل Production؛ كان آخر migration موجودًا هو `fix_order_modifier_authoritative_pricing` ولم تكن migrations التالية مسجلة.

تم تطبيقها بالترتيب على Supabase Production `azzdesuowpdcoflmyezn` ثم إعادة قراءة migration history والتأكد من تسجيلها فعليًا:

1. `accounting_kds_station_assignments` ✅
2. `kds_queue_legacy_compat` ✅
3. `kds_empty_legacy_order_compat` ✅

سجل Production بعد التطبيق يحتوي عليها بإصدارات Supabase المسجلة:
- `20260902154339` — `accounting_kds_station_assignments`
- `20260902154358` — `kds_queue_legacy_compat`
- `20260902154420` — `kds_empty_legacy_order_compat`

---

## 4) Production verification بعد التطبيق ✅

تم تنفيذ فحص read-only بعد migrations وكانت النتيجة:

- `get_kitchen_queue(text,uuid)` موجود ✅
- يدعم `sent / cooking / ready` حسب العقد ✅
- المسار الحديث يحتوي exact join على `order_kitchen_sends.order_item_id` ✅
- legacy empty-order guard موجود ✅
- `get_my_kitchen_stations` يطبق user/station assignment filter ✅
- `send_to_kitchen(uuid,uuid)` لا يحتوي مسار خصم مخزون ✅
- assignment branch mismatches: `0` ✅
- category → station orphan references: `0` ✅
- عدد الفروع: `2`
- عدد Treasury accounts: `4`
- الفروع الناقصة Cash أو Bank: `0` ✅
- عدد Chart of Accounts: `54` ✅
- Kitchen station assignments الحالية: `0`
- Categories المربوطة حاليًا بمحطة: `0`
- لا توجد طلبات KDS نشطة (`sent/cooking/ready`) وقت الفحص، لذلك تم التحقق من contract/function/schema وليس من عرض طلب حي فعلي في Production.

عدم وجود assignments أو routed categories حاليًا هو **حالة بيانات** وليس فشل schema؛ الربط والبنية والقيود موجودة.

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

---

## 7) ما تبقى بعد إغلاق هذه المرحلة

لا يوجد إصلاح KDS مفتوح حاليًا.

قبل بدء أي مرحلة جديدة:
1. انتظر Verify وDeploy الخاصين بآخر commit لتحديث هذا الملف، ويجب أن يكونا أخضرين على نفس HEAD.
2. لا تبدأ Full Project Audit.
3. ابدأ فقط من ملاحظة مستخدم جديدة أو Regression مثبت.

فحص طلب KDS حي في Production لا يمكن إثباته حاليًا لأن قاعدة البيانات لا تحتوي وقت الفحص أي order نشط بحالة `sent/cooking/ready`. لا تنشئ بيانات وهمية في Production فقط لإثبات ذلك.

---

## 8) ملاحظات تشغيلية

- npm install سبق أن أبلغ عن 3 vulnerabilities (1 moderate, 2 high). لا تشغّل `npm audit fix --force` بشكل أعمى.
- Supabase Leaked Password Protection قد يحتاج Dashboard setting حسب الخطة.
- لا تطبق Production DB changes مستقبلًا قبل CI أخضر لأي migration جديدة.

---

## 9) تعريف النجاح لهذه المرحلة

أُنجز فعليًا:
- `phase2_kitchen_routing.test.ts` أخضر ✅
- Verify `verify + db + browser-smoke` SUCCESS ✅
- Deploy SUCCESS على نفس HEAD ✅
- migrations الثلاث الجديدة مطبقة ومثبتة Production ✅
- station/category/user schema + branch consistency verified ✅
- KDS inventory-neutral verified ✅
- كل فرع لديه Cash + Bank ✅
- accounting/treasury data objects غير فارغة ✅
- Source of Truth محدث ✅

المتبقي الإجرائي الوحيد لهذه المرحلة: نجاح CI/Deploy الخاصين بcommit تحديث هذا الملف نفسه، ثم اعتماد ذلك commit كـHEAD النهائي.
