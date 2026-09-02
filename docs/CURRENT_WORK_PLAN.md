# CURRENT WORK PLAN — john-s

> المرجع الرئيسي لحالة العمل. يُحدّث بعد كل إصلاح أو قرار معماري أو نتيجة CI مهمة.

آخر تحديث: 2026-09-02

## 1) الحالة العامة

المشروع يعمل على `main` مع Supabase الإنتاجية.

آخر baseline مكتمل قبل إصلاح عرض تركيب المنتج:
- Verify main #45 على `4e17122a19d50a7297102f19163c033669419019`: **SUCCESS**.
- lint ✅ typecheck ✅ unit ✅ build ✅
- canonical migrations / schema ✅
- integration/security/RLS ✅
- Playwright browser smoke ✅
- Deploy #47 ✅

الإصلاح الأحدث لعرض وحدة التصنيع الخاصة بالمنتج موجود في الكود، والتحقق النهائي بعد تنظيف الأدوات المؤقتة جارٍ على `main`.

---

## 2) بيانات Excel الجديدة — مكتمل ✅

- المنتجات: **352/352**.
- الأقسام: **30/30**.
- أسماء مكررة: **0**.
- منتجات بدون قسم: **0**.
- الخامات المختلفة: **215**.
- المنتجات ذات الوصفة: **265**.
- أسطر الوصفات: **1205/1205**.
- وصفات فارغة: **0**.
- منتجات بلا وصفة في ملف المصدر: **87**.

### التكلفة
- لا نعتمد تكلفة ثابتة مستوردة من Excel.
- تكلفة الخامات تأتي من المشتريات/دفعات المخزون الفعلية.
- تكلفة المصنع تنتقل من تكلفة مكوناته الفعلية أثناء الإنتاج.

---

## 3) المصنعات / Semi-finished Components ✅

- المنتجات المصنعة الداخلية: **17**.
- `inventory_units` المصنعة: **17**.
- مخفية من POS كمنتجات بيع مستقلة.
- وصفات التصنيع الخام في `inventory_unit_recipes`.
- المنتج النهائي الذي يستهلك مصنعًا يرتبط به عبر `product_unit_links`.
- علاقات المنتج → المصنع من Excel: **52**.

### مصنع داخل مصنع ✅
Migration:
`supabase/migrations/20260901233000_nested_manufacturing_hybrid_sale_inventory.sql`

تم دعم `inventory_unit_recipe_units(parent -> component manufactured unit)`.
العلاقات الفعلية: **3**:
1. `mash side` ← `ماش مصنع .` — 0.133452 دفعة.
2. `penna white side` ← `صوص الفريدو تصنيع` — 0.062925 دفعة.
3. `rice side` ← `ارز بسمتى مصنع.` — 0.053727 دفعة.

`produce_inventory_unit` يستهلك الخامات والمصانع الفرعية FIFO، يرفض النقص قبل إتمام التصنيع، ويجمع التكلفة الفعلية في batch المصنع الناتج.

---

## 4) معمارية المخزون والبيع — Hybrid Inventory ✅

### منتج بوصفة خامات مباشرة
`Product -> recipe_items -> raw_materials`
- البيع يخصم الخامات FIFO بعد Preflight.

### منتج يستخدم مصنعًا
`Product -> product_unit_links -> manufactured inventory_unit`
- البيع يخصم المصنع من `inventory_unit_batches`.
- خامات المصنع لا تخصم مرة ثانية عند البيع لأنها خصمت وقت التصنيع.

### منتج جاهز بلا وصفة
- يخصم من `inventory_batches/inventory` الخاصة بالمنتج الجاهز.

التغطية الفعلية:
- المنتجات القابلة للبيع: **335/335** لها مسار مخزون واضح.
- وصفة خامات مباشرة: **196**.
- تستخدم مصنعًا: **52**.
- جاهزة بلا وصفة: **87**.
- خارج دورة المخزون: **0**.
- الـ17 المتبقية هي المصنعات الداخلية المخفية من POS.

---

## 5) عرض مكونات المنتج في الواجهة — مُصحح ✅

