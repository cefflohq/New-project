// Pure, runtime-independent extraction from a Google Cloud Vision
// DOCUMENT_TEXT_DETECTION response (Marketplace Verification V1).
// It only EXTRACTS candidate fields; every decision is made server-side in
// SQL (_marketplace_decide). OCR is document screening, not JPJ verification.

const LICENCE_CLASSES = ['B', 'B1', 'B2', 'D', 'DA', 'E', 'E1', 'E2'];

export function visionText(response) {
  const a = response?.responses?.[0]?.fullTextAnnotation;
  if (!a?.text) return { text: '', confidence: 0 };
  const blocks = (a.pages || []).flatMap((p) => p.blocks || []);
  const conf = blocks.length
    ? blocks.reduce((s, b) => s + (b.confidence ?? 0), 0) / blocks.length
    : 0;
  return { text: a.text, confidence: Math.round(conf * 1000) / 1000 };
}

export function normalizePlate(p) {
  return String(p || '').toUpperCase().replace(/[^A-Z0-9]/g, '');
}

function parseDate(s) {
  const m = s.match(/^(\d{1,2})[/.-](\d{1,2})[/.-](\d{4})$/);
  if (!m) return null;
  const [d, mo, y] = [+m[1], +m[2], +m[3]];
  if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
  return `${y}-${String(mo).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
}

/** Malaysian driving licence: IC, name, classes, expiry (latest date). */
export function extractLicence({ text, confidence }) {
  const upper = String(text || '').toUpperCase();
  const lines = upper.split('\n').map((l) => l.trim()).filter(Boolean);
  if (!lines.length) return { text_found: false, confidence: 0 };
  const icMatch = upper.match(/\b(\d{6})\s?-?\s?(\d{2})\s?-?\s?(\d{4})\b/);
  let name = null;
  const ni = lines.findIndex((l) => /^(NAMA|NAME)\b/.test(l) || /NAMA\s*\/\s*NAME/.test(l));
  if (ni >= 0) {
    const inline = lines[ni].replace(/^.*?(NAMA\s*\/\s*NAME|NAMA|NAME)\s*:?\s*/, '');
    name = inline && /[A-Z]{2,}/.test(inline) ? inline : lines[ni + 1] || null;
  }
  const classes = new Set();
  for (const l of lines) {
    if (!/(KELAS|CLASS)/.test(l)) continue;
    const idx = lines.indexOf(l);
    for (const src of [l.replace(/^.*?(KELAS\s*\/\s*CLASS|KELAS|CLASS)\s*:?/, ''), lines[idx + 1] || '']) {
      for (const t of src.split(/[\s,]+/)) if (LICENCE_CLASSES.includes(t)) classes.add(t);
    }
  }
  const dates = (upper.match(/\b\d{1,2}[/.-]\d{1,2}[/.-]\d{4}\b/g) || [])
    .map(parseDate).filter(Boolean).sort();
  return {
    text_found: true,
    confidence,
    ic: icMatch ? icMatch[1] + icMatch[2] + icMatch[3] : null,
    name: name ? name.replace(/[^A-Z@' /-]/g, ' ').replace(/\s+/g, ' ').trim() : null,
    classes: [...classes],
    expiry: dates.length ? dates[dates.length - 1] : null,
  };
}

/** Malaysian plate candidates from a vehicle photo (e.g. "VAB 1234"). */
export function extractPlates({ text, confidence }) {
  const out = [];
  for (const raw of String(text || '').toUpperCase().split('\n')) {
    const p = normalizePlate(raw);
    if (/^[A-Z]{1,4}[0-9]{1,4}[A-Z]{0,3}$/.test(p) && /[0-9]/.test(p) && p.length >= 3 && !out.some((o) => o.text === p)) {
      out.push({ text: p, confidence });
    }
  }
  return { plates: out };
}
