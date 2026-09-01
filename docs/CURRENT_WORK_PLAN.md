# CURRENT WORK PLAN — john-s

> المرجع الرئيسي لحالة العمل. يجب تحديث هذا الملف بعد كل إصلاح أو قرار مهم أو نتيجة CI حتى لا تضيع الحالة بين الجلسات.

آخر تحديث: 2026-09-01

## 1) نظام موافقات المدير

الحالة: **قيد التنفيذ — الأساس + الخصم + إعادة الطباعة مكتملان، وباقي العمليات الحساسة قيد الربط**.

### مكتمل
- جدول `approval_requests` مع الحالات pending / approved / rejected / expired / consumed.
- الإجراءات المسجلة: discount, reprint, void_order, cancel_sent_item, refund, open_drawer, change_payment_method, force_close_shift.
- `request_manager_approval` لإنشاء الطلب.
- `decide_manager_approval` للموافقة/الرفض.
- `consume_manager_approval` لاستهلاك الموافقة مرة واحدة.
- منع الموافقة الذاتية.
- `approvals.review` للمدير/المالك/Super Admin.
- Realtime لطلبات الموافقات.
- `ApprovalInbox` للمدير.
- `CashierDiscountApprovalCard` للكاشير.
- الخصم للكاشير مربوط بموافقة Server-side في `process_sale`.
- إزالة `pos.reprint` من cashier.
- `sale_print_events` + `authorize_sale_print`.
- **إعادة الطباعة أصبحت مرتبطة فعلياً بمسار الإيصال** في `src/features/pos/utils/printing.ts` — commit `ee5acdc4a3415de6ed63d6c7219899abece939d4`.
  - أول طباعة تسجل وتسمح بالطباعة.
  - إعادة الطباعة لمن يملك `pos.reprint` تمر مباشرة.
  - الكاشير يرسل له النظام طلب موافقة reprint تلقائياً ويمنع الطباعة لحين الموافقة.
  - بعد الموافقة، المحاولة التالية تستهلك الموافقة مرة واحدة ثم تطبع.
- Verify main #25 لربط إعادة الطباعة: lint ✅ typecheck ✅ unit ✅ build ✅ DB/integration/RLS ✅ browser smoke ✅.

### متبقي في P1
- Refund approval integration.
- Cancel sent item approval.
- Open drawer approval.
- Change payment method approval.
- Force close shift approval.
- Void order عند الحاجة.
- Cashier/Manager E2E كامل للعمليات السابقة.
- تحسين رسالة UI الخاصة بحالة `REPRINT_APPROVAL_PENDING` بحيث تظهر للمستخدم بوضوح بدل الاعتماد على الخطأ العام.

---

## 2) ملاحظة حرجة مكتشفة أثناء P1 — إلغاء صنف مرسل للمطبخ

الحالة: **يجب إصلاحها قبل ربط الموافقة**.

الكود الحالي في `usePosOrder.ts` داخل `voidSentItem` يزيد كمية جدول `inventory` عند إلغاء صنف سبق إرساله للمطبخ، ويسجل `pos_void_restore`.

هذا غير صحيح بعد تثبيت المعمارية الحالية لأن:
- `send_to_kitchen` أصبح state-only.
- إرسال KDS لا يخصم المخزون.
- الخصم الحقيقي يتم مرة واحدة فقط عند البيع عبر `process_sale` / `inventory_units`.

النتيجة المحتملة من المسار القديم: **إنشاء مخزون وهمي عند إلغاء صنف مرسل للمطبخ**.

### خطة الإصلاح المعتمدة
1. إزالة أي استرجاع/زيادة للمخزون من `voidSentItem`.
2. جعل الإلغاء State/KDS action فقط قبل البيع.
3. إضافة بوابة Server-side لخفض/إلغاء السطر المرسل.
4. cashier يحتاج approved `cancel_sent_item`; المدير صاحب الصلاحية يستطيع التنفيذ مباشرة.
5. منع تجاوز الواجهة عبر `update_order` لتقليل/حذف سطر sent بدون المسار المصرح.
6. تسجيل الإلغاء والسبب والمستخدم والموافقة في audit/KDS history.
7. اختبار أن المخزون لا يتغير عند send أو cancel sent item، ويتغير مرة واحدة فقط عند sale.
8. تحديث نص `VoidItemModal` القديم الذي يقول إن KDS خصم المخزون.