المشكلة المكتشفة:
`ProductsPage` كانت تعرض النظام القديم `product_components/product_units`، بينما بيانات التشغيل المستوردة والفعلية موجودة في `recipes/recipe_items` و`product_unit_links/inventory_units`.

تم التصحيح:
- نافذة تعديل المنتج تعرض **الخامات المباشرة الفعلية** من أحدث Recipe نشطة.
- تعرض **الوحدات المخزنية/المصنعة التي يستهلكها المنتج** من `product_unit_links`.
- تفصل ذلك عن **وحدات البيع** مثل قطعة/كرتونة.
- لا يتم نسخ البيانات إلى الجداول القديمة ولا إنشاء مخزون مكرر.

Commit الأساسي:
`481ae725a458f861a035343a85bc5dfecc849360` — `fix: show actual product recipes and inventory units`.

### وحدة التصنيع الخاصة بالمنتج
الصورة/الفحص كشف حالة `صوص بلو تشيز مصنع`:
- المنتج Manufactured داخلي.
- له وحدة تصنيع فعلية بنفس الاسم في `inventory_units`.
- لها **4 خامات تصنيع**.
- لم تكن تظهر لأن `product_unit_links` تمثل ما **يستهلكه** المنتج، وليست الوحدة التي **ينتجها** المنتج.

تم إصلاح العرض بحيث المنتج المصنع يعرض أيضًا **وحدة التصنيع الخاصة به** عند تطابق الاسم والفرع، بدون إنشاء self-link في `product_unit_links` حتى لا يستهلك المنتج نفسه.

Commit:
`8535e64fd09b4fb92eeab7a86d9d2b25a0b91ced` — `fix: show product own manufacturing unit`.

بعد الإصلاح، `صوص بلو تشيز مصنع` يجب أن يظهر له **1 وحدة مصنعة** بدل الرقم المضلل 0، بالإضافة إلى خاماته الأربع.

---

## 6) KDS والمخزون ✅

- `send_to_kitchen` State/Snapshot فقط ولا يخصم مخزونًا.
- البيع هو نقطة الخصم الفعلية مرة واحدة.
- Cancel sent item لا يعيد مخزونًا وهميًا.
- `cancel_sent_order_item` محمي Server-side ويتطلب موافقة للكاشير.

متبقي صغير:
- اختبار Delta عند زيادة كمية سطر سبق إرساله للمطبخ.

---

## 7) نظام موافقات المدير — P1

مكتمل:
- Discount approval.
- Reprint approval + `authorize_sale_print`.
- Cancel sent item approval.
- Realtime/ApprovalInbox + استهلاك الموافقة مرة واحدة.

متبقي:
1. Refund approval.
2. Change payment method approval.
3. Open drawer approval.
4. Force close shift approval.
5. Void order إذا كان له مسار مستقل.
6. Cashier/Manager E2E.
7. تحسين رسالة `REPRINT_APPROVAL_PENDING`.

---

## 8) حماية البيع — P2

مكتمل ✅:
- cashier لا يعدل `sales` مباشرة.
- `sale_items` immutable عبر RLS.
- authoritative catalog pricing Server-side مختبر.
- inventory preflight قبل mutation.
- أُغلق مسار Direct Sale fallback الذي كان يقبل subtotal/tax/total وأسعار الأسطر من العميل.
- إنشاء `sales` و`sale_items` أصبح محصورًا في `process_sale`؛ كل INSERT مباشر من authenticated مرفوض حتى للمدير.
- رفض الخادم التجاري لا يتحول إلى بيع Offline ناجح، وفشل الشبكة الغامض لا يُصفّ للبيع Offline لتجنب البيع المكرر.
- الضريبة والإجماليات تُحسب من إعدادات وأسعار الخادم، والخصومات تُقيد بحد السطر/الفاتورة.
- `paid_amount` المطبق لا يتجاوز إجمالي الفاتورة المحسوب من الخادم.
- الكميات غير الموجبة مرفوضة قبل أي كتابة، ومسار وحدات المخزون يستهلك معاملات `product_unit_links` الفعلية.

