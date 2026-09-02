# CURRENT WORK PLAN — john-s

> **Source of truth** لأي نموذج أو مطور يدخل يكمل العمل. اقرأ هذا الملف أولًا، ولا تعِد فتح أعمال أُغلقت إلا إذا ظهر Regression مثبت.

آخر تحديث: **2026-09-02**

## 1) الحالة الحالية — Release Baseline أخضر ✅

- Repository: `Premieros/john-s`
- Branch: `main`
- Supabase Production: `azzdesuowpdcoflmyezn`
- HEAD المعتمد: `5617da55725dd7cb1a160b8b1376c6c7254e619b`
- Verify main #197 / run `33600846169`: **SUCCESS**
  - lint ✅
  - typecheck ✅
  - typecheck all suites ✅
  - unit tests ✅
  - build ✅
  - Fresh DB canonical migrations ✅
  - schema verification ✅
  - Integration + Security/RLS regression ✅
  - Playwright Browser Smoke ✅
- Deploy #199 / run `33600846236`: **SUCCESS**

هذا هو الـbaseline الذي يبدأ منه أي عمل جديد.

---

## 2) دورة التشغيل الكاملة — مثبتة بالاختبار ✅

تم إضافة Release Gate حقيقي في:
`tests/integration/pos_operational_lifecycle.test.ts`

الدورة التي تمر فعليًا على Fresh DB:

`authenticated cashier → open shift → create order → send to KDS → process sale → inventory deduction → refund requires manager approval → manager approves → refund restores inventory → approval consumed once → close shift`

المثبت داخل الدورة:
- فتح الوردية يتم عبر RPC الحقيقي.
- إنشاء الطلب يستخدم سعر الخادم، ولا يثق في السعر المزور من العميل.
- KDS لا يخصم المخزون.
- البيع يخصم المخزون **مرة واحدة فقط**.
- Refund للكاشير يُرفض قبل موافقة المدير.
- موافقة المدير تعمل وتُستهلك مرة واحدة.
- Full refund يعيد المخزون فعليًا.
- الوردية تُغلق بنجاح بعد الدورة.

---

## 3) إصلاح Refund للمخزون الهجين ✅

Migration:
`20260902084000_refund_hybrid_inventory_restoration.sql`

المشكلة التي اكتشفها اختبار دورة التشغيل:
- `process_refund` القديم كان يعيد مخزون `inventory_batches/inventory_ledger` التقليدي فقط.
- البيع الحديث قد يكون خصم من `inventory_units` أو خامات Recipe مباشرة.
- بالتالي كان يمكن أن يتم Refund مالي ناجح بدون إعادة المخزون الحقيقي، أو إنشاء Product stock وهمي بدل المسار الذي خُصم.

الحل الحالي:
- بيع يعتمد على `inventory_units` → Refund يعيد وحدات المخزون.
- بيع يعتمد على raw recipe → Refund يعيد الخامات التي خُصمت.
- Ready/legacy product → يحتفظ بمسار استرجاع Product inventory القديم.
- الاسترجاع محدود بكمية الخصم الفعلية ويطرح ما سبق إرجاعه، لمنع Over-restoration في partial/repeated refunds.
- لا يتم إنشاء phantom product stock لبيع Hybrid.

تم تطبيق migration على **Production** بنجاح.

تحقق Production بعد التطبيق:
- `process_refund` مرتبط بـ `_restore_refund_hybrid_inventory` ✅
- `authenticated` يستطيع تشغيل `process_refund` حسب قواعده ✅
- `anon` لا يستطيع تشغيل Refund ✅
- الـhelper الداخلي غير متاح لـ`authenticated` ✅
- `service_role` يحتفظ بتنفيذ الـhelper ✅
- Negative inventory unit batches: **0**
- Negative product batches: **0**
- Negative raw-material batches: **0**
- Invalid negative sales totals/paid amounts: **0**

---

## 4) قواعد معمارية ثابتة — لا تغيّرها بدون قرار صريح

- **KDS لا يخصم المخزون.** `send_to_kitchen` = state/snapshot/delta فقط.
- **البيع هو نقطة خصم المخزون**، مرة واحدة فقط.
- Refund يجب أن يعكس نفس Inventory Path الذي خصمه البيع.
- لا نثق في أسعار/إجماليات مالية قادمة من العميل؛ الخادم هو المرجع.
- لا نحذف أو نضعف RLS أو Tests لإنجاح CI.
- كل البيانات branch-scoped يجب أن تبقى معزولة Server-side.
- Public signup مغلق؛ المستخدمون/Tenant provisioning من الإدارة أو المسار الداخلي فقط.
- Internal/security/accounting/inventory helpers لا تُفتح لـ`anon` أو `authenticated` فقط لإرضاء اختبار.
- عمليات الكاشير الحساسة تمر Permission أو Manager Approval Server-side.
- لا تعرض Demo/Seed tools في Production.
- لا تضف زرًا لميزة Backend غير مكتملة.

