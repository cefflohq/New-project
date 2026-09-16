// CEFFLO Customer Tracking PWA — inline SVG icon set.
//
// One family, one stroke weight, one geometric style. Icons inherit
// `currentColor` so the vendor theme token (or the graphite utility colour)
// decides the paint, never the icon itself.

const STROKE = 'fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"';

const PATHS = {
  bell: `<g ${STROKE}><path d="M12 3.4a5.4 5.4 0 0 0-5.4 5.4v3.05L5.3 15.1h13.4l-1.3-3.25V8.8A5.4 5.4 0 0 0 12 3.4Z"/><path d="M10.1 18a2 2 0 0 0 3.8 0"/></g>`,
  check: `<path ${STROKE} stroke-width="2.6" d="m5.4 12.4 4.3 4.3 8.9-9"/>`,
  chevronRight: `<path ${STROKE} d="m9.5 5.5 6.5 6.5-6.5 6.5"/>`,
  chevronLeft: `<path ${STROKE} stroke-width="2.1" d="m14.5 5.5-6.5 6.5 6.5 6.5"/>`,
  copy: `<g ${STROKE}><rect x="9" y="9" width="11" height="11" rx="2.6"/><path d="M15.5 6.2A2.2 2.2 0 0 0 13.4 4H6.2A2.2 2.2 0 0 0 4 6.2v7.2a2.2 2.2 0 0 0 2.2 2.2"/></g>`,
  clock: `<g ${STROKE}><circle cx="12" cy="12" r="8.4"/><path d="M12 7.3V12l3.1 1.9"/></g>`,
  phone: `<path ${STROKE} d="M7.9 3.9h1.9a1 1 0 0 1 .94.66l1.02 2.77a1 1 0 0 1-.35 1.15l-1.2.87a11.7 11.7 0 0 0 4.45 4.45l.87-1.2a1 1 0 0 1 1.15-.35l2.77 1.02a1 1 0 0 1 .66.94v1.9a2.6 2.6 0 0 1-2.85 2.6C10.9 18.06 5.94 13.1 5.3 6.75A2.6 2.6 0 0 1 7.9 3.9Z"/>`,
  chat: `<path ${STROKE} d="M20.2 11.7a7.6 7.6 0 0 1-8.2 7.57 8.2 8.2 0 0 1-2.62-.6l-4.2 1.13 1.14-3.83A7.6 7.6 0 1 1 20.2 11.7Z"/>`,
  expand: `<g ${STROKE} stroke-width="2"><path d="M14.4 4.2h5.4v5.4M19.8 4.2l-6.6 6.6M9.6 19.8H4.2v-5.4M4.2 19.8l6.6-6.6"/></g>`,
  close: `<path ${STROKE} stroke-width="2.1" d="M6.5 6.5l11 11M17.5 6.5l-11 11"/>`,
  calendar: `<g ${STROKE}><rect x="3.6" y="5.3" width="16.8" height="15.1" rx="3"/><path d="M3.6 10h16.8M8.3 3.4v3.4M15.7 3.4v3.4"/></g>`,
  person: `<g ${STROKE}><circle cx="12" cy="8.2" r="3.7"/><path d="M4.9 20.2a7.6 7.6 0 0 1 14.2 0"/></g>`,
  note: `<g ${STROKE}><rect x="4.6" y="3.4" width="14.8" height="17.2" rx="3"/><path d="M8.6 9h6.8M8.6 12.6h6.8M8.6 16.2h4.2"/></g>`,
  refresh: `<g ${STROKE}><path d="M20 12a8 8 0 1 1-2.6-5.9"/><path d="M20.4 4.3v4.4H16"/></g>`,
  // Filled status glyphs (drawn on a pale vendor-tinted disc).
  store: `<g fill="currentColor"><path d="M2.6 4.2a1 1 0 0 1 1-1h16.8a1 1 0 0 1 1 1v.7a2.9 2.9 0 0 1-5.1 1.9 2.9 2.9 0 0 1-4.3.3 2.9 2.9 0 0 1-4.3-.3A2.9 2.9 0 0 1 2.6 4.9Z"/><path d="M4.6 9.9v9.4a1.5 1.5 0 0 0 1.5 1.5h11.8a1.5 1.5 0 0 0 1.5-1.5V9.9a4.4 4.4 0 0 1-3.3-.6 4.4 4.4 0 0 1-4.1.4 4.4 4.4 0 0 1-4.1-.4 4.4 4.4 0 0 1-3.3.6Z"/><rect x="9.4" y="13.4" width="5.2" height="7.4" rx="1" fill="var(--status-glyph-cutout, #E8F1FE)"/></g>`,
  truck: `<g fill="currentColor"><path d="M2.4 7.2a1.6 1.6 0 0 1 1.6-1.6h8.2a1.6 1.6 0 0 1 1.6 1.6v9H4a1.6 1.6 0 0 1-1.6-1.6Z"/><path d="M15.2 9.1h2.9a1.6 1.6 0 0 1 1.32.7l1.9 2.8a1.6 1.6 0 0 1 .28.9v2.5h-6.4Z"/><circle cx="7.4" cy="17.7" r="2.4"/><circle cx="17.4" cy="17.7" r="2.4"/></g>`,
  parcel: `<g fill="currentColor"><path d="M12 2.4 21 7 12 11.6 3 7Z"/><path d="M2.6 8.4 11.3 12.8v8.6L2.6 17Z" opacity=".82"/><path d="M21.4 8.4 12.7 12.8v8.6L21.4 17Z" opacity=".56"/></g>`,
  home: `<g fill="currentColor"><path d="M11.36 3.3a1 1 0 0 1 1.28 0l8.12 6.8a1 1 0 0 1-.64 1.77H19v7.33a1.8 1.8 0 0 1-1.8 1.8H6.8A1.8 1.8 0 0 1 5 19.2v-7.33H3.24a1 1 0 0 1-.64-1.77Z"/></g>`,
  starOutline: `<path ${STROKE} stroke-width="1.6" d="m12 3.6 2.66 5.4 5.96.87-4.31 4.2 1.02 5.93L12 17.2l-5.33 2.8 1.02-5.93-4.31-4.2 5.96-.87Z"/>`,
  starFilled: `<path fill="currentColor" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round" d="m12 3.6 2.66 5.4 5.96.87-4.31 4.2 1.02 5.93L12 17.2l-5.33 2.8 1.02-5.93-4.31-4.2 5.96-.87Z"/>`,
  leaf: `<g fill="currentColor"><path d="M12 2.6c3.5 2.9 5.3 6 5.3 9.2 0 3.4-2.3 5.9-5.3 6.9-3-1-5.3-3.5-5.3-6.9 0-3.2 1.8-6.3 5.3-9.2Z"/><rect x="11.52" y="6" width="0.96" height="12.6" fill="var(--vendor-mark-cutout, #FFFFFF)"/><rect x="11.15" y="16.6" width="1.7" height="4.8" rx="0.85"/></g>`
};