ملاحظة إضافية للمراجعة: زيادة كمية سطر سبق إرساله للمطبخ مع الحفاظ على نفس `order_item_id` قد لا تُرسل Delta جديداً إلى KDS؛ يجب إضافة اختبار لهذه الحالة قبل إغلاق دورة KDS بالكامل.

---

## 3) حماية البيع ومكافحة التلاعب

مكتمل:
- منع cashier من تعديل `sales` مباشرة.
- منع UPDATE/DELETE المباشر على `sale_items`.
- خصم cashier يحتاج موافقة دقيقة.
- اختبارات RLS محدثة للحماية الجديدة.
- اختبارات `process_sale` تعمل بهوية مستخدم مصادق عليه ولا يوجد bypass إنتاجي لـ `AUTH_REQUIRED`.
- authoritative pricing موجود ومختبر: اختبار `process_sale_pricing` يثبت أن سعر العميل المزور لا يعتمد عليه وأن سعر الكتالوج هو الذي يسجل.

### مراجعة P2
البند القديم الذي كان يقول إن authoritative pricing غير موجود أصبح متقادماً. قبل أي تطوير جديد في P2 يجب عمل Audit صغير لما يحسبه `031_process_sale_pricing.sql` وما غطته الاختبارات، ثم إضافة اختبارات tampering فقط للفجوات الحقيقية المتبقية مثل tax/discount/unit combinations إن وجدت.

---

## 4) KDS والمخزون

الحالة الحالية المعتمدة:
- `send_to_kitchen` = State/Snapshot فقط.
- `order_kitchen_sends` يسجل السطور المرسلة ويمنع التكرار.
- `069_resume_order_kitchen_incremental.sql` يحافظ على `order_item_id` للسطر المطابق حتى لا يعاد إرسال نفس السطر.
- المخزون لا يخصم عند KDS.
- المخزون يخصم مرة واحدة عند البيع من `inventory_units`.
- لا يتم حذف legacy inventory/manufacturing objects بدون audit اعتماديات كامل.

---

## 5) CI / GitHub Actions

### P0 — مغلق ✅
آخر baseline أخضر قبل P1:
- Verify main #24 — commit `91391c4bf9d6181101719fc44234cbb94b7cb5f2` — SUCCESS.
- lint ✅
- typecheck ✅
- unit tests ✅
- build ✅
- canonical migrations ✅
- schema verification ✅
- integration/security/RLS ✅
- Playwright browser smoke ✅
- GitHub Pages deploy ✅

### P1 reprint checkpoint ✅
- Commit `ee5acdc4a3415de6ed63d6c7219899abece939d4`.
- Verify main #25: SUCCESS على verify + DB + browser smoke.

قاعدة ثابتة: لا نعتبر أي مرحلة مكتملة قبل lint + typecheck + tests + DB verification + browser smoke، ولا نضعف RLS أو نحذف/نتخطى اختبارات لإجبار CI على النجاح.

---

## 6) إظهار الفرع بجانب كل سجل — P3

القرار المعتمد:
> أي سجل مرتبط بفرع يجب أن يعرض اسم الفرع بوضوح في القوائم والتفاصيل والفواتير والطباعة والتقارير، وليس فقط تطبيق `branch_id` داخلياً.

الخطة:
- إنشاء `BranchBadge` موحد.
- جلب `branch:branches(id,name)` حيث يلزم.
- Sales/invoices/refunds/shifts أولاً.
- Products ثانياً.
- Purchases/Receiving/RFQs/Purchase Requests/Expenses.
- Inventory/Counts/Batches/Valuation/Waste/Transfers.
- Customers/Suppliers/Employees/Users إذا كانت branch-scoped.
- Tables/Dining Areas/Kitchen Stations.
- Reports/Audit/Approvals/Excel/PDF/printed documents.
- لا نضيف branch للكيانات العامة على مستوى المؤسسة إذا كانت معمارياً مشتركة.

---

## 7) Products vs POS — P4

