# CURRENT WORK PLAN — john-s

> **Source of Truth لأي نموذج أو مطور يكمل العمل. اقرأ هذا الملف أولًا.**
>
> السجل التنفيذي التفصيلي: [`docs/FRONTEND_V2_REBUILD_LOG.md`](./FRONTEND_V2_REBUILD_LOG.md)
>
> قاعدة البيانات الوحيدة المسموح بها لهذا المشروع: `azzdesuowpdcoflmyezn` وفق [`docs/DATABASE_IDENTITY_LOCK.md`](./DATABASE_IDENTITY_LOCK.md).

آخر تحديث: **2026-09-05 — Africa/Cairo**

## 1) الحالة الحالية الموثقة

- Repository: `Premieros/johna-s`.
- Current main: `main@096b2788c4068131de34fd5c24f55b0d9db17367`.
- Supabase Production Project Ref: `azzdesuowpdcoflmyezn` فقط.
- Verify main #702 ✅:
  - Database Identity Lock ✅
  - API Contract ✅
  - Lint ✅
  - TypeScript application/tests ✅
  - Unit ✅
  - Build ✅
  - Fresh DB + canonical migrations ✅
  - Schema verification ✅
  - Integration/Security/RLS ✅
  - Browser Smoke ✅
- Deploy #521 ✅:
  - Database Identity Lock ✅
  - Build ✅
  - Production API Parity ✅
  - GitHub Pages Deploy ✅
- `development/frontend-v2` لم يعد فرع عمل صالحًا؛ هو تاريخي ومتأخر عن `main` ولا يحتوي عملًا فريدًا مطلوبًا للاستكمال.
- PR #18 / `fix/permission-first-root-drift-v2` ما زال مفتوحًا ويحمل حزمة Permission-First إضافية، لكنه غير جاهز للدمج حتى تتم مزامنته مع `main` وتصبح Integration/Security/RLS وBrowser Smoke خضراء.

## 2) القرارات التشغيلية الثابتة

1. **Super Admin فقط** له implicit full-access. كل دور آخر هو Label فقط ويعتمد على `roles.permissions`.
2. يوجد اسم Canonical واحد لكل Capability تشغيلية؛ أسماء Legacy لا تُضاف إلى UI أو Permission Matrix أو Routes أو أي كود جديد.
3. Branch Access يأتي من `user_may_access_branch()` و`user_branch_access` مع الفرع الأساسي، والواجهة لا تتجاوز RLS.
4. إرسال المطبخ يخصم مخزون الـdelta الجديد فقط ويسجل Inventory Events/Effects، والدفع لا يخصم المخزون مرة أخرى.
5. الصلاحيات الحساسة تُفرض في الخادم أيضًا؛ إخفاء زر في UI ليس حماية.
6. Split Payment ليس Split Order؛ النقل/الفصل لا يعيدان خصم المخزون أو إرسال KDS.
7. لا Merge/Deploy لحزمة تشغيلية قبل TypeScript + Unit + Build + Fresh DB + Schema + Integration/RLS + Browser Smoke.
8. لا نعيد Legacy aliases لحماية أدوار غير مستخدمة؛ المصدر الوحيد هو canonical permission model.
9. أي تعديل رصيد مخزون يجب أن يمر عبر حركة/RPC موثقة؛ لا حذف مباشر لرصيد inventory من الواجهة.
10. **Database Identity Lock غير قابل للتجاوز:** أي URL أو Project Ref مختلف عن `azzdesuowpdcoflmyezn` هو Hard Failure.
11. لا نعيد فتح عمل مغلق على `main` إلا إذا وجد Regression مثبت باختبار أو Runtime evidence حديث.

## 3) ما هو مغلق فعليًا على main ✅

- Database identity enforcement في Verify + Deploy.
- API Contract / Lint / TypeScript / Unit / Build.
- Fresh DB + canonical migrations + Schema verification.
- Integration/Security/RLS gate الحالية على `main`.
- Browser Smoke الحالية.
- Production API Parity الحالية.
- GitHub Pages Deploy الحالية.
- POS canonical permissions الأساسية:
  - `pos.view`
  - `pos.order.create`
  - `pos.order.edit`
  - `pos.payment.take`
  - `pos.order.split`
  - `pos.order.transfer`
  - `pos.receipt.print`
  - `pos.send_kitchen`
