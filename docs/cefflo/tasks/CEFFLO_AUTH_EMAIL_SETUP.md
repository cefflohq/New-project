# CEFFLO — Production Auth Email Setup

## Objective
Configure Cefflo's production authentication emails so signup confirmation, password reset, magic link/OTP, email change, and invitations are sent using the Cefflo domain instead of the default Supabase sender.

## Target Architecture
Supabase Auth → Resend SMTP → User Inbox

Cloudflare is used only for DNS/domain verification.

## Target Sender
- From name: `Cefflo`
- Preferred sender: `no-reply@auth.cefflo.com`
- Sending subdomain: `auth.cefflo.com`
- Do not create or pay for a Gmail/Google Workspace mailbox solely for automated Auth emails.

## Implementation Scope

### 1. Resend
1. Create/configure the Cefflo sending domain using `auth.cefflo.com`.
2. Obtain the DNS records required by Resend for domain verification and email authentication.
3. Do not expose API keys or SMTP credentials in logs, screenshots, commits, or chat output.
4. After DNS verification succeeds, create the credential required for SMTP.

### 2. Cloudflare DNS
1. Open the DNS zone for `cefflo.com`.
2. Add exactly the DNS records supplied by Resend.
3. Preserve all unrelated existing DNS records.
4. Do not modify nameservers, website routing, or unrelated Cefflo services.
5. Confirm Resend reports the sending domain as verified.

### 3. Supabase Auth — Custom SMTP
Configure the correct Cefflo Supabase project to use Resend Custom SMTP.

Expected Resend SMTP configuration:
- Host: `smtp.resend.com`
- Username: `resend`
- Password: Resend API key / SMTP credential
- Sender name: `Cefflo`
- Sender email: `no-reply@auth.cefflo.com`

Do not place secrets in the repository. Use the appropriate secret/configuration mechanism.

### 4. Auth URLs
Before testing, verify:
- Production Site URL is correct.
- Allowed redirect URLs contain only required Cefflo destinations.
- Confirmation and password-reset links return users to the intended Cefflo application.
- Do not weaken authentication or redirect security just to make a test pass.

### 5. Email Templates
Polish the Supabase Auth templates for:
- Confirm signup
- Reset password
- Magic link / OTP, if enabled
- Change email
- Invite user, if used

Brand direction:
- Clean and minimal
- Cefflo branding
- Clear primary CTA
- Mobile-friendly
- No unnecessary marketing content in transactional emails
- Keep required Supabase template variables intact.

### 6. End-to-End QA
Use a safe test account and verify:
1. New signup triggers the confirmation email.
2. Sender displays as Cefflo from the Cefflo domain.
3. Email reaches the inbox successfully.
4. Confirmation link works.
5. Password-reset request sends successfully.
6. Password-reset link works and returns to the correct Cefflo surface.
7. Test mobile rendering and basic desktop rendering.
8. Check that secrets have not entered git history or application logs.

## Safety / Change Rules
- Inspect before changing.
- Do not touch production until the target Supabase project and Cefflo DNS zone are positively identified.
- Never print secret values.
- Never commit credentials.
- Do not delete or replace unrelated Cloudflare DNS records.
- Do not disable email confirmation merely to bypass setup.
- If an action requires the founder to log in, approve access, create an account, complete verification, or supply a secret, STOP at that step and state exactly what action is required.
- After the founder completes that action, continue from the stopped step.
- Prefer clean configuration over workarounds.

## Required Completion Report
At completion, report:

| Check | Result |
|---|---|
| Resend domain | Verified / Not verified |
| Cloudflare DNS | Configured / Blocked |
| Supabase Custom SMTP | Configured / Blocked |
| Sender | Final sender address |
| Signup confirmation test | Pass / Fail |
| Password reset test | Pass / Fail |
| Redirect test | Pass / Fail |
| Secrets committed | Must be No |
| Manual founder action remaining | List, or None |

Also list exactly what was changed and any remaining risks or follow-up work.

## Definition of Done
This task is complete only when a real test signup confirmation and a real password-reset email have both been delivered through the Cefflo sender and their links work correctly. DNS configuration alone is not completion.