المشكلة المؤكدة:
- `ProductsPage` يحمل أول 100 سجل عبر `usePaginatedRows`.
- البحث الحالي Client-side على السجلات المحملة فقط.
- POS يسحب جميع المنتجات النشطة للفرع.
- لذلك قد يظهر منتج في POS ولا يظهر/لا يُبحث عنه في ProductsPage قبل Load More.
- Offline cache في POS يحتاج مراجعة عند تعديل/تعطيل/حذف المنتجات.

الخطة:
- Server-side product search.
- Pagination حقيقية مع البحث.
- توحيد branch + active rules بين POS وProducts.
- cache invalidation بعد product mutations.
- اختبار أن أي منتج قابل للبيع في POS يمكن العثور عليه وإدارته من ProductsPage لنفس الفرع.

---

## 8) ترتيب العمل القادم

### P1 — جاري الآن
1. ✅ Reprint approval integration.
2. **Cancel sent item: إصلاح زيادة المخزون الوهمية + Server-side approval gate + tests.**
3. Refund approval integration.
4. Change payment method approval.
5. Open drawer approval.
6. Force close shift approval.
7. Void order إذا كان له مسار فعلي مستقل.
8. Cashier/Manager E2E.

### P2
- Audit authoritative pricing الموجود فعلياً وإغلاق أي gaps حقيقية فقط.

### P3
- Branch visibility standard على كل الصفحات والسجلات.

### P4
- Products/POS consistency + search + cache.

### P5
- بقية الصفحات والتقارير والتصدير والطباعة.

---

## 9) قواعد ثابتة أثناء التطوير

- لا نحذف أو نضعف RLS أو الاختبارات.
- لا نثق في بيانات العميل في العمليات المالية الحساسة.
- كل عملية حساسة للكاشير: ممنوعة أو Permission/Approval Server-side.
- لا نعالج عرض UI فوق مسار DB خاطئ؛ نصحح المصدر أولاً.
- لا نضيف تغييرات جانبية أثناء إصلاح CI واحد.
- كل finding/قرار/إصلاح مهم يجب أن ينعكس في هذا الملف.
- لا نعلن أي ميزة مكتملة إلا بعد الكود + DB + tests + تشغيل فعلي مناسب.

---

## 10) استيراد بيانات Excel الجديدة — مكتمل للكتالوج والوصفات ✅

المصدران المعتمدان في 2026-09-01:
- ملف المنتجات والأسعار والأقسام `Document النادى(1).xls`.
- ملف الوصفات والمكونات `sales recipe(2)(1).xlsx`.

النتيجة المحققة في قاعدة البيانات:
- المنتجات: **352/352**.
- الأقسام: **30/30**.
- لا توجد أسماء منتجات مكررة.
- لا يوجد منتج بدون قسم.
- جميع المنتجات الـ352 مرتبطة بالفرع المستهدف.
- الخامات/المكونات المختلفة: **215**.
- الوصفات: **265**.
- أسطر مكونات الوصفات: **1205/1205**.
- الوصفات الفارغة: **0**.
- المنتجات التي لها وصفة: **265**.
- المنتجات بدون وصفة في ملف الوصفات: **87**، وهذا يعكس أن ملف الوصفات لا يحتوي وصفة لكل منتج في الكتالوج.

ملاحظات التكلفة:
- `products.cost_price` بقي 0 عند الاستيراد عمداً؛ لم يتم نسخ تكلفة ثابتة من Excel.
- `raw_materials.default_cost` بقي 0 عمداً.
- لا توجد مشتريات حالياً، لذلك التكلفة الفعلية ستظل 0 إلى أن تسجل مشتريات.
- `process_purchase` يحدث تكلفة المنتجات المشتراة كمتوسط مرجح، بينما تكلفة الوصفة تقرأ تكلفة الخامات من مخزون/دفعات المشتريات؛ لذلك مصدر التكلفة المعتمد هو **المشتريات** وليس ملف Excel.

ملاحظات الأسعار:
- 25 منتجاً سعر بيعها 0 في البيانات المستوردة؛ 17 منها تقريباً من قسم `تصنيعات` وهي عناصر داخلية، والبقية عناصر كتالوج مثل بعض Cocktail/Dessert. يجب مراجعة هذه الأسعار من المصدر قبل اعتبارها مشكلة لأن الاستيراد لم يختلق أسعاراً غير موجودة.