- KDS: `pos.kds_view`.
- Products: `products.view`, `products.create`, `products.edit`, `products.delete`, `products.modifiers.manage`.
- Stock counts: `inventory.view`, `inventory.count.create`, `inventory.count.approve`.
- Transfers: `inventory.view`, `inventory.transfer.create`, `inventory.transfer.approve`.
- Inventory adjustment: `inventory.adjust`.
- Inventory ledger: `inventory.ledger.view`.
- Waste Center contracts and approval flow الموجودة على `main` تمر بالـCI الحالي.
- Multi-branch context موجود ويخضع لـRLS الحالي.

## 4) الانحرافات المفتوحة — ترتيب العمل الإلزامي

### P0-A — Permission-First Root Closure 🔴

**المشكلة:**
`main` أخضر، لكن PR #18 يثبت أن هناك عملًا إضافيًا مقصودًا لإغلاق root-level permission drift ومنع أي role-based authorization متبقٍ.

**نقطة العمل:**
`fix/permission-first-root-drift-v2` / PR #18.

**الخطوات:**
1. مزامنة PR #18 مع آخر `main` بدون فقد Database Identity Lock أو أي إصلاحات أحدث.
2. مراجعة الـ30 commit أمام `main` وإلغاء أي commit أصبح مكررًا أو تجاوزه `main` بدل دمجه آليًا.
3. تثبيت القاعدة: `owner` وأي Role آخر = Label فقط؛ لا implicit grants.
4. إزالة أي runtime legacy alias أو role-name authorization بقي في التطبيق أو SQL الجديد.
5. تشغيل Verify كامل.
6. إصلاح Integration/Security/RLS فقط على Regression مثبت؛ لا إضعاف اختبارات أو RLS.
7. تشغيل Browser Smoke.
8. لا Merge حتى تصبح كل البوابات خضراء.

**Definition of Done:**
- لا role-based operational authorization خارج Super Admin implicit bypass.
- لا Legacy permissions في TypeScript/Routes/UI/Permission Matrix أو migrations جديدة.
- Fresh DB + Integration/Security/RLS + Browser Smoke ✅.

### P0-B — SECURITY DEFINER Exposure Audit 🔴

**المشكلة:**
Supabase Security Advisor على Production `azzdesuowpdcoflmyezn` يسجل تحذيرات EXECUTE على SECURITY DEFINER functions، منها وظائف متاحة لـ`anon` وعدد كبير متاح لـ`authenticated`.

**مهم:** وجود التحذير لا يعني تلقائيًا أن كل RPC غير آمنة؛ يجب التدقيق Function-by-Function وعدم كسر RPCs المقصودة.

**الخطوات:**
1. استخراج قائمة SECURITY DEFINER الحالية مع owner, schema, proacl/grants, search_path.
2. تصنيفها إلى:
   - API مقصود للـanon.
   - API مقصود للمستخدم authenticated مع authorization داخلي.
   - Helper داخلي لا يجب أن يكون executable خارجيًا.
   - Admin/Super Admin only.
3. لكل Function حساسة، تحقق من:
   - `auth.uid()` / authenticated actor validation.
   - canonical permission check.
   - branch/tenant scope.
   - input object ownership/scope.
   - safe `search_path`.
4. Revoke EXECUTE عن أي Helper داخلي أو Function لا تحتاج Public API.
5. نقل Helpers الداخلية إلى schema غير معرض إذا كان ذلك مناسبًا.
6. إضافة regression tests تمنع عودة grants غير المقصودة.
7. إعادة Security Advisor بعد التعديل.

**أولوية خاصة:**
- `_production_schema_contract_kitchen_v1()`
- `get_login_email()`
- `record_login_failure()`
- user/admin mutation RPCs
- inventory/accounting/treasury mutation RPCs
- Super Admin RPCs

**Definition of Done:**
- كل SECURITY DEFINER external exposure موثق ومقصود ومختبر.
- لا anon EXECUTE غير ضروري.
- لا privileged helper exposed بلا سبب.

### P0-C — Auth Password Hardening 🔴

