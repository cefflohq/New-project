-- Integrations Phase 2 (Founder 2026-10-10, staging first): Wix, Google Sheets,
-- Google Drive. See docs/cefflo/security/INTEGRATIONS_PHASE2.md.
--
-- Wix: a Wix Automation ("Order placed" → Send HTTP request) posts to a
-- per-connection URL whose last segment is a server-generated token held in
-- Vault (shown once at connect). Google Sheets / Drive: a Google Apps Script
-- the owner installs in their own sheet or folder posts rows with a
-- connection-bound API key (same /api/orders endpoint and checks as Phase 1).
-- No Google OAuth and no Wix app credentials are involved.

alter table public.integration_connections drop constraint if exists integration_connections_provider_check;
alter table public.integration_connections add constraint integration_connections_provider_check
  check (provider in ('api', 'woocommerce', 'shopify', 'wix', 'google_sheets', 'google_drive'));

-- The API panel lists only general API keys; Sheets/Drive keys belong to
-- their own connection.
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
      from integration_api_keys k join integration_connections c on c.id = k.connection_id
      where k.business_id = p_business and k.revoked_at is null and c.provider = 'api'), '[]'::jsonb),
    'events', coalesce((select jsonb_agg(x.e order by x.received_at desc) from (
        select jsonb_build_object('provider', c.provider, 'outcome', ev.outcome, 'reason', ev.reason,
          'external_id', ev.external_id, 'received_at', ev.received_at) as e, ev.received_at
        from integration_events ev join integration_connections c on c.id = ev.connection_id
        where ev.business_id = p_business order by ev.received_at desc limit 20) x), '[]'::jsonb));
end $$;

-- The 5-key cap counts general API keys only.
create or replace function public.integration_create_api_key(p_business uuid)
returns jsonb language plpgsql security definer set search_path to 'public', 'extensions' as $$
declare cid uuid; k text; kid uuid;
begin
  if not is_business_member(p_business) then raise exception 'forbidden'; end if;
  select id into cid from integration_connections where business_id = p_business and provider = 'api' and status = 'active';
  if cid is null then
    insert into integration_connections(business_id, provider, created_by) values (p_business, 'api', auth.uid()) returning id into cid;
  end if;
  if (select count(*) from integration_api_keys where connection_id = cid and revoked_at is null) >= 5 then
    raise exception 'too many active keys';
  end if;
  k := 'cfk_live_' || encode(gen_random_bytes(24), 'hex');
  insert into integration_api_keys(connection_id, business_id, key_prefix, key_hash, created_by)
    values (cid, p_business, left(k, 17), encode(digest(k, 'sha256'), 'hex'), auth.uid()) returning id into kid;
  return jsonb_build_object('id', kid, 'key', k, 'prefix', left(k, 17));
end $$;

create or replace function public.integration_connect_wix(p_business uuid, p_site_url text)
returns jsonb language plpgsql security definer set search_path to 'public', 'extensions' as $$
declare u text := lower(btrim(coalesce(p_site_url, ''))); tok text; cid uuid;
begin
  if not is_business_member(p_business) then raise exception 'forbidden'; end if;
  if u !~ '^https://[a-z0-9.-]+\.[a-z]{2,}(/.*)?$' then raise exception 'invalid site url'; end if;
  tok := encode(gen_random_bytes(24), 'hex');
  cid := _integration_connection(p_business, 'wix', regexp_replace(u, '/+$', ''), tok);
  return jsonb_build_object('id', cid, 'token', tok);
end $$;

-- Sheets / Drive: new connection + one key bound to it (shown once).
-- Reconnecting revokes the previous connection and its key.
create or replace function public.integration_connect_google(p_business uuid, p_provider text)
returns jsonb language plpgsql security definer set search_path to 'public', 'extensions' as $$
declare cid uuid; k text;
begin
  if not is_business_member(p_business) then raise exception 'forbidden'; end if;
  if p_provider not in ('google_sheets', 'google_drive') then raise exception 'invalid provider'; end if;
  update integration_api_keys set revoked_at = now()
    where revoked_at is null and connection_id in (
      select id from integration_connections where business_id = p_business and provider = p_provider and status = 'active');
  cid := _integration_connection(p_business, p_provider, null, null);
  k := 'cfk_live_' || encode(gen_random_bytes(24), 'hex');
  insert into integration_api_keys(connection_id, business_id, key_prefix, key_hash, created_by)
    values (cid, p_business, left(k, 17), encode(digest(k, 'sha256'), 'hex'), auth.uid());
  return jsonb_build_object('id', cid, 'key', k);
end $$;

revoke all on function public.integration_connect_wix(uuid, text), public.integration_connect_google(uuid, text) from public, anon;
grant execute on function public.integration_connect_wix(uuid, text), public.integration_connect_google(uuid, text) to authenticated;
