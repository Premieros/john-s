# CURRENT WORK PLAN — john-s / Frontend V2

> **Source of Truth لأي نموذج أو مطور يكمل العمل. اقرأ هذا الملف أولًا.**
>
> السجل التنفيذي التفصيلي: [`docs/FRONTEND_V2_REBUILD_LOG.md`](./FRONTEND_V2_REBUILD_LOG.md)

آخر تحديث: **2026-09-04 — Africa/Cairo**

---

## 1) الحالة الحالية

- Repository: `Premieros/johna-s`
- Production branch: `main`
- Production baseline عند بدء V2: `4e63ce21597958dc9ee9852ca2ff00e4e14c86a3`
- **فرع التطوير الوحيد:** `development/frontend-v2`
- Draft PR الوحيد للتطوير: **#6 — `feat: rebuild frontend v2 from database contract`**
- آخر HEAD قبل تحديث هذا السجل: `c7f6d7276b934e9d5f3114e270edbff139fab322`
- Supabase Production: `azzdesuowpdcoflmyezn`
- PR #3 وPR #5 مغلقان/superseded؛ لا يضاف عليهما تطوير جديد.
- لا يوجد Merge إلى `main` ولا Production migration من PR #6 حتى هذا التحديث.

الخطة السابقة محفوظة في Git history. لا يعاد فتح عمل مغلق بدون Regression مثبت.

---

## 2) القرار المعماري الملزم — Branch Access + Permission First

نبني **Frontend V2 من الصفر** فوق الـBackend/Database الحالية باعتبارها Source of Truth، مع إبقاء الواجهة القديمة مؤقتًا حتى اكتمال واستقرار V2.

### 2.1 قاعدة الفروع

1. المستخدم يعمل على **أي فرع لديه Access فعلي عليه**؛ لا يتم حبسه في `users.branch_id` فقط.
2. مصدر Branch Access هو `user_may_access_branch()` والـRLS، مع `user_branch_access` والفـرع الأساسي كـlegacy/primary grant حيث يلزم.
3. اختيار فرع في الواجهة لا يمنح صلاحية؛ الخادم/RLS هما المرجع النهائي.
4. وجود Permission لا يسمح بالعمل خارج الفروع المخولة، ووجود Branch Access لا يسمح بتنفيذ Action بدون Permission المطلوبة.

### 2.2 قاعدة الصلاحيات

1. **الصلاحيات هي الأساس. الأدوار أصبحت Labels/Templates وليست سلطة Authorization مستقلة.**
2. إذا كانت للمستخدم Permission فعالة لميزة/إجراء، **لا يجوز حجبها بسبب اسم دوره**.
3. Role name لا يمنح ولا يمنع Action في V2 إذا توجد Permission صريحة مناسبة.
4. `owner` ليس Global Admin ولا implicit admin.
5. **Super Admin فقط** هو الـimplicit/platform admin ذو Full Access غير القابل للاختزال بمصفوفة الأدوار العادية.
6. كل المستخدمين الآخرين — بما فيهم `owner` و`branch_manager` وأي Role مخصص — يعتمد وصولهم على Permissions الفعلية + Branch Access.
7. أي Action حساس يحتاج Server-side permission check؛ إخفاء/إظهار الزر في React ليس حماية.
8. عند تعذر تحميل Permission map لغير Super Admin يكون السلوك **fail closed**؛ لا fallback تلقائي إلى Default Role permissions.
9. تعديل/إنشاء Role template لا يسمح للمستخدم بمنح Permission لا يملكها هو، إلا Super Admin.

> ملاحظة تنفيذية: التخزين الحالي للصلاحيات الفعالة يعتمد أساسًا على `roles.permissions` المرتبطة بالمستخدم. إذا أضيف لاحقًا Direct User Permission Override فيجب دمجه في نفس Effective Permission resolver بحيث يظل اسم الدور غير قادر على حجب Permission ممنوحة للمستخدم.

### 2.3 قواعد عامة

