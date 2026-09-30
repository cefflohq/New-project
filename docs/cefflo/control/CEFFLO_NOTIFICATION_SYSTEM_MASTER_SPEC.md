# CEFFLO NOTIFICATION SYSTEM --- MASTER SPEC

**Status:** Product / UX Specification\
**Surfaces:** Vendor App, Vendor Web, Driver App, Operator, Helper,
FOUNDR\
**Brand sender:** `Cefflo`\
**Purpose:** Define one consistent notification system across Cefflo
without creating separate notification architectures per role or app.

------------------------------------------------------------------------

## 1. Product Principle

Cefflo notifications are operational signals, not engagement spam.

Every notification must answer at least one of these questions:

-   What just happened?
-   What needs attention?
-   What action should the user take?
-   What important platform information does Cefflo need to communicate?

Do not send notifications merely to make users reopen the app.

Core rules:

1.  One notification engine.
2.  One Cefflo visual identity.
3.  One Notification Center pattern per app.
4.  Targeting is determined by business, role and event relevance.
5.  Repeated events should be aggregated where appropriate.
6.  Resolved conditions must stop generating reminders.
7.  Toast disappearance never deletes the notification from Notification
    Center.
8.  Permission checks happen server-side. Client UI is not an
    authorization boundary.

------------------------------------------------------------------------

## 2. Surfaces and Audiences

### 2.1 Vendor App

Vendor App serves business-side operational users.

Possible authenticated roles:

-   Owner
-   Operator
-   Helper

The app receives business operations notifications according to the
user's role and relevance.

### 2.2 Vendor Web

Vendor Web follows the same notification semantics as Vendor App.

Vendor Web must not create a separate notification taxonomy or backend.

Where technically possible it uses the same:

-   notification records;
-   preferences;
-   read/unread state;
-   targeting;
-   deep-link destinations;
-   aggregation rules.

Presentation may adapt for desktop/web dimensions.

### 2.3 Driver App

Driver App receives rider-specific operational notifications.

Examples:

-   new run assignment;
-   pickup ready;
-   run changed;
-   delivery issue requiring action;
-   business invitation/join status;
-   operational broadcast targeted to riders.

### 2.4 Operator

Operator is a role inside the Vendor experience, not a separate branded
app.

Notification sender remains:

**Cefflo**

Do not display `Cefflo Operator`.

Operator receives operational notifications permitted for the Operator
role.

### 2.5 Helper

Helper is also a role, not a separate notification product.

Notification sender remains:

**Cefflo**

Do not display `Cefflo Helper`.

Helpers must receive only notifications relevant to Helper
responsibilities. They must not automatically receive Owner/Operator
operational or administrative notifications.

### 2.6 FOUNDR

FOUNDR is the platform administration surface.

FOUNDR has two notification responsibilities:

1.  **Platform administration notifications** for authorized FOUNDR
    admins.
2.  **Broadcast authoring and targeting** to Cefflo users.

FOUNDR Broadcast is not the source of all notifications. Normal
operational notifications are generated automatically by Cefflo events.

------------------------------------------------------------------------

## 3. Notification Sources

There are two primary sources.

### 3.1 System-generated

Triggered automatically by real Cefflo events.

Examples:

-   storefront order created;
-   order requires planning;
-   run assigned;
-   pickup started;
-   delivery completed;
-   delivery issue reported;
-   run becomes stuck;
-   team join request received;
-   invitation/request approved;
-   business operational reminder;
-   system status event.

These must be based on real backend state.

### 3.2 FOUNDR Broadcast

Authorized FOUNDR administrators can create a manual platform
announcement.

FOUNDR must support deliberate targeting rather than sending everything
to everyone.

Potential targeting dimensions:

-   all eligible businesses;
-   selected business;
-   selected businesses;
-   role/audience;
-   app/surface where applicable.

Examples of audience selections:

-   Owner
-   Operator
-   Owner + Operator
-   Rider
-   another explicitly supported audience

FOUNDR must show the intended audience before Send.

A broadcast must create normal notification records and pass through the
same recipient security model as other notifications.

------------------------------------------------------------------------

## 4. Sender Naming

The visible sender is always:

**Cefflo**

Do not use:

-   Cefflo Owner
-   Cefflo Operator
-   Cefflo Helper
-   Cefflo Rider

