# CURRENT WORK PLAN — john-s

> **Source of Truth** لأي نموذج أو مطور يكمل العمل. اقرأ هذا الملف أولًا. لا تعِد فحص المشروع كله ولا تفتح عملًا مغلقًا بدون Regression مثبت.

آخر تحديث: **2026-09-03 — Africa/Cairo**

## 1) المشروع والحالة الحالية

- Repository: `Premieros/john-s`
- Branch: `main`
- Supabase Production: `azzdesuowpdcoflmyezn`
- آخر HEAD وظيفي أخضر قبل commit هذا السجل: `a0687ff0aba83486f4f6bbf16feb557a7f35b202`
- Verify: run `33723080777` / #339 ✅
  - lint ✅
  - typecheck ✅
  - test suites typecheck ✅
  - unit ✅
  - build ✅
  - Fresh DB / canonical migrations ✅
  - integration + security/RLS ✅
  - browser-smoke ✅
- Deploy: run `33723080770` / #341 ✅ على نفس HEAD.

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
- visibility هي read-side فقط؛ stock/accounting/write truth تعمل على 100% من الحقيقة.
- لا تفتح KDS أو مراحل مغلقة بدون Regression مثبت.
- حذف الفرع من شاشة الفروع هو Hard Delete، وليس soft delete/deactivate.

---

## 3) Production Acceptance — مغلق ✅

تم تنفيذ قبول Production ببيانات حقيقية داخل فروع QA مع مستخدمي Auth حقيقيين، ثم حذف فروع QA وآثارها.

تم التحقق من:
- شراء → مخزون → طلب → إرسال للمطبخ → بيع/محاسبة/تكلفة ضمن الحدود التي تسمح بها أدوات Production.
- `send_to_kitchen` لا يخصم المخزون.
- البيع يخصم FIFO مرة واحدة.
- KDS يعرض ما تم إرساله فعليًا.
- branch isolation والصلاحيات الأساسية.
- Dining Area لمدير الفرع مع `floor_plan.manage`.
- `payment_status` بعد settlement مغطى باختبار Integration.
- Hard Delete يزيل بيانات الفرع و`public.users` وAuth users/identities/sessions.
- لا توجد بيانات QA متبقية بعد التنظيف.

Production migrations ذات الصلة:
- `20260903051805` — `fix_branch_hard_delete_acceptance`
- `20260903054119` — `production_acceptance_regressions`
- `20260903054126` — `preserve_financial_visibility_contract`

---

## 4) Product Components + Modifiers — مغلق ✅

قواعد مثبتة:
- `product_components` هو BOM للتكلفة النظرية، وليس مصدر الخصم التشغيلي المباشر.
- الخصم التشغيلي يتم عبر `product_unit_links` / recipes / modifier inventory effects.
- Modifier pricing authoritative server-side.
- Modifier snapshots محفوظة على order/sale items.
- `send_to_kitchen` يحتفظ بالـsnapshot ولا يخصم المخزون.
- `process_sale` يطبق base inventory + modifier deltas مرة واحدة.
- Refund يعيد exact sale-item inventory snapshot نسبيًا.
- exact sent-item void لا يغير المخزون.

Production QA الأخير للمكونات/الإضافات أثبت:
- BOM: كمية 2 × تكلفة 10 = تكلفة نظرية 20 ✅
- Modifier إلزامي يرفض الاختيار الفارغ ✅
- خيار Double أضاف +30 للسعر server-side ✅
- KDS استقبل Modifier snapshot ✅
- stock بقي 50 بعد `send_to_kitchen` ✅
- إعادة send لنفس الطلب أعادت `items_sent_count=0` ✅
- خصم Modifier داخل transaction حقيقي خفّض stock من 50 إلى 46 للكمية 2، ثم ROLLBACK أعاده إلى 50 ✅
- اختبارات `modifier_burger_lifecycle.test.ts` و`modifier_exact_void_refund.test.ts` تغطي البيع والـpartial refund exact-line على Fresh DB ✅
- فرع QA الخاص بهذا الاختبار حُذف، وbranch/products/orders/modifier groups/options/effects/Auth = 0 ✅

