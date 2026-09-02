# CURRENT WORK PLAN — john-s

> المرجع الرئيسي لحالة العمل الحالية. يُحدّث بعد كل إصلاح أو قرار معماري أو نتيجة CI مهمة.

آخر تحديث: 2026-09-02

## 1) الحالة العامة — Baseline أخضر ✅

المشروع يعمل على `main` مع Supabase Production: `azzdesuowpdcoflmyezn`.

Baseline المعتمد بعد الفحص الشامل:
- HEAD الذي اجتاز البوابات: `d0249fb50da0733d6cbb5aa7e3a0481a2bfe21b1`.
- Verify main #178 / run `33594520386`: **SUCCESS**.
- App: lint ✅ typecheck ✅ typecheck:all ✅ unit ✅ build ✅
- Fresh DB: canonical migrations ✅ schema verification ✅
- Integration + Security + RLS regression ✅
- Playwright Browser Smoke ✅
- Deploy #180 / run `33594520436`: **SUCCESS**.

تم تطبيق آخر hardening أيضًا على Production، مع بقاء التسجيل العام مغلقًا.

---

## 2) سلامة Production — فحص شامل ✅

نتائج الفحص المباشر:
- مخزون سالب: **0**.
- دفعات مخزون سالبة: **0**.
- قيود محاسبية غير متوازنة: **0**.
- Orphan sale/purchase/order items: **0**.
- اختلافات إجماليات البيع: **0**.
- اختلافات إجماليات الشراء: **0**.
- استلام مشتريات أكبر من المطلوب: **0**.
- خلل حالة الطاولات/الطلبات المفتوحة: **0**.
- المنتجات القابلة للبيع ذات مسار مخزون: **335/335**.
- جداول تشغيلية بدون RLS: **0**.
- Supabase Security Advisor: لا توجد **ERRORS** حالية.

تحذيرات الأداء المتبقية ليست Release Blockers؛ لم يتم حذف `unused indexes` عشوائيًا لأن الإنتاج حديث وقد لا تكون الإحصائيات ممثلة للاستخدام الحقيقي بعد.

---

## 3) Security Surface Hardening — مكتمل ✅

Migrations الرئيسية في دفعة الإغلاق:
- `20260902073000_final_security_surface_hardening.sql`
- `20260902074000_final_anon_deny_by_default.sql`
- `20260902075000_disable_legacy_privileged_client_rpcs.sql`
- `20260902075500_lock_internal_accounting_and_legacy_kds_helpers.sql`
- `20260902080000_remove_verified_duplicate_indexes.sql`
- `20260902081000_final_branch_rpc_isolation.sql`
- `20260902082000_allow_db_admin_internal_setup_helpers.sql`
- `20260902083000_grant_service_role_internal_rpcs.sql`

الحالة النهائية:
- `anon` لا يملك صلاحيات مباشرة على جداول `public`.
- الاستثناءان قبل تسجيل الدخول فقط: `get_login_email(text)` و`record_login_failure(text)`.
- `register_tenant` مغلق أمام `anon` و`authenticated` ويعمل كـinternal provisioning فقط.
- `bootstrap_initial_super_admin` مغلق أمام `anon` و`authenticated`.
- `service_role` و`postgres` يحتفظان بالوصول الداخلي المطلوب بدون إعادة فتح RPCs للعميل.
- `schema_migrations` مغلق عن العملاء مع RLS.
- View `units` تعمل `security_invoker`.
- `search_path` للدوال الحساسة مثبت إلى `public, pg_temp` حيث لزم.
- دوال الخصم المباشر للمخزون، Audit helpers، Accounting seed helpers، وLegacy KDS inventory helpers ليست RPCs عامة للعميل.
- تم إغلاق تسريب branch availability/RPCs التي كانت تقبل `branch_id` خارجيًا بدون تحقق كافٍ.
- الاختبارات تثبت صراحةً أن `anon` لا يستطيع تشغيل Tenant provisioning.

ملاحظة خارج الكود: Supabase Leaked Password Protection ما زالت إعدادًا من لوحة Auth وليست migration داخل المستودع.

---

## 4) بيانات التشغيل / Excel ✅

- المنتجات: **352/352**.
- الأقسام: **30/30**.
- أسماء المنتجات المكررة: **0**.
- منتجات بدون قسم: **0**.
- الخامات: **215**.
- المنتجات ذات الوصفة: **265**.
- أسطر الوصفات: **1205**.
- وصفات فارغة: **0**.
- منتجات بلا وصفة مصدر: **87**.

التكلفة لا تعتمد تكلفة Excel ثابتة؛ الخامات والمصنعات تعتمد على المشتريات والدفعات الفعلية.

---

## 5) Hybrid Inventory / Manufacturing ✅

- المنتجات المصنعة الداخلية: **17** ومخفية من POS كمنتجات بيع مستقلة.
- `inventory_units` المصنعة: **17**.
- علاقات Product → manufactured unit: **52**.
- Nested manufacturing مدعوم عبر `inventory_unit_recipe_units`.
- البيع يخصم مرة واحدة فقط من المسار الفعلي:
  - direct raw recipe → خامات FIFO.
  - manufactured unit → `inventory_unit_batches`.
  - ready product → `inventory_batches/inventory`.
- لا يوجد منتج قابل للبيع بلا مسار مخزون: **335/335**.

قاعدة ثابتة: KDS لا يخصم المخزون؛ نقطة الخصم هي البيع.

---

## 6) KDS / Orders ✅

- `send_to_kitchen` State/Snapshot فقط.
- `sent_quantity` يدعم Delta عند زيادة كمية سطر سبق إرساله.
- Approved kitchen void يخفض الكمية المرسلة الصافية.
- Legacy KDS inventory consumption/reversal RPCs مقفلة عن العميل.
- Cancel sent item محمي Server-side ويمر عبر Manager Approval للكاشير عند الحاجة.