- لا نعيد بناء قاعدة البيانات من الصفر.
- لا نحذف Legacy DB إلا بعد dependency proof + migration + regression.
- لا زر شكلي: كل Action يحتاج Backend حقيقي + Permission + حالات UI + اختبار.
- العربية RTL هي الأساس، الإنجليزية LTR.
- الحسابات والمخزون والأسعار الحساسة authoritative من الخادم.
- لا Production migration من PR #6 بدون طلب صريح وبعد Verify مناسب.

---

## 3) Production DB snapshot — قراءة فقط

فحص 2026-09-04:

- 100 public tables
- 243 public functions
- 331 RLS policies
- 2 active branches
- 8 active users
- 335 active products
- 2 active warehouses

التصنيف:

- **Canonical:** users/roles/branches/user_branch_access، POS/orders/KDS/sales/shifts، catalog/modifiers، inventory/units/counts/transfers، procurement، waste/approvals، accounting/treasury/reports.
- **Legacy/Compatibility:** subscriptions وبعض raw-material/recipes/production paths القديمة/الهجينة؛ لا تُعرض تلقائيًا في V2.
- **Hardening backlog:** overloads وSECURITY DEFINER/search_path تُراجع فقط عندما تدخل في مسار V2 الفعلي.

لا يعاد تشكيل Production أثناء بناء V2 بدون Migration/Verify مستقلين.

---

## 4) ما تم فعليًا حتى آخر HEAD

### Foundation ✅

- App Shell RTL-first جديد.
- Sidebar قابل للطي + mobile drawer.
- V2 branch context من الفروع التي تسمح بها RLS، وليس `users.branch_id` وحده.
- Capability registry يربط Modules/Actions بالـBackend.
- `/v2` Home/status surface.
- `useV2Can()` لقراءة permission strings من DB-backed permissions.

### Permission-first / Branch Access ✅ من ناحية التنفيذ الأساسي

Migration الأساسية:
`20260904046000_permission_first_roles_branch_access.sql`

تم:

- `can_permission()` أصبح Super Admin-only implicit bypass؛ باقي المستخدمين يعتمدون على DB-backed permissions.
- `user_may_access_branch()` أصبح يعتمد Super Admin أو `user_branch_access` أو primary branch grant، بدون org/role-name global bypass.
- `owner` لم يعد implicit/global admin في المسارات التي تم تحويلها.
- `is_pos_admin()` تم استبداله بـ`is_platform_admin()` في مسارات V2 الحساسة التي مستها migration.
- `create_user` / `delete_user` / `update_user_password` أصبحت `users.manage` + branch scope بدل Role-name admin gates.
- إدارة `user_branch_access` أصبحت permission-based + branch-scoped.
- Role rows أصبحت templates/labels؛ guard يمنع منح Permission أعلى من صلاحيات المانح، وSuper Admin فقط هو الاستثناء.
- Frontend permission resolver أصبح fail-closed لغير Super Admin إذا لم توجد DB permission map.
- Permission Matrix لا تعتبر `owner` immutable full-access role؛ Super Admin فقط immutable full-access.
- `UsersPage` أصبحت تعتمد `users.manage` وتتعامل مع الفروع المخولة بدل الفرع الأساسي فقط.
- Unit tests القديمة الخاصة بـPermission definitions تم تحديثها في `c7f6d727...` لتطابق العقد الجديد.

### POS V2 — منفذ جزئيًا

موجود فعليًا:

- `/v2/pos`.
- Table-first للصالة + Takeaway + Delivery + Drive Thru.
- تحميل منتجات/تصنيفات/طاولات/طلبات مفتوحة حسب الفرع.
- Cart وكميات وحذف.
- Modifiers المطلوبة min/max.
- عرض availability الفعلي.
- إنشاء Order عبر `create_order`.
- تعديل/استئناف Order عبر `update_order`.
- Multi-branch POS contract يستخدم `user_may_access_branch`.
- **Send to Kitchen داخل POS V2 مربوط فعليًا** بـ`pos.send_kitchen` و`send_to_kitchen` canonical RPC.
- kitchen delta-send محفوظ؛ لا يعيد إرسال الكميات السابقة.