---

## 5) Financial Visibility Policy — مغلق ومطبق ✅

- `owner` فقط يرى 100% من التاريخ المالي ضمن نطاقه.
- غير الـowner: الفترة الحديثة 100%، والتاريخ الأقدم deterministic percentage.
- Production defaults: **7 أيام / 30%**.
- لا يظهر للمستخدم المقيد أن هناك بيانات مخفية.
- `open/held` تظل مرئية تشغيليًا للمستخدم المصرح له.
- الحقيقة التشغيلية للمخزون والمحاسبة لا تدخل في sampling.
- Super Admin لديه UI لإدارة الأيام والنسبة في `/super-admin`.

Production migrations:
- `20260902184106` — `financial_visibility_sales`
- `20260902184129` — `financial_visibility_related_reads`
- `20260902184138` — `financial_visibility_reporting_invoker`
- `20260902184150` — `financial_visibility_order_history`
- `20260902194257` — `financial_visibility_admin_controls`

---

## 6) Kitchen / KDS — مغلق ✅

- modern KDS يعتمد على `order_kitchen_sends.order_item_id`.
- legacy compatibility للطلبات القديمة الفارغة فقط.
- Kitchen Stations editor لديه branch selector مستقل.
- المستخدمون وفئات المنتجات branch-specific.
- `save_kitchen_station_assignments` يحمي branch/category mismatch.
- Kitchen panel داخل POS يعرض الآن فقط الطلبات التي لها kitchen sends؛ الطلب المفتوح غير المرسل لا يتكرر داخله.

Production migrations:
- `20260902154339` — `accounting_kds_station_assignments`
- `20260902154358` — `kds_queue_legacy_compat`
- `20260902154420` — `kds_empty_legacy_order_compat`
- `20260902194308` — `kitchen_station_editor_context`

---

## 7) POS / Tables UI — مغلق ومطبق ✅

### 7.1 50 طاولة افتراضية

Repo migration:
- `supabase/migrations/20260903090000_default_50_dining_tables.sql`

Production migration:
- `20260903062933` — `default_50_dining_tables` ✅

السلوك:
- كل فرع جديد يحصل تلقائيًا على **50 طاولة**.
- الأسماء: `طاولة 01` → `طاولة 50`.
- السعة الافتراضية: 4.
- status: `vacant`.
- layout منظم 10 × 5.
- إذا لم توجد منطقة، تُنشأ `الصالة الرئيسية`.
- لا يتم حذف الطاولات المخصصة الموجودة.
- يمكن إضافة طاولة 51 وما بعدها بلا حد.
- الاختبار `tests/integration/default_dining_tables.test.ts` يثبت 50 baseline + إمكانية إضافة طاولة إضافية.

Production verification:
- الفرع الموجود فعليًا: **فرع نادي سموحة** فقط.
- dining tables = 50.
- active tables = 50.
- numbered defaults = 50.
- first = `طاولة 01`.
- last = `طاولة 50`.
- area count = 1.

### 7.2 تنظيف منطقة الطاولات

`src/features/pos/components/tables/PosTablesSidebar.tsx`:
- يعرض الطاولات فقط.
- أزيل قسم standalone active orders المكرر من نفس المنطقة.
- يبقى البحث برقم/اسم الطاولة أو رقم الطلب.
- يعرض إجمالي الطاولات وعدد المشغولة فقط.

### 7.3 تنظيف Kitchen panel

`src/features/pos/components/kitchen/KitchenPanel.tsx`:
- يعرض فقط orders التي لها `order_kitchen_sends`.
- أزيلت قائمة open orders غير المرسلة من Kitchen panel لأنها موجودة في Active Orders/POS.
- modifiers/notes/sent time محفوظة.

