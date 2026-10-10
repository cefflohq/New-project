// Google Apps Script templates for Integrations Phase 2 (Sheets / Drive).
// Served by GET /integrations-inbound/script/{sheets|drive}; the Vendor apps
// put the connection key and endpoint in place of the two placeholders before
// showing the script to the Owner/Operator. The script runs in the owner's own
// Google account, so Cefflo never holds a Google token.

const CORE = `
// Cefflo order import. Row 1 = headers. Recognised columns (any case, EN/BM):
//   Order ID | Name/Nama | Phone/Telefon | Address/Alamat | Item/Produk | Qty/Kuantiti | Price/Harga | Notes/Nota
// Rows with the same Order ID become one order with several items. Without an
// Order ID column every row is one order. "Item" may also hold "Nasi lemak x2, Kek x1".
var CEFFLO_KEY = '__CEFFLO_KEY__';
var CEFFLO_URL = '__CEFFLO_URL__';
var CEFFLO_COLS = {
  id: ['order id', 'order', 'order no', 'no order', 'id', 'external_id'],
  name: ['name', 'customer', 'customer name', 'nama', 'nama pelanggan', 'pelanggan'],
  phone: ['phone', 'phone number', 'tel', 'telefon', 'no telefon', 'no tel', 'hp', 'no hp'],
  address: ['address', 'delivery address', 'alamat', 'alamat penghantaran'],
  item: ['item', 'items', 'product', 'produk', 'barang'],
  qty: ['qty', 'quantity', 'kuantiti', 'kuantity', 'unit'],
  price: ['price', 'unit price', 'harga'],
  notes: ['notes', 'note', 'nota', 'catatan', 'remarks']
};

function cefflo_cols_(header) {
  var map = {};
  var h = header.map(function (x) { return String(x).trim().toLowerCase(); });
  Object.keys(CEFFLO_COLS).forEach(function (k) {
    for (var i = 0; i < h.length; i++) if (CEFFLO_COLS[k].indexOf(h[i]) >= 0) { map[k] = i; break; }
  });
  map.status = h.indexOf('cefflo');
  return map;
}

// Sheets stores 0123456789 as the number 123456789; put the 0 back.
function cefflo_phone_(v) {
  if (typeof v !== 'number') return String(v || '').trim();
  var d = String(Math.round(v));
  return d.indexOf('60') === 0 ? '+' + d : '0' + d;
}

function cefflo_items_(text, qty, price) {
  var name = String(text || '').trim();
  if (qty !== '' && qty != null) return [{ name: name, quantity: Number(qty) || 1, price: Number(price) || 0 }];
  return name.split(/[,\\n]+/).map(function (part) {
    var s = part.trim(), m;
    if (!s) return null;
    if ((m = s.match(/^(.*?)\\s*[x×*]\\s*(\\d+)$/i))) return { name: m[1].trim(), quantity: Number(m[2]), price: 0 };
    if ((m = s.match(/^(\\d+)\\s*[x×*]?\\s+(.*)$/i))) return { name: m[2].trim(), quantity: Number(m[1]), price: 0 };
    return { name: s, quantity: 1, price: Number(price) || 0 };
  }).filter(Boolean);
}

// rows: 2-D values incl. header. idPrefix makes row-based ids unique per source.
// mark(rowIndex, text) writes the result back when the source is writable.
function cefflo_send_rows_(rows, idPrefix, mark) {
  if (!rows.length) return { sent: 0, failed: 0 };
  var c = cefflo_cols_(rows[0]);
  if (c.name == null || c.phone == null || c.address == null || c.item == null) throw new Error('Cefflo: need columns Name, Phone, Address and Item in row 1.');
  var orders = {}, order = [];
  for (var r = 1; r < rows.length; r++) {
    var row = rows[r];
    if (c.status >= 0 && String(row[c.status]).indexOf('Sent') === 0) continue;
    if (!String(row[c.name] || '').trim() && !String(row[c.item] || '').trim()) continue;
    var id = c.id != null && String(row[c.id]).trim() ? String(row[c.id]).trim() : idPrefix + ':' + (r + 1);
    if (!orders[id]) {
      orders[id] = { rows: [], body: { external_id: id, customer_name: String(row[c.name] || '').trim(),
        customer_phone: cefflo_phone_(row[c.phone]), delivery_address: String(row[c.address] || '').trim(),
        notes: c.notes != null ? String(row[c.notes] || '').trim() : '', items: [] } };
      order.push(id);
    }
    orders[id].rows.push(r);
    orders[id].body.items = orders[id].body.items.concat(cefflo_items_(row[c.item], c.qty != null ? row[c.qty] : '', c.price != null ? row[c.price] : 0));
  }
  var sent = 0, failed = 0;
  order.forEach(function (id) {
    var o = orders[id];
    var res = UrlFetchApp.fetch(CEFFLO_URL, { method: 'post', contentType: 'application/json', muteHttpExceptions: true,
      headers: { Authorization: 'Bearer ' + CEFFLO_KEY }, payload: JSON.stringify(o.body) });
    var code = res.getResponseCode(), j = {};
    try { j = JSON.parse(res.getContentText()); } catch (e) {}
    var text = code === 201 ? 'Sent ' + (j.order_reference || '') : code === 200 && j.duplicate ? 'Sent (already in Cefflo)' : 'Error: ' + (j.error || code);
    if (text.indexOf('Sent') === 0) sent++; else failed++;
    o.rows.forEach(function (r) { mark(r, text); });
    Utilities.sleep(1100); // stay under 60 orders/minute per key
  });
  return { sent: sent, failed: failed };
}
`;

