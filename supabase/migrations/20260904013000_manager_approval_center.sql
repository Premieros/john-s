-- Configurable, branch-scoped manager approval center.
-- Keeps existing approval_requests as the immutable workflow record and adds
-- policy/assignment configuration without weakening branch isolation.

create table if not exists public.approval_action_catalog (
  action_key text primary key,
  domain text not null,
  label_ar text not null,
  label_en text not null,
  description_ar text,
  description_en text,
  supports_threshold boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

insert into public.approval_action_catalog(action_key,domain,label_ar,label_en,supports_threshold) values
  ('void_sent_item','pos','إلغاء صنف مُرسل للمطبخ','Void sent kitchen item',false),
  ('order_cancel','pos','إلغاء طلب','Cancel order',false),
  ('order_merge','pos','دمج الطلبات','Merge orders',false),
  ('order_transfer','pos','نقل طلب/طاولة','Transfer order/table',false),
  ('order_split','pos','تقسيم الطلب','Split order',false),
  ('high_discount','pos','خصم مرتفع','High discount',true),
  ('refund','sales','مرتجع/استرداد','Refund / return',true),
  ('stock_count_approve','inventory','اعتماد الجرد','Approve stock count',false),
  ('stock_adjustment','inventory','تسوية المخزون','Inventory adjustment',true),
  ('warehouse_transfer','inventory','تحويل مخزني','Warehouse transfer',true),
  ('purchase_approve','procurement','اعتماد شراء','Approve purchase',true),
  ('purchase_reverse','procurement','عكس/حذف شراء','Reverse purchase',true),
  ('expense_approve','finance','اعتماد مصروف','Approve expense',true),
  ('payment_approve','finance','اعتماد دفعة','Approve payment',true),
  ('treasury_transfer','finance','تحويل خزينة/بنك','Treasury transfer',true),
  ('journal_post','accounting','ترحيل قيد يدوي','Post manual journal',true),
  ('journal_reverse','accounting','عكس قيد','Reverse journal',true)
on conflict (action_key) do update set
  domain=excluded.domain,label_ar=excluded.label_ar,label_en=excluded.label_en,
  supports_threshold=excluded.supports_threshold,is_active=true;

create table if not exists public.approval_policies (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(id) on delete cascade,
  action_key text not null references public.approval_action_catalog(action_key),
  requires_approval boolean not null default false,
  approver_user_id uuid references public.users(id) on delete set null,
  threshold_amount numeric(14,2),
  settings jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_by uuid references public.users(id) on delete set null,
  updated_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(branch_id, action_key),
  check (threshold_amount is null or threshold_amount >= 0)
);
create index if not exists idx_approval_policies_branch on public.approval_policies(branch_id,action_key) where is_active;
create index if not exists idx_approval_requests_pending_branch on public.approval_requests(branch_id,status,created_at desc);

alter table public.approval_action_catalog enable row level security;
alter table public.approval_policies enable row level security;

drop policy if exists approval_catalog_read on public.approval_action_catalog;
create policy approval_catalog_read on public.approval_action_catalog for select to authenticated using (true);

drop policy if exists approval_policies_read_branch on public.approval_policies;
create policy approval_policies_read_branch on public.approval_policies for select to authenticated
using (public.user_may_access_branch(branch_id));

drop policy if exists approval_policies_manage_branch on public.approval_policies;
create policy approval_policies_manage_branch on public.approval_policies for all to authenticated
using (
  public.user_may_access_branch(branch_id)
  and (public.is_pos_admin() or public.has_permission(auth.uid(),'settings.manage'))
)
with check (
  public.user_may_access_branch(branch_id)
  and (public.is_pos_admin() or public.has_permission(auth.uid(),'settings.manage'))
  and (approver_user_id is null or exists (
    select 1 from public.users u
    where u.id=approver_user_id and u.is_active=true
      and (u.branch_id=branch_id or public.is_pos_admin())
  ))
);

-- Seed policies for every branch. Existing structural POS approval semantics are
-- preserved: policies start disabled until an administrator explicitly enables them.
insert into public.approval_policies(branch_id,action_key,requires_approval)
select b.id,c.action_key,false
from public.branches b cross join public.approval_action_catalog c
on conflict (branch_id,action_key) do nothing;

create or replace function public.get_approval_policy(
  p_branch_id uuid,
  p_action_key text,
  p_amount numeric default null
) returns jsonb
language plpgsql security definer set search_path=public,pg_temp as $$
declare v public.approval_policies%rowtype; v_required boolean := false;
begin
  if auth.uid() is not null and not public.user_may_access_branch(p_branch_id) then
    return jsonb_build_object('success',false,'error','BRANCH_ACCESS_DENIED');
  end if;
  select * into v from public.approval_policies
   where branch_id=p_branch_id and action_key=p_action_key and is_active=true;
  if not found then
    return jsonb_build_object('success',true,'requires_approval',false,'action_key',p_action_key);
  end if;
  v_required := v.requires_approval and (
    v.threshold_amount is null or p_amount is null or abs(p_amount) >= v.threshold_amount
  );
  return jsonb_build_object(
    'success',true,'requires_approval',v_required,'action_key',p_action_key,
    'approver_user_id',v.approver_user_id,'threshold_amount',v.threshold_amount,
    'settings',v.settings
  );
end; $$;

-- Replace request RPC so request types are driven by the active catalog and policy.
create or replace function public.request_manager_approval(
  p_branch_id uuid,
  p_request_type text,
  p_entity_type text default null,
  p_entity_id uuid default null,
  p_payload jsonb default '{}'::jsonb,
  p_reason text default null,
  p_ttl_minutes integer default 15
) returns jsonb
language plpgsql security definer set search_path=public,pg_temp as $$
declare v_id uuid; v_exp timestamptz; v_policy public.approval_policies%rowtype;
begin
  if auth.uid() is null then return jsonb_build_object('success',false,'error','AUTH_REQUIRED'); end if;
  if not public.user_may_access_branch(p_branch_id) then return jsonb_build_object('success',false,'error','BRANCH_ACCESS_DENIED'); end if;
  if not exists(select 1 from public.approval_action_catalog where action_key=p_request_type and is_active=true) then
    return jsonb_build_object('success',false,'error','INVALID_REQUEST_TYPE');
  end if;
  select * into v_policy from public.approval_policies
   where branch_id=p_branch_id and action_key=p_request_type and is_active=true;
  v_exp := now() + make_interval(mins => greatest(1,least(coalesce(p_ttl_minutes,15),1440)));
  insert into public.approval_requests(branch_id,request_type,entity_type,entity_id,requested_by,payload,reason,status,expires_at)
  values(p_branch_id,p_request_type,p_entity_type,p_entity_id,auth.uid(),coalesce(p_payload,'{}'::jsonb),nullif(trim(p_reason),''),'pending',v_exp)
  returning id into v_id;
  return jsonb_build_object('success',true,'approval_id',v_id,'status','pending','expires_at',v_exp,
    'approver_user_id',case when found then v_policy.approver_user_id else null end);
end; $$;

-- Assigned-manager aware decision RPC. Global POS admins and explicit
-- approvals.review permission remain valid emergency/admin reviewers.
create or replace function public.decide_manager_approval(
  p_approval_id uuid,
  p_decision text,
  p_reason text default null
) returns jsonb
language plpgsql security definer set search_path=public,pg_temp as $$
declare v public.approval_requests%rowtype; v_assigned uuid;
begin
  if auth.uid() is null then return jsonb_build_object('success',false,'error','AUTH_REQUIRED'); end if;
  if p_decision not in ('approved','rejected') then return jsonb_build_object('success',false,'error','INVALID_DECISION'); end if;
  select * into v from public.approval_requests where id=p_approval_id for update;
  if not found then return jsonb_build_object('success',false,'error','APPROVAL_NOT_FOUND'); end if;
  if not public.user_may_access_branch(v.branch_id) then return jsonb_build_object('success',false,'error','BRANCH_ACCESS_DENIED'); end if;
  if v.status <> 'pending' then return jsonb_build_object('success',false,'error','APPROVAL_NOT_PENDING','status',v.status); end if;
  if v.expires_at is not null and v.expires_at <= now() then
    update public.approval_requests set status='expired',updated_at=now() where id=v.id;
    return jsonb_build_object('success',false,'error','APPROVAL_EXPIRED');
  end if;
  select approver_user_id into v_assigned from public.approval_policies
   where branch_id=v.branch_id and action_key=v.request_type and is_active=true;
  if not (
    public.is_pos_admin()
    or public.has_permission(auth.uid(),'approvals.review')
    or v_assigned=auth.uid()
  ) then return jsonb_build_object('success',false,'error','APPROVAL_REVIEW_DENIED'); end if;
  if v.requested_by=auth.uid() and not public.is_pos_admin() then
    return jsonb_build_object('success',false,'error','SELF_APPROVAL_DENIED');
  end if;
  if p_decision='approved' then
    update public.approval_requests set status='approved',approved_by=auth.uid(),approved_at=now(),reason=coalesce(nullif(trim(p_reason),''),reason),updated_at=now() where id=v.id;
  else
    update public.approval_requests set status='rejected',rejected_by=auth.uid(),rejected_at=now(),reason=coalesce(nullif(trim(p_reason),''),reason),updated_at=now() where id=v.id;
  end if;
  return jsonb_build_object('success',true,'approval_id',v.id,'status',p_decision);
end; $$;

grant select on public.approval_action_catalog, public.approval_policies to authenticated;
grant insert,update,delete on public.approval_policies to authenticated;
grant execute on function public.get_approval_policy(uuid,text,numeric) to authenticated;
grant execute on function public.request_manager_approval(uuid,text,text,uuid,jsonb,text,integer) to authenticated;
grant execute on function public.decide_manager_approval(uuid,text,text) to authenticated;