The role is a targeting/access concept, not the brand identity.

Driver App may be named `Cefflo Driver` at the app/launcher level, but
an in-app notification still uses `Cefflo` as its sender.

------------------------------------------------------------------------

## 5. In-App Toast / Banner

### 5.1 Visual structure

Standard layout:

``` text
[CEFFLO ICON]   Cefflo                         Just now
                Notification title
                Notification message
```

The component is universal. Content changes according to event type.

### 5.2 Logo

Use the official Cefflo symbol.

The icon tile must use the approved Cefflo blue gradient background.

Do not substitute:

-   black;
-   lime;
-   grey;
-   random gradients.

### 5.3 Card style

Preferred visual direction:

-   compact;
-   premium;
-   glassmorphic light/dark grey;
-   background blur;
-   subtle border;
-   subtle shadow;
-   high text contrast;
-   rounded corners;
-   no excessive decoration.

Do not make the entire notification card Cefflo blue.

The blue branding is primarily carried by the official app icon.

### 5.4 Typography hierarchy

1.  `Cefflo` --- small/medium.
2.  Notification title --- semibold/bold.
3.  Message --- regular, secondary emphasis.
4.  `Just now` / relative time --- secondary.

Title should normally fit on one line.

Message should normally be limited to approximately two visible lines in
the toast.

### 5.5 Status dots

Do not place a decorative lime/blue dot beside every toast title.

Unread indication belongs primarily in Notification Center.

Only introduce a status indicator if it has a defined semantic meaning.

------------------------------------------------------------------------

## 6. Motion and Lifetime

Default animation:

1.  Notification enters from the top.
2.  Simultaneous subtle fade-in.
3.  Settle quickly without strong bounce.
4.  Remain visible.
5.  Fade and slide upward out of view.

Recommended timing:

-   entrance: `250–350 ms`;
-   default visible duration: approximately `3 seconds`;
-   exit: approximately `200–300 ms`.

High-attention notifications may remain approximately `4–5 seconds` if
needed.

Do not make ordinary notifications persistent overlays.

The user can tap the toast before it disappears.

------------------------------------------------------------------------

## 7. Tap Behaviour / Deep Linking

A notification should open the most relevant destination.

Examples:

  Notification            Destination
  ----------------------- ---------------------------------
  New order               Order detail
  Orders ready to plan    Planning / relevant order queue
  Delivery issue          Issue / affected run
  Rider assigned          Relevant run
  Join request            Team / Riders approval surface
  Storefront order        Order detail
  FOUNDR broadcast        Notification detail
  Driver run assignment   Driver run
  Driver delivery issue   Relevant delivery stop/run

If a destination is unavailable because state changed, show an honest
fallback rather than a blank screen.

------------------------------------------------------------------------

## 8. Notification Preferences

Each supported app/user has:

-   **Notifications On / Off**
-   **Sound On / Off**

These are independent controls.

### Notifications ON + Sound ON

-   create/store notification;
-   show toast when eligible;
-   play Cefflo signature sound when supported.

### Notifications ON + Sound OFF

-   create/store notification;
-   show toast;
-   no sound.

### Notifications OFF

-   create/store notification;
-   keep it in Notification Center;
-   no toast;
-   no sound.

Turning notifications off must not delete notification history.

Preferences should persist per user through the real backend.

------------------------------------------------------------------------

## 9. Sound

### 9.1 Final direction

Cefflo will use one dedicated **Cefflo signature notification sound**.

Target characteristics:

-   approximately `0.6–0.9 seconds`;
-   short;
-   clean;
-   premium;
-   operational;
-   recognizable;
-   suitable for repeated use;
-   audible on phone speakers without being harsh.

No looping.

Sound plays once when an eligible in-app notification arrives.

### 9.2 Current implementation rule

Until the official sound is approved:

-   do not label a generic/dev sound as the official Cefflo sound;
-   mobile may temporarily use the device/system alert where already
    implemented;
-   unsupported web sound should be represented honestly as pending;
-   do not ship an unapproved brand sound.

------------------------------------------------------------------------

## 10. Notification Center

Toast and Notification Center are separate presentation layers over the
same notification system.

A toast disappearing does not remove the notification.

Notification Center should support:

