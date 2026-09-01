# CURRENT WORK PLAN — john-s

> مرجع العمل الحالي للمشروع. يجب تحديث هذا الملف بعد كل إصلاح أو قرار مهم حتى لا تضيع الحالة بين الجلسات.

آخر تحديث: 2026-09-01

## 1) الحالة الحالية

### أ. نظام موافقات المدير

الحالة: **مطبق جزئياً — الأساس جاهز لكن التكامل الكامل لم ينتهِ بعد**.

تم إنجازه:
- جدول `approval_requests`.
- إنشاء طلب موافقة من الكاشير عبر `request_manager_approval`.
- قبول/رفض الطلب عبر `decide_manager_approval`.
- استهلاك الموافقة مرة واحدة عبر `consume_manager_approval`.
- منع الموافقة الذاتية.
- صلاحية `approvals.review` للمدير/المالك/Super Admin على مستوى قاعدة البيانات.
- Realtime لطلبات الموافقات.
- Inbox للمدير: `src/components/ApprovalInbox.tsx`.
- بطاقة طلب خصم الكاشير: `src/features/pos/components/checkout/CashierDiscountApprovalCard.tsx`.
- تشديد صلاحيات الكاشير في `usePosPermissions.ts`.
- خصم البيع للكاشير يحتاج موافقة على مستوى `process_sale`.
- إزالة `pos.reprint` من الكاشير.
- إنشاء `authorize_sale_print` وتسجيل `sale_print_events`.

متبقي:
- ربط `authorize_sale_print` فعلياً بزر/مسار طباعة الفاتورة قبل أي إعادة طباعة.
- ربط الموافقات بالعمليات الفعلية التالية:
  - refund
  - cancel sent item
  - open drawer
  - change payment method
  - force close shift
  - void order عند الحاجة
- اختبار E2E كامل بحساب Cashier فعلي + Manager فعلي.
- التأكد من نجاح CI النهائي بعد آخر تعديل لـ `CashierDiscountApprovalCard`.

ممنوع اعتبار نظام الموافقات "مكتمل بالكامل" قبل إنهاء البنود السابقة.

---

## 2) حماية البيع ومكافحة التلاعب

تم:
- منع الكاشير من الخصم المباشر من الواجهة.
- منع تحديث `sale_items` مباشرة.
- تقييد تحديث `sales` للمدير/الصلاحيات المناسبة.
- خصم الكاشير مربوط بموافقة مع مطابقة النوع والقيمة والإجمالي الفرعي.

أولوية حرجة متبقية:
- **إعادة احتساب الأسعار و subtotal / total على الخادم** بدلاً من الثقة الكاملة في القيم القادمة من العميل.
- التحقق من سعر كل منتج ووحدة من قاعدة البيانات داخل مسار البيع.
- رفض أي اختلاف غير مصرح به بين سعر العميل والسعر الرسمي.

هذا البند أعلى أولوية أمنية بعد إغلاق تكامل الموافقات.

---

## 3) إظهار الفرع بجانب كل سجل

القرار المعتمد:
> أي سجل مرتبط بفرع يجب أن يعرض اسم الفرع للمستخدم بوضوح في القوائم والتفاصيل والطباعة والتقارير، وليس فقط الاعتماد على فلترة `branch_id` داخلياً.

### الموجود حالياً
- العزل حسب الفرع موجود في صفحات كثيرة باستخدام `useBranchFilter()`.
- بعض الصفحات مثل `WarehousesPage` تجلب `branch:branches(*)` وتعرض عمود الفرع بالفعل.
- التطبيق غير موحد على بقية الصفحات.

### المطلوب
إنشاء معيار موحد:
- مكوّن `BranchBadge` أو equivalent موحد.
- عرض اسم الفرع وليس UUID.
- الاستعلامات التي تحتاج الفرع تستخدم مثلاً:
  - `branch:branches(id,name)`
- إظهار الفرع في:
  - صفوف الجداول.
  - نوافذ التفاصيل.
  - رأس الفواتير والمستندات.
  - الطباعة.
  - Excel/PDF.

### ترتيب التنفيذ
1. Sales / invoices / refunds / shifts.
2. Products.
3. Purchases / receiving / RFQs / purchase requests / expenses.
4. Inventory / batches / stock counts / valuation / waste / transfers.
5. Customers / suppliers / employees / users عند كونها branch-scoped.
6. Tables / dining areas / kitchen stations.
7. Reports / audit log / approval requests / printed documents.

