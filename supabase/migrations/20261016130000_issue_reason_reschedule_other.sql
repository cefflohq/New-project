-- Driver "Customer requested reschedule" and "Other" become recordable
-- issue reasons (Founder 2026-10-16).
alter type public.delivery_issue_reason add value if not exists 'customer_rescheduled';
alter type public.delivery_issue_reason add value if not exists 'other';
