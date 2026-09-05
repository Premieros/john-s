# Main Deviation Closure Log — 2026-09-05

> هذا السجل إلزامي لكل دفعة إصلاح على `Premieros/johna-s`.
> قاعدة البيانات الوحيدة المسموح بها للمشروع: Supabase project ref `azzdesuowpdcoflmyezn`.

## P0 — PR #18 Permission-First Root Drift

### نقطة البداية
- PR: `#18` — `refactor: enforce permission-first authorization at the root`.
- Branch: `fix/permission-first-root-drift-v2`.
- Verified head before this log entry: `918749d0d7f6bb19c60fa182766c151383989ca0`.
- Verify run: `33972141884` / `#696`.

### نتائج التحقق المثبتة
- Frontend API contract ✅
- Lint ✅
- TypeScript application ✅
- TypeScript tests ✅
- Unit ✅
- Build ✅
- Fresh PostgreSQL + canonical migrations ✅
- Schema verification ✅
- Integration / Security / RLS ❌
- Browser Smoke: skipped because DB gate failed.

### نطاق التغيير في PR #18
التغييرات محصورة في نموذج Permission-First:
- `src/lib/domains/types/users.ts`
- أربع migrations تبدأ بـ `20260905110500_...` وتنتهي بـ `20260905110600_...`
- Contract/Integration tests المرتبطة بالصلاحيات، modifiers، product units، stock valuation.

### قواعد الإصلاح
1. Super Admin فقط هو implicit bypass.
2. كل Role آخر Label فقط؛ الصلاحيات من `roles.permissions`.
3. لا إعادة Legacy permission aliases.
4. لا إضعاف RLS أو حذف/تخفيف اختبار لإخراج CI أخضر.
5. لا DDL على Production في هذه الدفعة.
6. لا استخدام لأي Supabase project غير `azzdesuowpdcoflmyezn`.
7. Browser Smoke لا يعتبر مكتملًا قبل نجاح Integration/Security/RLS.

### التشخيص الجاري
GitHub يعرض أن الفشل محصور في خطوة `npm run test:integration` لكنه لا يعرض النص الخام للـjob log عبر الموصل الحالي. سيتم إضافة artifact تشخيصي مؤقت/محدود إلى Workflow الفرع لالتقاط مخرجات Integration كاملة، ثم إصلاح الاختبار/العقد الفعلي فقط وإزالة التشخيص الزائد إن لم يعد مطلوبًا.

### الحالة
`IN_PROGRESS` — لا دمج قبل Full Verify أخضر.
