# CURRENT WORK PLAN — john-s

> **Source of Truth** لأي نموذج أو مطور يكمل العمل. اقرأ هذا الملف أولًا. لا تعِد فحص المشروع كله ولا تفتح عملًا مغلقًا بدون Regression مثبت.

آخر تحديث: **2026-09-03 — Africa/Cairo**

---

## 1) الحالة الحالية — اقرأ هذا أولًا

- Repository: `Premieros/john-s`
- Branch: `main`
- Supabase Production: `azzdesuowpdcoflmyezn`
- آخر HEAD وظيفي مُتحقق بالكامل: `c10f19df05691749481ec2ee6ca13a2b1fb206d4`
- Verify: run `33753268374` / #415 ✅
  - lint ✅
  - typecheck ✅
  - test suites typecheck ✅
  - unit ✅
  - build ✅
  - Fresh DB / canonical migrations ✅
  - schema verification ✅
  - integration + security/RLS ✅
  - Browser Smoke ✅
- Deploy لنفس الـHEAD: run `33753268339` / #417 ✅

آخر ما أُغلق في POS:
- Tables-first landing يعمل على الهاتف/التابلت/الديسكتوب ويعرض مباشرة: Quick Order / Delivery / Drive Thru / Active Orders.
- زر New Order يرجع إلى منطقة الطاولات بدل Landing مكرر.
- Bottom POS Navigation القديم محذوف بالكامل مع spacing/import/component remnants المرتبطة به.
- Top Action Bar أصبح authoritative للإجراءات العامة العاملة: Customer / Merge-Transfer / Print / Hold / Kitchen / Pay.
- لوحة السلة لم تعد تكرر Kitchen / Print / Hold / Pay / Customer؛ أبقِ Discount وسلوك Split/Void السياقيين للصنف المحدد.
- زر مسح الطلب الكامل الملتبس أزيل من Top Action Bar ومن رأس السلة؛ Void يظل مرتبطًا بالصنف المحدد.
- Browser Smoke بعد هذا التنظيم أخضر.
- manager approval للعمليات الهيكلية أصبح مغطى باختبار single-use صريح: Pending → approve → execute → consumed؛ إعادة نفس العملية لا تعيد استخدام الموافقة بل تنشئ طلب موافقة جديدًا ولا تنفذ mutation ثانية.
- لا يوجد أي تغيير جديد في Inventory/KDS/RLS بسبب تعديلات Top Action Bar أو اختبار single-use.
- **لم تُضف أو تُطبق أي Production migration تشغيلية جديدة في مرحلة UI/test الأخيرة.**

> لا تعتبر أي migration تشغيلية جديدة جاهزة لـProduction لمجرد نجاح Deploy للواجهة. أي migration جديدة مستقبلًا لا تُطبق على Production إلا بعد Verify كامل أخضر بما فيه Browser Smoke.

---

## 2) العمل النشط الآن — الأولوية الحالية

### A. أمان الدخول ومنع تسريب كاش مستخدم سابق — مغلق بالاختبارات الحالية ✅

Regression السابق من الحساب `sayed3la2@gmail.com` كان Client-side وليس RLS:
- Auth session وحده لا يكفي للدخول؛ يجب وجود Profile نشط فعلي في `public.users`.
- fallback user/local super-admin behavior أُلغي.
- لا يتم الثقة في profile محلي قديم بدل profile الخادم.
- POS offline cache مفصول حسب المستخدم/الفرع ولا يُحمّل catalog بدون branch/user context صحيح.
- regression coverage موجودة ضمن البوابات الحالية.

**لا تُضعف RLS بسبب هذا العيب؛ RLS في Production كان يمنع القراءة كما يجب. لا تعِد فتح هذا البند بدون Regression مثبت.**

### B. إعادة تدفق شاشة البيع POS — مغلق في baseline الحالي ✅

العقد المطبق:
1. دخول `/pos` يبدأ من **منطقة الطاولات**، وليس من شاشة منتجات مزدحمة.
2. Header منطقة البداية يعرض مباشرة:
   - طلب سريع
   - Delivery
   - Drive Thru / Car
   - Active Orders
3. الضغط على طاولة فارغة يبدأ طلب الطاولة ثم يفتح المنتجات.
4. الطاولة المشغولة تستأنف طلبها الحالي.
5. بعد فتح الطلب تظهر شاشة المنتجات + السلة + **Top Action Bar واضح**.
6. Bottom Navigation القديم retired ومحذوف ولا يجب إعادته.
7. لا تكرر نفس الإجراءات العامة داخل السلة.

Top Action Bar الحالي:
- Kitchen / إرسال للمطبخ
- Print
- Merge / Transfer
- Add Customer
- Hold
- Pay

إجراءات السلة السياقية:
- Discount
- Split للصنف/الكمية المحددة
- Void/Remove للصنف المحدد

**ممنوع إضافة زر شكلي بدون backend فعلي.**

### C. Split / Merge / Transfer بموافقة المدير — العقد مغلق ومثبت ✅