ملاحظة:
- لا نضيف الفرع للكيانات العامة على مستوى المؤسسة إذا كانت معمارياً غير مرتبطة بفرع.
- أي سجل يفترض أن يكون branch-scoped لكنه بدون `branch_id` يجب اعتباره مشكلة بيانات/تصميم ومراجعته.

---

## 4) مشكلة اختلاف منتجات POS عن صفحة المنتجات

المشكلة المؤكدة:
- `ProductsPage` يستخدم `usePaginatedRows` بحجم صفحة 100.
- البحث الحالي في صفحة المنتجات يتم Client-side فقط على السجلات التي تم تحميلها.
- POS يسحب جميع المنتجات النشطة للفرع مباشرة.
- لذلك يمكن أن يظهر منتج في POS ولا يظهر في أول 100 منتج بصفحة المنتجات.
- POS لديه أيضاً Offline cache وقد يعرض بيانات قديمة في بعض الحالات.

### خطة الإصلاح
- تحويل البحث في المنتجات إلى Server-side search.
- الحفاظ على Pagination بدون حصر البحث في أول 100 سجل.
- توحيد قواعد `branch_id` و `is_active` بين POS وصفحة المنتجات.
- مراجعة POS Offline cache وإبطال/تحديث cache بعد إنشاء/تعديل/تعطيل/حذف منتج.
- اختبار قاعدة نهائية:
  - كل منتج يظهر في POS يمكن إيجاده وإدارته في ProductsPage لنفس الفرع.
  - كل منتج نشط وقابل للبيع في ProductsPage يظهر في POS حسب نفس الشروط.

---

## 5) KDS والمخزون

الحالة الحالية:
- `send_to_kitchen` أصبح state-only ولا يخصم المخزون.
- الخصم الفعلي للمخزون يتم مرة واحدة عند البيع عبر `process_sale` -> `deduct_sale_unit_inventory`.
- مسار المخزون الحالي يعتمد `inventory_units`.

متبقي للمراجعة المستقبلية:
- يوجد legacy schema قديم مرتبط بالمواد الخام/التصنيع.
- لا يتم حذف الجداول القديمة الآن بدون audit كامل للاعتماديات والهجرات.

---

## 6) CI / GitHub Actions

قاعدة العمل:
- لا نعتبر أي تعديل مكتمل قبل:
  1. lint
  2. typecheck
  3. tests
  4. DB verification
  5. browser smoke
  6. deploy

آخر مشكلة معروفة قبل تحديث هذا الملف:
- اختبارات `PaymentPanel` فشلت لأن `CashierDiscountApprovalCard` كان يستخدم `useAuth()` بدون `AuthProvider` في الاختبارات.
- تم تجهيز بديل يزيل هذا الاعتماد المباشر.
- يجب التحقق من آخر Commit وتشغيل `Verify main` بعد رفع التعديل.

---

## 7) ترتيب العمل القادم

### P0 — إغلاق العمل المفتوح الحالي
- تحقق من آخر CI بعد تعديل `CashierDiscountApprovalCard`.
- إصلاح أي فشل فقط، بدون إضافة تغييرات جانبية.

### P1 — إكمال نظام الموافقات
- Print/reprint integration.
- Refund approval integration.
- Cancel sent item approval.
- Open drawer approval.
- Change payment method approval.
- Force close shift approval.
- Cashier/Manager E2E.

### P2 — حماية الأسعار والإجماليات Server-side
- إعادة احتساب الأسعار والإجماليات داخل DB/RPC.
- اختبارات tampering سلبية.

### P3 — Branch visibility standard
- إنشاء `BranchBadge`.
- تعميمه على المبيعات والمنتجات أولاً.
- ثم بقية الصفحات حسب الأولوية المذكورة.

### P4 — Products/POS consistency
- Server-side search.
- Pagination سليمة.
- cache invalidation.
- اختبارات تطابق POS vs Products.

### P5 — بقية الصفحات والتقارير
- المشتريات.
- المخزون.
- المصروفات.
- المستخدمون والأطراف.
- التقارير والتصدير والطباعة.

---

## 8) قواعد ثابتة أثناء التطوير

- لا نحذف أو نضعف RLS أو الاختبارات لتجاوز فشل.
- لا نثق في بيانات العميل في العمليات المالية الحساسة.
- كل عملية حساسة للكاشير يجب أن تكون إما ممنوعة أو مرتبطة بصلاحية/موافقة Server-side.
- لا يتم دمج إصلاحات غير مرتبطة أثناء إصلاح CI واحد.
- كل تغيير مهم يجب أن ينعكس في هذا الملف.
- لا يتم إعلان أي ميزة "مكتملة" إلا بعد التحقق من الكود + قاعدة البيانات + الاختبارات + التشغيل.