---

## 9) Products vs POS — P4

متبقي:
- Server-side product search بدل البحث في أول 100 سجل فقط.
- Pagination حقيقية مع البحث.
- توحيد branch + active conditions بين Products وPOS.
- invalidate/update Offline catalog cache بعد تغييرات المنتجات.
- اختبار تطابق الـ335 منتجًا القابل للبيع بين الصفحتين.

---

## 10) Branch visibility — P3

كل سجل branch-scoped يجب أن يعرض اسم الفرع بوضوح.
المطلوب: `BranchBadge` موحد، بدءًا من Sales/invoices/refunds/shifts ثم Products ثم المشتريات والمخزون والأطراف والتقارير والطباعة.

---

## 11) ترتيب العمل القادم

### أولوية فورية
- إغلاق Verify/Deploy لإصلاح عرض مكونات ووحدة تصنيع المنتج.

### ثم P1
- Refund → Change payment method → Open drawer → Force close shift → E2E.

### ثم P2/P3/P4
- security pricing/tax gaps.
- Branch visibility.
- Products/POS search + pagination + cache consistency.

---

## 12) قواعد ثابتة

- لا نحذف أو نضعف RLS أو الاختبارات لتجاوز فشل.
- لا نثق في بيانات العميل في العمليات المالية.
- لا ننشئ وحدات مخزون وهمية أو self-links لمجرد العرض.
- تكلفة الخامات والمصنعات تعتمد على المشتريات الفعلية.
- KDS لا يخصم المخزون؛ البيع يخصم مرة واحدة فقط.
- المصنع يمكن أن يدخل في مصنع آخر عبر `inventory_unit_recipe_units`.
- كل عملية حساسة للكاشير تمر Permission أو Manager Approval Server-side.
- كل تعديل مهم يجب أن ينعكس في هذا الملف.

---

### إصلاح Recipe الوحدات — raw_materials.cost_price ✅
- تم إصلاح `InventoryUnitsPage` الذي كان يستعلم عن العمود غير الموجود `raw_materials.cost_price`.
- قائمة الخامات تحتاج فقط `id,name`، لذلك أزيل العمود القديم من الاستعلام ومن نوع الواجهة.
- لم يتم إنشاء عمود تكلفة ثابت جديد؛ مصدر التكلفة التشغيلي يبقى المشتريات/الدفعات الفعلية وفق معمارية FIFO الحالية.
- صفحة Recipes العامة لا تعتمد `cost_price` في الاستعلام؛ تستخدم بيانات الخامة الحالية وحسابها التقديري منفصل عن تكلفة FIFO التشغيلية.

---

### تنظيف وصف وحدات التصنيع من نصوص الترحيل الداخلية ✅
- تم اكتشاف ظهور نص تقني يبدأ بـ `Manufactured component migrated from product` داخل حقل الوصف في نافذة تعديل `inventory_units`.
- تم تحديث `InventoryUnitsPage` بحيث يخفي هذا النص الداخلي القديم من حقل الوصف، مع إبقاء أي وصف حقيقي كتبه المستخدم كما هو.
- عند حفظ الوحدة بعد فتحها، يُحفظ الوصف الفعلي فقط، ويصبح الوصف فارغًا بدل النص التقني إذا لم يكتب المستخدم وصفًا جديدًا.
- لم يتم تنفيذ حذف جماعي لبيانات الترحيل من قاعدة البيانات حتى لا نفقد أي مرجع تاريخي دون داعٍ.

Commit الإصلاح:
`2e9bb33ba17580b44d806be07a8788ce4d93b468` — `fix: hide internal migration text from inventory unit description`.


---

