// CEFFLO Customer Tracking PWA — Proof of Delivery adapter.
//
//   POD UI  <-  POD adapter/reference  <-  mock asset now
//                                          (protected signed access later)
//
// The UI only ever holds an opaque POD *reference*; resolving it to a URL is
// the adapter's job. That keeps private storage paths out of the view layer and
// leaves room for signed/expiring URLs when the Core Backend owns POD.

import { POD_ASSETS } from './fixtures.js';

export function createPodAdapter({ assets = POD_ASSETS } = {}) {
  return {
    /**
     * @param {{reference?: string, url?: string}|null} pod customer-safe POD descriptor
     * @returns {Promise<string|null>} displayable image URL, or null when unavailable
     */
    async resolve(pod) {
      if (!pod) return null;
      // A backend-supplied (already signed) URL wins over the prototype asset.
      if (pod.url) return pod.url;
      return assets[pod.reference] ?? null;
    }
  };
}