-   newest-first list;
-   read/unread;
-   relative timestamp;
-   title;
-   short message;
-   tap destination;
-   persistent server-backed state.

Suggested grouping:

-   Today
-   Earlier

Unread styling should be subtle and accessible.

Example:

``` text
TODAY

Delivery needs attention
Run #18 hasn't progressed for 25 minutes.
2 min

5 new orders
New orders are waiting to be planned.
18 min

Delivery completed
Order #1048 was delivered successfully.
32 min

Cefflo update
A platform update is available.
2 hr
```

------------------------------------------------------------------------

## 11. Priority Model

Internal notification priority:

### INFO

Informational state change.

Examples:

-   delivery completed;
-   request approved;
-   general Cefflo update.

### ACTION

The recipient has useful work to perform.

Examples:

-   new storefront order;
-   orders ready to plan;
-   join request;
-   new run assignment.

### ATTENTION

Operational condition may require prompt intervention.

Examples:

-   delivery issue;
-   stuck run;
-   failed/blocked operational step.

Priority may influence:

-   duration;
-   ordering;
-   reminder eligibility;
-   aggregation rules.

Do not turn the UI into a red/yellow/green dashboard. Keep the toast
visually consistent and communicate severity through clear copy and
context.

------------------------------------------------------------------------

## 12. Event Catalogue --- Vendor Owner

Owner is the broadest business-side recipient.

Potential notification classes:

### Orders

-   New storefront order
-   New public order
-   Multiple new orders
-   Order cancelled
-   Orders ready to plan

### Delivery operations

-   Run ready
-   Pickup started
-   Run started
-   Rider assigned/reassigned
-   Delivery completed
-   Run completed

### Attention

-   Delivery issue
-   Run not progressing
-   Unassigned deliveries requiring action
-   Rider unavailable where operationally relevant

### Team

-   Operator join request
-   Helper join request
-   Rider join request
-   Relevant request status changes

### Platform

-   FOUNDR broadcast
-   planned maintenance
-   service status
-   important product/operational announcement

Owner should not receive noise for every low-value internal state
transition.

------------------------------------------------------------------------

## 13. Event Catalogue --- Operator

Operator receives operational notifications required to operate the
business.

Examples:

-   new order;
-   orders ready to plan;
-   run ready;
-   rider assignment/reassignment;
-   pickup/run status;
-   delivery issue;
-   stuck operation;
-   relevant rider/team operational request;
-   FOUNDR broadcast targeted to Operator.

Operator should not receive Owner-only account/subscription/security
administration notifications.

------------------------------------------------------------------------

## 14. Event Catalogue --- Helper

Helper notifications are intentionally restricted.

Helper does not inherit all Owner/Operator notifications.

Potential Helper notifications should only exist when there is a defined
Helper workflow.

Examples may include:

-   invitation/join status;
-   a task or operational event explicitly assigned to the Helper;
-   a broadcast explicitly designed and authorized for Helper audience,
    if Helper broadcast support is introduced.

Default principle:

**If there is no Helper action or relevant information, do not notify
the Helper.**

Do not leak business administration, subscription, sensitive
team-management, or unrelated operational information through
notifications.

------------------------------------------------------------------------

## 15. Event Catalogue --- Driver App

Driver notifications are action-oriented and run-specific.

### Assignment

**New delivery run**\
You have 8 stops ready for pickup.

### Run changes

**Run updated**\
Your delivery run has been updated.

### Pickup

**Pickup ready**\
Your assigned run is ready to begin.

### Delivery attention

**Delivery needs attention**\
Check the latest update for your current stop.

### Join/business

**Request approved**\
You can now deliver for {business}.

### Platform

FOUNDR broadcast targeted to Riders/Driver users.

Driver should not receive Vendor-only business management notifications.

If a driver belongs to multiple businesses, the notification must
identify the relevant business when ambiguity is possible.

------------------------------------------------------------------------

## 16. Event Catalogue --- Vendor Web

Vendor Web uses the same event catalogue as Vendor App for the signed-in
role.

Do not duplicate business rules for web.

Differences are presentation-only where necessary:

-   desktop-width toast;
-   browser lifecycle;
-   web audio limitations;
-   web navigation/deep links.

Read/unread and preferences must remain synchronized with Vendor App for
the same user.