غير مكتمل بعد:

- Payment / Split Payment.
- Discount / void / cancel / transfer / split UI والـapproval flows التابعة لها.
- Receipt print/reprint.
- **قرار المستخدم: خصم المخزون عند Send to Kitchen. هذا القرار لم يُثبت كمنفذ في الـRPC الحالي بعد، لأن العقد الحالي في HEAD يسجل KDS delta فقط؛ يلزم تنفيذ/اختبار هذا التغيير قبل اعتباره مكتملًا.**

### Shifts / Closing V2 ✅ للربط الحالي

- `/v2/shifts` مربوط بالـRoute والـSidebar.
- فتح الشفت permission-based + branch-access-based.
- المستخدم متعدد الفروع يستطيع امتلاك شفت مفتوح واحد فقط عبر الفروع المصرح بها.
- Header يقرأ الشفت المفتوح عبر فروع المستخدم ويعرض الانتقال للفرع الصحيح.
- فتح الشفت: `shifts.open`.
- إغلاق الشفت الشخصي: `shifts.close`.
- إدارة شفت مستخدم آخر: `shifts.manage`.
- لا bypass باسم `branch_manager`.
- تقارير user/shift/day closing مربوطة بالـRPCs الموجودة.

### Unified Approval Center — منفذ جزئيًا

تم:

- Queue موحدة: manager approvals + waste + stock counts + warehouse transfers.
- `decide_operational_approval` يوجه القرار إلى RPC الحقيقي لكل نوع.
- self-approval يحتاج `approvals.override` صراحة.
- الصفوف تعتمد `required_permission` بدل hard-code لاسم Role.
- approve/reject للهالك والجرد والتحويلات hardened مع Branch Access.

متبقي:

- route visibility النهائي حسب مجموعة Permissions الاعتماد الفعلية بدل أي Gate عام قديم.
- assigned-manager / policy configuration الكامل لكل نوع Action.

### Waste Center ✅ للـfixes الحالية

- تحميل/اختيار المنتجات حسب الفرع.
- `p_product_id` يرسل إلى `create_waste_entry`.
- Integration بمستخدم حقيقي وصلاحية `production.waste` بدل service-role bypass.
- النوع canonical للاختبار `finished_good`.

---

## 5) CI — آخر حالة مثبتة

### Verify #543 — checkpoint أخضر قبل Permission-first refactor

Run: `33850444754`
Head: `8c819f67ecef4012ca4cca4fb43da92475116d22`

- API contract ✅
- lint ✅
- typecheck ✅
- typecheck:all ✅
- unit ✅
- build ✅
- canonical migrations: 200/200 ✅
- schema ✅
- Integration/Security/RLS: 444/444 ✅
- Browser Smoke: 50 passed / 5 known legacy selector failures.

### Verify #559 — آخر Run على Permission-first HEAD

Run: `33866122650`
Head: `c7f6d7276b934e9d5f3114e270edbff139fab322`

Frontend job ✅ بالكامل:

- API contract ✅
- lint ✅
- typecheck ✅
- typecheck:all ✅
- unit ✅
- build ✅

DB job:

- Fresh DB/container setup ✅
- canonical migrations ✅
- schema verification ✅
- integration/security/RLS step ❌
- Browser Smoke لم يبدأ لأنه skipped بعد DB failure.

**لا يُفترض سبب فشل Integration من اسم الـrun فقط. يجب قراءة failing assertions/logs ثم إصلاح الاختبارات القديمة إذا كانت تخالف العقد الجديد، أو إصلاح الكود إذا ظهر Regression حقيقي. ممنوع إضعاف RLS أو إعادة owner implicit admin لإخضرار الاختبار.**

---

## 6) المتبقي — الترتيب الصحيح الآن

### أولوية 0 — إغلاق Permission-first regression gate

