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
- Supabase Production: `azzdesuowpdcoflmyezn`
- PR #3 وPR #5 مغلقان/superseded؛ لا يضاف عليهما تطوير جديد.
- جميع migrations المذكورة في هذا الملف بعد baseline هي **على فرع V2 فقط** ولم تُطبق على Production.

الخطة السابقة محفوظة في Git history. لا يعاد فتح عمل مغلق بدون Regression مثبت.

---

## 2) القرار المعماري

نبني **Frontend V2 من الصفر** فوق الـBackend/Database الحالية باعتبارها Source of Truth، مع إبقاء الواجهة القديمة مؤقتًا حتى اكتمال واستقرار V2.

قواعد ثابتة:

1. لا نعيد بناء قاعدة البيانات من الصفر.
2. لا نحذف Legacy DB إلا بعد dependency proof + migration + regression.
3. لا زر شكلي: كل Action يحتاج Backend حقيقي + Permission + حالات UI + اختبار.
4. Branch isolation server-side عبر `user_may_access_branch` والـRLS.
5. `super_admin` و`owner` فقط global admin؛ **ممنوع** إضافة `branch_manager` إلى `isAdminRole`.
6. العربية RTL هي الأساس، الإنجليزية LTR.
7. الحسابات والمخزون والأسعار الحساسة authoritative من الخادم.
8. لا Production migration من PR #6 قبل Verify كامل أخضر وطلب صريح.

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

ملاحظة مثبتة من Production: بعض الأدوار القديمة — وخصوصًا `cashier` — تحمل صلاحيات أوسع من المطلوب. لا يتم سحبها مباشرة من Production؛ V2 يبني Permission Matrix واختبارات وصول أولًا ثم يتم التضييق بأمان.

---

## 4) ما تم في V2 حتى هذا الـCheckpoint

### Foundation ✅ / مستمر

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
- Multi-branch POS contract يستخدم `user_may_access_branch` بدل مساواة `users.branch_id` في RPCs التي تمسها V2.

غير مكتمل في UI بعد:

- زر Send to Kitchen داخل POS V2.
- Payment / Split Payment.
- Discount/void/cancel/transfer/split UI.
- Receipt print/reprint.

### Kitchen permission hardening — branch only

Migration:
`20260904043000_harden_v2_kitchen_send_permission.sql`

- `pos.sell` يسمح بإنشاء Order فقط.
- `send_to_kitchen(uuid)` يتطلب `pos.send_kitchen` (أو global admin).
- branch access يبقى عبر `user_may_access_branch`.
- delta-send/KDS behavior لم يتغير.
- Integration test جديد يثبت أن `pos.sell` وحدها لا تسمح بإرسال المطبخ وأن cross-branch يظل مرفوضًا.

### Shifts / multi-branch — Backend + Header V2

- `open_shift` أصبح permission-based + branch-access-based.
- مستخدم متعدد الفروع يفتح **شفت واحد فقط** في أي فرع مصرح له.
- Header V2 يقرأ الشفت المفتوح للمستخدم عبر كل فروعه.
- إذا كان الشفت في فرع آخر يظهر الانتقال لذلك الفرع بدل محاولة فتح شفت ثانٍ.
- فتح الشفت من Header مربوط فعلًا بـ`open_shift` و`shifts.open`.

Migration:
`20260904044000_harden_v2_shift_close_permission.sql`

- إغلاق الشفت الشخصي يحتاج `shifts.close`.
- إغلاق شفت مستخدم آخر يحتاج `shifts.manage`.
- لا bypass بسبب اسم `branch_manager`.
- branch scope عبر `user_may_access_branch`.
- Integration test يغطي secondary branch + one-open-shift + unauthorized branch + explicit close permission.

تقارير DB موجودة على الفرع:
- `get_user_closing_report`
- `get_shift_closing_report`
- `get_day_closing_report`

لكن شاشة تقارير الإغلاق V2 لم تُبنَ بعد.

### Unified Approval Center — منفذ جزئيًا

- Queue واحدة تجمع حاليًا:
  - manager approvals
  - pending waste
  - submitted stock counts
  - pending warehouse transfers
