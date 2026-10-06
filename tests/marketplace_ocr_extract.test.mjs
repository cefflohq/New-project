// Unit tests: Marketplace Verification OCR extraction (no network).
import { extractLicence, extractLicenceFrontBack, extractPlates, normalizePlate, visionText } from '../supabase/functions/verify-marketplace-driver/extract.mjs';
const results = []; let fails = 0;
const ok = (n, c, x = '') => { results.push(`${c ? 'PASS' : 'FAIL'}  ${n}${x ? '  -> ' + JSON.stringify(x).slice(0, 200) : ''}`); if (!c) fails++; };
const vision = (text, conf = 0.97) => ({ responses: [{ fullTextAnnotation: { text, pages: [{ blocks: [{ confidence: conf }, { confidence: conf }] }] } }] });

const licText = `MALAYSIA\nLESEN MEMANDU / DRIVING LICENCE\nNAMA / NAME\nAHMAD FAIZAL BIN ISMAIL\nNO. PENGENALAN / IDENTITY NO.\n900101-14-5678\nKELAS / CLASS\nB2 D\nTEMPOH / VALIDITY\n12/03/2024 - 11/03/2029\nJALAN 3, TAMAN UDA`;
const L = extractLicence(visionText(vision(licText)));
ok('licence: IC normalised (dashes removed)', L.ic === '900101145678', L);
ok('licence: name from the NAMA / NAME label', L.name === 'AHMAD FAIZAL BIN ISMAIL', L.name);
ok('licence: classes B2 + D', L.classes.includes('B2') && L.classes.includes('D') && L.classes.length === 2, L.classes);
ok('licence: expiry = latest validity date', L.expiry === '2029-03-11', L.expiry);
ok('licence: confidence carried from Vision', L.confidence === 0.97);
const L2 = extractLicence(visionText(vision('NAME: SITI AMINAH\nIDENTITY NO 900101145678\nCLASS: DA\n01.01.2022 31.12.2026')));
ok('licence: inline labels, no dashes', L2.ic === '900101145678' && L2.name === 'SITI AMINAH' && L2.classes[0] === 'DA' && L2.expiry === '2026-12-31', L2);
ok('licence: empty Vision response -> text_found false (retake)', extractLicence(visionText({ responses: [{}] })).text_found === false);
const L3 = extractLicence(visionText(vision('blurry nothing here')));
ok('licence: unreadable text -> no IC (retake)', L3.text_found === true && L3.ic === null && L3.classes.length === 0 && L3.expiry === null, L3);

// FRONT + BACK combined: fields may come from either side
const front = visionText(vision('LESEN MEMANDU / DRIVING LICENCE\nNAMA / NAME\nSITI AMINAH BINTI ALI\nNO. PENGENALAN / IDENTITY NO.\n900101-14-5678', 0.96));
const back = visionText(vision('KELAS / CLASS\nB2 D\nTEMPOH / VALIDITY\n01/02/2023 - 31/01/2028', 0.9));
const FB = extractLicenceFrontBack(front, back);
ok('front+back: IC + name from front, class + expiry from back', FB.text_found && FB.ic === '900101145678' && FB.name === 'SITI AMINAH BINTI ALI' && FB.classes.join() === 'B2,D' && FB.expiry === '2028-01-31' && FB.sides === 2, FB);
ok('front+back: confidence = the weaker side', FB.confidence === 0.9, FB.confidence);
const noBack = extractLicenceFrontBack(front, visionText({ responses: [{}] }));
ok('front+back: back unreadable -> text_found false (retake), side named', noBack.text_found === false && noBack.unreadable.join() === 'back', noBack);
const noFront = extractLicenceFrontBack(visionText(vision('   ')), back);
ok('front+back: front unreadable -> retake', noFront.text_found === false && noFront.unreadable.join() === 'front', noFront);

for (const p of ['VAB 1234', 'VAB-1234', 'vab1234', ' V A B 1 2 3 4 ']) ok(`plate normalise "${p}" -> VAB1234`, normalizePlate(p) === 'VAB1234');
const P = extractPlates(visionText(vision('HONDA\nVAB 1234\nSERVICE 03-1234 5678', 0.95)));
ok('plate: candidate found from photo text', P.plates.some((x) => x.text === 'VAB1234' && x.confidence === 0.95), P);
ok('plate: phone numbers / words are not plates', !P.plates.some((x) => /^HONDA$|^SERVICE/.test(x.text)), P);
ok('plate: nothing readable -> no candidates', extractPlates(visionText(vision('###'))).plates.length === 0);

console.log(results.join('\n')); console.log(`\n${results.length - fails}/${results.length} passed`);
process.exit(fails ? 1 : 0);