---

## 7) Manager Approvals — P1 ✅ أساسيًا

مكتمل Server-side مع Audit:
- Discount.
- Reprint.
- Cancel sent item.
- Refund.
- Change payment method.
- Force close shift.
- Open drawer authorization/audit.
- Realtime approval inbox + استهلاك الموافقة مرة واحدة.
- Cashier/Manager approval lifecycle مغطى بالاختبارات.

المتبقي الاختياري فقط:
- حسم `void_order` إذا كان سيبقى له مسار تشغيل مستقل عن cancel/refund.
- Hardware drawer pulse يحتاج Printer/Hardware bridge؛ قاعدة البيانات تغطي الإذن والموافقة والتدقيق فقط.

---

## 8) Sale Financial Authority — P2 ✅

- Online POS يكتب عبر `process_sale` فقط.
- Direct INSERT إلى `sales` و`sale_items` من المستخدم المسجل مرفوض.
- أسعار السطور والإجماليات والضريبة النهائية Server-authoritative.
- لا يتم الوثوق في `subtotal`, `tax_amount`, `total`, `unit_price` القادمة من الواجهة.
- `paid_amount` لا يتجاوز إجمالي الخادم.
- الكميات غير الموجبة مرفوضة قبل الكتابة.
- رفض الخادم لا يتحول إلى Offline success.
- فشل الشبكة الغامض لا يُصفّ تلقائيًا كبيع Offline لتجنب البيع المكرر.
- Create/update order staging أصبح Server-authoritative بدل تخزين totals مزورة من العميل.
- ضريبة الفرع تستخدم effective branch settings مع fallback للإعدادات العامة.
- خصومات السطر/الفاتورة تمر القيود وموافقة المدير عند الحاجة.
- أخطاء `INVALID_PRODUCT` و`INVALID_QUANTITY` مفصولة بوضوح.

---

## 9) Purchase UOM / Partial Receiving ✅

Migrations:
- `20260902020000_purchase_raw_uom_normalization.sql`
- `20260902061000_purchase_receipt_uom_accounting.sql`
- `20260902071000_purchase_order_input_uom_validation.sql`

مغلق:
- kg ↔ g و l ↔ ml بالتحويل الصحيح للكمية والتكلفة.
- UOM غير المتوافق يرفض بدل تلويث المخزون.
- Partial receipts تطبع الكمية المستلمة الفعلية لا كامل PO line.
- حركة كل GRN تحفظ مرجع `purchase_receipt`.
- إكمال عدة GRNs يبني قيمة المخزون/القيد من كامل أمر الشراء.
- Manual PO يجمع subtotal/total من البنود.
- `paid_amount` لا يتجاوز PO total.
- Integration E2E يغطي: 2kg @ 120/kg → 0.5 + 1.5 → 2000g @ 0.12/g → قيد 240 متوازن.

---

## 10) Branch Visibility — P3 ✅

`BranchBadge` والهوية الفعلية للفرع مغطاة في:
- Products + Raw Materials.
- Sales / invoices / refunds + Shifts.
- Purchases + Receipts + Backorders.
- Purchase Requests + RFQs.
- Inventory + Warehouses + Transfers.
- Inventory Batches + Inventory Ledger.
- Users.
- Customers + Suppliers + exports.
- Audit Log.
- Reports والتجميعات عند اختيار كل الفروع.
- POS receipt وShift/Z reports الأساسية.

Backorders RPC يعيد `branch_id` ويحافظ على branch isolation.

---

## 11) Products vs POS — P4 ✅

- ProductsPage: server-side search على `name`, `name_en`, `barcode`, `sku`.
- Pagination حقيقية من السيرفر.
- POS catalog: `branch_id = effectiveBranch` + `is_active = true`.
- تعديلات/حذف المنتجات تبطل Offline POS catalog cache.
- Contract tests تثبت عدم الرجوع إلى بحث داخل أول 100 سجل أو نطاق فرع مختلف.

---

## 12) قرارات ثابتة

- لا نحذف أو نضعف RLS أو الاختبارات لتجاوز فشل.
- لا نثق في بيانات العميل في العمليات المالية.
- Public signup مغلق؛ Tenant provisioning داخلي فقط.
- لا نفتح Internal RPCs للمستخدم المسجل لمجرد إنجاح الاختبارات.
- KDS لا يخصم المخزون؛ البيع يخصم مرة واحدة فقط.
- لا ننشئ self-links أو مخزونًا وهميًا للعرض.
- التكلفة التشغيلية من المشتريات/الدفعات الفعلية.
- كل عملية حساسة للكاشير تمر Permission أو Manager Approval Server-side.
- كل سجل branch-scoped يجب أن يحترم العزل ويعرض هوية الفرع حيث يلزم.

---

## 13) الخطوة التالية

الفحص الشامل والإغلاق الأمني وP1/P2/P3/P4 الأساسية أصبحت على baseline أخضر.

العمل التالي يجب أن يكون **تشغيليًا/Release polish وليس إعادة فتح hardening المكتمل**:
1. فحص دورة تشغيل بشرية على الموقع المنشور: Login → فتح وردية → طلب → KDS → بيع → طباعة → Refund/Approval → إغلاق وردية.
2. تفعيل Leaked Password Protection من إعدادات Supabase Auth إذا كان الحساب/الخطة يدعمها.
3. مراجعة `npm audit` وترقية التبعيات عالية الخطورة بطريقة غير كاسرة؛ لا تستخدم `npm audit fix --force` عشوائيًا.
4. تحسينات UX/Performance غير الحاجبة بعد تثبيت الإصدار.