---

## 5) Inventory الحالي ✅

Hybrid inventory هو التصميم المعتمد:
- Sellable products: **335**
  - Direct raw recipe: **196**
  - Manufactured-unit path: **52**
  - Ready products: **87**
- Internal manufactured products: **17**، ومخفية من POS كمنتجات بيع مستقلة.
- كل المنتجات القابلة للبيع لها Inventory Path: **335/335**.
- Nested manufactured units مدعومة.
- التكلفة التشغيلية تعتمد المشتريات/الدفعات الفعلية، لا تكلفة Excel ثابتة.

بيانات الاستيراد المرجعية:
- Products: **352**
- Categories: **30**
- Raw materials: **215**
- Products with recipes: **265**
- Recipe lines: **1205**
- Empty recipes: **0**

---

## 6) Security / Permissions — مغلق أساسيًا ✅

الحالة المطلوبة والمثبتة:
- `anon` بلا وصول مباشر لجداول `public`.
- الاستثناءات الضرورية قبل Login فقط: `get_login_email(text)` و`record_login_failure(text)`.
- `register_tenant` و`bootstrap_initial_super_admin` غير متاحين لـ`anon/authenticated`.
- Direct inventory mutation/internal accounting/audit/legacy KDS helpers ليست Client RPCs عامة.
- Branch isolation مغطى بـRLS/Integration tests.
- Manager Approval مغطى للعمليات الحساسة، ومنها Refund، Discount، Reprint، Cancel sent item، Change payment method، Open drawer، Force close shift.
- التسجيل العام في الواجهة محذوف.

إعداد خارجي متبقٍ وليس migration:
- **Supabase Leaked Password Protection** يحتاج تفعيلًا من Auth settings إذا كان متاحًا للحساب/الخطة.

---

## 7) User-facing UI — المراجعة مكتملة ✅

المرجع التفصيلي: `docs/UI_VISIBILITY_AUDIT.md`

الحالة الأساسية:
- POS يعرض Counters للطلبات النشطة، Delivery، الطاولات المشغولة، وKDS.
- Discount / Hold-Resume / Send to Kitchen / Print / Pay / Table transfer ومسارات الموافقة ظاهرة حسب السياق والصلاحية.
- Approval Inbox ظاهر في Header.
- Refund وChange Payment Method ظاهرين من Sales.
- Open Drawer وForce Close Shift موجودان في Shift UI.
- Kitchen top navigation يفتح KDS الحقيقي.
- Kitchen Stations لها مدخل إداري واضح.
- Public Register UI ورابط Create Account محذوفان.
- Demo/Seed button محذوف من Super Admin.
- Placeholder `Premier Assistant — Coming soon` وعلامة `New` الوهمية محذوفان.

ميزات **غير منفذة بالكامل** وليست مجرد أزرار مخفية:
- `Split Bill`
- `Merge Tables`

لا تضف لهما UI شكليًا؛ إذا طُلبتا يجب تنفيذهما Backend + UI + tests كميزة كاملة.

---

## 8) الخطوة التالية

لا تعِد مراجعة hardening أو دورة البيع الحالية بدون سبب مثبت؛ الـbaseline الحالي أخضر.

الأولوية التالية حسب طلب المستخدم:
1. أي ملاحظات UI/UX أو وظائف جديدة يحددها المستخدم بعد معاينة النسخة المنشورة.
2. عند طلب `Split Bill` أو `Merge Tables`: تصميم Contract وتشغيل كامل ثم UI واختبارات.
3. مراجعة `npm audit` وترقية التبعيات عالية الخطورة بشكل مدروس؛ **لا تستخدم `npm audit fix --force` عشوائيًا**.
4. تفعيل Leaked Password Protection من Supabase Auth إن أمكن.
5. Release polish / UX / performance بعد تثبيت الوظائف المطلوبة.

### قاعدة تسليم لأي نموذج جديد
ابدأ من HEAD والـCI المذكورين في القسم 1، اقرأ هذا الملف و`docs/UI_VISIBILITY_AUDIT.md`، ثم نفّذ المطلوب الجديد فقط. لا تعيد بناء أو فحص أجزاء مغلقة إلا إذا ظهر فشل CI أو Regression قابل لإعادة الإنتاج.