### Branch visibility — Products + Raw Materials ✅
- تحقق إنتاجي: المنتجات **352/352** لديها `branch_id`، والخامات **215/215** لديها `branch_id`، ولا توجد سجلات بدون فرع.
- كل بيانات Excel الحالية موجودة على **فرع نادي سموحة** فقط؛ لم يتم نسخها تلقائيًا إلى الفرع الرئيسي.
- أُنشئ `BranchBadge` موحد في `src/components/BranchBadge.tsx`.
- `ProductsPage` تعرض الفرع في الجدول وداخل نافذة التعديل.
- `RawMaterialsPage` تعرض الفرع في الجدول وداخل نافذة الإضافة/التعديل.
- قائمة الخامات أصبحت تطبق `branchFilter` صراحةً.
- إنشاء/تعديل الخامة يرسل `branch_id` صراحةً، مع اختيار الفرع للمدير العام وإظهاره ثابتًا للمستخدم المحصور بفرعه.
- هذه أول شريحة مكتملة من P3؛ بقية الصفحات branch-scoped ما زالت ضمن الخطة.


---

### إصلاح TypeScript لربط الخامات بالفروع ✅
- أضيف `branch_id: string` إلى نوع `RawMaterial` في `src/lib/domains/types/manufacturing.ts` حتى يطابق مخطط قاعدة البيانات الفعلي واستخدام `RawMaterialsPage`.
- Commit: `836f128f6eacfdae06f4b353a6b3f9e8cf9b6465`.

### P3 Branch visibility — Sales / Refunds / Shifts ✅
- تم توسيع `BranchBadge` إلى صفحة المبيعات/الفواتير، وهي نفس الصفحة التي تعرض وتنفذ المرتجعات.
- استعلام `SalesPage` أصبح يجلب `branch_id` صراحةً، ويعرض اسم الفرع في كل صف.
- تم تحويل عمود الفرع في `ShiftsPage` إلى `BranchBadge` الموحد بدل النص العادي.
- Commit التطبيق: `83ea36c99615139cf3f2445f2faa504b3f06043d`.
- المكتمل في P3 حتى الآن: Products + Raw Materials + Sales/Invoices/Refund rows + Shifts.
- المتبقي في P3: Purchases/Receiving/Procurement، Inventory/Warehouses/Transfers، Users/Parties، Reports، والطباعة/المستندات التي لا تعرض الفرع بعد.


---

### P3 Branch visibility — Procurement / Inventory ✅
- baseline قبل هذه الدفعة: Verify main #66 وDeploy #68 على `bbcf76f8c60213579fc83a04b27efe680f22f143` = SUCCESS.
- تم إضافة `BranchBadge` إلى `PurchasesPage` لكل فاتورة شراء باستخدام `purchase.branch_id`.
- تم إضافة `BranchBadge` إلى جدول إيصالات الاستلام في `ReceivingPage` باستخدام `PurchaseReceiptRow.branch_id`.
- لم يتم تخمين فرع Backorders؛ نوع `PurchaseBackorderRow` الحالي لا يعيد `branch_id`، وهذه فجوة Backend يجب إغلاقها من RPC قبل إظهار الفرع للمستخدم متعدد الفروع.
- تم توحيد عرض الفرع في `WarehousesPage` و`TransfersPage` عبر `BranchBadge`.
- تم إضافة فرع واضح لكل سجل في `InventoryPage` من فرع المخزن، وإضافة اسم الفرع أيضًا إلى تصدير Excel للمخزون.
- Commit التطبيق: `388d89fc791035adb92949fd782ae356b4588fb9`.
- المكتمل في P3 حتى الآن: Products + Raw Materials + Sales/Invoices/Refund rows + Shifts + Purchases + Receiving receipts + Inventory + Warehouses + Transfers.
- المتبقي في P3: Backorders RPC branch identity، Purchase Requests/RFQs عند الحاجة، Users/Parties، Reports، والطباعة/المستندات التي لا تعرض الفرع بعد.

---

## تحديث 2026-09-02 — KDS / الموافقات / P3 ✅

### Production schema drift — مغلق ✅
- اكتُشف أن Production لا يحتوي `order_kitchen_voids` و`cancel_sent_order_item` رغم وجود Migration في المستودع.
- طُبقت Migration `cancel_sent_item_approval` على Production ثم تم التحقق من الجدول وRLS والدالة وtrigger الحماية.
- لم يتم تخطي أو إضعاف RLS لمعالجة الانحراف.

