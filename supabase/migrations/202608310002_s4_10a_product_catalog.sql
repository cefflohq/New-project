-- S4-10A: tenant-safe Product Catalog and category ordering contract.
-- Product media, inventory, modifiers, public ordering and payment truth are
-- deliberately absent. Display price is presentation/order-snapshot data only.

create table public.product_categories (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 1 and 80),
  sort_order integer not null check (sort_order >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz,
  unique (business_id, id)
);

create unique index product_categories_live_name_idx
  on public.product_categories (business_id, lower(btrim(name)))
  where archived_at is null;
create unique index product_categories_live_sort_idx
  on public.product_categories (business_id, sort_order)
  where archived_at is null;

create table public.products (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  category_id uuid not null,
  name text not null check (char_length(btrim(name)) between 1 and 120),
  description text check (description is null or char_length(description) <= 1000),
  display_price numeric(12,2) not null check (display_price >= 0 and display_price <= 9999999999.99),
  status text not null default 'active' check (status in ('active','hidden')),
  sort_order integer not null check (sort_order >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz,
  constraint products_category_same_business_fk
    foreign key (business_id, category_id)
    references public.product_categories(business_id, id)
    on delete restrict
);

create index products_working_catalog_idx
  on public.products (business_id, category_id, status, sort_order)
  where archived_at is null;
create unique index products_live_category_sort_idx
  on public.products (category_id, sort_order)
  where archived_at is null;

alter table public.product_categories enable row level security;
alter table public.products enable row level security;

create policy product_categories_vendor_read on public.product_categories
  for select to authenticated
  using (public.is_business_member(business_id));
create policy products_vendor_read on public.products
  for select to authenticated
  using (public.is_business_member(business_id));

revoke all on table public.product_categories from public, anon, authenticated;
revoke all on table public.products from public, anon, authenticated;
grant select on table public.product_categories to authenticated;
grant select on table public.products to authenticated;

create function public.create_product_category(p_business_id uuid, p_name text)
returns public.product_categories
language plpgsql security definer set search_path = public
as $$
declare v public.product_categories;
begin
  if not public.is_business_member(p_business_id) then raise exception 'forbidden'; end if;
  if nullif(btrim(p_name), '') is null or char_length(btrim(p_name)) > 80 then raise exception 'invalid category name'; end if;
  perform 1 from public.businesses where id=p_business_id for update;
  insert into public.product_categories(business_id,name,sort_order)
  select p_business_id,btrim(p_name),coalesce(max(sort_order)+1,0)
  from public.product_categories where business_id=p_business_id and archived_at is null
  returning * into v;
  return v;
exception when unique_violation then raise exception 'category already exists';
end;
$$;

create function public.update_product_category(p_category_id uuid, p_name text)
returns public.product_categories
language plpgsql security definer set search_path = public
as $$
declare v public.product_categories;
begin
  select * into v from public.product_categories where id=p_category_id and archived_at is null for update;
  if v.id is null or not public.is_business_member(v.business_id) then raise exception 'forbidden'; end if;
  if nullif(btrim(p_name), '') is null or char_length(btrim(p_name)) > 80 then raise exception 'invalid category name'; end if;
  update public.product_categories set name=btrim(p_name),updated_at=now() where id=v.id returning * into v;
  return v;
exception when unique_violation then raise exception 'category already exists';
end;
$$;

create function public.reorder_product_categories(p_business_id uuid, p_category_ids uuid[])
returns setof public.product_categories
language plpgsql security definer set search_path = public
as $$
declare expected_count integer; provided_count integer;
begin
  if not public.is_business_member(p_business_id) then raise exception 'forbidden'; end if;
  perform 1 from public.product_categories where business_id=p_business_id and archived_at is null for update;
  select count(*) into expected_count from public.product_categories where business_id=p_business_id and archived_at is null;
  select count(distinct x) into provided_count from unnest(coalesce(p_category_ids,'{}'::uuid[])) x;
  if cardinality(coalesce(p_category_ids,'{}'::uuid[]))<>expected_count or provided_count<>expected_count
     or exists(select 1 from unnest(coalesce(p_category_ids,'{}'::uuid[])) x where not exists(
       select 1 from public.product_categories c where c.id=x and c.business_id=p_business_id and c.archived_at is null))
  then raise exception 'invalid category order'; end if;
  -- Shift away from the live unique index before assigning final positions.
  update public.product_categories set sort_order=sort_order+1000000 where business_id=p_business_id and archived_at is null;
  update public.product_categories c set sort_order=o.ord-1,updated_at=now()
  from unnest(p_category_ids) with ordinality o(id,ord) where c.id=o.id;
  return query select * from public.product_categories where business_id=p_business_id and archived_at is null order by sort_order,id;
end;
$$;

create function public.archive_product_category(p_category_id uuid)
returns public.product_categories
language plpgsql security definer set search_path = public
as $$
declare v public.product_categories;
begin
  select * into v from public.product_categories where id=p_category_id and archived_at is null for update;
  if v.id is null or not public.is_business_member(v.business_id) then raise exception 'forbidden'; end if;
  if exists(select 1 from public.products where category_id=v.id and archived_at is null) then raise exception 'category contains products'; end if;
  update public.product_categories set archived_at=now(),updated_at=now() where id=v.id returning * into v;
  update public.product_categories set sort_order=sort_order+1000000 where business_id=v.business_id and archived_at is null;
  update public.product_categories set sort_order=ranked.position,updated_at=now()
  from (select id,row_number() over(order by sort_order,id)-1 position from public.product_categories where business_id=v.business_id and archived_at is null) ranked
  where product_categories.id=ranked.id;
  return v;
end;
$$;

create function public.create_product(p_business_id uuid,p_category_id uuid,p_name text,p_description text,p_display_price numeric,p_status text default 'active')
returns public.products
language plpgsql security definer set search_path = public
as $$
declare v public.products;
begin
  if not public.is_business_member(p_business_id) then raise exception 'forbidden'; end if;
  if not exists(select 1 from public.product_categories where id=p_category_id and business_id=p_business_id and archived_at is null) then raise exception 'invalid category'; end if;
  if nullif(btrim(p_name),'') is null or char_length(btrim(p_name))>120 then raise exception 'invalid product name'; end if;
  if p_description is not null and char_length(p_description)>1000 then raise exception 'invalid description'; end if;
  if p_display_price is null or p_display_price<0 or p_display_price>9999999999.99 then raise exception 'invalid price'; end if;
  if p_status is null or p_status not in ('active','hidden') then raise exception 'invalid status'; end if;
  perform 1 from public.product_categories where id=p_category_id for update;
  insert into public.products(business_id,category_id,name,description,display_price,status,sort_order)
  select p_business_id,p_category_id,btrim(p_name),nullif(btrim(p_description),''),p_display_price,p_status,coalesce(max(sort_order)+1,0)
  from public.products where category_id=p_category_id and archived_at is null returning * into v;
  return v;
end;
$$;

create function public.update_product(p_product_id uuid,p_category_id uuid,p_name text,p_description text,p_display_price numeric,p_status text)
returns public.products
language plpgsql security definer set search_path = public
as $$
declare v public.products; old_category uuid; new_order integer;
begin
  select * into v from public.products where id=p_product_id and archived_at is null for update;
  if v.id is null or not public.is_business_member(v.business_id) then raise exception 'forbidden'; end if;
  if not exists(select 1 from public.product_categories where id=p_category_id and business_id=v.business_id and archived_at is null) then raise exception 'invalid category'; end if;
  if nullif(btrim(p_name),'') is null or char_length(btrim(p_name))>120 then raise exception 'invalid product name'; end if;
  if p_description is not null and char_length(p_description)>1000 then raise exception 'invalid description'; end if;
  if p_display_price is null or p_display_price<0 or p_display_price>9999999999.99 then raise exception 'invalid price'; end if;
  if p_status is null or p_status not in ('active','hidden') then raise exception 'invalid status'; end if;
  old_category:=v.category_id;
  if old_category is distinct from p_category_id then
    perform 1 from public.product_categories where id in (old_category,p_category_id) order by id for update;
    select coalesce(max(sort_order)+1,0) into new_order from public.products where category_id=p_category_id and archived_at is null;
  else new_order:=v.sort_order; end if;
  update public.products set category_id=p_category_id,name=btrim(p_name),description=nullif(btrim(p_description),''),display_price=p_display_price,status=p_status,sort_order=new_order,updated_at=now() where id=v.id returning * into v;
  if old_category is distinct from p_category_id then
    update public.products set sort_order=sort_order+1000000 where category_id=old_category and archived_at is null;
    update public.products set sort_order=ranked.position,updated_at=now()
    from (select id,row_number() over(order by sort_order,id)-1 position from public.products where category_id=old_category and archived_at is null) ranked where products.id=ranked.id;
  end if;
  return v;
end;
$$;

create function public.set_product_status(p_product_id uuid,p_status text)
returns public.products language plpgsql security definer set search_path=public as $$
declare v public.products;
begin
  select * into v from public.products where id=p_product_id and archived_at is null for update;
  if v.id is null or not public.is_business_member(v.business_id) then raise exception 'forbidden'; end if;
  if p_status is null or p_status not in ('active','hidden') then raise exception 'invalid status'; end if;
  update public.products set status=p_status,updated_at=now() where id=v.id returning * into v; return v;
end; $$;

create function public.reorder_products(p_category_id uuid,p_product_ids uuid[])
returns setof public.products
language plpgsql security definer set search_path = public
as $$
declare c public.product_categories; expected_count integer; provided_count integer;
begin
  select * into c from public.product_categories where id=p_category_id and archived_at is null for update;
  if c.id is null or not public.is_business_member(c.business_id) then raise exception 'forbidden'; end if;
  perform 1 from public.products where category_id=c.id and archived_at is null for update;
  select count(*) into expected_count from public.products where category_id=c.id and archived_at is null;
  select count(distinct x) into provided_count from unnest(coalesce(p_product_ids,'{}'::uuid[])) x;
  if cardinality(coalesce(p_product_ids,'{}'::uuid[]))<>expected_count or provided_count<>expected_count
     or exists(select 1 from unnest(coalesce(p_product_ids,'{}'::uuid[])) x where not exists(
       select 1 from public.products p where p.id=x and p.category_id=c.id and p.archived_at is null))
  then raise exception 'invalid product order'; end if;
  update public.products set sort_order=sort_order+1000000 where category_id=c.id and archived_at is null;
  update public.products p set sort_order=o.ord-1,updated_at=now()
  from unnest(p_product_ids) with ordinality o(id,ord) where p.id=o.id;
  return query select * from public.products where category_id=c.id and archived_at is null order by sort_order,id;
end;
$$;

create function public.archive_product(p_product_id uuid)
returns public.products language plpgsql security definer set search_path=public as $$
declare v public.products;
begin
  select * into v from public.products where id=p_product_id and archived_at is null for update;
  if v.id is null or not public.is_business_member(v.business_id) then raise exception 'forbidden'; end if;
  update public.products set archived_at=now(),updated_at=now() where id=v.id returning * into v;
  update public.products set sort_order=sort_order+1000000 where category_id=v.category_id and archived_at is null;
  update public.products set sort_order=ranked.position,updated_at=now()
  from (select id,row_number() over(order by sort_order,id)-1 position from public.products where category_id=v.category_id and archived_at is null) ranked where products.id=ranked.id;
  return v;
end; $$;

do $$ declare f regprocedure; begin
  for f in select p.oid::regprocedure from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname in ('create_product_category','update_product_category','reorder_product_categories','archive_product_category','create_product','update_product','set_product_status','reorder_products','archive_product')
  loop execute format('revoke all on function %s from public, anon, authenticated',f); execute format('grant execute on function %s to authenticated',f); end loop;
end $$;