- `decide_operational_approval` يوجه القرار إلى RPC الحقيقي لكل نوع.
- المدير لا يوافق على طلبه لمجرد اسم الدور؛ self-approval يحتاج `approvals.override` صراحة.
- Integration test محدث يثبت:
  - review بدون override → `SELF_APPROVAL_FORBIDDEN`
  - review + override → self approval مسموح.
- `ApprovalCenterPage` يقرأ `required_permission` لكل صف ويقرر إتاحة زر الموافقة من DB permissions، بدون `branch_manager` hard-code.

Migration hardening:
`20260904045000_harden_v2_operational_approval_targets.sql`

- direct `approve_waste` أصبح permission + branch checked.
- approve/reject stock count أصبح multi-branch safe عبر `user_may_access_branch`.
- approve/reject warehouse transfer أصبح permission + branch checked داخل SECURITY DEFINER.

متبقي:
- فك route visibility القديم من `settings.manage` بحيث يرى مركز الموافقات من لديه أي صلاحية اعتماد فعلية، بدون فتح Settings له.
- assigned-manager/policy configuration الكامل لكل نوع Action لم يكتمل بعد.

### Waste Center

- تم إصلاح تحميل/اختيار المنتجات حسب الفرع.
- `p_product_id` يرسل فعليًا إلى `create_waste_entry`.
- المنتج يظهر في جدول الهالك بدل تسجيل هالك بلا منتج.

---

## 5) CI checkpoint

Baseline سابق مثبت في Verify #525:

- frontend API contract ✅
- lint ✅
- typecheck ✅
- typecheck:all ✅
- unit ✅
- Fresh DB migrations ✅
- schema/contract verification ✅
- integration وصل إلى فشل واحد فقط بسبب اختبار self-approval القديم؛ تم تحديث الاختبار ليغطي `approvals.override` صراحة.

بعد ذلك أضيفت migrations/tests الخاصة بـKitchen/Shift/Operational approvals وHeader shift؛ **آخر Verify على HEAD الحالي يجب قراءته قبل أي تعديل جديد**.

لا تعتبر هذه المجموعة Production-ready حتى:

- Fresh DB ✅
- integration/security/RLS ✅
- browser smoke ✅ أو أي failure قديم يثبت أنه unrelated ويغلق/يصلح قبل الدمج.

---

## 6) ترتيب التنفيذ المتبقي

1. إغلاق Verify على HEAD الحالي وإصلاح أي Regression فقط.
2. ربط **Send to Kitchen** داخل POS V2 بالصلاحية الجديدة Server-side.
3. بناء شاشة Shifts/Closing V2:
   - user closing report
   - shift closing + actual cash
   - shift report
   - day close يجمع كل الشفتات.
4. جعل Approval Center قابلًا للوصول حسب صلاحيات الاعتماد الفعلية بدل `settings.manage`.
5. Payment + Split Payment في POS V2 باستخدام RPCs الرسمية.
6. POS structural actions + approval flow + print/reprint.
7. Waste V2 final UX/regression.
8. Inventory / warehouses / counts / transfers.
9. Catalog / products / modifiers.
10. Procurement / suppliers.
11. Sales / customers / refunds.
12. Accounting / treasury / reconciliation.
13. Unified table-first Reports.
14. Users / Roles / full granular Permission Matrix / Settings / Audit.

---

## 7) Definition of Done لأي شاشة

لا تعتبر الشاشة مكتملة حتى:

- Queries/Mutations موجودة وتعمل فعليًا.
- كل زر يعمل أو لا يظهر.
- loading/empty/error/success states.
- branch scope صحيح.
- UI permission + server permission للعمليات الحساسة.
- RTL/LTR + desktop/tablet/mobile.
- unit/contract tests.
- integration test لأي DB mutation.
- browser smoke للمسار الأساسي.
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

> أي مطور أو نموذج يكمل: اقرأ هذا الملف ثم `docs/FRONTEND_V2_REBUILD_LOG.md`، أعد قراءة HEAD/PR #6 أولًا، ولا تنشئ فرع تطوير إضافي.
