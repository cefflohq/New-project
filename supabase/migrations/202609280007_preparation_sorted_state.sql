-- D-74 Sorting (Founder decision): Sorting is an independent per-order
-- checkpoint between Packed and Ready. The existing preparation state model
-- is extended rather than duplicated:
--   not_started -> preparing -> packed -> sorted -> ready
-- Kept in its own migration: a new enum value must be committed before any
-- function may use it (202609280008).
alter type public.preparation_status add value if not exists 'sorted' after 'packed';
