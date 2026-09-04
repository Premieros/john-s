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
- آخر Checkpoint مثبت قبل تحديث هذا السجل: `8c819f67ecef4012ca4cca4fb43da92475116d22`
- Supabase Production: `azzdesuowpdcoflmyezn`
- PR #3 وPR #5 مغلقان/superseded؛ لا يضاف عليهما تطوير جديد.
- جميع migrations المذكورة بعد Production baseline موجودة على فرع V2 فقط ما لم يُذكر صراحة خلاف ذلك، ولم تُطبق على Production من PR #6.

الخطة السابقة محفوظة في Git history. لا يعاد فتح عمل مغلق بدون Regression مثبت.

---

## 2) القرار المعماري

نبني **Frontend V2 من الصفر** فوق الـBackend/Database الحالية باعتبارها Source of Truth، مع إبقاء الواجهة القديمة مؤقتًا حتى اكتمال واستقرار V2.

قواعد ثابتة:

1. لا نعيد بناء قاعدة البيانات من الصفر.
2. لا نحذف Legacy DB إلا بعد dependency proof + migration + regression.
3. لا زر شكلي: كل Action يحتاج Backend حقيقي + Permission + حالات UI + اختبار.
4. Branch isolation server-side عبر `user_may_access_branch` والـRLS.
5. العقد الحالي يبقي `super_admin` و`owner` كـglobal admin؛ **ممنوع** إضافة `branch_manager` إلى `isAdminRole`.
6. **V2 permission-first:** اسم الدور يعتبر تسمية/قالبًا بقدر الإمكان، والتحكم الفعلي بالميزات والإجراءات يتم بالصلاحيات الصريحة. صلاحيات Super Admin/platform-only تظل استثناءً. لا نعيد كتابة مسار مستقر فقط للتنظيف، لكن أي Action جديد لا يعتمد على اسم الدور إذا كانت له Permission واضحة.
7. العربية RTL هي الأساس، الإنجليزية LTR.
8. الحسابات والمخزون والأسعار الحساسة authoritative من الخادم.
9. لا Production migration من PR #6 بدون طلب صريح وبعد Verify مناسب.

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

ملاحظة: بعض أدوار Production القديمة تحمل صلاحيات أوسع من المطلوب. لا نعيد تشكيل Production أثناء بناء V2؛ التحكم الجديد يبنى Permission-first مع اختبارات وصول ثم يتم أي تضييق لاحق بأمان.

---

## 4) ما تم في V2 حتى هذا الـCheckpoint

### Foundation ✅

- App Shell RTL-first جديد.
- Sidebar قابل للطي + mobile drawer.
- V2 branch context من الفروع التي تسمح بها RLS، وليس `users.branch_id` وحده.
- Capability registry يربط Modules/Actions بالـBackend.
- `/v2` Home/status surface.
- `useV2Can()` لقراءة permission strings الجديدة مباشرة من DB-backed roles بدون تقييدها بالـlegacy TypeScript union.

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
- Multi-branch POS contract يستخدم `user_may_access_branch` في المسارات التي تمسها V2.

غير مكتمل في UI بعد:

- زر Send to Kitchen داخل POS V2.
- Payment / Split Payment.
- Discount/void/cancel/transfer/split UI.
- Receipt print/reprint.

### Kitchen permission hardening ✅ على Fresh DB

Migration:
`20260904043000_harden_v2_kitchen_send_permission.sql`

- تم الحفاظ على العقد canonical: `send_to_kitchen(uuid, uuid DEFAULT NULL)`، بدون إعادة overload أحادي غامض.
- `pos.sell` لا يساوي صلاحية إرسال المطبخ.
- الإرسال يتطلب `pos.send_kitchen` أو platform admin وفق العقد الحالي.
- branch access عبر `user_may_access_branch`.
- delta-send/KDS response semantics محفوظة.
- Integration يثبت permission denial وcross-branch isolation.

### Shifts / Closing V2 — Backend + Page موجودة، الربط بالتنقل متبقٍ

- `open_shift` permission-based + branch-access-based.
- المستخدم متعدد الفروع يستطيع امتلاك شفت مفتوح واحد فقط عبر الفروع المصرح بها.
- Header V2 يقرأ الشفت المفتوح للمستخدم عبر كل فروعه ويعرض الانتقال للفرع الصحيح عند الحاجة.
- فتح الشفت مربوط بـ`open_shift` و`shifts.open`.
- إغلاق الشفت الشخصي يحتاج `shifts.close`، وإدارة شفت مستخدم آخر تحتاج `shifts.manage`.
- لا bypass باسم `branch_manager`.
- branch scope عبر `user_may_access_branch`.

Migration:
`20260904044000_harden_v2_shift_close_permission.sql`

صفحة V2 موجودة فعليًا:
`src/v2/pages/V2ShiftsPage.tsx`

وتستخدم:
- `get_active_shift`
- `close_shift`
- `get_user_closing_report`
- `get_shift_closing_report`
- `get_day_closing_report`

**المتبقي لهذه الخطوة فقط:** ربط `/v2/shifts` بالـRoute والـSidebar ثم Verify.

### Unified Approval Center — منفذ جزئيًا

- Queue موحدة تجمع حاليًا manager approvals + pending waste + submitted stock counts + pending warehouse transfers.
- `decide_operational_approval` يوجه القرار إلى RPC الحقيقي لكل نوع.
- self-approval يحتاج `approvals.override` صراحة، وليس اسم الدور.
- `ApprovalCenterPage` يقرأ `required_permission` لكل صف بدل hard-code لـ`branch_manager`.

