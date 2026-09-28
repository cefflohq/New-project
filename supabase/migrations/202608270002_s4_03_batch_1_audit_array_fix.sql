-- S4-03 Batch 1 corrective migration: make changed-field accumulation unambiguous.

create or replace function public.update_business_profile(
  p_business_id uuid,
  p_name text default null,
  p_phone text default null,
  p_email text default null,
  p_address text default null,
  p_operating_area text default null,
  p_timezone text default null,
  p_currency text default null,
  p_idempotency_key text default null
) returns public.businesses
language plpgsql
security definer
set search_path = public
as $$
declare
  b public.businesses;
  changed text[] := '{}';
begin
  if not public.is_business_owner(p_business_id) then
    raise exception 'forbidden';
  end if;

  select * into b from public.businesses where id = p_business_id for update;
  if b.id is null then
    raise exception 'forbidden';
  end if;

  if p_name is not null and p_name is distinct from b.name then changed := array_append(changed, 'name'); end if;
  if p_phone is not null and p_phone is distinct from b.phone then changed := array_append(changed, 'phone'); end if;
  if p_email is not null and p_email is distinct from b.email then changed := array_append(changed, 'email'); end if;
  if p_address is not null and p_address is distinct from b.address then changed := array_append(changed, 'address'); end if;
  if p_operating_area is not null and p_operating_area is distinct from b.operating_area then changed := array_append(changed, 'operating_area'); end if;
  if p_timezone is not null and p_timezone is distinct from b.timezone then changed := array_append(changed, 'timezone'); end if;
  if p_currency is not null and p_currency is distinct from b.currency then changed := array_append(changed, 'currency'); end if;

  if cardinality(changed) > 0 then
    update public.businesses set
      name = coalesce(p_name, name),
      phone = coalesce(p_phone, phone),
      email = coalesce(p_email, email),
      address = coalesce(p_address, address),
      operating_area = coalesce(p_operating_area, operating_area),
      timezone = coalesce(p_timezone, timezone),
      currency = coalesce(p_currency, currency),
      updated_at = now()
    where id = p_business_id
    returning * into b;

    insert into public.business_profile_audit(
      business_id, actor_user_id, changed_fields, request_id
    ) values (
      p_business_id, auth.uid(), changed, p_idempotency_key
    );
  end if;

  return b;
end;
$$;

revoke all on function public.update_business_profile(uuid,text,text,text,text,text,text,text,text) from public;
grant execute on function public.update_business_profile(uuid,text,text,text,text,text,text,text,text) to authenticated;
