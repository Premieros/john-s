# CURRENT WORK PLAN — john-s

> **Source of Truth لأي نموذج أو مطور يكمل العمل. اقرأ هذا الملف أولًا.**
>
> السجل التنفيذي التفصيلي: [`docs/FRONTEND_V2_REBUILD_LOG.md`](./FRONTEND_V2_REBUILD_LOG.md)

آخر تحديث: **2026-09-05 — Africa/Cairo**

## 1) الحالة الحالية

- Repository: `Premieros/johna-s`.
- Current main بعد تنظيف نموذج الصلاحيات: `main@b0064a51ef2c90258ffaedbfc0570b6984f1de44`.
- PR #12 `refactor: eliminate legacy permission model drift` تم دمجه.
- Verify main #650: Frontend + Fresh DB + Schema + Integration/Security/RLS + Browser Smoke ✅.
- Deploy #509: Build + Production API Parity + GitHub Pages Deploy ✅.
- V2 هي Gateway فقط إلى مساحات التشغيل الأصلية؛ لا يوجد POS/Shifts/Home موازٍ في V2.

## 2) القرارات التشغيلية الثابتة

1. **Super Admin فقط** له implicit full-access. كل دور آخر يعتمد على `roles.permissions`.
2. يوجد اسم Canonical واحد لكل Capability تشغيلية؛ أسماء Legacy لا تُضاف إلى UI أو Permission Matrix أو أي كود جديد.
3. Branch Access يأتي من `user_may_access_branch()` و`user_branch_access` مع الفرع الأساسي، والواجهة لا تتجاوز RLS.
4. إرسال المطبخ يخصم مخزون الـdelta الجديد فقط ويسجل Inventory Events/Effects، والدفع لا يخصم المخزون مرة أخرى.
5. الصلاحيات الحساسة تُفرض في الخادم أيضًا؛ إخفاء زر في UI ليس حماية.
6. Split Payment ليس Split Order؛ النقل/الفصل لا يعيدان خصم المخزون أو إرسال KDS.
7. لا Merge/Deploy لحزمة تشغيلية قبل TypeScript + Unit + Build + Fresh DB + Schema + Integration/RLS + Browser Smoke.
8. لا نعيد Legacy aliases لحماية أدوار غير مستخدمة حاليًا؛ المصدر الوحيد هو الـcanonical permission model.
9. أي تعديل رصيد مخزون يجب أن يمر عبر حركة/RPC موثقة؛ لا حذف مباشر لرصيد inventory من الواجهة.

## 3) العقود المغلقة على main ✅

- POS: `pos.view`, `pos.order.create`, `pos.order.edit`, `pos.payment.take`, `pos.order.split`, `pos.order.transfer`, `pos.receipt.print`, `pos.send_kitchen`.
- KDS: `pos.kds_view`.
- Products: `products.view`, `products.create`, `products.edit`, `products.delete`, `products.modifiers.manage`.
- Stock counts: `inventory.view`, `inventory.count.create`, `inventory.count.approve`.
- Transfers: `inventory.view`, `inventory.transfer.create`, `inventory.transfer.approve`.
- Inventory adjustment: `inventory.adjust`.
- Inventory ledger: `inventory.ledger.view`.
- الهالك: عنصر محدد + مخزن محدد + اعتماد + خصم فعلي موثق؛ القراءة بـ`waste.view`.
- الموافقات: `approvals.review`, `approvals.override`, `approvals.policy.manage` مع سياسات فرع/مبلغ/صلاحية/مستخدم.
- Multi-branch: اختيار فرع موحد عبر `premier_active_branch` مع RLS.
- Production API Parity وGitHub Pages أخضران على `main@b0064a5`.

## 4) Canonical Permission Model المغلق ✅

### Legacy permissions المحذوفة من التطبيق

