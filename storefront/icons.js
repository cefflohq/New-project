// CEFFLO Storefront — inline SVG icon set.
//
// One family, one stroke weight. Icons inherit `currentColor` so a brand
// token (or a neutral utility colour) decides the paint, never the icon
// itself — same convention as customer/icons.js.

const STROKE = 'fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"';

const PATHS = {
  store: `<g ${STROKE}><path d="M4 9.5 5.6 4h12.8L20 9.5"/><path d="M4 9.5a2.6 2.6 0 0 0 5.1 1 2.6 2.6 0 0 0 4.9 0 2.6 2.6 0 0 0 4.9 0 2.6 2.6 0 0 0 1.1-.9"/><path d="M5.4 10v9.4a1 1 0 0 0 1 1h11.2a1 1 0 0 0 1-1V10"/><path d="M9.6 20.4v-5.6a1 1 0 0 1 1-1h2.8a1 1 0 0 1 1 1v5.6"/></g>`,
  search: `<g ${STROKE}><circle cx="10.6" cy="10.6" r="6.6"/><path d="m20 20-4.7-4.7"/></g>`,
  shoppingCart: `<g ${STROKE}><path d="M3.5 4h2l2.3 11.4a2 2 0 0 0 2 1.6h7.4a2 2 0 0 0 2-1.6L20.5 8H6.2"/><circle cx="9.5" cy="20" r="1.3" fill="currentColor" stroke="none"/><circle cx="17" cy="20" r="1.3" fill="currentColor" stroke="none"/></g>`,
  chevronLeft: `<path ${STROKE} d="m14.5 5.5-6.5 6.5 6.5 6.5"/>`,
  chevronRight: `<path ${STROKE} d="m9.5 5.5 6.5 6.5-6.5 6.5"/>`,
  plus: `<path ${STROKE} stroke-width="2.2" d="M12 5v14M5 12h14"/>`,
  minus: `<path ${STROKE} stroke-width="2.2" d="M5 12h14"/>`,
  trash: `<g ${STROKE}><path d="M5 7h14M9.5 7V5a1.5 1.5 0 0 1 1.5-1.5h2A1.5 1.5 0 0 1 14.5 5v2"/><path d="M6.5 7 7.3 19a1.5 1.5 0 0 0 1.5 1.4h6.4a1.5 1.5 0 0 0 1.5-1.4L17.5 7"/></g>`,
  check: `<path ${STROKE} stroke-width="2.4" d="m5.4 12.4 4.3 4.3 8.9-9"/>`,
  star: `<path ${STROKE} stroke-width="1.6" d="m12 3.6 2.66 5.4 5.96.87-4.31 4.2 1.02 5.93L12 17.2l-5.33 2.8 1.02-5.93-4.31-4.2 5.96-.87Z"/>`,
  starFilled: `<path fill="currentColor" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round" d="m12 3.6 2.66 5.4 5.96.87-4.31 4.2 1.02 5.93L12 17.2l-5.33 2.8 1.02-5.93-4.31-4.2 5.96-.87Z"/>`,
  heart: `<path ${STROKE} d="M12 20.2s-7.6-4.6-9.6-9A5 5 0 0 1 12 6.9 5 5 0 0 1 21.6 11.2c-2 4.4-9.6 9-9.6 9Z"/>`,
  heartFilled: `<path fill="currentColor" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round" d="M12 20.2s-7.6-4.6-9.6-9A5 5 0 0 1 12 6.9 5 5 0 0 1 21.6 11.2c-2 4.4-9.6 9-9.6 9Z"/>`,
  package: `<g ${STROKE}><path d="M12 2.4 21 7 12 11.6 3 7Z"/><path d="M2.6 8.4 11.3 12.8v8.6L2.6 17Z"/><path d="M21.4 8.4 12.7 12.8v8.6L21.4 17Z"/></g>`,
  gift: `<g ${STROKE}><rect x="3.5" y="9.5" width="17" height="11" rx="1.4"/><path d="M3.5 13.5h17"/><path d="M12 9.5v11"/><path d="M12 9.5c-1.6 0-4.5-.4-4.5-2.9A2.1 2.1 0 0 1 9.6 4.5C11.7 4.5 12 8 12 9.5Z"/><path d="M12 9.5c1.6 0 4.5-.4 4.5-2.9a2.1 2.1 0 0 0-2.1-2.1C12.3 4.5 12 8 12 9.5Z"/></g>`,
  leaf: `<g ${STROKE}><path d="M5.5 18.5C3 12 6.7 5.3 15.5 3.6c2.2 8.3-1.6 14.6-10 14.9Z"/><path d="M5.7 18.3 15 5.4"/></g>`,
  flame: `<path ${STROKE} d="M12 21.3c4 0 6.6-2.7 6.6-6.3 0-3-1.9-4.7-2.9-6.6-.6 1.6-1.4 2.5-2.3 2.5-1.5 0-1.7-2.4-1.1-5.4-3.5 2.2-5.9 5.6-5.9 9.5 0 3.6 2.6 6.3 5.6 6.3Z"/>`,
  badgePlus: `<g ${STROKE}><circle cx="12" cy="12" r="8.6"/><path d="M12 8.2v7.6M8.2 12h7.6"/></g>`,
  sparkles: `<g ${STROKE}><path d="M11.2 3.4 12.6 8l4.6 1.4-4.6 1.4-1.4 4.6-1.4-4.6L5.2 9.4l4.6-1.4Z"/><path d="M18 15.4l.7 2 2 .7-2 .7-.7 2-.7-2-2-.7 2-.7Z"/></g>`,
  layoutGrid: `<g ${STROKE}><rect x="3.5" y="3.5" width="7.2" height="7.2" rx="1.4"/><rect x="13.3" y="3.5" width="7.2" height="7.2" rx="1.4"/><rect x="3.5" y="13.3" width="7.2" height="7.2" rx="1.4"/><rect x="13.3" y="13.3" width="7.2" height="7.2" rx="1.4"/></g>`,
  image: `<g ${STROKE}><rect x="3.5" y="4.5" width="17" height="15" rx="2"/><circle cx="9" cy="10" r="1.7"/><path d="m5 17.5 4.6-4.6a1.8 1.8 0 0 1 2.5 0l1.4 1.4"/><path d="m13 17.5 3.4-3.4a1.8 1.8 0 0 1 2.5 0l1.6 1.6"/></g>`,
  tag: `<g ${STROKE}><path d="M12.6 3.5h5.9a1 1 0 0 1 1 1v5.9a2 2 0 0 1-.6 1.4l-8.6 8.6a2 2 0 0 1-2.8 0l-5.9-5.9a2 2 0 0 1 0-2.8l8.6-8.6a2 2 0 0 1 1.4-.6Z"/><circle cx="15.5" cy="7.5" r="1.4" fill="currentColor" stroke="none"/></g>`,
  mapPin: `<g ${STROKE}><path d="M12 21.2s6.8-6 6.8-11.2a6.8 6.8 0 1 0-13.6 0c0 5.2 6.8 11.2 6.8 11.2Z"/><circle cx="12" cy="10" r="2.4"/></g>`,
  x: `<path ${STROKE} stroke-width="2.1" d="M6.5 6.5l11 11M17.5 6.5l-11 11"/>`
};

/**
 * @param {keyof PATHS} name
 * @param {{size?: number, className?: string}} [options]
 */
export function icon(name, { size = 24, className = '' } = {}) {
  const body = PATHS[name];
  if (!body) return '';
  const classes = ['sf-icon', className].filter(Boolean).join(' ');
  return `<svg class="${classes}" viewBox="0 0 24 24" width="${size}" height="${size}" aria-hidden="true" focusable="false">${body}</svg>`;
}
