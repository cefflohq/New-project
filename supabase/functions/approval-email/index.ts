// approval-email — Cefflo's transactional emails (Brevo). Called by database
// triggers, authorised by the same x-push-secret as the push hook.
//   POST ← { kind, id }
//   kind 'rider' | 'team'            approved or rejected (from the row's status)
//   kind 'new_rider' | 'new_team'    a new application, to the business owner
//   kind 'docs_opened'               a driver's sealed documents were opened
//   kind 'complaint_filed'           to both sides (complainant: received; respondent: please reply)
//   kind 'complaint_decided'         Cefflo's decision, to both sides
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SECRET = Deno.env.get('CEFFLO_PUSH_WEBHOOK_SECRET') ?? '';
const BREVO = Deno.env.get('BREVO_API_KEY') ?? '';
const FROM = { name: 'Cefflo', email: Deno.env.get('CEFFLO_MAIL_FROM') ?? 'no-reply@cefflo.com' };
const PLAY = Deno.env.get('CEFFLO_DRIVER_PLAY_URL') ?? 'https://play.google.com/store/apps/details?id=com.cefflo.driver';
const APPSTORE = Deno.env.get('CEFFLO_DRIVER_APPSTORE_URL') ?? 'https://cefflo.com';
const VENDOR_WEB = Deno.env.get('CEFFLO_VENDOR_WEB_URL') ?? 'https://cefflo-vendor-web-staging.vercel.app';
const VENDOR_PWA = Deno.env.get('CEFFLO_VENDOR_PWA_URL') ?? 'https://cefflo-vendor-app-staging.vercel.app';

const KINDS = ['rider', 'team', 'new_rider', 'new_team', 'docs_opened', 'complaint_filed', 'complaint_decided'];
const json = (v: unknown, status = 200) =>
  new Response(JSON.stringify(v), { status, headers: { 'content-type': 'application/json' } });

function safeEqual(a: string, b: string) {
  if (!a || !b || a.length !== b.length) return false;
  let r = 0;
  for (let i = 0; i < a.length; i++) r |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return r === 0;
}

