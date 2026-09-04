# CURRENT WORK PLAN — john-s

> **Source of Truth لأي نموذج أو مطور يكمل العمل. اقرأ هذا الملف أولًا.**
>
> السجل التنفيذي التفصيلي: [`docs/FRONTEND_V2_REBUILD_LOG.md`](./FRONTEND_V2_REBUILD_LOG.md)

آخر تحديث: **2026-09-05 — Africa/Cairo**

## 1) الحالة الحالية

- Repository: `Premieros/johna-s`.
- Baseline قبل تنظيف نموذج الصلاحيات: `main@54e3711`.
- فرع التدقيق الحالي: `fix/permission-model-zero-drift` — Draft PR #12.
- Production لم يُعدّل ضمن حزمة التنظيف الحالية.
- V2 هي Gateway فقط إلى مساحات التشغيل الأصلية؛ لا يوجد POS/Shifts/Home موازٍ في V2.

## 2) القرارات التشغيلية الثابتة

1. **Super Admin فقط** له implicit full-access. كل دور آخر يعتمد على `roles.permissions`.
2. يوجد اسم Canonical واحد لكل Capability تشغيلية؛ أسماء Legacy لا تُضاف إلى UI أو Permission Matrix أو أي كود جديد.
3. Branch Access يأتي من `user_may_access_branch()` و`user_branch_access` مع الفرع الأساسي، والواجهة لا تتجاوز RLS.
4. إرسال المطبخ يخصم مخزون الـdelta الجديد فقط ويسجل Inventory Events/Effects، والدفع لا يخصم المخزون مرة أخرى.
5. الصلاحيات الحساسة تُفرض في الخادم أيضًا؛ إخفاء زر في UI ليس حماية.
6. Split Payment ليس Split Order؛ النقل/الفصل لا يعيدان خصم المخزون أو إرسال KDS.
7. لا Merge/Deploy لحزمة تشغيلية قبل TypeScript + Unit + Build + Fresh DB + Schema + Integration/RLS + Browser Smoke.

## 3) العقود المغلقة على main ✅

- POS: `pos.view`, `pos.order.create`, `pos.order.edit`, `pos.payment.take`, `pos.order.split`, `pos.order.transfer`, `pos.receipt.print`, `pos.send_kitchen`.
- KDS: `pos.kds_view`.
- الهالك: عنصر محدد + مخزن محدد + اعتماد + خصم فعلي موثق؛ القراءة بـ`waste.view`.
- الموافقات: `approvals.review`, `approvals.override`, `approvals.policy.manage` مع سياسات فرع/مبلغ/صلاحية/مستخدم.
- Multi-branch: اختيار فرع موحد عبر `premier_active_branch` مع RLS.
- Production API Parity وGitHub Pages كانا أخضرين على baseline المذكور أعلاه.

## 4) حزمة Zero Permission Drift الحالية

الهدف هو إزالة أي ازدواج قد يسبب تعارضًا مستقبليًا، وليس الحفاظ على توافق واجهي مع أدوار غير مستخدمة حاليًا.

### Canonical permissions

- Products: `products.view`, `products.create`, `products.edit`, `products.delete`, `products.modifiers.manage`.
- Stock counts: `inventory.view`, `inventory.count.create`, `inventory.count.approve`.
- Transfers: `inventory.view`, `inventory.transfer.create`, `inventory.transfer.approve`.
- Inventory ledger: `inventory.ledger.view`.
- Procurement actions: `procurement.request.create`, `procurement.order.create`, `procurement.receive`, `procurement.payment.create`.
- Accounting actions: `accounting.journal.post`, `accounting.treasury.transfer`, `accounting.reconciliation.manage`.

### Legacy permissions المحذوفة من التطبيق

`pos.sell`, `pos.pay`, `pos.transfer_order`, `pos.split_order`, `products.manage`, `inventory.manage`, `inventory.transfers`, `inventory.transfers.approve`, `catalog.view`, `procurement.view`, `accounting.view`, `admin.view`.

قد تظل الأسماء التاريخية داخل migrations القديمة كسجل تاريخي فقط؛ لا يجوز إعادة استخدامها في TypeScript أو Permission Matrix أو Routes أو UI جديد.

### Dead code المحذوف

- `src/v2/pages/V2PosPage.tsx`
- `src/v2/pages/V2ShiftsPage.tsx`
- `src/v2/pages/V2HomePage.tsx`
- `src/v2/components/V2AppShell.tsx`

`useV2Can` إن استُخدم مع permission string ديناميكي فهو Adapter إلى `useCan` فقط وليس Authorization model ثانيًا.

## 5) بوابة التحقق الحالية

- API contract جرى تحديثه بعد إزالة V2 dead code؛ الجداول التي لم يعد Frontend يقرأها مباشرة هي: `approval_requests`, `product_modifier_groups`, `product_modifier_options`, `shifts`.
- Draft PR #12 يجب أن يبقى غير مدمج حتى يمر: API contract، Lint، TypeScript application/tests، Unit، Build، Fresh DB، Schema، Integration/Security/RLS، Browser Smoke.
- أي فشل يُصلح في سببه فقط؛ لا نعيد Legacy permission ولا نضع role-name bypass لتجاوز الاختبار.

## 6) المتبقي بعد Zero Drift

- نظام الطباعة المحلي بثلاث محطات ثابتة فقط لكل فرع: `cashier`, `kitchen`, `barista`، وأي صنف بلا محطة يذهب للمطبخ مع تنبيه للمدير.
- حماية `main` بـrequired checks إن سمحت صلاحيات GitHub الإدارية المتاحة؛ CI وحده لا يكفي إن كان direct push مسموحًا.

## 7) Definition of Done

- Capability واحدة = Permission canonical واحدة لكل فعل.
- UI action + server authorization + branch/RLS متوافقة.
- لا duplicate operational implementation قابل للصيانة بالخطأ.
- Source of Truth محدث مع كل Merge.
- Fresh DB + Integration/Security/RLS + Browser Smoke أخضر.
- Production لا يتغير إلا بطلب صريح منفصل.