/**
 * @param {keyof PATHS} name
 * @param {{size?: number, className?: string, title?: string}} [options]
 */
export function icon(name, { size = 24, className = '' } = {}) {
  const body = PATHS[name];
  if (!body) return '';
  const classes = ['icon', className].filter(Boolean).join(' ');
  return `<svg class="${classes}" viewBox="0 0 24 24" width="${size}" height="${size}" aria-hidden="true" focusable="false">${body}</svg>`;
}

/**
 * Prototype route illustration for C2.
 *
 * This is deliberately a stylised fixture drawing, not a map tile service and
 * not a live position: the Master forbids presenting fabricated location as
 * real. The route/pins paint from the vendor theme token.
 */
export function routeMapSvg() {
  return `<svg class="map-canvas" viewBox="0 0 400 300" preserveAspectRatio="xMidYMid slice" aria-hidden="true" focusable="false">
    <rect width="400" height="300" fill="#F2F4F6"/>
    <g fill="#E3EFE0">
      <rect x="18" y="22" width="86" height="54" rx="6"/>
      <rect x="150" y="10" width="96" height="46" rx="6"/>
      <rect x="292" y="40" width="92" height="62" rx="6"/>
      <rect x="10" y="150" width="74" height="70" rx="6"/>
      <rect x="128" y="126" width="104" height="58" rx="6"/>
      <rect x="266" y="150" width="84" height="48" rx="6"/>
      <rect x="40" y="248" width="120" height="44" rx="6"/>
      <rect x="216" y="236" width="150" height="56" rx="6"/>
    </g>
    <g stroke="#FFFFFF" stroke-linecap="round" fill="none">
      <path d="M0 96h400" stroke-width="13"/>
      <path d="M0 206h400" stroke-width="11"/>
      <path d="M116 0v300" stroke-width="12"/>
      <path d="M252 0v300" stroke-width="10"/>
      <path d="M0 40h116M252 118h148M0 266h400" stroke-width="6"/>
      <path d="M48 96v170M348 0v300" stroke-width="6"/>
    </g>
    <path d="M62 128 C 62 186, 150 168, 196 178 S 300 214, 340 196"
      fill="none" stroke="var(--vendor-primary)" stroke-width="7" stroke-linecap="round"/>
    <g transform="translate(46 92)">
      <path d="M16 0a16 16 0 0 1 16 16c0 11-16 28-16 28S0 27 0 16A16 16 0 0 1 16 0Z" fill="var(--vendor-primary)"/>
      <g transform="translate(7 7) scale(0.75)" fill="#FFFFFF">
        <path d="M2.6 4.2a1 1 0 0 1 1-1h16.8a1 1 0 0 1 1 1v.7a2.9 2.9 0 0 1-5.1 1.9 2.9 2.9 0 0 1-4.3.3 2.9 2.9 0 0 1-4.3-.3A2.9 2.9 0 0 1 2.6 4.9Z"/>
        <path d="M4.6 9.9v9.4a1.5 1.5 0 0 0 1.5 1.5h11.8a1.5 1.5 0 0 0 1.5-1.5V9.9a4.4 4.4 0 0 1-3.3-.6 4.4 4.4 0 0 1-4.1.4 4.4 4.4 0 0 1-4.1-.4 4.4 4.4 0 0 1-3.3.6Z"/>
      </g>
    </g>
    <g transform="translate(316 160)">
      <path d="M16 0a16 16 0 0 1 16 16c0 11-16 28-16 28S0 27 0 16A16 16 0 0 1 16 0Z" fill="#0F172A"/>
      <g transform="translate(7 6) scale(0.78)" fill="#FFFFFF">
        <path d="M11.36 3.3a1 1 0 0 1 1.28 0l8.12 6.8a1 1 0 0 1-.64 1.77H19v7.33a1.8 1.8 0 0 1-1.8 1.8H6.8A1.8 1.8 0 0 1 5 19.2v-7.33H3.24a1 1 0 0 1-.64-1.77Z"/>
      </g>
    </g>
    <g transform="translate(174 152) scale(1.5)" fill="var(--vendor-primary)">
      <path d="M2.4 7.2a1.6 1.6 0 0 1 1.6-1.6h8.2a1.6 1.6 0 0 1 1.6 1.6v9H4a1.6 1.6 0 0 1-1.6-1.6Z"/>
      <path d="M15.2 9.1h2.9a1.6 1.6 0 0 1 1.32.7l1.9 2.8a1.6 1.6 0 0 1 .28.9v2.5h-6.4Z"/>
      <circle cx="7.4" cy="17.7" r="2.4"/><circle cx="17.4" cy="17.7" r="2.4"/>
    </g>
  </svg>`;
}
