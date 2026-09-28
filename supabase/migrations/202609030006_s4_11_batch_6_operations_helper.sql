-- S4-11 Batch 6 (Grow V1 Flow 2, C1-C3): Operations/Helper workspace.
--
-- Flow 1 finding (audit report §9/§10): no prepare/pack/ready order-
-- lifecycle states exist anywhere; the Vendor UI's own "Helper Pool" tab
-- renders "Helpers is not connected yet." This migration makes
-- Prepare -> Pack -> Ready real, canonical backend truth.
--
-- Founder-locked infrastructure decision (scope-lock §15, applied at scope
-- freeze): distinct workspace does NOT mean duplicate identity/team
-- infrastructure. This reuses the existing Core Team plumbing --
-- business_members / team_invitations / create_team_invitation /
-- accept_team_invitation -- completely unchanged, by adding exactly one
-- new member_role value. Zero new invitation/identity tables.

alter type public.member_role add value 'helper';

create type public.preparation_status as enum ('not_started','preparing','packed','ready');

alter table public.delivery_stops
  add column preparation_status public.preparation_status not null default 'not_started',
  add column preparation_updated_at timestamptz,
  add column preparation_updated_by uuid references auth.users on delete set null;