`pos.sell`, `pos.pay`, `pos.transfer_order`, `pos.split_order`, `products.manage`, `inventory.manage`, `inventory.transfers`, `inventory.transfers.approve`, `catalog.view`, `procurement.view`, `accounting.view`, `admin.view`.

قد تظل الأسماء التاريخية داخل migrations القديمة كسجل تاريخي فقط؛ لا يجوز إعادة استخدامها في TypeScript أو Permission Matrix أو Routes أو UI جديد.

### Dead code المحذوف

- `src/v2/pages/V2PosPage.tsx`
- `src/v2/pages/V2ShiftsPage.tsx`
- `src/v2/pages/V2HomePage.tsx`
- `src/v2/components/V2AppShell.tsx`

`useV2Can` ليس Authorization model ثانيًا؛ إن بقي فهو Adapter إلى `useCan` فقط.

## 5) آخر بوابة تحقق مكتملة ✅

- API Contract ✅
- Lint ✅
- TypeScript application/tests ✅
- Unit ✅
- Build ✅
- Fresh DB + canonical migrations ✅
- Schema verification ✅
- Integration/Security/RLS: **458/458 ✅**
- Browser Smoke ✅
- Production API Parity ✅
- GitHub Pages Deploy ✅

## 6) المرحلة التالية — إصلاحات UI/Runtime بعد الدمج 🔴

هذه المشاكل مثبتة من الواجهة المنشورة بالصور بتاريخ 2026-09-05، وتُنفذ بالترتيب التالي بدون توسيع النطاق إلى POS/Inventory Backend المستقر.

### نقطة تحقق الإصلاح المحلي — لم تُنشر بعد

- فرع العمل: `fix/p0-ui-db-alignment` مبني على حزمة إصلاحات `fix/screenshot-regressions-and-drift-audit`.
- Recipe/Components selectors أصبحت تقرأ المنتجات المتاحة للفرع من العقد نفسه، بدون فلتر `manufactured` القديم، وLive Costing يقرأ متوسط تكلفة مخزون المواد الخام.
- Auth/permission revalidation أصبح في الخلفية مع بقاء App Shell مركبًا، وأضيف recovery لمرة واحدة لأخطاء stale dynamic chunks.
- Dialog المنتج/الوحدة أصبح آمنًا ضمن ارتفاع الـviewport، وحقول الأرقام تستخدم NumericInput الموحد.
- أضيف Contract test لانحراف UI/DB، كما أصبح Production Parity يفشل صراحةً عند غياب `orders.inventory_warehouse_id` بدل إعطاء نتيجة خضراء زائفة.
- Production ما زالت تفتقد حزمة kitchen inventory boundary؛ لم تُطبّق migrations ولم يحدث Push/Deploy ضمن هذه النقطة.
- التحقق المحلي الحالي: API Contract ✅، Lint ✅، TypeScript ✅، Unit `323/323` ✅، Components `62/62` ✅، Build ✅.
- المتبقي قبل الدمج/النشر: تشغيل migrations على Fresh PostgreSQL بالترتيب canonical، ثم Integration/Security/RLS وBrowser Smoke وProduction parity عبر CI.

### P0 — توحيد عقد المنتجات مع الوصفات والمكونات

1. شاشة **إضافة وصفة** تعرض قائمة منتجات فارغة رغم وجود منتجات في النظام.
2. شاشة **المكونات** وفلتر `منتجات مصنّعة فقط` لا يعرضان المنتجات المتوقعة.
3. يجب تحديد مصدر بيانات Canonical واحد للمنتجات التي تدخل الوصفات/المكونات، وإزالة أي فلترة قديمة تعتمد manufacturing flags أو نموذج قديم أزيل سابقًا.
4. Live Costing يجب أن يعتمد نفس المنتج/الوحدة/المكونات المختارة ويعطي تكلفة فعلية بدل `0.00` عند وجود بيانات صحيحة.
5. الاختبار المطلوب: Product موجود في الفرع → يظهر في Recipe selector → تضاف مكوناته → Live Costing يحسب القيمة الصحيحة.

