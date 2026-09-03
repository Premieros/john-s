# CURRENT WORK PLAN — john-s

> **Source of Truth** لأي نموذج أو مطور يكمل العمل. اقرأ هذا الملف أولًا. لا تعِد فحص المشروع كله ولا تفتح عملًا مغلقًا بدون Regression مثبت.

آخر تحديث: **2026-09-03 — Africa/Cairo**

---

## 1) الحالة الحالية — اقرأ هذا أولًا

- Repository: `Premieros/john-s`
- Branch: `main`
- Supabase Production: `azzdesuowpdcoflmyezn`
- آخر HEAD وظيفي قبل إعادة تنظيم هذا السجل: `b7d132aac3ba453f02815af1989936b20bb519a7`
- Verify الجاري لهذا الـHEAD: run `33736650009` / #391
  - lint ✅
  - typecheck ✅
  - test suites typecheck ✅
  - unit ✅
  - build ✅
  - Fresh DB / canonical migrations ✅
  - schema verification ✅
  - integration + security/RLS ✅
  - browser-smoke: كان قيد التنفيذ عند آخر تحقق من السجل
- Deploy لنفس الـHEAD: run `33736649955` / #393 ✅

> لا تعتبر أي migration تشغيلية جديدة جاهزة لـProduction لمجرد نجاح Deploy للواجهة. migrations الخاصة بالعمل النشط أدناه لا تُطبق على Production إلا بعد Verify كامل أخضر بما فيه browser-smoke.

---

## 2) العمل النشط الآن — الأولوية الحالية

### A. أمان الدخول ومنع تسريب كاش مستخدم سابق

Regression مثبت من الحساب `sayed3la2@gmail.com`:
- الحساب موجود في Supabase Auth لكنه لا يملك صفًا مطابقًا في `public.users`.
- اختبار RLS مباشر على Production لنفس UID أعاد: 0 منتجات، 0 وصفات، 0 حسابات، 0 فروع.
- سبب ظهور بيانات للمستخدم كان Client-side وليس RLS: fallback profile / local auth behavior + POS offline cache من جلسة/فرع سابق.

الإصلاح الجاري/المطبق في الكود:
- وجود Auth session وحده لا يكفي للدخول؛ يجب وجود Profile نشط فعلي في `public.users`.
- إلغاء fallback user/local super-admin behavior.
- عدم الثقة في profile محلي قديم بدل profile الخادم.
- فصل POS offline cache حسب المستخدم/الفرع ومنع تحميل catalog بدون branch context صحيح.
- إضافة regression tests تمنع رجوع هذا المسار.

**لا تُضعف RLS بسبب هذا العيب؛ RLS في Production كان يمنع القراءة كما يجب.**

### B. إعادة تدفق شاشة البيع POS

المطلوب الثابت:
1. دخول `/pos` يبدأ من **منطقة الطاولات**، وليس من شاشة منتجات مزدحمة.
2. Header منطقة البداية يحتوي إجراءات واضحة مثل:
   - طلب سريع
   - Delivery
   - Drive Thru / Car
   - Active Orders
3. الضغط على طاولة فارغة يبدأ طلب الطاولة ثم يفتح المنتجات.
4. الطاولة المشغولة تستأنف طلبها الحالي.
5. بعد فتح الطلب تظهر شاشة المنتجات + السلة، ومعها **Top Action Bar واضح**.
6. لا يوجد Bottom Navigation قديم؛ المكوّن القديم retired ولا يجب إعادته. أزل أي padding/spacing متبقٍ سببه الشريط القديم.
7. لا تكرر نفس البيانات في الطاولات/الطلبات/Kitchen panel.

Top Action Bar المطلوب عند وجود طلب:
- Kitchen / إرسال للمطبخ
- Print
- Split (فصل أصناف — التعريف في القسم 3)
- Void عند تحديد صنف في السلة
- Merge / Transfer
- Add Customer
- Hold عند الحاجة
- Pay

**ممنوع إضافة زر شكلي بدون backend فعلي.**

