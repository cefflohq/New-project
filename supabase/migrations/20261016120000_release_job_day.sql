-- Release one day of a booked opening (Founder 2026-10-16): the driver
-- picks one slot on My Schedule; only that day leaves their schedule.
-- Releasing the last day withdraws the request.
alter table public.rider_job_requests
  add column if not exists released_days smallint[] not null default '{}';

create or replace function public.my_job_schedule()
returns table(request_id uuid, status text, opening_id uuid, business_name text, area_label text,
  shift_start time, shift_end time, days smallint[], pay_amount numeric, pay_unit text, business_id uuid)
language sql stable security definer set search_path = public as $$
  select r.id, r.status, o.id, b.name, o.area_label, o.shift_start, o.shift_end,
         array(select d from unnest(o.days) d where not d = any(r.released_days) order by d),
         o.pay_amount, o.pay_unit, b.id
  from rider_job_requests r
  join rider_job_openings o on o.id = r.opening_id
  join businesses b on b.id = o.business_id
  where r.auth_user_id = auth.uid() and r.status in ('pending','approved')
  order by o.shift_start
$$;

create or replace function public.release_job_day(p_request_id uuid, p_day smallint)
returns void
language plpgsql security definer set search_path = public as $$
declare r rider_job_requests; o rider_job_openings; left_days smallint[];
begin
  select * into r from rider_job_requests
   where id = p_request_id and auth_user_id = auth.uid() and status in ('pending','approved')
   for update;
  if r.id is null then raise exception 'request not found'; end if;
  select * into o from rider_job_openings where id = r.opening_id;
  if not p_day = any(o.days) then raise exception 'day not in this booking'; end if;
  left_days := array(select d from unnest(o.days) d
                     where not d = any(r.released_days) and d <> p_day);
  if cardinality(left_days) = 0 then
    update rider_job_requests set status = 'withdrawn', decided_at = now() where id = r.id;
  else
    update rider_job_requests
       set released_days = array(select distinct d from unnest(r.released_days || p_day) d order by d)
     where id = r.id;
  end if;
end $$;
revoke all on function public.release_job_day(uuid, smallint) from public, anon;
grant execute on function public.release_job_day(uuid, smallint) to authenticated;