- Supabase Advisor: `Leaked Password Protection Disabled`.
- تفعيل leaked password protection من إعدادات Supabase Auth إذا كانت الخطة/الباقة الحالية تدعمها.
- بعد التفعيل: اختبار Login/Create User/Password Update flows.

**Definition of Done:** Advisor warning مغلق أو موثق كقيد منصة صريح إن تعذر تقنيًا.

### P1-A — Runtime UI Regression Re-verification 🟠

لا نعتبر قائمة UI القديمة مفتوحة بالكامل تلقائيًا، لأن عدة إصلاحات اندمجت بعد تسجيلها.

**يجب إعادة التحقق على النسخة الحالية فقط من:**
1. Recipe selector يعرض منتجات الفرع الموجودة.
2. Components selectors لا تعتمد manufacturing flag قديمًا.
3. Live Costing لا يبقى `0.00` عند وجود بيانات تكلفة صحيحة.
4. Product/Unit dialogs usable على Desktop/Mobile بدون قص المحتوى.
5. التنقل بين خمس صفحات لا يعرض full-screen permission loader بعد bootstrap الأول.
6. stale dynamic import recovery بعد Deploy جديد لا يدخل reload loop.
7. RTL/Empty States في Recipe/Components.

**قاعدة:** لا تعديل قبل Regression مثبت على `main` الحالي.

### P1-B — Protect `main` 🟠

`main` غير Protected حاليًا.

**الهدف:** منع Direct Push أو Merge يتجاوز بوابات التحقق.

**Required checks المقترحة:**
- verify
- db
- browser-smoke
- production parity عند الـrelease/deploy gate حسب بنية GitHub المتاحة.

إذا تعذر تفعيل Branch Protection بسبب صلاحيات GitHub App، يوثق ذلك كقيد خارجي ولا يتم الادعاء بأنه محمي.

### P2 — Printing Finalization 🟡

بعد إغلاق P0/P1:
- تثبيت نظام الطباعة المحلي.
- المحطات القياسية لكل فرع: `cashier`, `kitchen`, `barista`.
- أي صنف بلا محطة يذهب إلى kitchen مع تنبيه Manager.
- first print / reprint / kitchen print تخضع للصلاحيات المخصصة.

## 5) ترتيب التنفيذ من الآن

1. **Permission-First PR #18 synchronization + regression closure.**
2. **SECURITY DEFINER exposure audit.**
3. **Leaked Password Protection.**
4. **Full Verify على main candidate.**
5. **Runtime UI regression audit على النسخة المنشورة الحالية.**
6. إصلاح Runtime regressions المثبتة فقط.
7. **Protect main** إن سمحت صلاحيات GitHub.
8. Printing finalization.
9. Full operational E2E/regression pass.
10. Final zero-drift report قبل إعلان 100%.

## 6) بوابة الدمج لكل حزمة

لا تعتبر أي حزمة جاهزة حتى تحقق:

- Database Identity Lock ✅
- API Contract ✅
- Lint ✅
- TypeScript app/tests ✅
- Unit ✅
- Build ✅
- Fresh DB + canonical migrations ✅
- Schema verification ✅
- Integration/Security/RLS ✅
- Browser Smoke ✅
- Production API Parity عند الحاجة ✅
- Source of Truth + execution log updated ✅

## 7) Definition of Done النهائي للمشروع

- Capability واحدة = Permission canonical واحدة لكل فعل.
- Super Admin فقط implicit full-access؛ بقية الأدوار Labels فقط.
- UI action + server authorization + branch/RLS متوافقة.
- لا duplicate operational implementation يمكن أن يسبب drift.
- لا SECURITY DEFINER exposure غير مقصود.
- لا Cross-branch data leak.
- Database identity ثابتة على `azzdesuowpdcoflmyezn` فقط.
- Runtime UI الحالي خالٍ من regressions المثبتة.
- لا stale dynamic-import crash بعد Deploy جديد.
- جميع Modals الحرجة usable على Desktop/Mobile.
- `main` محمي بالـchecks إن أتاحت صلاحيات GitHub ذلك، وإلا القيد موثق بوضوح.
- Source of Truth محدث مع كل Merge.
- Fresh DB + Integration/Security/RLS + Browser Smoke + Production Parity أخضر.
- لا إعلان Final 100% قبل **Zero-Drift Report** نهائي.