Migration hardening:
`20260904045000_harden_v2_operational_approval_targets.sql`

- direct `approve_waste` permission + branch checked.
- approve/reject stock count multi-branch safe.
- approve/reject warehouse transfer permission + branch checked.

متبقي:
- route visibility حسب صلاحيات الاعتماد الفعلية بدل `settings.manage`.
- assigned-manager/policy configuration الكامل لكل نوع Action لم يكتمل بعد.

### Waste Center ✅ للـfixes الحالية

- تم إصلاح تحميل/اختيار المنتجات حسب الفرع.
- `p_product_id` يرسل فعليًا إلى `create_waste_entry`.
- Fixture القديم لم يعد يعتمد على `service_role` bypass؛ Integration يعمل بمستخدم حقيقي وصلاحية `production.waste`.
- نوع الهالك في V2 test أصبح canonical `finished_good`.

---

## 5) CI checkpoint — Verify #543

Run: `33850444754`
Head المختبر: `8c819f67ecef4012ca4cca4fb43da92475116d22`

### Frontend ✅

- API contract ✅
- lint ✅
- typecheck ✅
- typecheck:all ✅
- unit ✅
- build ✅

### Fresh DB / Security ✅

- canonical migrations: **200 applied / 0 skipped** ✅
- schema verification ✅
- expected tables: 60/60 ✅
- expected functions: 65/65 ✅
- contract RPCs: 107/107 ✅
- contract tables: 61/61 ✅
- Integration/Security/RLS: **57 files / 444 tests passed** ✅

ومنها:
- V2 kitchen permission 3/3 ✅
- V2 operational approval security 5/5 ✅
- V2 multi-branch shift contract 6/6 ✅
- Waste Center 8/8 ✅

### Browser Smoke — known legacy failure، ليس Regression من V2

- 50 passed / 5 failed.
- الخمس حالات نفسها تتوقف في `tests/e2e/pos-actions.spec.ts` عند helper `addProduct` انتظار `pos-cart-qty-...`.
- هذا نفس stale direct-add selector المثبت سابقًا على الـlegacy POS، قبل الوصول لمنطق kitchen/payment الحالي.
- الإصلاح المعروف Test-only موجود تاريخيًا في commit `8d5fb44cd3da3b67b753cc4bd14e8ce3a58a1859` (`test: target direct POS add action`).
- **ممنوع** تعديل منطق POS الحقيقي لإسكات هذه الاختبارات؛ إذا احتجنا إغلاق Browser gate ننقل إصلاح الاختبار الضيق فقط بعد إعادة قراءة الـHEAD.

لا يوجد تطبيق جديد على Production من هذا الـCheckpoint.

---

## 6) ترتيب التنفيذ المتبقي

1. ربط شاشة **Shifts/Closing V2** بالمسار `/v2/shifts` والـSidebar فقط.
2. Verify ثم تحديث السجل عند نجاح الربط.
3. ربط **Send to Kitchen** داخل POS V2 بـ`pos.send_kitchen` وRPC canonical.
4. Verify ثم تحديث السجل.
5. جعل Approval Center قابلًا للوصول حسب صلاحيات الاعتماد الفعلية بدل `settings.manage`.
6. Payment + Split Payment في POS V2 باستخدام RPCs الرسمية.
7. POS structural actions + approval flow + print/reprint.
8. Waste V2 final UX/regression.
9. Inventory / warehouses / counts / transfers.
10. Catalog / products / modifiers.
11. Procurement / suppliers.
12. Sales / customers / refunds.
13. Accounting / treasury / reconciliation.
14. Unified table-first Reports.
15. Users / Roles / granular Permission Matrix / Settings / Audit — مع الحفاظ على permission-first وعدم إعادة عمل المسارات المستقرة بلا Regression.
16. قبل الدمج النهائي: إغلاق known Browser helper regression بإصلاح Test-only المثبت أو إثبات بديله.

---

## 7) Definition of Done لأي شاشة

لا تعتبر الشاشة مكتملة حتى:

- Queries/Mutations حقيقية وتعمل فعليًا.
- كل زر يعمل أو لا يظهر.
- loading/empty/error/success states.
- branch scope صحيح.
- UI permission + server permission للعمليات الحساسة.
- RTL/LTR + desktop/tablet/mobile.
- unit/contract tests.
- integration test لأي DB mutation.
- browser smoke للمسار الأساسي أو توثيق Regression legacy مثبت لا يخص الشاشة قبل الدمج.
- لا regression على KDS/inventory/accounting.

---

## 8) ثوابت لا تُفتح بدون Regression

- `send_to_kitchen` لا يخصم physical inventory؛ sale هو مسار الخصم الرسمي الحالي.
- Split Payment ≠ Split Order.
- Split/Merge/Transfer لا يسبب stock deduction أو KDS resend.
- الأسعار والإجماليات الحساسة authoritative من الخادم.
- لا RLS bypass.
- public registration ليس مسار إنشاء مستخدم عادي.
- لا Demo/Seed tools في Production UI.
- لا حسابات مالية مستقلة في client بدل RPCs الرسمية.
- لا Role-name authorization لمسار V2 جديد إذا كانت له Permission صريحة مناسبة.

> أي مطور أو نموذج يكمل: اقرأ هذا الملف ثم `docs/FRONTEND_V2_REBUILD_LOG.md`، أعد قراءة HEAD/PR #6 أولًا، ولا تنشئ فرع تطوير إضافي.