### C. Split / Merge / Transfer بموافقة المدير

Backend-first. للكاشير: يبدأ العملية، لكن التنفيذ يظل Pending حتى موافقة المدير. المدير/المصرح له يوافق ثم تُستهلك الموافقة مرة واحدة.

قواعد غير قابلة للتغيير:
- لا خصم مخزون بسبب Split/Merge/Transfer.
- لا إعادة إرسال KDS بسبب هذه العمليات.
- لا تزوير أو إعادة كتابة تاريخ kitchen sends.
- Branch isolation server-side.
- العمليات الذرية عبر RPCs وليس تحديثات client مباشرة.

### D. Split Payment داخل الدفع فقط

- Split Payment ليس Split الطلب.
- يظهر فقط داخل Checkout/Payment.
- مثال: جزء Cash + جزء Card/Visa.
- يجب أن يساوي مجموع وسائل الدفع إجمالي الفاتورة.
- البيع/المخزون يمر من المسار المركزي مرة واحدة فقط.
- لا تقسيم دفع Offline قبل وجود عقد آمن وصريح لذلك.

### E. قبل تطبيق العمل النشط على Production

بالترتيب:
1. Verify كامل أخضر بما فيه Browser Smoke.
2. مراجعة عدم وجود regression في KDS/inventory/refund/accounting.
3. تطبيق migrations الجديدة فقط بعد الخطوتين أعلاه.
4. تحقق Production محدود وآمن.
5. تحديث هذا السجل بالـHEAD وrun/migration النهائيين.

---

## 3) عقد POS الثابت — Split ≠ Split Payment

### 3.1 Split — فصل صنف/كمية من الطلب

مثال: الطلب يحتوي 2 Burger؛ يمكن اختيار 1 فقط وفصله.

الوجهات المسموحة:
- طلب سريع جديد مستقل.
- طاولة فارغة → إنشاء طلب جديد عليها.
- طاولة مشغولة → إضافة الجزء المفصول إلى طلبها المفتوح.

للكاشير:
- ينشئ طلب الموافقة.
- لا تتغير الطلبات فعليًا قبل موافقة المدير.
- بعد approve تُنفذ العملية وتُستهلك الموافقة مرة واحدة.

KDS/Inventory:
- Split لا يخصم مخزونًا.
- Split لا ينشئ Kitchen Send جديدًا لمجرد نقل السطر.
- إذا كان السطر مرسلًا للمطبخ، يجب الحفاظ على تاريخ وهوية الإرسال؛ لا تُنفذ طريقة تكسر traceability.

### 3.2 Merge — دمج الطلبات

- دمج طلب كامل في طلب آخر.
- للكاشير يحتاج موافقة مدير قبل التنفيذ.
- بعد النجاح يُفرغ/يغلق المصدر حسب العقد التنفيذي.
- لا خصم مخزون جديد.
- لا Kitchen resend.

### 3.3 Transfer — نقل طلب كامل

- نقل الطلب من طاولة إلى أخرى.
- للكاشير يحتاج موافقة مدير.
- حافظ على نفس `order_id` عند نقل الطلب الكامل متى كان ذلك هو المسار المعتمد، لحماية KDS والتاريخ التشغيلي.
- لا خصم مخزون ولا resend.

### 3.4 Split Payment — تقسيم وسائل الدفع

- يظهر في شاشة الدفع فقط.
- يدعم توزيع الإجمالي بين طرق مسموحة مثل Cash + Card/Visa.
- مجموع الأجزاء = إجمالي الفاتورة بالضبط.
- كل جزء يُسجل في مساره المالي الصحيح.
- `_process_sale_core` / المسار المركزي يظل مسؤولًا عن حقيقة البيع وخصم المخزون مرة واحدة.

---

## 4) ثوابت معمارية — لا تغيّرها