متبقي بعد استيراد البيانات:
- اختبار واجهة Products/POS على الـ352 منتجاً بالكامل، خصوصاً بسبب حد Pagination الحالي 100 في ProductsPage.
- معالجة P4 server-side search حتى يمكن إيجاد أي منتج دون Load More.
- قبل أول بيع فعلي يجب مراجعة عقد `inventory_units/product_unit_links` لأن النظام الحالي يشترط وحدات مخزون لكل منتج قابل للبيع.

---

## 11) تحويل قسم تصنيعات إلى Manufactured Components — منفذ ✅

القرار المعتمد:
> عناصر قسم `تصنيعات` ليست منتجات بيع عادية؛ هي مكونات نصف مصنعة لها وصفاتها ومخزونها ويمكن أن تدخل كمكوّن داخل منتج نهائي.

تم في قاعدة الإنتاج:
- تحويل **17/17** عنصرًا في قسم `تصنيعات` إلى `products.product_type = manufactured`.
- تعطيل ظهور المنتجات الـ17 في POS (`is_active = false`) مع بقاء وحدات التصنيع نفسها فعالة.
- إنشاء **17 inventory_units** من النوع `manufactured`.
- نسخ وصفات التصنيع إلى `inventory_unit_recipes`: **71 سطرًا**.
- اكتشاف المصنعّات المستخدمة فعليًا داخل وصفات منتجات أخرى وربطها عبر `product_unit_links` و`product_components`.
- العلاقات الحالية: **52 علاقة** منتج نهائي → مكوّن مصنع.
- عدد المصنعّات المستخدمة فعليًا في المنتجات النهائية حسب ملف الوصفات: **6**؛ باقي المصنعّات لها وصفة تصنيع لكنها غير مستخدمة كمكوّن في منتج نهائي بالملف الحالي.
- تم منع استخدام الكمية الخام مثل `100 gr` باعتبارها 100 دفعة؛ وحدة المخزون للمصنع هي **دفعة وصفة واحدة**، واستهلاك المنتج النهائي يُسجل كنسبة من الدفعة.
- مثال تحقق: 100 جم من `صوص الفريدو تصنيع` أصبحت تقريبًا `0.0787` من دفعة الصوص بدل 100 وحدة.
- تم تصحيح حالات kg→gram الحرجة في مراجع المصنعّات (مثل 0.16 kg أرز → 160 g) قبل حساب نسب الدفعات.

التكلفة:
- أضيف migration: `supabase/migrations/20260901224500_manufactured_unit_purchase_cost.sql`.
- commit: `4e7e401302dfc3be3ca3dc36f410a7bc715c1efb`.
- `produce_inventory_unit` لم يعد يعتمد على `raw_materials.default_cost` كأساس؛ يستخدم `_raw_wavg_cost` المشتق من دفعات المشتريات.
- بعد التصنيع يتم تحديث `inventory_units.cost_price` وتكلفة المنتج المصنع المقابل.
- بذلك المسار المقصود للتكلفة هو: **سعر شراء الخامة → متوسط تكلفة الخامة → تكلفة دفعة المصنع → تكلفة المنتج الذي يستهلك المصنع**.

تحقق البيانات بعد التحويل:
- manufactured products المخفية عن POS: **17**.
- manufactured inventory units الفعالة: **17**.
- manufactured recipe rows: **71**.
- product_unit_links: **52**.
- product_components: **52**.
- علاقات بكمية <=0 أو >=1 بعد تحويلها لنسبة دفعة: **0**.

متبقي قبل أول دورة تشغيل فعلية كاملة:
- تسجيل مشتريات حقيقية للخامات حتى تصبح تكلفتها > 0.
- تنفيذ عملية تصنيع فعلية تجريبية لوحدة مصنعة والتحقق من خصم الخامات وتكوين batch وتكلفته.
- اختبار بيع منتج يستخدم مصنعًا والتأكد من خصم نسبة الدفعة الصحيحة مرة واحدة.
- المصنع `ماش مصنع .` يدخل حاليًا في `mash side` (مصنع داخل مصنع). البنية الحالية لـ`inventory_unit_recipes` تدعم خامة→مصنع، لكنها لا تدعم رسميًا مصنع→مصنع متداخل؛ يلزم قرار/امتداد مخصص إذا أردنا تشغيل هذا المستوى كتسلسل تصنيع فعلي بدل إبقائه كمرجع وصفة فقط.
