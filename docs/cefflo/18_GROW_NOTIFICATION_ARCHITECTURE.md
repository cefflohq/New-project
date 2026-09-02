# Grow V1 Notification Architecture Boundary

Status: design only. Live WhatsApp/SMS delivery is not implemented or authorized.

## Product truth

Grow V1 may display an estimated arrival only when `orders.estimated_arrival_at` contains a credible backend-produced value. When it is null, Customer Tracking keeps its existing honest unavailable state. No client-side random duration, stale placeholder, or inferred promise is permitted.

No Cefflo surface may say that a notification was sent, delivered, read, or failed unless a future authorized provider integration supplies that fact.

## Future event boundary

A future implementation may consume immutable delivery events after the authoritative transaction commits. Candidate triggers include order approval, Rider assignment, pickup, out-for-delivery, arrival, delivery, issue, and recovery. The delivery lifecycle remains authoritative; notification delivery must never drive or roll back lifecycle state.

The eventual boundary should translate an eligible event into a provider-neutral command containing:

- a stable event identifier and notification purpose;
- business, order, recipient, locale, and approved template identifiers;
- the minimum template variables required for that message;
- consent and channel-eligibility evidence;
- an idempotency key derived from event, recipient, channel, and template version.

This document does not authorize an outbox table, queue, Edge Function, provider SDK, phone-number export, or live send.

## Idempotency and retries

Each provider submission must be uniquely keyed so retries cannot create duplicate customer messages. A future worker may retry transient failures with bounded exponential backoff. Permanent failures, exhausted retries, invalid consent, and invalid destinations must become observable terminal outcomes without changing order status.

Provider request IDs and provider delivery receipts may be stored only in a separately approved notification record. Raw provider secrets and unnecessary message content must never be written to delivery events.

## Consent and templates

Before any live integration, the Founder must separately approve:

- the provider and commercial contract;
- channel-specific opt-in and opt-out behavior;
- template text, locale fallback, and template-version policy;
- retention rules for recipient data, request metadata, and receipts;
- operating ownership for failed sends and customer support escalation.

Templates must distinguish operational updates from marketing. A tracking link must use the existing opaque-token boundary and must not expose internal database identifiers.

## Security and tenant isolation

Future notification commands must be created only from server-authoritative business/order data. Business identity, recipient, lifecycle status, ETA, and tracking link must not be accepted as client-authoritative values. Provider credentials must remain server-side and environment-scoped. Cross-business reads or sends are forbidden.

## Failure handling and observability

The future system should expose counts and traces for accepted, submitted, provider-confirmed, transient-failed, permanent-failed, and suppressed messages. Logs must use stable internal correlation IDs, redact recipient data, and never contain provider secrets or raw tracking tokens.

A provider outage must leave Vendor, Rider, and Customer operational truth intact. UI copy may state only the outcome proven by the provider boundary.

## Deferred implementation gate

Live notification implementation requires a new Founder-authorized work package. Until then:

- no provider is selected or called;
- no outbox or notification persistence is created;
- no message delivery is claimed;
- the current Customer Tracking ETA remains real when supplied and honestly unavailable otherwise.
