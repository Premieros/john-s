# CURRENT WORK PLAN — john-s

> **Source of Truth لأي نموذج أو مطور يكمل العمل. اقرأ هذا الملف أولًا.**
>
> السجل التنفيذي التفصيلي: [`docs/FRONTEND_V2_REBUILD_LOG.md`](./FRONTEND_V2_REBUILD_LOG.md)

آخر تحديث: **2026-09-04 — Africa/Cairo**

---

## 1) الحالة الحالية

- Repository: `Premieros/johna-s`
- `main` المدموج عند بدء إغلاق الفجوات النهائية: `f70412e88aa3f2c8affb1028af07594b33f40117`
- فرع العمل الحالي: `fix/final-operational-gaps`
- لا يوجد أي تعديل أو Migration على Supabase Production من هذا العمل.
- لا نعيد بناء المشتريات أو المخزون المستقر؛ نغلق الفجوات فوق الموجود.

## 2) القرارات التشغيلية الثابتة

1. Super Admin فقط له implicit full-access؛ كل دور آخر يعتمد على `roles.permissions` الفعلية.
2. Branch Access يأتي من `user_may_access_branch()` و`user_branch_access` مع الفرع الأساسي.
3. المستخدم متعدد الفروع يستطيع اختيار أي فرع ظاهر له؛ اختيار الواجهة لا يتجاوز RLS.
4. إرسال المطبخ يخصم المخزون عند الـdelta الجديد فقط، ويسجل Inventory Events/Effects، ولا يعيد الخصم عند الدفع.
5. لا يجوز إخفاء حماية حساسة في الواجهة فقط؛ يلزم Server-side permission check.
6. Split Payment ليس Split Order، والنقل/الفصل لا يخصمان مخزونًا ولا يعيدان إرسال KDS.
7. لا Production deployment/migration قبل Fresh DB + Integration/RLS + Browser verification.

## 3) ما هو مغلق على `main` ✅

- Send to Kitchen مربوط بـ`pos.send_kitchen` وبالفرع.
- خصم المخزون عند الإرسال للمطبخ مع idempotent delta effects والاسترجاع عند void المعتمد.
- الدفع يعيد استخدام آثار الإرسال ولا يخصم مرة ثانية.
- Backend المشتريات والمخزون ودورات الاستلام والتحويل والجرد موجودة ومختبرة.
- Permission-first وMulti-branch primitives موجودة في Backend وV2.

## 4) العمل الحالي على `fix/final-operational-gaps`

### صلاحيات POS الدقيقة — منفذ محليًا، بانتظار Fresh DB CI

- أضيفت وربطت: `pos.view`، `pos.order.create`، `pos.order.edit`، `pos.payment.take`، `pos.order.split`، `pos.order.transfer`، `pos.receipt.print`.
- Route/Menu/Buttons وmutation guard تستخدم الصلاحيات الدقيقة.
- توافق رجعي ينسخ صلاحيات POS القديمة إلى المقابلات الجديدة قبل تفعيل الحاجز.
- مستخدم الدفع فقط لا يستطيع إنشاء أو تعديل الطلب؛ تغيير بيانات الطلب أثناء الإغلاق يتطلب `pos.order.edit`.

### الهالك — منفذ محليًا، بانتظار Fresh DB CI

- الإنشاء يتطلب عنصرًا واحدًا محددًا: Product أو Inventory Unit.
- المخزن إلزامي ويجب أن يكون من نفس الفرع.
- إنشاء الهالك يبقى `pending` ولا يغير المخزون.
- الاعتماد بـ`waste.approve` يخصم ذريًا من المخزن المحدد ويسجل ledger/movement مرجعيًا بالهالك.
- الرفض لا يغير المخزون، وتكرار الاعتماد ممنوع.
- الواجهة تعرض وتختار الفرع/المخزن/العنصر الحقيقي.

### الموافقات — منفذ محليًا، بانتظار Fresh DB CI

- Route مركز الموافقات أصبح `approvals.review` بدل `settings.manage`.
- سياسة الموافقة تدعم: العملية، الفرع، حد مبلغ، صلاحية، موظف بعينه، أو الموظف والصلاحية معًا.
- غياب السياسة يحافظ على صلاحية الاعتماد الحالية ولا يقفل التشغيل.
- السياسات مفروضة في DB على طلبات المدير والهالك والجرد والتحويل.
- إدارة السياسات تحتاج `approvals.policy.manage` ولا تمنح Settings access.

### تعدد الفروع ومشكلة إعادة التحميل — منفذ محليًا

- Legacy `useBranchFilter` يستخدم الفرع المختار إذا كان ظاهرًا عبر RLS، بدل حبس غير Super Admin في `users.branch_id`.
- مدير/محاسب متعدد الفروع يرى selector الفروع المخولة؛ “كل الفروع” تبقى Super Admin فقط.
- `TOKEN_REFRESHED` لا يعيد تحميل ملف المستخدم ولا يفك تركيب الشاشة، لمنع شاشة “التحقق من الصلاحيات” المتكررة.

### Permission Matrix وKDS — منفذ محليًا

- Matrix تعرض صلاحيات Capability Registry الدقيقة لـPOS والهالك والموافقات والشفتات والمخزون والكتالوج والمشتريات والمحاسبة والإدارة.
- Route/Menu/Top tab لشاشة KDS كلها تستخدم `pos.kds_view`.

## 5) التحقق المحلي الحالي

- TypeScript application ✅
- TypeScript tests ✅
- ESLint ✅ (تحذيران Fast Refresh قديمان، بلا errors)
- Unit/components: **376/376 ✅**
- Production build ✅
- API contract regenerated: **107 RPCs / 62 tables ✅**
- Fresh DB migrations + Integration/Security/RLS: **بانتظار CI على الفرع**
- Browser Smoke: **بعد نجاح DB gate**

## 6) نقطة الاستكمال الإلزامية

1. تشغيل Fresh Postgres وتطبيق كل migrations حتى `20260904056000_approval_policies.sql`.
2. إصلاح أي خطأ SQL/Regression حقيقي بدون إضعاف RLS أو إعادة role-name bypass.
3. تشغيل Integration/Security/RLS كاملًا، خصوصًا: عرض POS فقط؛ دفع فقط بلا إنشاء/تعديل؛ عنصر + مخزن + اعتماد هالك + خصم فعلي + ledger؛ وسياسات الموافقة عبر فرعين وحدود مبلغ.
4. تشغيل Browser Smoke للـPOS والهالك والموافقات والتنقل بلا full-page permission reload.
5. لا دمج إلى `main` قبل أخضر كامل ومراجعة المستخدم.

## 7) مؤجل بعد هذه الحزمة

- محطات الطباعة الأساسية الثلاث: Cashier / Kitchen / Barista وربط الطابعة المحلية بكل محطة وفرع.
- استكمال واجهات V2 المخطط لها للمخزون والمشتريات والتقارير؛ لا إعادة بناء Backend المستقر.

## 8) Definition of Done

- Query/Mutation حقيقي، UI states كاملة، وRTL/LTR.
- Permission في UI والخادم + Branch Access/RLS.
- اختبار Unit/Contract، واختبار Integration لأي DB mutation.
- Fresh DB + Schema + Integration/RLS + Browser Smoke أخضر.
- لا تغيير على Production إلا بطلب صريح منفصل.