### 7.4 عقد Split / Merge / Transfer / Split Payment — ثابت ولا يُخلط بينها

**Split (فصل أصناف من الطلب):**
- Split لا يعني تقسيم الدفع.
- يتم تحديد صنف أو كمية من صنف داخل الطلب الحالي؛ مثال: طلب به 2 Burger يمكن فصل 1 فقط.
- وجهة الجزء المفصول يمكن أن تكون:
  - طلب سريع جديد مستقل.
  - طاولة فارغة، فيُنشأ عليها طلب جديد.
  - طاولة مشغولة، فيُضاف الجزء المفصول إلى الطلب المفتوح عليها.
- الكاشير يستطيع بدء طلب Split، لكن **لا يتم التنفيذ الفعلي قبل موافقة المدير**؛ يبقى الإجراء Pending حتى approve.
- موافقة المدير يجب أن تكون مرتبطة بنفس العملية وتُستهلك مرة واحدة فقط.
- Split لا يخصم مخزونًا، ولا يعيد إرسال الصنف إلى KDS لمجرد نقله بين الطلبات.
- إذا كان الصنف قد أُرسل إلى المطبخ، يجب الحفاظ على تاريخ/هوية kitchen send وعدم تزوير إرسال جديد.

**Merge (دمج الطلبات):**
- دمج طلب كامل في طلب آخر.
- للكاشير: يبدأ الطلب، لكن التنفيذ يظل Pending حتى موافقة المدير.
- بعد نجاح الدمج، الطلب/الطاولة المصدر تُغلق أو تُفرغ حسب العقد النهائي، بدون خصم مخزون جديد وبدون إعادة إرسال KDS.

**Transfer (نقل الطلب):**
- نقل الطلب كاملًا من طاولة إلى طاولة أخرى.
- للكاشير: يبدأ النقل، لكن التنفيذ يظل Pending حتى موافقة المدير.
- يفضّل الحفاظ على نفس `order_id` عند نقل الطلب الكامل حتى لا يتغير سجل المطبخ والتاريخ التشغيلي.
- لا خصم مخزون ولا kitchen resend بسبب النقل.

**Split Payment (تقسيم الدفع):**
- منفصل تمامًا عن Split الطلب.
- يظهر فقط داخل شاشة الدفع.
- يسمح بتقسيم إجمالي الفاتورة على أكثر من وسيلة؛ مثال: جزء Cash + جزء Card/Visa، ويمكن دعم طرق أخرى مسموحة بالنظام.
- مجموع أجزاء الدفع يجب أن يساوي إجمالي الفاتورة authoritative من الخادم.
- تنفيذ Split Payment يجب أن يمر عبر مسار البيع المركزي بحيث يحدث inventory deduction مرة واحدة فقط.
- لا يُستخدم زر Split الخاص بالأصناف كواجهة لتقسيم الدفع ولا العكس.

هذه القواعد تعتبر **عقد تشغيل POS ثابت**؛ أي تعديل لاحق يجب أن يحافظ على الفصل بين order-item split وpayment split وعلى manager approval للكاشير في Split/Merge/Transfer.

---

## 8) Branch selector / Hard Delete — مغلق ✅

Hard Delete:
- `delete_branch_cascade(uuid)` للـowner/super_admin فقط.
- لا يمكن حذف فرع الحساب الحالي.
- بيانات الفرع وحسابات Auth التابعة له تُزال.

Ghost branch fix:
- Production لا يحتوي `الفرع الرئيسي` المحذوف؛ الموجود فقط `فرع نادي سموحة`.
- سبب ظهوره كان module cache في `useBranches`.
- `notifyBranchesChanged()` يبطل cache بعد create/update/delete.
- كل mounted branch selectors تعيد fetch فور mutation.
- إذا كان الفرع المحذوف هو active branch المحلي، يتم مسح `premier_active_branch` إلى All Branches.
- لا يعتمد الحل على realtime أو stale cached row.