- `send_to_kitchen` لا يخصم المخزون؛ هو state/snapshot فقط.
- `process_sale` هو نقطة خصم المخزون مرة واحدة فقط.
- Refund يعكس exact inventory path الذي خصمه البيع.
- الأسعار والإجماليات وModifier component deltas authoritative من الخادم.
- لا تضعف/تحذف/تتخطى RLS أو الاختبارات.
- Branch isolation دائمًا server-side.
- Public registration مغلق.
- Sensitive cashier actions تحتاج permission أو manager approval.
- لا expose لـinternal/security/accounting/inventory helpers للعميل لمجرد إنجاح اختبار.
- لا Demo/Seed tools في Production UI.
- Financial Visibility هي read-side فقط؛ stock/accounting/write truth تعمل على 100% من الحقيقة.
- حذف الفرع هو Hard Delete، وليس deactivate/soft delete.
- لا تغيّر KDS أو inventory behavior لمجرد تعديل UI.

---

## 5) Production baseline المغلق — ملخص فقط

### 5.1 Product Components + Modifiers ✅

- `product_components` = BOM للتكلفة النظرية، وليس مسار الخصم التشغيلي المباشر.
- الخصم التشغيلي عبر `product_unit_links` / recipes / modifier inventory effects.
- Modifier pricing server-side.
- KDS يحتفظ بالـmodifier snapshot.
- `send_to_kitchen` لا يخصم.
- sale يخصم base + modifier deltas مرة واحدة.
- Refund يعيد exact sale-item inventory snapshot نسبيًا.
- اختبارات lifecycle/void/refund موجودة وخضراء على Fresh DB.

### 5.2 KDS ✅

- modern KDS يعتمد على `order_kitchen_sends.order_item_id`.
- legacy compatibility للطلبات القديمة الفارغة فقط.
- Kitchen panel داخل POS يعرض فقط ما أُرسل للمطبخ.
- لا تعِد unsent active orders إلى Kitchen panel.

Production migrations الأساسية:
- `20260902154339 accounting_kds_station_assignments`
- `20260902154358 kds_queue_legacy_compat`
- `20260902154420 kds_empty_legacy_order_compat`
- `20260902194308 kitchen_station_editor_context`

### 5.3 Financial Visibility ✅

- `owner` فقط يرى 100% من التاريخ المالي ضمن نطاقه.
- غير owner: recent N days = 100%، والقديم deterministic percentage.
- Production defaults: 7 أيام / 30%.
- الحقيقة التشغيلية والمحاسبية لا تدخل في sampling.

### 5.4 Hard Delete / Branch selector ✅

- `delete_branch_cascade(uuid)` محمي.
- يحذف بيانات الفرع ومستخدمي Auth التابعين وفق العقد الحالي.
- ghost branch القديم كان Cache في الواجهة؛ Production نفسه لا يحتوي الفرع المحذوف.
- branch cache يُبطل بعد create/update/delete.

### 5.5 50 طاولة افتراضية ✅

- كل فرع يحصل على `طاولة 01` → `طاولة 50`، سعة 4، layout 10×5.
- يمكن إضافة طاولات 51+.
- لا تُحذف الطاولات المخصصة الموجودة.
- Production الحالي تحقق سابقًا من 50 طاولة نشطة في فرع نادي سموحة.

Production migration:
- `20260903062933 default_50_dining_tables`

### 5.6 Product Images ✅

- `products.image_url` مستخدم للصورة الحقيقية.
- Storage bucket: `product-images`.
- الرفع محمي بالفرع و`products.manage`.
- fallback images تقريبية في الواجهة فقط ولا تكتب بيانات وهمية في المنتج.

Production migration:
- `20260903070945 product_image_storage`

### 5.7 Reports / Costing / Permissions UI ✅

- Reports بدون charts مكررة؛ selector/filters موحدة.
- Costing يحافظ على COGS / Net Sales الصحيح.
- Roles/Permissions UI grouped وقابل للإدارة بدون إضعاف backend permissions.

---

## 6) Production Acceptance السابق — ملخص

تم سابقًا إنشاء فروع QA ومستخدمي Auth حقيقيين ثم حذفهم بالكامل.