A notification read on one surface should reflect the same server-backed
state on the other.

------------------------------------------------------------------------

## 17. Event Catalogue --- FOUNDR

FOUNDR itself may receive platform-administration notifications where
needed.

Examples:

-   platform operational incident;
-   failed broadcast;
-   significant admin action requiring review;
-   stuck business/rider operational signal if part of FOUNDR Live Ops;
-   system-level maintenance state.

FOUNDR notifications must remain platform-admin only.

FOUNDR also owns the Broadcast authoring surface.

Broadcast authoring fields should include at minimum:

-   title;
-   message;
-   target business scope;
-   target role/audience;
-   send confirmation.

Future scheduling may be added separately. Do not imply scheduled
broadcasting exists unless implemented.

------------------------------------------------------------------------

## 18. Broadcast Rules

FOUNDR Broadcast must be deliberate.

Before sending, admin should be able to understand:

-   what is being sent;
-   who receives it;
-   which business/businesses are targeted.

Broadcast examples:

### All eligible Vendor users

**Cefflo update**\
A new operational update is now available.

### Specific business

**Important account update**\
Please review the latest Cefflo notice.

### Rider audience

**Driver app update**\
A new Driver update is available.

Broadcast targeting must be enforced by backend recipient selection.

Client-side filtering alone is insufficient.

------------------------------------------------------------------------

## 19. Aggregation / Anti-Spam

Cefflo may process high-frequency operational events. Do not display one
toast per event indefinitely.

Example:

First order:

**New delivery order**\
Order #1048 has just arrived.

Several orders arriving within a short aggregation window:

**5 new orders**\
New orders are waiting for you.

Aggregation should preserve the underlying Notification Center
usefulness without creating a rapid sequence of banners/sounds.

Potential aggregation groups:

-   new orders;
-   completed deliveries;
-   repeated attention events of the same type;
-   multiple similar operational updates.

Do not aggregate unrelated critical issues into vague copy.

------------------------------------------------------------------------

## 20. Reminder Rules

Reminders are state-driven, not engagement-driven.

Good examples:

**Today's deliveries**\
24 orders are scheduled for today.

**Orders ready to plan**\
18 orders still need a delivery plan.

**Needs attention**\
2 deliveries haven't progressed.

Bad examples:

-   We miss you.
-   Come back to Cefflo.
-   See what's new.

A reminder must check current state before being emitted.

If the action has been completed, the reminder must not be sent.

------------------------------------------------------------------------

## 21. Frequency Principles

Use these rules:

**Important new event → immediate**

**Repeated similar events → aggregate**

**Action remains unresolved → eligible reminder**

**Action resolved → stop reminder**

**Informational low-value state → Notification Center only or no
notification**

Avoid fixed arbitrary daily notification counts unless the product later
defines a specific digest.

Cefflo should optimize for operational usefulness, not notification
volume.

------------------------------------------------------------------------

## 22. Example Copy Library

### Vendor

**New delivery order**\
Order #CF-1048 has just arrived.

**5 new orders**\
New orders are waiting to be planned.

**Orders ready to plan**\
12 orders still need a delivery plan.

**Delivery needs attention**\
Run #R-018 hasn't progressed recently.

**Delivery completed**\
Order #CF-1048 was delivered successfully.

**New rider request**\
Aiman wants to join your delivery team.

### Driver

**New delivery run**\
You have 8 stops ready for pickup.

**Run updated**\
Your delivery route has been updated.

**Request approved**\
You can now deliver for Bloom & Co.

### Platform

**Cefflo update**\
An important platform update is available.

**Scheduled maintenance**\
Cefflo will be briefly unavailable during maintenance.

Copy must be factual and concise.

Do not use hype, unnecessary emoji, or marketing-style urgency for
ordinary operational events.

------------------------------------------------------------------------

## 23. Realtime Behaviour

When an eligible notification is created while the recipient is actively
using the app:

1.  backend creates notification;
2.  recipient-specific realtime event is received;
3.  app updates Notification Center;
4.  unread state updates;
5.  preferences are evaluated;
6.  if Notifications ON, show toast;
7.  if Sound ON and sound is supported, play sound once.

Do not show old notifications as new banners after reconnecting.

A freshness threshold should prevent historical rows from replaying as
fresh toasts.