const esc = (s: string) => s.replace(/[&<>"']/g, c => `&#${c.charCodeAt(0)};`);
const ASSETS = Deno.env.get('CEFFLO_EMAIL_ASSETS_URL') ?? 'https://cefflo-email-assets.vercel.app/img';
// Both store badges share one size and sit side by side.
const badge = (href: string, img: string, alt: string) =>
  `<td width="50%" align="center" style="padding:0 4px"><a href="${esc(href)}"><img src="${ASSETS}/${img}?v=3" alt="${alt}" width="140" style="display:block;width:100%;max-width:140px;height:auto;border:0"></a></td>`;
// Fluid: the pair shrinks to fit narrow phone screens and stays centred.
const badges = (...cells: string[]) =>
  `<table role="presentation" cellpadding="0" cellspacing="0" border="0" align="center" width="100%" style="width:100%;max-width:296px;margin:0 auto"><tr>${cells.join('')}</tr></table>`;
const button = (href: string, label: string) =>
  `<a href="${esc(href)}" style="display:inline-block;background:#FFC93C;color:#1b1b1b;text-decoration:none;font-weight:700;padding:14px 28px;border-radius:999px;margin:6px 4px">${esc(label)}</a>`;

function page(heading: string, lines: string[], buttons = '') {
  return `<!doctype html><html><body style="margin:0;background:#f5f7fa;font-family:Arial,sans-serif;color:#0f1b33">
<div style="max-width:520px;margin:0 auto;padding:10px">
<img src="${ASSETS}/header.png?v=3" alt="Cefflo" width="488" style="display:block;width:100%;height:auto;border:0;border-radius:16px 16px 0 0;background:#0a2a70">
<div style="background:#fff;border-radius:0 0 16px 16px;padding:24px">
<p style="font-size:22px;font-weight:700;margin:0 0 12px">${heading}</p>
${lines.map(l => `<p style="font-size:15px;line-height:1.5;margin:0 0 10px">${l}</p>`).join('')}
${buttons ? `<div style="text-align:center;margin-top:20px">${buttons}</div>` : ''}
</div>
<p style="font-size:12px;line-height:1.5;color:#5b6577;text-align:center;margin:16px 0 0">Questions or need help? Email us at <a href="mailto:support@cefflo.com" style="color:#0060FE;text-decoration:none">support@cefflo.com</a></p>
<p style="font-size:12px;line-height:1.5;color:#5b6577;text-align:center;margin:20px 0 0">Cefflo Technologies<br>SSM: PG0592731-P</p>
</div></body></html>`;
}

Deno.serve(async req => {
  if (req.method !== 'POST') return json({ error: 'not found' }, 404);
  if (!safeEqual(req.headers.get('x-push-secret') ?? '', SECRET)) return json({ error: 'unauthorized' }, 401);
  if (!BREVO) return json({ error: 'email not configured' }, 503);
  const { kind, id } = await req.json().catch(() => ({}));
  if (!KINDS.includes(kind) || typeof id !== 'string' || !/^[0-9a-f-]{36}$/.test(id)) {
    return json({ error: 'bad request' }, 400);
  }
  const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, { auth: { persistSession: false } });
  const person = async (userId: string, fallback = '') => {
    const { data: u } = await db.auth.admin.getUserById(userId);
    const email = u?.user?.email;
    if (!email) return null;
    const meta = (u!.user!.user_metadata ?? {}) as Record<string, unknown>;
    const name = String(meta.full_name ?? meta.name ?? fallback ?? '').trim() || email.split('@')[0];
    return { email, name, first: name.split(/\s+/)[0] };
  };
  const bizName = async (businessId: string) =>
    (await db.from('businesses').select('name').eq('id', businessId).maybeSingle()).data?.name ?? 'your business';
  const owner = async (businessId: string) => {
    const { data } = await db.from('business_members').select('user_id')
      .eq('business_id', businessId).eq('role', 'owner').eq('status', 'active').limit(1).maybeSingle();
    return data ? person(data.user_id) : null;
  };
  const roleName = (r: string) => r === 'helper' ? 'a Helper' : r === 'operator' ? 'an Operator' : 'a driver';

  let to: { email: string; name: string; first: string } | null = null;
  let subject = '', html = '';
  const extra: { to: { email: string; name: string }; subject: string; html: string }[] = [];

  if (kind === 'rider' || kind === 'team') {
    let userId: string, businessId: string, role: string, approved: boolean, fallback = '';
    if (kind === 'rider') {
      const { data: r } = await db.from('riders').select('auth_user_id, business_id, status, name').eq('id', id).maybeSingle();
      if (!r?.auth_user_id || !['active', 'inactive'].includes(r.status)) return json({ sent: 0 });
      userId = r.auth_user_id; businessId = r.business_id; role = 'driver'; approved = r.status === 'active'; fallback = r.name ?? '';
    } else {
      const { data: t } = await db.from('team_join_requests').select('user_id, business_id, status, role').eq('id', id).maybeSingle();
      if (!t || !['approved', 'rejected'].includes(t.status)) return json({ sent: 0 });
      userId = t.user_id; businessId = t.business_id; role = t.role; approved = t.status === 'approved';
    }
    to = await person(userId, fallback);
    if (!to) return json({ sent: 0 });
    const biz = esc(await bizName(businessId));
    if (approved) {
      subject = 'Congratulations! Your application has been approved';
      html = role === 'driver'
        ? page(`Congratulations, ${esc(to.first)}! 🎉`, [
            `Your application to drive with <b>${biz}</b> has been approved.`,
            'Install the Cefflo Driver app, then log in with this email.',
          ], badges(badge(PLAY, 'google-play.png', 'Get it on Google Play'), badge(APPSTORE, 'app-store.png', 'Download on the App Store')))
        : page(`Congratulations, ${esc(to.first)}! 🎉`, [
            `Your request to join <b>${biz}</b> as ${roleName(role)} has been approved.`,
          ], button(role === 'helper' ? VENDOR_PWA : VENDOR_WEB, 'Log in now'));
    } else {
      subject = 'Update on your application';
      html = page(`Hi ${esc(to.first)},`, [
        `Thank you for applying to join <b>${biz}</b> as ${roleName(role)}. Unfortunately, your application was not approved this time.`,
        'You can still find other opportunities on Cefflo.',
      ]);
    }
  } else if (kind === 'new_rider' || kind === 'new_team') {
    let businessId: string, applicant: string, role: string;
    if (kind === 'new_rider') {
      const { data: r } = await db.from('riders').select('business_id, status, name').eq('id', id).maybeSingle();
      if (!r || r.status !== 'pending') return json({ sent: 0 });
      businessId = r.business_id; applicant = r.name ?? 'Someone'; role = 'driver';
    } else {
      const { data: t } = await db.from('team_join_requests').select('user_id, business_id, status, role').eq('id', id).maybeSingle();
      if (!t || t.status !== 'pending') return json({ sent: 0 });
      businessId = t.business_id; role = t.role; applicant = (await person(t.user_id))?.name ?? 'Someone';
    }
    to = await owner(businessId);
    if (!to) return json({ sent: 0 });
    subject = `New application: ${applicant}`;
    html = page('New application waiting', [
      `<b>${esc(applicant)}</b> has applied to join <b>${esc(await bizName(businessId))}</b> as ${roleName(role)}.`,
      'Review and approve or reject the application in Cefflo.',
    ], button(VENDOR_WEB, 'Review application'));
  } else if (kind === 'complaint_filed' || kind === 'complaint_decided') {
    const { data: c } = await db.from('complaints').select('*').eq('id', id).maybeSingle();
    if (!c) return json({ sent: 0 });
    const biz = esc(await bizName(c.business_id));
    const CAT: Record<string, string> = { damaged_lost: 'Damaged or lost item', conduct: 'Conduct', safety: 'Safety', unpaid: 'Not paid', fraud: 'Fraud or scam', other: 'Other' };
    const DEC: Record<string, string> = { settled: 'Settled between both sides', no_fault: 'No fault found', warning: 'A warning was given', driver_at_fault: 'The driver was at fault', vendor_at_fault: 'The business was at fault', customer_at_fault: 'The customer was at fault', false_report: 'The report was found to be false' };
    const due = new Date(c.reply_due_at).toLocaleString('en-MY', { timeZone: 'Asia/Kuala_Lumpur', dateStyle: 'medium', timeStyle: 'short' });
    const complainant = c.complainant_user_id ? await person(c.complainant_user_id)
      : /@/.test(c.complainant_contact ?? '') ? { email: c.complainant_contact, name: c.complainant_name || 'Customer', first: (c.complainant_name || 'there').split(/\s+/)[0] } : null;
    const respondent = c.respondent_user_id ? await person(c.respondent_user_id) : null;
    const where = (role: string) => role === 'driver' ? 'the Cefflo Driver app' : 'Cefflo';
    const cta = (role: string) => role === 'vendor' ? button(VENDOR_WEB, 'Open Cefflo') : '';
    if (kind === 'complaint_filed') {
      if (complainant) {
        to = complainant;
        subject = `We received your complaint ${c.ref}`;
        html = page(`Hi ${esc(to.first)},`, [
          `We received your complaint <b>${c.ref}</b> (${CAT[c.category]}).`,
          `The other side has until <b>${due}</b> to give their account. Cefflo then reviews both sides and the delivery records, and tells you the outcome by email.`,
        ]);
      }
      if (respondent) {
        const m = { to: respondent, subject: `Please respond to complaint ${c.ref}`, html: page(`Hi ${esc(respondent.first)},`, [
          `A complaint was filed ${c.respondent_role === 'driver' ? `about a delivery you made for <b>${biz}</b>` : `about <b>${biz}</b>`}: <b>${CAT[c.category]}</b>.`,
          `Please give your side in ${where(c.respondent_role)} by <b>${due}</b>. You can add up to 5 photos. If we don't hear from you, Cefflo decides with the records it has.`,
        ], cta(c.respondent_role)) };
        if (to) extra.push(m); else { to = respondent; subject = m.subject; html = m.html; }
      }
    } else {
      const lines = (r: { first: string }) => page(`Hi ${esc(r.first)},`, [
        `Cefflo has reviewed complaint <b>${c.ref}</b> (${CAT[c.category]}).`,
        `Outcome: <b>${DEC[c.decision] ?? 'Resolved'}</b>`,
        esc(c.decision_note ?? ''),
      ]);
      const subj = `Outcome of complaint ${c.ref}`;
      if (complainant) { to = complainant; subject = subj; html = lines(complainant); }
      if (respondent) { if (to) extra.push({ to: respondent, subject: subj, html: lines(respondent) }); else { to = respondent; subject = subj; html = lines(respondent); } }
    }
    if (!to) return json({ sent: 0 });
  } else {
    const { data: c } = await db.from('driver_incident_cases').select('rider_user_id, status, opened_at, expires_at').eq('id', id).maybeSingle();
    if (!c || c.status !== 'open') return json({ sent: 0 });
    to = await person(c.rider_user_id);
    if (!to) return json({ sent: 0 });
    const fmt = (d: string) => new Date(d).toLocaleString('en-MY', { timeZone: 'Asia/Kuala_Lumpur', dateStyle: 'medium', timeStyle: 'short' });
    subject = 'Your documents were opened for an incident review';
    html = page(`Hi ${esc(to.first)},`, [
      'A business reported an incident involving you. To investigate it, Cefflo opened your verification documents (IC and driving licence).',
      `Opened: <b>${fmt(c.opened_at)}</b><br>Access ends: <b>${fmt(c.expires_at)}</b>`,
      'Only Cefflo staff handling this case can see them, and every opening is recorded. If you have questions about this review, email support@cefflo.com.',
    ]);
  }

  let sent = 0;
  for (const m of [{ to: to!, subject, html }, ...extra]) {
    const res = await fetch('https://api.brevo.com/v3/smtp/email', {
      method: 'POST',
      headers: { 'api-key': BREVO, 'content-type': 'application/json', accept: 'application/json' },
      body: JSON.stringify({ sender: FROM, to: [{ email: m.to.email, name: m.to.name }], subject: m.subject, htmlContent: m.html }),
    });
    if (res.ok) sent++; else console.error('brevo', res.status, await res.text());
  }
  return sent ? json({ sent }) : json({ error: 'send failed' }, 502);
});
