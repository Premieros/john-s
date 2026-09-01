# CURRENT WORK PLAN — john-s

> المرجع الرئيسي لحالة العمل. يُحدّث بعد كل إصلاح أو قرار معماري أو نتيجة CI مهمة.

آخر تحديث: 2026-09-01

## 1) الحالة العامة

المشروع يعمل على `main` مع قاعدة Supabase الإنتاجية.

آخر baseline كود مكتمل التحقق قبل تحديث هذا السجل:
- Commit: `853d43fad4e2e7296da985cd61643d0fe6c829ce`
- Verify main #40: **SUCCESS**
- lint ✅
- typecheck ✅
- full test typecheck ✅
- unit tests ✅
- build ✅
- canonical migrations ✅
- schema verification ✅
- integration/security/RLS: **334/334 ✅**
- Playwright browser smoke ✅

قاعدة ثابتة: لا نعتبر أي مسار مكتملًا قبل نجاح الكود + DB + الاختبارات + smoke المناسب.

---

## 2) بيانات Excel الجديدة — مكتمل ✅

المصادر:
- `Document النادى(1).xls` — المنتجات والأسعار والأقسام.
- `sales recipe(2)(1).xlsx` — وصفات المنتجات والمكونات.

الحالة الفعلية في الإنتاج:
- المنتجات: **352/352**.
- الأقسام: **30/30**.
- أسماء المنتجات المكررة: **0**.
- منتجات بدون قسم: **0**.
- الخامات/المكونات المختلفة: **215**.
- المنتجات ذات الوصفة: **265**.
- أسطر الوصفات: **1205/1205**.
- الوصفات الفارغة: **0**.
- المنتجات بدون وصفة في ملف الوصفات: **87**.

### التكلفة
- لم تُستورد تكلفة ثابتة من Excel.
- `products.cost_price` و`raw_materials.default_cost` لم يُستخدما كمصدر تكلفة نهائي.
- مصدر التكلفة التشغيلي هو **المشتريات ودفعات المخزون الفعلية**.
- التصنيع يأخذ تكلفة الخامات من FIFO/تكلفة الشراء الفعلية ويرحّلها إلى تكلفة الوحدة المصنعة.

---

## 3) المصنعات / Semi-finished Components — مكتمل معماريًا ✅

تم تحويل قسم `تصنيعات` إلى مكونات مصنعة داخلية:
- المنتجات المصنعة الداخلية: **17**.
- `inventory_units` المصنعة: **17**.
- جميعها مخفية من POS كمنتجات بيع مستقلة.
- الوصفات الخام للمصنعات محفوظة في `inventory_unit_recipes`.
- المنتجات النهائية التي تستخدم مصنعًا ترتبط به عبر `product_unit_links`.
- علاقات المنتج النهائي → المصنع الموجودة من ملف Excel: **52**.

### مصنع داخل مصنع — تم دعمه رسميًا ✅

Migration:
`supabase/migrations/20260901233000_nested_manufacturing_hybrid_sale_inventory.sql`

تم إنشاء:
`inventory_unit_recipe_units(parent unit -> manufactured component unit)`

العلاقات الفعلية المكتشفة والمحوّلة في الإنتاج: **3**
1. `mash side` ← `ماش مصنع .` — **0.133452 دفعة**.
2. `penna white side` ← `صوص الفريدو تصنيع` — **0.062925 دفعة**.
3. `rice side` ← `ارز بسمتى مصنع.` — **0.053727 دفعة**.

تم حذف الـraw placeholder المقابل من وصفة المصنع الأعلى عند التحويل، لمنع الخصم المزدوج.

### سلوك `produce_inventory_unit`
- يرفض كمية تصنيع <= 0.
- يرفض التصنيع عند نقص الخامات.
- يرفض التصنيع عند نقص المصنع الفرعي المطلوب.
- يستهلك الخامات الأساسية من FIFO.
- يستهلك المصنع الفرعي من `inventory_unit_batches` بنظام FIFO.
- يسجل `production_consumption` للوحدات المصنعة المستهلكة.
- يجمع تكلفة الخامات + تكلفة المصنع الفرعي.
- ينشئ batch للمصنع الناتج بالتكلفة المجمعة.
- يحدث تكلفة `inventory_unit` والمنتج المصنع المطابق.