### KDS quantity delta — مكتمل على Production ✅
- Migration: `20260902051000_kitchen_quantity_delta.sql`.
- أضيف `order_kitchen_sends.sent_quantity` مع CHECK يمنع القيم السالبة.
- زيادة نفس `order_item_id` من 1 إلى 3 ترسل للمطبخ +2 فقط، بدل إعادة إرسال السطر كاملًا.
- approved kitchen void يخفض `sent_quantity` عبر `trg_sync_kitchen_sent_quantity_after_void` حتى تُحسب الزيادة التالية من صافي ما وصل للمطبخ.
- Verify main run `33570934419`: App + DB/Integration/Security/RLS + Browser Smoke = SUCCESS.
- طُبقت Migration على Production وتم التحقق من العمود والدوال والtrigger والقيد، وعدد القيم السالبة = 0.

### Manager approvals — توسعة P1 ✅
المكتمل الآن Server-side مع التدقيق:
- Discount.
- Reprint.
- Cancel sent item.
- Refund.
- Change payment method.
- Force close shift.
- Open drawer authorization/audit.

ملاحظة: فتح درج النقدية الفيزيائي يحتاج Printer/Hardware bridge؛ النظام الحالي ينجز الإذن/الموافقة/Audit ولا يدّعي إرسال نبضة Hardware بدون bridge.

المتبقي في P1: Cashier/Manager E2E شامل، تحسين `REPRINT_APPROVAL_PENDING`، وVoid order فقط إذا بقي له مسار مستقل عن cancel/refund.

### P3 Branch visibility — تقدم كبير ✅
مكتمل في الواجهات الرئيسية التالية:
- Products + Raw Materials.
- Sales / invoices / refund rows + Shifts.
- Purchases + Receipts.
- Purchase Requests + RFQs.
- Receiving Backorders: أضيف `branch_id` إلى نوع البيانات والواجهة ونافذة الاستلام.
- Inventory + Warehouses + Transfers.
- Inventory Batches + Inventory Ledger.

Migration الجديدة للـBackorders:
`20260902052000_purchase_backorders_branch_visibility.sql`
- تعيد `branch_id` من `get_purchase_backorders`.
- تحافع على branch isolation الموجود.
- تقوي SECURITY DEFINER إلى `search_path = public, pg_temp`.
- تمنع EXECUTE من `PUBLIC/anon` وتبقيه لـ`authenticated/service_role`.
- لها regression test مستقل: `purchase_backorders_branch_visibility.test.ts`.

المتبقي في P3: Users/Parties، Reports، والطباعة/المستندات التي لا يظهر فيها الفرع بوضوح، مع فحص أي صفحات مخزون فرعية أخرى قبل اعتبار P3 مغلقًا.

### الحالة التالية
- لا تُطبق Migration Backorders على Production قبل Verify أخضر على HEAD النظيف.
- بعد P3: P4 Products/POS server-side search + pagination + cache consistency ثم E2E نهائي.

---

## تحديث 2026-09-02 — Backorders Production + P3 Parties/Audit + P4 audit ✅

### Backorders branch visibility — Production ✅
- Verify main run `33572558012`: App/lint/typecheck/unit/build + DB/Integration/Security/RLS + Browser Smoke = SUCCESS.
- Deploy run `33572557921`: SUCCESS.
- طُبقت Migration `purchase_backorders_branch_visibility` على Production.
- `get_purchase_backorders(uuid)` يعيد `branch_id` فعليًا.
- الدالة `SECURITY DEFINER` مع `search_path=public, pg_temp`.
- `anon` لا يملك EXECUTE؛ `authenticated` و`service_role` فقط يملكان EXECUTE.
- واجهة Receiving تعرض BranchBadge في Backorders وفي نافذة الاستلام.

### P3 Users / Parties / Audit ✅
- Users: تم توحيد عرض الفرع باستخدام `BranchBadge`.
- Customers: أضيف BranchBadge للجدول واسم الفرع إلى Excel export.
- Suppliers: أضيف BranchBadge للجدول واسم الفرع إلى Excel export.
- Audit Log: أضيف branch filter إلى الاستعلام وعرض BranchBadge لكل سجل.
- commit الفعلي: `49b59f3611cdcd2dfd397c10a1f30906ffc6391d`.

