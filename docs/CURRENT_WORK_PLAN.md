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
- التأكد من نجاح CI النهائي بعد إصلاح اختبارات التكامل المرتبطة بتشديد `process_sale` وRLS.

ممنوع اعتبار نظام الموافقات "مكتمل بالكامل" قبل إنهاء البنود السابقة.

---

## 2) حماية البيع ومكافحة التلاعب

تم:
- منع الكاشير من الخصم المباشر من الواجهة.
- منع تحديث `sale_items` مباشرة.
- تقييد تحديث `sales` للمدير/الصلاحيات المناسبة.
- خصم الكاشير مربوط بموافقة مع مطابقة النوع والقيمة والإجمالي الفرعي.
- اختبارات التكامل تم تعديلها كي تستخدم مستخدماً مصادقاً عليه بدلاً من تجاوز شرط `AUTH_REQUIRED`.
- مصفوفة RLS أصبحت تختبر صراحة أن الكاشير لا يستطيع تعديل `sales` مباشرة وأن `sale_items` غير قابلة لـUPDATE/DELETE عبر RLS.

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
- اختبار KDS المركب تم تعديله ليستدعي `process_sale` تحت هوية الكاشير المصادق عليها، مع إبقاء شرط `AUTH_REQUIRED` الإنتاجي كما هو.

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

### آخر حالة موثقة
`Verify main #19` على commit `4e63610696be3043d228fe42d52e676a397ced8c`:
- Frontend verify: **ناجح بالكامل**.
  - lint ✅
  - typecheck ✅
  - typecheck:all ✅
  - unit tests: 331/331 ✅
  - build ✅
- Schema verification: **ناجح بالكامل**.
  - Tables 60/60 ✅
  - Functions 65/65 ✅
  - Contract RPCs 95/95 ✅
  - Contract tables 55/55 ✅
- DB integration: فشل 9 اختبارات فقط بسبب أن الاختبارات القديمة لم تكن متوافقة مع تشديد الموافقات/RLS، وليس بسبب فشل migration.

### الإصلاحات التي تم دفعها بعد #19
- `7e8ca2b177d8648e515e017b631c30860cfb8aab`
  - مصادقة fixture لاختبارات `process_sale_order_settlement` بدلاً من تجاوز `AUTH_REQUIRED`.
- `1d1542b936bfb493207bb3eeccb261643652951a`
  - مصادقة fixture لاختبارات authoritative pricing.
- `197dab1751d19ffbcb4d035c9c6f65272ac78ac0`
  - تشغيل settlement داخل اختبار KDS بهوية الكاشير الحالية.
- `60dbf2801ffa5d959763a9f6d94994f37fc7fbca`
  - تحديث مصفوفة RLS لتتوقع منع cashier UPDATE على `sales` ومنع UPDATE/DELETE على `sale_items` لكل authenticated caller.

مهم:
- لم يتم إضعاف RLS.
- لم يتم حذف أو skip أي اختبار.
- لم يتم إضافة bypass إنتاجي لشرط `AUTH_REQUIRED`.
- الخطوة الحالية: انتظار/فحص أحدث `Verify main` بعد هذه commits، ثم معالجة أي فشل متبقٍ فقط.

---

## 7) ترتيب العمل القادم

### P0 — إغلاق العمل المفتوح الحالي
الحالة: **قيد التحقق النهائي**.
- ✅ إصلاح frontend/unit regression الخاص بـ `CashierDiscountApprovalCard`.
- ✅ frontend verify أصبح أخضر بالكامل في #19.
- ✅ تحديد أن الفشل المتبقي كان fixtures/expectations قديمة بعد cashier hardening.
- ✅ تحديث اختبارات settlement/pricing/KDS لتستخدم auth حقيقي في CI.
- ✅ تحديث RLS matrix لتختبر الحماية الجديدة بدلاً من توقع الصلاحيات القديمة.
- ⏳ التحقق من أحدث CI بعد commits السابقة.
- ⏳ browser smoke + deploy بعد نجاح DB job.

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
