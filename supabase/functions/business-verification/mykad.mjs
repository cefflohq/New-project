// MyKad front, read from a Google Vision DOCUMENT_TEXT_DETECTION response
// (Founder 2026-10-17). Pure, so it can be tested in Node.
//
// Photos are often sideways or upside down, so lines are rebuilt from word
// positions in the card's own orientation: the IC number fixes the reading
// direction and the letter height; the name is the line(s) just below it.
// Background micro-text (much smaller than the IC digits) is ignored.
// Returns the 12-digit IC and the holder's name, or nulls (Cefflo then
// reads the photo by eye).
const NOISE = /^(MYKAD|KAD PENGENALAN|MALAYSIA|IDENTITY CARD|WARGANEGARA|LELAKI|PEREMPUAN|ISLAM|KRISTIAN|BUDDHA|HINDU)\b/;
const ADDRESS = /\d|\b(JALAN|JLN|TAMAN|TMN|LORONG|LRG|KAMPUNG|KG|NO|BLOK|LOT|SEKSYEN|PERSIARAN|BANDAR|APARTMENT|FLAT)\b/;
const IC_RE = /(\d{6})\s?-?\s?(\d{2})\s?-?\s?(\d{4})/;

const v = (p) => ({ x: p?.x ?? 0, y: p?.y ?? 0 });

/** Words with their text and the four corners Vision gives (in reading order). */
function words(response) {
  const out = [];
  for (const page of response?.responses?.[0]?.fullTextAnnotation?.pages ?? [])
    for (const block of page.blocks ?? [])
      for (const para of block.paragraphs ?? [])
        for (const w of para.words ?? []) {
          const text = (w.symbols ?? []).map((s) => s.text).join('');
          const c = (w.boundingBox?.vertices ?? []).map(v);
          if (text && c.length === 4) out.push({ text, c });
        }
  return out;
}

export function readMyKad(response) {
  const all = words(response);
  if (!all.length) return { ic: null, name: null };

  // The IC number may be one word or split around the dashes: join runs of
  // consecutive words and look for the pattern.
  let ic = null, icWords = null;
  for (let i = 0; i < all.length && !ic; i++) {
    if (!/^\d/.test(all[i].text)) continue;
    let s = '';
    for (let j = i; j < Math.min(all.length, i + 6); j++) {
      if (!/^[\d-]+$/.test(all[j].text)) break;
      s += all[j].text;
      const m = s.match(IC_RE);
      if (m && s.replace(/[^0-9-]/g, '').length <= 14) { ic = m[1] + m[2] + m[3]; icWords = all.slice(i, j + 1); break; }
    }
  }
  if (!ic) return { ic: null, name: null };

  // Reading direction: from the first word's top-left to top-right corner.
  const a = icWords[0].c;
  const dx = a[1].x - a[0].x, dy = a[1].y - a[0].y;
  const len = Math.hypot(dx, dy) || 1;
  const ux = dx / len, uy = dy / len;            // along the line
  const nx = -uy, ny = ux;                       // "down" on the card
  const local = (p) => ({ u: p.x * ux + p.y * uy, d: p.x * nx + p.y * ny });
  const box = (w) => {
    const pts = w.c.map(local);
    const us = pts.map((p) => p.u), ds = pts.map((p) => p.d);
    return { u0: Math.min(...us), u1: Math.max(...us), d0: Math.min(...ds), d1: Math.max(...ds) };
  };
  const icBox = icWords.map(box).reduce((m, x) => ({ u0: Math.min(m.u0, x.u0), u1: Math.max(m.u1, x.u1), d0: Math.min(m.d0, x.d0), d1: Math.max(m.d1, x.d1) }));
  const h = icBox.d1 - icBox.d0 || 1;            // letter height of the IC digits

  // Words below the IC number, of normal print size, starting near the IC's
  // left edge (the name is printed under it, left-aligned).
  const cand = all.filter((w) => !icWords.includes(w)).map((w) => ({ w, ...box(w) }))
    .filter((x) => x.d0 > icBox.d1 - h * 0.3 && x.d0 < icBox.d1 + h * 8)
    .filter((x) => x.d1 - x.d0 > h * 0.55 && x.d1 - x.d0 < h * 2.2)
    .filter((x) => x.u0 > icBox.u0 - h * 3);

  // Group into lines by vertical position on the card.
  cand.sort((p, q) => p.d0 - q.d0);
  const lines = [];
  for (const x of cand) {
    const line = lines.find((l) => Math.abs(l.d - (x.d0 + x.d1) / 2) < h * 0.6);
    if (line) line.items.push(x); else lines.push({ d: (x.d0 + x.d1) / 2, items: [x] });
  }
  const texts = lines.sort((p, q) => p.d - q.d)
    .map((l) => l.items.sort((p, q) => p.u0 - q.u0).map((x) => x.w.text).join(' ').replace(/\s+([@'\/.-])\s*/g, '$1 ').trim().toUpperCase());

  const name = [];
  for (const t of texts) {
    if (NOISE.test(t)) continue;
    if (ADDRESS.test(t) || !/^[A-Z@'\/.\s-]+$/.test(t) || t.length < 3) break;
    name.push(t);
    if (name.length === 2) break;
  }
  const full = name.join(' ').replace(/\s+/g, ' ').trim();
  return { ic, name: full.length >= 5 ? full : null };
}