Backend-first. للكاشير:
- يبدأ العملية فتظل Pending.
- المدير/المصرح له يوافق.
- التنفيذ يحدث بعد الموافقة فقط.
- الموافقة تُستهلك مرة واحدة.
- replay لنفس العملية بعد `consumed` يحتاج approval request جديدًا ولا ينفذ mutation ثانية.

قواعد مثبتة ولا تُغيّر:
- لا خصم مخزون بسبب Split/Merge/Transfer.
- لا إعادة إرسال KDS بسبب هذه العمليات.
- لا تزوير أو إعادة كتابة تاريخ kitchen sends.
- Branch isolation server-side.
- العمليات الذرية عبر RPCs وليس تحديثات client مباشرة.
- السطر المرسل للمطبخ لا يُعاد re-parent عبر Split بطريقة تكسر traceability.

### D. Split Payment داخل الدفع فقط — **العمل التالي المفتوح**

قبل أي تعديل: افحص التنفيذ الحالي فقط ولا تعِد بناء Checkout كاملًا.

العقد المطلوب:
- Split Payment ليس Split الطلب.
- يظهر فقط داخل Checkout/Payment.
- يدعم توزيع الإجمالي بين طرق مسموحة مثل Cash + Card/Visa.
- مجموع الأجزاء يجب أن يساوي إجمالي الفاتورة بالضبط.
- كل جزء يُسجل في مساره المالي الصحيح.
- حقيقة البيع وخصم المخزون تمر من المسار المركزي مرة واحدة فقط.
- لا تقسيم دفع Offline قبل وجود عقد آمن وصريح لذلك.
- لا تضف migration أو RPC جديدًا إذا كان backend الحالي يغطي العقد بالفعل؛ أثبت النقص أولًا.

### E. قبل تطبيق أي عمل تشغيلي جديد على Production

بالترتيب:
1. Verify كامل أخضر بما فيه Browser Smoke.
2. مراجعة عدم وجود regression في KDS/inventory/refund/accounting.
3. تطبيق migrations الجديدة فقط إذا كان العمل الجديد أضاف migrations فعلية ومطلوبة.
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
- consumed approval لا يمكن استخدامها مرة ثانية؛ replay يحتاج request جديدًا.

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

- Auth profile/cache hardening.
- Tables-first POS landing + direct Quick/Delivery/Drive Thru/Active Orders.
- authoritative POS Top Action Bar + retired Bottom Navigation.
- Split/Merge/Transfer manager approval + single-use approval replay protection.
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

> الاستثناء الحالي المفتوح في POS هو **Split Payment داخل Checkout** فقط، إلى جانب أي Regression جديد مثبت مستقبلًا.

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
- لا تسمح بإعادة استخدام approval status `consumed` لتنفيذ mutation ثانية.
- لا تعِد Hard Delete إلى soft delete.

---

## 9) تعريف النجاح للمرحلة الحالية

المتحقق بالفعل ✅:
- Auth profile/cache regression مغلق ومغطى باختبار.
- `/pos` يبدأ بالطاولات + quick order actions في header.
- اختيار طاولة/طلب يفتح products workspace.
- Top Action Bar واضح ويحتوي فقط إجراءات عامة عاملة بلا تكرار داخل السلة.
- Split item/quantity يعمل بموافقة المدير ضمن العقد الحالي.
- Merge وTransfer يعملان بموافقة المدير.
- approvals single-use ومغطاة باختبار replay صريح.
- لا inventory deduction بسبب Split/Merge/Transfer.
- لا KDS resend/trace corruption بسبب Split/Merge/Transfer.
- lint/typecheck/unit/build ✅
- Fresh DB/schema/integration/security/RLS ✅
- Browser Smoke ✅

المتبقي لإغلاق مرحلة POS كلها:
- Split Payment يعمل داخل Checkout فقط وفق العقد في 3.4.
- إذا تطلب Split Payment migration جديدة: Verify كامل أخضر ثم تطبيقها على Production.
- Production sanity check محدود وآمن عند وجود تغيير تشغيلي فعلي يحتاجه.
- تحديث هذا السجل بالـHEAD/Verify/Production migration النهائية لذلك البند.

---

## 10) Next exact step

1. افحص **فقط** التنفيذ الحالي لـSplit Payment داخل Checkout/Payment والاختبارات/RPC المرتبطة به؛ لا تفحص المشروع كاملًا.
2. حدد gap مثبتة بين التنفيذ الحالي والعقد في 3.4.
3. إن كان موجودًا ومكتملًا: أضف/صحح الاختبار الضروري فقط ولا تعِد بناءه.
4. إن كان ناقصًا: أكمل أقل تعديل ممكن مع الحفاظ على `_process_sale_core` / `process_sale` كنقطة البيع وخصم المخزون مرة واحدة.
5. شغّل Verify كامل بما فيه Fresh DB + integration/security/RLS + Browser Smoke.
6. لا تطبق Production migration إلا إذا أُضيفت migration فعلية ومطلوبة ونجحت كل البوابات.
7. بعد ذلك فقط: Production sanity محدود وآمن وتحديث هذا الملف.