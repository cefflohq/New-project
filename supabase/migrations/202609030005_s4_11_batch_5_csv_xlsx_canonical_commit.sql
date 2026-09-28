-- S4-11 Batch 5 (Grow V1 Flow 2, B1): CSV/XLSX canonical commit.
--
-- Flow 1 finding (audit report §4): upload -> parse -> preview -> validate
-- -> row-fix is real, substantial, working frontend engineering
-- (vendor/index.html readImportFile/confirmCsvImport). The only missing
-- piece is the commit step -- confirmCsvImport's own code comment says
-- exactly why: "the current CSV shape has no order items and cannot
-- satisfy the existing authoritative create_delivery path without
-- inventing product data." This migration closes only that backend gap,
-- per the Founder-recommended reconciliation (scope-lock §9): extend the
-- canonical creation contract with a minimal-items convention rather than
-- building a second, competing import-only write path. Every imported
-- order becomes a real row in `orders`, created through the same
-- `create_delivery` used by every other intake path -- same tracking
-- token, same event log, same everything.
--
-- Batch behavior (Master MD §11): truthful, traceable, retry-safe. Uses
-- the exact same idempotency-ledger pattern as build_rider_run (S4-06
-- Batch 5a) -- a true key+payload ledger in delivery_events, not a
-- state-based shortcut, enforced by a DB-level partial unique index.

create unique index import_committed_idempotency_key_idx
  on public.delivery_events ((metadata->>'idempotency_key'))
  where event_type = 'import.committed';

-- p_rows shape: a jsonb array of objects, each with:
--   source_row_ref   text   -- the import UI's own row identifier (e.g. its
--                               preview-table row id), echoed back so the
--                               frontend can map results back to rows
--                               without relying on array position.
--   customer_name     text  (required)
--   customer_phone     text  (required)
--   delivery_address    text (required)
--   notes               text (optional)
--   zone_name           text (optional -- matched case-insensitively
--                               against this business's existing active
--                               Zones; unmatched/absent -> no zone, not a
--                               rejection, matching Zone's existing
--                               "optional label" design)
--   items_description   text (optional free text -> becomes exactly one
--                               synthetic line item, satisfying whatever
--                               downstream code expects a non-empty items
--                               array without inventing a product catalog
--                               link this import format was never given)
--
-- A row missing any required field is rejected with a factual reason and
-- does NOT abort the batch -- every other valid row still commits. This is
-- a per-row-safe batch, not an all-or-nothing transaction, matching the
-- Task Master's explicit "identify rejected rows; report committed rows."
create function public.import_orders_batch(
  p_business_id uuid,
  p_rows jsonb,
  p_idempotency_key uuid
) returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  existing_event delivery_events;
  row_obj jsonb;
  row_ref text;
  c_name text;
  c_phone text;
  c_addr text;
  c_notes text;
  c_zone_name text;
  c_items_desc text;
  matched_zone_id uuid;
  new_order jsonb;
  committed jsonb := '[]'::jsonb;
  rejected jsonb := '[]'::jsonb;
  items_payload jsonb;
begin
  if not is_business_member(p_business_id) then
    raise exception 'forbidden';
  end if;
  if p_idempotency_key is null then
    raise exception 'idempotency key required';
  end if;
  if p_rows is null or jsonb_typeof(p_rows) <> 'array' or jsonb_array_length(p_rows) = 0 then
    raise exception 'no rows to import';
  end if;

  -- True idempotency ledger lookup FIRST: a matching committed
  -- import.committed event proves a retry regardless of current order
  -- state, and returns the exact original committed/rejected result
  -- rather than re-deriving or re-inserting anything.
  select * into existing_event
    from delivery_events
    where event_type = 'import.committed' and (metadata->>'idempotency_key')::uuid = p_idempotency_key
    limit 1;
  if existing_event.id is not null then
    if (existing_event.metadata->>'business_id')::uuid <> p_business_id
       or existing_event.metadata->'rows' <> p_rows then
      raise exception 'idempotency key conflict';
    end if;
    return jsonb_build_object(
      'committed', existing_event.metadata->'committed',
      'rejected', existing_event.metadata->'rejected'
    );
  end if;

  for row_obj in select * from jsonb_array_elements(p_rows) loop
    row_ref := row_obj->>'source_row_ref';
    c_name := nullif(trim(row_obj->>'customer_name'), '');
    c_phone := nullif(trim(row_obj->>'customer_phone'), '');
    c_addr := nullif(trim(row_obj->>'delivery_address'), '');
    c_notes := coalesce(row_obj->>'notes', '');
    c_zone_name := nullif(trim(row_obj->>'zone_name'), '');
    c_items_desc := nullif(trim(row_obj->>'items_description'), '');

    if c_name is null or c_phone is null or c_addr is null then
      rejected := rejected || jsonb_build_array(jsonb_build_object(
        'source_row_ref', row_ref,
        'reason', 'missing_required_field'
      ));
      continue;
    end if;

    matched_zone_id := null;
    if c_zone_name is not null then
      select id into matched_zone_id from zones
        where business_id = p_business_id and status = 'active' and lower(name) = lower(c_zone_name)
        limit 1;
    end if;

    -- Synthetic single-line-item convention (scope-lock §9): the import
    -- format was never given a product-catalog link, so a free-text
    -- description becomes exactly one line item rather than inventing
    -- product data. No description at all -> genuinely empty items array,
    -- which create_delivery already accepts (p_items default '[]').
    if c_items_desc is not null then
      items_payload := jsonb_build_array(jsonb_build_object('description', c_items_desc, 'quantity', 1));
    else
      items_payload := '[]'::jsonb;
    end if;

    begin
      new_order := create_delivery(
        p_business_id, c_name, c_phone, c_addr, c_notes,
        null, null, items_payload, matched_zone_id, 'any'
      );
      committed := committed || jsonb_build_array(jsonb_build_object(
        'source_row_ref', row_ref,
        'order_id', new_order->'order'->>'id',
        'public_ref', new_order->'order'->>'public_ref'
      ));
    exception when others then
      rejected := rejected || jsonb_build_array(jsonb_build_object(
        'source_row_ref', row_ref,
        'reason', sqlerrm
      ));
    end;
  end loop;

  -- Ledger the whole batch result as one committed event, guarded by the
  -- same partial unique index pattern as build_rider_run -- a genuinely
  -- concurrent duplicate submission of the same key becomes a clean
  -- "idempotency key conflict" rather than a silent double-import.
  begin
    insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
      values (p_business_id, 'import.committed', auth.uid(), 'vendor',
              jsonb_build_object(
                'idempotency_key', p_idempotency_key,
                'business_id', p_business_id,
                'rows', p_rows,
                'committed', committed,
                'rejected', rejected
              ));
  exception when unique_violation then
    raise exception 'idempotency key conflict';
  end;

  return jsonb_build_object('committed', committed, 'rejected', rejected);
end;
$$;

revoke all on function public.import_orders_batch(uuid, jsonb, uuid) from public, anon;
grant execute on function public.import_orders_batch(uuid, jsonb, uuid) to authenticated;
