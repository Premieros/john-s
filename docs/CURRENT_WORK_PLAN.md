# CURRENT WORK PLAN — john-s

> المرجع الرئيسي لحالة العمل. يُحدّث بعد كل إصلاح أو قرار معماري أو نتيجة CI مهمة.

آخر تحديث: 2026-09-01

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

مكتمل:
- cashier لا يعدل `sales` مباشرة.
- `sale_items` immutable عبر RLS.
- authoritative catalog pricing Server-side مختبر.
- inventory preflight قبل mutation.

متبقي Audit محدود لـ:
- tax tampering.
- discount combinations.
- unit/quantity combinations.
- أي مسار بديل قد يقبل subtotal/total من العميل.

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