const SHEETS = `${CORE}
// ---- Google Sheets: new rows on the FIRST tab are sent every 5 minutes.
// Setup: Extensions > Apps Script, paste this file, Save, choose cefflo_setup, Run, Allow.
function cefflo_setup() {
  ScriptApp.getProjectTriggers().forEach(function (t) { if (t.getHandlerFunction() === 'cefflo_send') ScriptApp.deleteTrigger(t); });
  ScriptApp.newTrigger('cefflo_send').timeBased().everyMinutes(5).create();
  cefflo_send();
}

function cefflo_send() {
  var ss = SpreadsheetApp.getActiveSpreadsheet(), sh = ss.getSheets()[0];
  var lock = LockService.getScriptLock();
  if (!lock.tryLock(1000)) return;
  try {
    var rows = sh.getDataRange().getValues();
    if (!rows.length) return;
    var statusCol = rows[0].map(function (x) { return String(x).trim().toLowerCase(); }).indexOf('cefflo');
    if (statusCol < 0) { statusCol = rows[0].length; sh.getRange(1, statusCol + 1).setValue('Cefflo'); rows[0].push('Cefflo'); rows.forEach(function (r, i) { if (i) r.push(''); }); }
    cefflo_send_rows_(rows, ss.getId() + ':' + sh.getSheetId(), function (r, text) { sh.getRange(r + 1, statusCol + 1).setValue(text); });
  } finally { lock.releaseLock(); }
}
`;

const DRIVE = `${CORE}
// ---- Google Drive: CSV, Excel (.xlsx) or Google Sheets files dropped in ONE
// folder are imported every 10 minutes, then moved to "Cefflo imported".
// Setup: script.google.com > New project, paste this file, put the folder link
// below, Save, choose cefflo_setup, Run, Allow.
var CEFFLO_FOLDER = 'PASTE_FOLDER_LINK_OR_ID';

function cefflo_setup() {
  ScriptApp.getProjectTriggers().forEach(function (t) { if (t.getHandlerFunction() === 'cefflo_send') ScriptApp.deleteTrigger(t); });
  ScriptApp.newTrigger('cefflo_send').timeBased().everyMinutes(10).create();
  cefflo_send();
}

function cefflo_folder_() {
  var m = String(CEFFLO_FOLDER).match(/[-\\w]{25,}/);
  if (!m) throw new Error('Cefflo: put the Drive folder link in CEFFLO_FOLDER.');
  return DriveApp.getFolderById(m[0]);
}

function cefflo_rows_(file) {
  var type = file.getMimeType();
  if (type === MimeType.CSV || /\\.csv$/i.test(file.getName())) return Utilities.parseCsv(file.getBlob().getDataAsString());
  if (type === MimeType.GOOGLE_SHEETS) return SpreadsheetApp.openById(file.getId()).getSheets()[0].getDataRange().getValues();
  if (/\\.xlsx?$/i.test(file.getName())) {
    // Convert a copy to Google Sheets (Drive API v3 files.copy), read it, delete the copy.
    var res = UrlFetchApp.fetch('https://www.googleapis.com/drive/v3/files/' + file.getId() + '/copy', { method: 'post', contentType: 'application/json',
      headers: { Authorization: 'Bearer ' + ScriptApp.getOAuthToken() }, payload: JSON.stringify({ mimeType: MimeType.GOOGLE_SHEETS, name: 'cefflo-tmp' }) });
    var id = JSON.parse(res.getContentText()).id;
    try { return SpreadsheetApp.openById(id).getSheets()[0].getDataRange().getValues(); }
    finally { DriveApp.getFileById(id).setTrashed(true); }
  }
  return null;
}

function cefflo_send() {
  var lock = LockService.getScriptLock();
  if (!lock.tryLock(1000)) return;
  try {
    var folder = cefflo_folder_(), done = folder.getFoldersByName('Cefflo imported');
    done = done.hasNext() ? done.next() : folder.createFolder('Cefflo imported');
    var files = folder.getFiles();
    while (files.hasNext()) {
      var f = files.next(), rows = cefflo_rows_(f);
      if (!rows) continue;
      var errors = [];
      var r = cefflo_send_rows_(rows, f.getId(), function (row, text) { if (text.indexOf('Error') === 0) errors.push('Row ' + (row + 1) + ': ' + text); });
      if (errors.length) f.setDescription('Cefflo: ' + r.sent + ' sent, ' + r.failed + ' failed\\n' + errors.join('\\n'));
      f.moveTo(done);
    }
  } finally { lock.releaseLock(); }
}
`;

export const SCRIPTS: Record<string, string> = { sheets: SHEETS.trimStart(), drive: DRIVE.trimStart() };
