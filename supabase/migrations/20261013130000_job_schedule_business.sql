-- Run Details pay and pickup time (Founder 2026-10-13): my_job_schedule also
-- returns the business_id, so the Driver App matches an approved hiring
-- contract (pickup time, pay per drop) to the run of that business by id,
-- never by name. The return type changes, so the function is dropped and
-- recreated with the same grants.

drop function if exists public.my_job_schedule();

create function public.my_job_schedule()
 returns table(request_id uuid, status text, opening_id uuid, business_name text, area_label text,
               shift_start time without time zone, shift_end time without time zone, days smallint[],
               pay_amount numeric, pay_unit text, business_id uuid)
 language sql
 stable security definer
 set search_path to 'public'
as $function$
  select r.id, r.status, o.id, b.name, o.area_label, o.shift_start, o.shift_end, o.days, o.pay_amount, o.pay_unit, b.id
  from rider_job_requests r
  join rider_job_openings o on o.id = r.opening_id
  join businesses b on b.id = o.business_id
  where r.auth_user_id = auth.uid() and r.status in ('pending','approved')
  order by o.shift_start
$function$;

revoke all on function public.my_job_schedule() from public, anon;
grant execute on function public.my_job_schedule() to authenticated;