اختبار مباشر:
`tests/integration/nested_manufactured_units.test.ts`
يثبت خامة → مصنع أول → مصنع ثان + انتقال التكلفة وخصم كمية المصنع الأول.

---

## 4) معمارية المخزون والبيع — القرار النهائي الحالي ✅

تم إلغاء الفكرة القديمة التي تقول إن كل منتج يجب أن يملك `inventory_unit/product_unit_link` صناعيًا لمجرد السماح بالبيع؛ ذلك كان سيكرر المخزون ويخلق وحدات وهمية للخامات.

المسار المعتمد أصبح **Hybrid Inventory**:

### أ) منتج له خامات مباشرة في وصفته
`Product -> recipe_items -> raw_materials`

عند البيع:
- تُجمع الكميات المطلوبة حسب الوصفة.
- يتم Preflight للمخزون كاملًا قبل أي خصم.
- الخصم يتم من `raw_material_inventory/raw_material_batches` FIFO.
- التكلفة تأتي من دفعات الشراء الفعلية.

### ب) منتج يستخدم مصنعًا
`Product -> product_unit_links -> manufactured inventory_unit`

عند البيع:
- يخصم نسبة المصنع المطلوبة من `inventory_unit_batches` FIFO.
- لا يعاد خصم خامات المصنع مرة ثانية؛ خاماته خُصمت وقت التصنيع.

إذا كان نفس المنتج له خامات مباشرة + مصنع، يخصم الاثنين معًا بدون Double Deduction.

### ج) منتج جاهز/مُشترى وليس له وصفة
عند البيع:
- يستخدم مخزون المنتج الجاهز الحالي `inventory_batches/inventory`.
- لا يتم إنشاء inventory unit مكرر له فقط لإرضاء شرط تقني.

### تغطية المنتجات الفعلية في الإنتاج
المنتجات القابلة للبيع: **335/335 مصنفة بمسار مخزون واضح**:
- وصفة خامات مباشرة: **196**.
- تستخدم مكونات مصنعة عبر unit links: **52**.
- منتجات جاهزة بلا وصفة: **87**.
- غير مصنف/خارج دورة المخزون: **0**.

الـ17 المتبقية من أصل 352 هي المصنعات الداخلية المخفية من POS.

---

## 5) KDS والمخزون ✅

المعمارية المعتمدة:
- `send_to_kitchen` = State/Snapshot فقط.
- لا يوجد خصم مخزون عند إرسال KDS.
- `order_kitchen_sends` يمنع تكرار الإرسال لنفس السطر.
- الخصم الحقيقي يحدث مرة واحدة عند البيع.
- إلغاء صنف تم إرساله للمطبخ لا يعيد مخزونًا لأن KDS لم يخصم مخزونًا أصلًا.

### Cancel sent item
تم:
- إزالة مسار زيادة المخزون الوهمية.
- إضافة `cancel_sent_order_item` Server-side.
- cashier يحتاج موافقة `cancel_sent_item`.
- منع خفض/حذف sent item عبر تجاوز `update_order`.
- تسجيل الإلغاء/السبب/المستخدم.
- اختبار أن cancel لا يغير المخزون.

متبقي صغير في KDS:
- اختبار/مراجعة زيادة كمية سطر سبق إرساله مع الحفاظ على نفس `order_item_id` والتأكد أن Delta الجديد يصل للمطبخ بصورة صحيحة.

---

## 6) نظام موافقات المدير — P1

### مكتمل ✅
- `approval_requests`.
- إنشاء/قبول/رفض/استهلاك الموافقة مرة واحدة.
- منع self-approval.
- Realtime + `ApprovalInbox`.
- خصم cashier بموافقة Server-side.
- إعادة الطباعة بموافقة Server-side عبر `authorize_sale_print`.
- `sale_print_events`.
- Cancel sent item بموافقة Server-side.