### P4 Products/POS — نتيجة المراجعة
- `usePaginatedRows` يدعم server-side text search أصلًا.
- ProductsPage يستخدم server-side search على `name`, `name_en`, `barcode`, `sku` مع pagination حقيقي من السيرفر.
- ProductsPage يبطل POS offline catalog cache بعد تعديل/حذف المنتج.
- POS يحمل المنتجات من `products` مع `branch_id = effectiveBranch` و`is_active = true`، ويخزن نفس الكتالوج للـoffline.
- لذلك المشكلة القديمة: البحث داخل أول 100 فقط لم تعد موجودة في الكود الحالي.
- المتبقي في P4: regression coverage يثبت server-side search + تطابق branch/is_active بين Products/POS، ثم إغلاق البند إذا نجح.

### P3 المتبقي
- Reports: فلتر الفرع موجود، لكن عند اختيار “كل الفروع” بعض النتائج لا تحمل اسم الفرع؛ يحتاج إصلاحًا حقيقيًا للبيانات وليس Badge شكليًا.
- Print/documents: مراجعة أن الفرع ظاهر بوضوح في المستندات المطبوعة الأساسية.

---
## تحديث 2026-09-02 — الحالة الحالية بعد إغلاق Backorders وP3 Parties ✅

### CI / Deploy
- Verify main على `ed54f20206ce2195ccf1fd3763069a7c2135b804` اكتمل بالكامل SUCCESS: lint + typecheck + unit + build + DB migrations + schema verification + Integration/Security/RLS + Browser Smoke.
- Deploy لنفس الدفعة اكتمل SUCCESS.
- تحديث السجل السابق فشل أول مرة بسبب Base64 padding فقط، ثم تم إصلاح الأداة المؤقتة ونجح commit السجل `a9eed15c4e13143d82474ba4e54a283ea94454a3`.
- تم حذف Workflow المؤقت بعد نجاحه في commit `3ba8ed7b1ea45c9ccff57513353d75cd8dd5b4a5`.

### Backorders — Production مغلق ✅
- Migration `20260902052000_purchase_backorders_branch_visibility.sql` مطبقة على Production.
- `get_purchase_backorders(uuid)` يعيد `branch_id` فعليًا.
- الدالة `SECURITY DEFINER` مع `search_path = public, pg_temp`.
- `anon` لا يملك EXECUTE؛ التنفيذ محصور في `authenticated` و`service_role`.
- Receiving يعرض `BranchBadge` في Backorders وفي نافذة الاستلام.

### P3 Branch Visibility — المكتمل حتى الآن ✅
- Products + Raw Materials.
- Sales / invoices / refund rows + Shifts.
- Purchases + Receipts + Backorders.
- Purchase Requests + RFQs.
- Inventory + Warehouses + Transfers.
- Inventory Batches + Inventory Ledger.
- Users.
- Customers + Suppliers، مع اسم الفرع في Excel export.
- Audit Log، مع branch filter فعلي وعرض `BranchBadge`.

### P3 Reports + Print/Documents — مكتمل في المستندات الأساسية ✅
- كل تقارير التشغيل تضيف هوية الفرع الفعلية إلى الصفوف والجداول وExcel وCSV والطباعة.
- التقارير التجميعية لا تخلط طريقة الدفع أو الموظف أو المنتج أو الاستهلاك أو الأداء بين الفروع؛ التجميع أصبح داخل كل فرع.
- تقرير الربح يعرض صفًا مستقلًا لكل فرع عند اختيار «كل الفروع».
- إيصال POS يعرض اسم الفرع الفعلي، وتقارير إغلاق الوردية/Z-Report كانت تعرض الفرع بالفعل وتم تثبيت ذلك باختبار عقد.
- لا توجد مستندات طباعة مستقلة حالية لأوامر الشراء أو الاستلام؛ الصفحات الحالية تغطي العرض والتصدير فقط.
- اختبارات العقد تمنع حذف هوية الفرع من التقارير وإيصال POS وتقارير الوردية.