------------------------------------------------------------------------

## 24. Offline / Reconnect

If realtime disconnects:

-   persisted notifications remain the source of truth;
-   on reconnect/refetch, Notification Center catches up;
-   missed historical notifications should not all animate as new
    banners;
-   unread state remains accurate.

Notification delivery must degrade gracefully.

------------------------------------------------------------------------

## 25. Security and Privacy

Core requirements:

-   user reads only their own notification records unless explicitly
    authorized otherwise;
-   FOUNDR broadcast functions require platform-admin authorization;
-   recipient targeting occurs server-side;
-   Helper restrictions must be enforced server-side;
-   one business must not see another business's notifications;
-   notification payloads must not leak sensitive data to unauthorized
    roles;
-   deep links must re-check authorization at destination.

Never assume that possession of a notification payload grants access to
the referenced resource.

------------------------------------------------------------------------

## 26. Cross-Surface Consistency

For the same user:

Vendor App and Vendor Web should share:

-   notification history;
-   read/unread state;
-   preferences where product design specifies global user preferences;
-   notification IDs;
-   destinations;
-   backend recipient logic.

Do not create duplicate notifications merely because the user has
multiple Cefflo surfaces open.

Each active surface may render the same realtime event locally, but the
backend notification record should remain one logical notification.

------------------------------------------------------------------------

## 27. UI State Requirements

### Empty

Example:

**No notifications yet**

Important updates and operational activity will appear here.

### Loading

Use the standard Cefflo loading treatment.

### Error

Do not fabricate an empty list.

Show an honest retry state.

### Read

Normal/subdued treatment.

### Unread

Subtle emphasis.

Avoid excessive badges and colors.

------------------------------------------------------------------------

## 28. Notification Badge

If app-level unread badge support is implemented:

-   badge count is derived from unread notifications;
-   reading/marking notifications updates it;
-   avoid separate local-only badge counters.

Badge behavior must be consistent with backend unread state.

This is optional unless already implemented.

------------------------------------------------------------------------

## 29. FOUNDR Broadcast Delivery Flow

``` text
FOUNDR Admin
    ↓
Compose Broadcast
    ↓
Select Business Scope
    ↓
Select Eligible Audience / Role
    ↓
Confirm
    ↓
Backend authorization
    ↓
Resolve recipients
    ↓
Create recipient notification rows
    ↓
Realtime delivery to active clients
    ↓
Notification Center
    ↓
Toast (if Notifications ON)
    ↓
Cefflo sound (if Sound ON + supported)
```

------------------------------------------------------------------------

## 30. Operational Notification Flow

``` text
Real Cefflo Event
    ↓
Notification rule
    ↓
Determine relevant business + role + user
    ↓
Deduplicate / aggregate if required
    ↓
Create notification
    ↓
Notification Center
    ↓
Realtime to active client
    ↓
Toast
    ↓
Optional sound
    ↓
Tap → authorized destination
```

------------------------------------------------------------------------

## 31. Role Matrix

  ------------------------------------------------------------------------------------------
  Capability             Owner     Operator          Helper        Rider        FOUNDR Admin
  --------------- ------------ ------------ --------------- ------------ -------------------
  Own                      Yes          Yes  Only if Helper          Yes                 Yes
  Notification                                notifications              
  Center                                              exist              

  Notification             Yes          Yes              If          Yes                 Yes
  preferences                                 notifications              
                                                enabled for              
                                                     Helper              

  Order                    Yes          Yes Only explicitly           No Only admin/live-ops
  operational                                      relevant                              use
  notifications                                                          

  Run/business             Yes          Yes Only explicitly Assigned run   Platform/live-ops
  attention                                        relevant         only 

  Team join                Yes As permitted        No admin  Own request      Platform admin
  notifications                                  visibility       status      where required

  Rider               Business          Yes         Only if          Yes       Live-ops only
  assignment           side as                     relevant              
  notification        relevant                                           

  FOUNDR           If targeted  If targeted         Only if  If targeted      N/A / internal
  broadcast                                     supported +              
  receive                                          targeted              

  Create FOUNDR             No           No              No           No                 Yes
  broadcast                                                              
  ------------------------------------------------------------------------------------------

This matrix defines notification eligibility, not general application
permissions.

