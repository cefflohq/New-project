-- Integrations Phase 1: fix integration_list event subquery alias.
create or replace function public.integration_list(p_business uuid)
returns jsonb language plpgsql stable security definer set search_path to 'public' as $$
begin
  if not is_business_member(p_business) then raise exception 'forbidden'; end if;
  return jsonb_build_object(
    'connections', coalesce((select jsonb_agg(jsonb_build_object(
        'id', c.id, 'provider', c.provider, 'status', c.status, 'shop_domain', c.shop_domain,
        'created_at', c.created_at, 'last_event_at', c.last_event_at) order by c.created_at desc)
      from integration_connections c where c.business_id = p_business and c.status = 'active'), '[]'::jsonb),
    'api_keys', coalesce((select jsonb_agg(jsonb_build_object(
        'id', k.id, 'prefix', k.key_prefix, 'created_at', k.created_at, 'last_used_at', k.last_used_at) order by k.created_at desc)
      from integration_api_keys k where k.business_id = p_business and k.revoked_at is null), '[]'::jsonb),
    'events', coalesce((select jsonb_agg(x.e order by x.received_at desc) from (
        select jsonb_build_object('provider', c.provider, 'outcome', ev.outcome, 'reason', ev.reason,
          'external_id', ev.external_id, 'received_at', ev.received_at) as e, ev.received_at
        from integration_events ev join integration_connections c on c.id = ev.connection_id
        where ev.business_id = p_business order by ev.received_at desc limit 20) x), '[]'::jsonb));
end $$;