### P1 — إصلاح Modals وإدخال البيانات

1. نافذة إضافة المنتج/الوحدة أطول من viewport وتقص حقولًا في الأسفل.
2. المطلوب Modal responsive:
   - `max-height` مناسب للشاشة.
   - Header ثابت.
   - Footer/Actions ثابتة.
   - Body وحده قابل للتمرير.
   - لا scroll مزدوج ولا عناصر خارج الشاشة.
3. توحيد حقول الأرقام ومنع ظهور browser spinner/number controls بشكل غير متناسق إذا كان التصميم يستخدم NumericInput مخصصًا.
4. اختبار Desktop + Mobile viewport على الأقل.

### P1 — Permission/Auth bootstrap loader

1. شاشة `جاري التحقق من صلاحية الحساب...` لا يجب أن تظهر أثناء كل تنقل عادي.
2. Full-screen bootstrap مسموح فقط عند بداية جلسة لا يوجد لها auth/permission snapshot معروف.
3. `TOKEN_REFRESHED` أو background permission refresh لا يحجب App Shell.
4. Provider يجب أن يبقى أعلى الـroutes التي تتغير حتى لا يُعاد mount مع كل Navigation.
5. الاختبار المطلوب: التنقل بين 5 صفحات متتالية لا يظهر full-screen permission loader بعد bootstrap الأول.

### P0 — Dynamic import / stale chunk recovery على GitHub Pages

1. الخطأ المثبت:
   `Failed to fetch dynamically imported module` لملف asset قديم بعد Deploy جديد.
2. يجب منع بقاء `index.html` أو Service Worker/PWA cache يشير إلى chunk لم يعد موجودًا.
3. إضافة recovery آمن: عند فشل dynamic import بسبب stale deployment يتم reload واحد فقط بعد تنظيف/تحديث cache، بدون reload loop.
4. مراجعة إعدادات Vite base + lazy imports + PWA/Service Worker + GitHub Pages caching.
5. اختبار نشر نسختين متتاليتين والتأكد أن جلسة مفتوحة على النسخة الأولى تنتقل للثانية بدون ErrorBoundary دائم.

### P2 — اتساق واجهة الوصفات والمكونات

1. توحيد الـselect/dropdown styling واتجاه RTL.
2. منع ظهور placeholder كخيار أزرق selectable إذا لم يكن قيمة حقيقية.
3. إضافة Empty State يوضح سبب عدم وجود منتجات بدل dropdown فارغ فقط.
4. أي Empty State يجب أن يفرّق بين: لا توجد منتجات، لا صلاحية، لا فرع، أو فشل تحميل.

## 7) ما بعد إصلاحات الواجهة

- نظام الطباعة المحلي بثلاث محطات ثابتة فقط لكل فرع: `cashier`, `kitchen`, `barista`، وأي صنف بلا محطة يذهب للمطبخ مع تنبيه للمدير.
- حماية `main` بـrequired checks إن سمحت صلاحيات GitHub الإدارية المتاحة؛ CI وحده لا يكفي إن كان direct push مسموحًا.

## 8) Definition of Done

- Capability واحدة = Permission canonical واحدة لكل فعل.
- UI action + server authorization + branch/RLS متوافقة.
- لا duplicate operational implementation قابل للصيانة بالخطأ.
- Recipe/Components/Product selectors تستخدم نفس Contract ومصدر البيانات.
- لا Full-screen permission loader بعد bootstrap الأول للجلسة.
- لا stale dynamic-import crash بعد Deploy جديد.
- جميع Modals المهمة usable على Desktop/Mobile بدون قص محتوى.
- Source of Truth محدث مع كل Merge.
- Fresh DB + Integration/Security/RLS + Browser Smoke أخضر.
- Production لا يتغير إلا بطلب صريح منفصل.