Production migrations السابقة:
- `20260902210800` — `branch_hard_delete`
- `20260903051805` — `fix_branch_hard_delete_acceptance`

---

## 9) Costing / Reports / Permissions — مغلق ✅

Costing:
- متوسط Food Cost لا يدخل المنتجات ذات التكلفة الصفرية في المتوسط.
- `suppliers.is_active` غير موجود ولم يعد مطلوبًا في Costing page.
- توجد بطاقة **COGS ÷ Net Sales** للحقيقة الإجمالية من المبيعات.
- `get_order_margin` و`get_costing_sales_summary` SECURITY INVOKER ويحترمان RLS.

Reports:
- selector واحد مرئي بدون تكرار.
- لا charts في صفحة التقارير الأساسية.
- filters/context في أعلى الصفحة.

Permissions UI:
- اختيار role واحد.
- search.
- grouped permissions.
- select/clear group.
- select all/clear all.
- custom global/branch roles.
- backend permission logic لم يُضعف بسبب التصميم.

---

## 10) UI / Navigation baseline — مغلق ✅

- Arabic RTL sidebar يمين الشاشة.
- fixed global Back button بعيدًا عن dashboard.
- POS product cards compact.
- product area vertical scroll يعمل.
- POS system quick navigation موجودة.
- mobile DataTable cards/header containment.
- no-cart-without-open-shift gate موجود على product click / + / modifiers / barcode.
- Browser Smoke يغطي wiring الأساسي.

---

## 11) أعمال مغلقة — لا تعِد فتحها بدون Regression مثبت

- KDS exact sends + legacy compatibility.
- Kitchen station branch/category assignment.
- Product Modifiers authoritative pricing/inventory effects.
- exact sale-item inventory snapshots / partial refund.
- exact sent-item void / mutation guards.
- open-order modifier immutability.
- manager approvals.
- accounting/treasury baseline.
- branch isolation.
- hybrid deduction/refund.
- Financial Visibility + admin controls.
- Hard Delete.
- Costing COGS/Net Sales.
- Reports de-duplication.
- Roles/Permissions UI.
- responsive/mobile work.
- 50 default tables + simplified POS tables/Kitchen panels.
- branch selector stale-cache fix.

---

## 12) ما لا يجب فعله مستقبلًا

- لا تستخدم React/CSS وحدهما كحماية مالية.
- لا تغير `process_sale` أو inventory deduction بسبب visibility.
- لا تستخدم sampling عشوائي متغير.
- لا تعرض للمستخدم المقيد أن هناك نسبة مخفية.
- لا تمنح Super Admin full financial history تلقائيًا لمجرد دوره التقني.
- لا تجعل current stock أو posting logic يعمل على sample.
- لا تعدل KDS inventory behavior بسبب UI.
- لا تعِد Hard Delete إلى soft delete أو `SET NULL` لبيانات الفرع.
- لا تجعل Kitchen panel يعرض unsent active orders مرة أخرى؛ مكانها Active Orders/POS.

---

## 13) تعريف النجاح الحالي

Checkpoint الوظيفي قبل commit السجل:
- `a0687ff0aba83486f4f6bbf16feb557a7f35b202`
- Verify `33723080777` / #339 ✅
- Deploy `33723080770` / #341 ✅
- Production migration `20260903062933 default_50_dining_tables` ✅
- Production: Samouha only + 50 active numbered tables ✅

يجب تشغيل Verify/Deploy على commit هذا السجل واعتماد نتيجته كـHEAD النهائي الجديد.

---

## 14) ملاحظات تشغيلية

- أي migration مستقبلية: Fresh DB + integration/RLS + browser-smoke أخضر قبل Production.
- لا تستخدم `npm audit fix --force` بشكل أعمى.
- مراجعة الواجهة هي code/wiring + automated browser-smoke ما لم يتم تنفيذ manual authenticated visual session صراحة.