------------------------------------------------------------------------

## 32. V1 Scope

V1 should include:

-   real notification persistence;
-   recipient-specific access;
-   realtime delivery;
-   Notification Center;
-   read/unread;
-   Notifications On/Off;
-   Sound On/Off;
-   in-app top toast;
-   approximately 3-second default toast;
-   deep links;
-   FOUNDR Broadcast;
-   Owner/Operator targeting;
-   Rider targeting where supported;
-   sensible event notifications;
-   aggregation for obvious high-frequency events;
-   no fake sound branding.

------------------------------------------------------------------------

## 33. Deferred / Future

Do not silently treat these as V1 unless separately approved:

-   scheduled FOUNDR broadcasts;
-   advanced campaign analytics;
-   marketing notification campaigns;
-   user-selectable notification tones;
-   complex per-category preference matrix;
-   SMS/email mirroring;
-   OS push when app is completely closed, unless push infrastructure is
    explicitly implemented;
-   notification delivery analytics;
-   AI-written broadcast copy;
-   advanced digest configuration.

------------------------------------------------------------------------

## 34. Acceptance Criteria

The notification system is considered functionally ready when:

1.  A real system event creates the correct notification for the correct
    recipient.
2.  Unauthorized roles do not receive restricted notifications.
3.  A FOUNDR broadcast reaches exactly its intended audience.
4.  Notification Center loads real persisted records.
5.  Read/unread persists.
6.  Realtime updates the Center without refresh.
7.  Notifications ON shows the toast.
8.  Notifications OFF suppresses toast/sound but retains the record.
9.  Sound OFF suppresses sound only.
10. Toast enters from the top and dismisses after approximately 3
    seconds.
11. Tapping opens the correct authorized destination.
12. Historical notifications do not replay as fresh banners after
    reconnect.
13. Repeated events do not create notification spam where aggregation is
    required.
14. Vendor App and Vendor Web stay consistent for the same user.
15. Driver receives only relevant Driver/rider notifications.
16. Helper does not inherit Owner/Operator notifications by default.
17. Production does not claim an official Cefflo signature sound until
    the asset is approved.

------------------------------------------------------------------------

## 35. Locked UX Decisions

The following are treated as the current design direction:

-   Visible sender: **Cefflo**
-   No role suffix in sender name
-   Official Cefflo logo
-   Logo tile: approved Cefflo blue gradient
-   Toast: compact grey glassmorphic treatment
-   Entry: slide down + subtle fade
-   Default display duration: approximately 3 seconds
-   Exit: fade + slide upward
-   One universal toast component
-   Dynamic title/message
-   No decorative lime unread dot beside toast titles
-   Notification Center retains notifications after toast disappears
-   Notification On/Off and Sound On/Off remain separate
-   One eventual Cefflo signature sound across supported Cefflo
    notification experiences
-   FOUNDR Broadcast is manual platform messaging; system notifications
    remain event-driven

------------------------------------------------------------------------

## 36. Implementation Guardrails

When implementing this specification:

-   do not create separate notification backends per app;
-   do not duplicate notification records per surface;
-   do not use client-only role filtering as security;
-   do not add fake notifications for demo appearance;
-   do not introduce engagement spam;
-   do not invent new roles;
-   do not redesign unrelated Cefflo surfaces;
-   do not introduce the final signature sound without explicit
    approval;
-   do not claim OS/background push exists unless it actually does;
-   preserve current backend authorization and strengthen it where
    required.

------------------------------------------------------------------------

## 37. Summary

Cefflo has one notification language across the platform.

**System events** generate operational notifications automatically.

**FOUNDR Broadcast** provides controlled manual platform communication
to selected businesses and roles.

Every eligible notification is persisted in a Notification Center. When
the recipient is active and Notifications are enabled, a compact Cefflo
glassmorphic banner slides down from the top, remains for approximately
three seconds, optionally plays the approved Cefflo signature sound,
then disappears. The notification itself remains available in
Notification Center.

Owner and Operator receive the broad business-operational set
appropriate to their permissions. Helper receives only explicitly
relevant notifications. Driver receives rider/run-specific
notifications. FOUNDR remains the controlled platform broadcast and
administration surface.

The goal is not more notifications.

The goal is **the right operational signal, to the right person, at the
right time.**
