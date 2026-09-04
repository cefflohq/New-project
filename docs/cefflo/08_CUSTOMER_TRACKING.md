# CEFFLO --- CUSTOMER TRACKING

Fuller canonical Customer Tracking doctrine:
`docs/cefflo/sot/04_CUSTOMER_TRACKING.md`.

## CT-00 Purpose

Give customers clear delivery visibility without requiring an account.

## CT-01 Access

Planned route: `tracking.cefflo.com`. Access is tokenized. Public access
must expose only required customer-facing data.

## CT-02 Core Experience

-   delivery identity/context appropriate for customer;
-   simplified delivery status;
-   ETA/progress where reliable;
-   POD after delivery;
-   rating after completion.

Historical simplified status direction: **Picked Up → On The Way →
Delivered** Internal lifecycle may be richer; map through
`10_DELIVERY_LIFECYCLE.md`.

## CT-03 Security

-   protect token format/entropy/expiry as designed;
-   rate-limit public endpoints where appropriate;
-   do not expose internal IDs/PII unnecessarily;
-   POD access must be controlled/signed where applicable;
-   rating mutation must be protected.

## CT-04 No Account

Do not introduce customer signup/login as a Stage 4 requirement without
Founder decision.

## CT-05 Failure States

Handle invalid/expired token, unavailable tracking data, network
failure, POD unavailable/upload pending and rating failure gracefully.

## CT-06 Stage 4 Gate

A valid customer tracking link provides correct lifecycle information,
protected POD/rating behaviour and appropriate failure handling without
account creation.