### متبقي
1. Refund approval integration.
2. Change payment method approval.
3. Open drawer approval.
4. Force close shift approval.
5. Void order إذا كان له مسار فعلي مستقل.
6. Cashier/Manager E2E كامل لهذه العمليات.
7. تحسين رسالة `REPRINT_APPROVAL_PENDING` في UI.

---

## 7) حماية البيع ومكافحة التلاعب

مكتمل:
- cashier لا يعدّل `sales` مباشرة.
- `sale_items` immutable مباشرة عبر RLS.
- خصومات cashier تمر بالموافقة.
- authoritative pricing موجود ومختبر: سعر الكتالوج Server-side هو المعتمد وليس السعر المزور القادم من العميل.
- مسار خصم المخزون الآن يعمل Preflight قبل mutation للمصنع/الخامات/المنتج الجاهز.

### P2 المتبقي
Audit صغير فقط للفجوات الحقيقية:
- tax tampering.
- discount combinations.
- unit/quantity combinations.
- التأكد أن total/subtotal النهائيين لا يمكن التلاعب بهما في أي مسار بديل.

---

## 8) Products vs POS — P4

المشكلة ما زالت قائمة في الواجهة:
- `ProductsPage` يحمل أول 100 منتج فقط في الصفحة الأولى.
- البحث Client-side على البيانات المحملة.
- POS يجلب جميع المنتجات النشطة للفرع.
- لذلك يمكن أن يظهر منتج في POS ولا يظهر في نتائج بحث Products قبل Load More.

المطلوب:
- Server-side search.
- Pagination حقيقية مع البحث.
- توحيد branch + active conditions بين POS وProducts.
- invalidate/update Offline catalog cache بعد create/edit/deactivate/delete.
- اختبار تطابق الـ335 منتجًا القابل للبيع بين Products وPOS لنفس الفرع.

---

## 9) إظهار الفرع بجانب كل سجل — P3

القرار:
كل سجل branch-scoped يجب أن يعرض **اسم الفرع** بوضوح، وليس UUID أو مجرد فلترة داخلية.

المطلوب:
- `BranchBadge` مشترك.
- Sales / invoices / refunds / shifts أولًا.
- Products.
- Purchases / Receiving / RFQs / Purchase Requests / Expenses.
- Inventory / Counts / Batches / Valuation / Waste / Transfers.
- Customers / Suppliers / Employees / Users عندما تكون branch-scoped.
- Tables / Dining Areas / Kitchen Stations.
- Reports / Audit / Approvals / Excel / PDF / print.

لا يضاف BranchBadge لكيان global على مستوى المؤسسة إذا لم يكن branch-scoped معماريًا.

---

## 10) ترتيب العمل القادم

### P1 — أولوية مباشرة
- Refund approval.
- Change payment method.
- Open drawer.
- Force close shift.
- E2E cashier/manager.

### P2
- إغلاق أي pricing/tax tampering gaps حقيقية فقط.

### P3
- Branch visibility standard.

### P4
- Products/POS server-side search + pagination + cache consistency.

### P5
- التقارير والتصدير والطباعة وبقية تحسينات التشغيل.

---

## 11) قواعد ثابتة

- لا نحذف أو نضعف RLS أو الاختبارات لتجاوز فشل.
- لا نثق في بيانات العميل في العمليات المالية الحساسة.
- لا نخلق وحدات مخزون وهمية أو مخزونًا مزدوجًا فقط لتجاوز شرط تقني.
- تكلفة الخامات والمصنعات تعتمد على المشتريات الفعلية.
- KDS لا يخصم المخزون؛ البيع يخصم مرة واحدة فقط.
- المصنع يمكن أن يدخل في مصنع آخر عبر `inventory_unit_recipe_units`.
- كل عملية حساسة للكاشير: Permission أو Manager Approval على الخادم.
- كل تعديل مهم يجب أن ينعكس في هذا الملف.
