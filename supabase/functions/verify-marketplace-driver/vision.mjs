// Google Cloud Vision (DOCUMENT_TEXT_DETECTION) with a restricted API key
// (Cloud Vision API only), server-side. Secret: GOOGLE_VISION_API_KEY.
// The key goes in the x-goog-api-key header (not the URL, so it cannot end
// up in URL/proxy logs). It is never logged, returned or put in an error:
// errors carry only a fixed code. Pure (fetch only) for Node tests.

/** Safe error: the message is a fixed code, never secret material. */
export class ScreeningUnavailable extends Error {
  constructor(code) {
    super(code);
    this.name = 'ScreeningUnavailable';
    this.code = code;
  }
}

export const VISION_URL = 'https://vision.googleapis.com/v1/images:annotate';

export function requireApiKey(key) {
  if (typeof key !== 'string' || key.trim().length < 20 || /\s/.test(key.trim())) {
    throw new ScreeningUnavailable('credential_missing');
  }
  return key.trim();
}

export async function annotateImage(imageBase64, apiKey, { fetchImpl = fetch } = {}) {
  const key = requireApiKey(apiKey);
  let res, body;
  try {
    res = await fetchImpl(VISION_URL, {
      method: 'POST',
      headers: { 'content-type': 'application/json', 'x-goog-api-key': key },
      body: JSON.stringify({
        requests: [{ image: { content: imageBase64 }, features: [{ type: 'DOCUMENT_TEXT_DETECTION' }], imageContext: { languageHints: ['ms', 'en'] } }],
      }),
    });
    body = await res.json();
  } catch {
    throw new ScreeningUnavailable('vision_failed');
  }
  if (!res.ok || !Array.isArray(body?.responses) || body.responses[0]?.error) {
    throw new ScreeningUnavailable('vision_failed');
  }
  return body;
}

/**
 * Screening orchestration: OCR the licence front + back and/or the vehicle
 * photo. Any failure throws ScreeningUnavailable so the caller records
 * NOTHING (the driver stays pending; never verified by a failure).
 */
export async function screen({ licence, vehicle, download, ocr, extractLicenceFrontBack, extractPlates }) {
  let lic = null, plate = null;
  if (licence) {
    const [f, b] = [await ocr(await download(licence.front)), await ocr(await download(licence.back))];
    lic = extractLicenceFrontBack(f, b);
  }
  if (vehicle) plate = extractPlates(await ocr(await download(vehicle)));
  return { licence: lic, plate };
}