تم التحقق من:
- شراء → مخزون → طلب → Kitchen → بيع ضمن حدود أدوات Production.
- `send_to_kitchen`: no deduction.
- sale: FIFO/single deduction.
- KDS snapshot صحيح.
- branch isolation الأساسي.
- Dining Area permissions.
- Hard Delete وتنظيف Auth.
- modifiers + inventory effects.

حدود مهمة:
- بعض العمليات المالية الحقيقية مثل refund/shift close أو payment retest تم منعها بأداة safety في بعض جلسات Production؛ لم يتم تجاوز الحماية. التغطية المكافئة موجودة في Fresh DB integration tests حيث ذُكر ذلك.

---

## 7) لا تُعد فتح هذه الأعمال بدون Regression مثبت

- KDS exact sends + legacy compatibility.
- Product Modifiers authoritative pricing/inventory effects.
- exact sale-item inventory snapshots / partial refund.
- exact sent-item void / mutation guards.
- open-order modifier immutability.
- accounting/treasury baseline.
- hybrid deduction/refund.
- Financial Visibility + admin controls.
- Hard Delete.
- Costing COGS/Net Sales.
- Reports de-duplication.
- Roles/Permissions UI.
- 50 default tables.
- product image storage.
- branch selector stale-cache fix.

> الاستثناء الحالي: POS UI / Split / Merge / Transfer / Split Payment / auth-cache hardening هي أعمال نشطة ومفتوحة كما هو موضح في القسم 2.

---

## 8) ما لا يجب فعله مستقبلًا

- لا تستخدم React/CSS كحماية مالية أو صلاحيات.
- لا تجعل Auth session بلا `public.users` profile صالح يُنشئ مستخدمًا افتراضيًا.
- لا تستخدم offline cache من مستخدم/فرع سابق عند غياب branch/user context الصحيح.
- لا تغير `process_sale` أو inventory deduction بسبب visibility أو UI.
- لا تعرض sampling financial policy للمستخدم المقيد.
- لا تمنح Super Admin full commercial history تلقائيًا لمجرد دوره التقني.
- لا تجعل current stock أو posting logic يعمل على sample.
- لا تعِد Bottom POS navigation القديم.
- لا تضع Split Payment في شريط Split الخاص بالأصناف.
- لا تنفذ cashier Split/Merge/Transfer قبل manager approval.
- لا تعِد Hard Delete إلى soft delete.

---

## 9) تعريف النجاح للمرحلة الحالية

تُغلق مرحلة POS الحالية فقط عندما يتحقق الآتي معًا:
- Auth profile/cache regression مغلق ومغطى باختبار.
- `/pos` يبدأ بالطاولات + quick order types في header.
- اختيار طاولة/طلب يفتح products workspace.
- Top Action Bar واضح ويحتوي فقط أزرارًا عاملة.
- Split item/quantity يعمل بموافقة المدير.
- Merge وTransfer يعملان بموافقة المدير.
- Split Payment يعمل داخل checkout فقط.
- لا inventory double deduction.
- لا KDS resend/trace corruption.
- lint/typecheck/unit/build ✅
- Fresh DB/schema/integration/security/RLS ✅
- Browser Smoke ✅
- migrations الجديدة مطبقة على Production بعد البوابات السابقة فقط.
- Source of Truth محدث بالـHEAD/Verify/Deploy/Production migration النهائية.

---

## 10) Next exact step

1. إغلاق Browser Smoke للـHEAD الوظيفي الحالي أو إصلاح regression إن ظهر.
2. إكمال Top POS Actions وربط Print / Customer / Split / Void / Merge-Transfer دون تكرار.
3. إزالة آخر spacing/import/component remnants المرتبطة بالـBottom Nav القديم.
4. التأكد أن approval flow للكاشير Pending حتى approve ثم execute مرة واحدة.
5. بعد Verify كامل فقط: تطبيق migrations التشغيلية الجديدة على Production.
6. Production sanity check محدود وآمن ثم تحديث هذا الملف.
