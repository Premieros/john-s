# CURRENT WORK PLAN — john-s / Frontend V2

> **Source of Truth لأي نموذج أو مطور يكمل العمل. اقرأ هذا الملف أولًا.**
>
> السجل التنفيذي التفصيلي للمرحلة الحالية: [`docs/FRONTEND_V2_REBUILD_LOG.md`](./FRONTEND_V2_REBUILD_LOG.md)

آخر تحديث: **2026-09-04 — Africa/Cairo**

---

## 1) الحالة الحالية

- Repository: `Premieros/johna-s`
- Production branch: `main`
- Production HEAD عند بدء V2: `4e63ce21597958dc9ee9852ca2ff00e4e14c86a3`
- **فرع التطوير الوحيد من الآن:** `development/frontend-v2`
- Frontend V2 branch بدأ من work-in-progress SHA: `cdeb587893132a6fa10f95dc767c58b02a0603a9`
- Supabase Production: `azzdesuowpdcoflmyezn`
- PR #3 وPR #5 أصبحا superseded بالفرع الموحد؛ لا يضاف عليهما تطوير جديد.

الخطة السابقة قبل V2 محفوظة بالكامل في Git history حتى `main@4e63ce21597958dc9ee9852ca2ff00e4e14c86a3`، ولا تُحذف حقائقها أو العقود المغلقة لمجرد إعادة بناء الواجهة.

---

## 2) القرار الحالي

بناء **Frontend V2 من الصفر** فوق الـBackend/Database الحالية، بدل الاستمرار في ترقيع صفحات الواجهة القديمة.

القواعد:

1. قاعدة البيانات والـRPCs والـRLS الحالية هي Source of Truth للمنطق الخلفي.
2. لا نعيد بناء DB من الصفر.
3. لا نحذف Legacy DB أثناء إعادة بناء UI إلا بعد dependency proof + migration + regression.
4. لا يوجد زر شكلي؛ كل Action يجب أن يكون له backend حقيقي وصلاحية واختبار.
5. Branch isolation دائمًا server-side عبر `user_may_access_branch` والـRLS.
6. `super_admin` و`owner` فقط global admin؛ لا تضف `branch_manager` إلى `isAdminRole`.
7. العربية RTL هي الأساس، الإنجليزية LTR.
8. الواجهة القديمة تبقى موجودة مؤقتًا حتى اكتمال Modules V2 واختبارها.
9. لا تطبق migrations V2 على Production قبل Verify كامل أخضر وبطلب صريح.

---

## 3) نتيجة فحص قاعدة Production الحالي

تم الفحص قراءة فقط في 2026-09-04:

- 100 public tables
- 243 public functions
- 331 RLS policies
- 2 active branches
- 8 active users
- 335 active products
- 2 active warehouses

تم تقسيم DB إلى:

- **Canonical:** users/roles/branches/user_branch_access، POS/orders/KDS/sales/shifts، catalog/modifiers، inventory/units/counts/transfers، procurement، waste/approvals، accounting/treasury/reports.
- **Legacy/Compatibility:** subscriptions/plan feature paths، وعدد من raw-material/recipes/production paths القديمة أو المختلطة؛ لا تُعرض تلقائيًا في V2 لمجرد وجودها.
- **Hardening backlog:** مراجعة function overloads وبعض SECURITY DEFINER search_path configurations على دفعات، بدون broad rewrite.

التفاصيل والأسماء والقرارات الدقيقة موجودة في `docs/FRONTEND_V2_REBUILD_LOG.md`.

---

## 4) ترتيب التنفيذ الملزم

1. V2 Foundation: App Shell + branch context + capability/permission registry.
2. POS V2 كامل مرتبط بالـbackend الفعلي.
3. Shifts + per-user close + shift close + day close لجميع الشفتات.
4. Approval Center الموحد.
5. Waste Center.
6. Inventory / warehouses / counts / transfers.
7. Products / categories / modifiers.
8. Procurement / suppliers.
9. Sales / customers / refunds.
10. Accounting / treasury / reconciliation.
11. Reports unified table-first.
12. Users / roles / granular permissions / settings / audit.

---

## 5) تعريف النجاح لأي شاشة

لا تعتبر الشاشة مكتملة حتى:

- كل Query/Mutation المستخدمة موجودة فعليًا.
- كل زر يعمل أو لا يظهر.
- loading / empty / error / success states موجودة.
- branch scope صحيح.
- permission gate صحيح في UI وserver عند الحاجة.
- RTL/LTR وdesktop/tablet/mobile.
- unit/contract tests.
- integration test لأي عملية تغير DB.
- browser smoke للمسار الأساسي.

---

## 6) الثوابت التي لا يعاد فتحها بدون Regression

- `send_to_kitchen` لا يخصم المخزون؛ sale هو مسار الخصم الرسمي الحالي.
- Split Payment ≠ Split Order.
- Split/Merge/Transfer لا يسبب stock deduction أو KDS resend.
- manager approvals single-use حيث العقد الحالي يفرض ذلك.
- الأسعار/الإجماليات الحساسة authoritative من الخادم.
- لا bypass لـRLS.
- public registration غير معتمد كمسار مستخدم عادي.
- لا Demo/Seed tools في Production UI.
- الحسابات والتقارير المالية لا تعتمد على حسابات client مستقلة عن DB.

---

## 7) Next exact step

1. أكمل توحيد العمل على `development/frontend-v2` فقط.
2. أصلح Navigation permission الخاصة بـApproval Center التي أوقفت Verify #516.
3. ابنِ V2 App Shell وmulti-branch context من `user_branch_access`/RLS بدل `users.branch_id` فقط.
4. أنشئ Capability Registry يربط كل زر بـpermission + backend action.
5. ابدأ POS V2 بالـTables/Order types/Cart ثم Kitchen/Approval/Payment.
6. شغّل Verify كامل قبل أي دمج أو Production migration.

> أي مطور أو نموذج يبدأ من `docs/FRONTEND_V2_REBUILD_LOG.md` بعد قراءة هذا الملف، ولا يعود لتفريع العمل على فروع مؤقتة متعددة.