1. تحديد الاختبارات الفاشلة داخل Integration/Security/RLS في Verify #559.
2. تصنيف كل Failure:
   - stale test يتوقع `owner/admin role bypass` أو fallback قديم → تحديث Test فقط إلى العقد الجديد.
   - Regression حقيقي في Branch Access/Permission server-side → إصلاح الكود/المigration بدون إضعاف العزل.
3. إعادة Verify حتى Fresh DB + Integration/Security/RLS أخضر.
4. تشغيل Browser Smoke بعد فتح الـDB gate.
5. تحديث السجل بالنتيجة الجديدة.

### ثم استكمال V2

6. Approval Center visibility/policies النهائية Permission-first.
7. تنفيذ قرار **خصم المخزون عند Send to Kitchen** مع idempotent delta inventory effects واختبارات تمنع الخصم المكرر.
8. Payment + Split Payment باستخدام RPCs الرسمية.
9. POS structural actions + approval flow + print/reprint.
10. Waste V2 final UX/regression.
11. Inventory / warehouses / counts / transfers.
12. Catalog / products / modifiers.
13. Procurement / suppliers.
14. Sales / customers / refunds.
15. Accounting / treasury / reconciliation.
16. Unified table-first Reports.
17. Users / Roles / granular Permission Matrix / Settings / Audit final UX.
18. إذا كان المطلوب **Direct per-user permission overrides** مستقلًا عن Role template، إضافته لاحقًا إلى Effective Permission resolver + UI + RLS/tests بدون تغيير قاعدة أن Role label شكلي.
19. قبل الدمج النهائي: إغلاق known Browser helper regression بإصلاح Test-only المثبت أو إثبات بديله.
20. Final Verify كامل ثم فقط يصبح PR #6 مرشحًا للدمج.

---

## 7) Definition of Done لأي شاشة

لا تعتبر الشاشة مكتملة حتى:

- Queries/Mutations حقيقية وتعمل فعليًا.
- كل زر يعمل أو لا يظهر.
- loading/empty/error/success states.
- branch scope صحيح عبر `user_may_access_branch`/RLS.
- Permission هي gate الوظيفية؛ Role label لا يحجب Permission فعالة.
- UI permission + server permission للعمليات الحساسة.
- RTL/LTR + desktop/tablet/mobile.
- unit/contract tests.
- integration test لأي DB mutation.
- browser smoke للمسار الأساسي أو توثيق Regression legacy مثبت لا يخص الشاشة قبل الدمج.
- لا regression على KDS/inventory/accounting.

---

## 8) ثوابت لا تُفتح بدون قرار/Regression مثبت

- **Super Admin فقط** implicit full-access/platform admin.
- `owner` و`branch_manager` وأي Role آخر ليسوا admin bypass.
- Role name = label/template؛ Permissions + Branch Access = authorization.
- المستخدم يستطيع العمل على كل فرع مخول له، وليس الفرع الأساسي فقط.
- لا Permission تمنح وصولًا لفرع غير مخول، ولا Role label يحجب Permission فعالة داخل فرع مخول.
- Split Payment ≠ Split Order.
- Split/Merge/Transfer لا يسبب stock deduction أو KDS resend إلا إذا عُرّف عقد صريح لذلك.
- الأسعار والإجماليات الحساسة authoritative من الخادم.
- لا RLS bypass.
- public registration ليس مسار إنشاء مستخدم عادي.
- لا Demo/Seed tools في Production UI.
- لا حسابات مالية مستقلة في client بدل RPCs الرسمية.
- قرار خصم المخزون عند `send_to_kitchen` **مطلوب لكنه لا يعتبر منفذًا حتى يضاف effect idempotent ويجتاز الاختبارات**.

> أي مطور أو نموذج يكمل: اقرأ هذا الملف ثم `docs/FRONTEND_V2_REBUILD_LOG.md`، أعد قراءة HEAD/PR #6 أولًا، ولا تنشئ فرع تطوير إضافي.