### P4 Products / POS — مغلق ✅
- البحث في ProductsPage أصبح Server-side بالفعل عبر `usePaginatedRows` على `name`, `name_en`, `barcode`, `sku`.
- Pagination مرتبطة بنتيجة البحث من السيرفر، وليست بحثًا داخل أول 100 فقط.
- POS يحمل المنتجات حسب `branch_id = effectiveBranch` و`is_active = true`.
- تعديلات/حذف المنتجات تبطل POS offline catalog cache.
- أضيفت اختبارات عقد P4 في commits `313c7c2182e2325d84b15e910c95dd700f779a69` و`e028764338ae6c2dab483cc46cf3104b5f33cc71` لتثبيت server-side search ونطاق كتالوج POS.
- Verify main على `e028764338ae6c2dab483cc46cf3104b5f33cc71` نجح بالكامل، وبذلك أُغلق P4.

### الأولوية التالية
1. اعتماد Cashier/Manager E2E الجديد في Verify: يغطي كل أنواع الإجراءات الحساسة، منع الموافقة الذاتية، عزل قرار المدير حسب الفرع، الاستهلاك مرة واحدة، وسجل التدقيق.
2. حسم ما إذا كان `void_order` له مسار تشغيل مستقل أو يظل نوع موافقة محجوزًا فقط.
3. استكمال P2 security audit المحدود للضرائب/الخصومات/الوحدات/الكميات.
4. Purchase UOM conversion audit قبل اعتماد E2E مشتريات حقيقي.

### تحسين تجربة موافقة إعادة الطباعة ✅
- `REPRINT_APPROVAL_PENDING` يعرض رسالة واضحة بالعربية والإنجليزية تطلب إعادة المحاولة بعد اعتماد المدير.
- فشل/انتظار الطباعة التلقائية لا يجعل عملية البيع المكتملة تظهر كأنها فشلت.
- الطباعة اليدوية تعالج الخطأ نفسه ولا تترك Promise غير معالج في الواجهة.

---

## تحديث 2026-09-02 — P2 Sale Financial Authority ✅

- أزيل مسار الكتابة المباشرة المتعدد الخطوات من `src/api/domains/pos.ts`؛ نقطة البيع Online تستدعي `process_sale` فقط.
- لا يتم تحويل `MANAGER_APPROVAL_REQUIRED` أو نقص المخزون أو انتهاء الاشتراك أو أي رفض خادم إلى نجاح Offline.
- Migration: `20260902060000_sale_financial_authority.sql` تمنع INSERT المباشر على `sales` و`sale_items` لكل مستخدم authenticated، وتحافظ على `_process_sale_core` داخليًا فقط.
- تم تقييد المبلغ المطبق `paid_amount` إلى إجمالي الخادم لمنع تضخيم حركة الوردية أو إنشاء فرق محاسبي مصطنع.
- توسع اختبار `process_sale_pricing` ليثبت تجاهل subtotal/tax/total/unit_price المزورة، حساب ضريبة 15% من الأساس الفعلي بعد الخصم، توازن القيد، وتقييد الدفع.
- أضيفت حالات رفض quantity = 0 وquantity = -1 مع إثبات عدم إنشاء فاتورة.
- عُدلت اختبارات RLS القديمة لتعكس العقد الجديد: البيع وسطور البيع RPC-only، لا Direct DML.
- التحقق المحلي: typecheck كامل ✅، 342 unit/component tests ✅، lint ✅، build ✅.
- Commit الإنتاج: `7c4513a030315ad9199abff493db07007106c948`.
- Verify main run `33577577166`: App + DB/Integration/Security/RLS + Browser Smoke = **SUCCESS**.
- Deploy run `33577577181`: **SUCCESS**.
- أُغلقت دفعة P2 المالية الأساسية بعد نجاح التحقق الكامل؛ الأولوية التالية هي Purchase UOM conversion audit ثم E2E دورة المشتريات.
