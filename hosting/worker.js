export default {
  async fetch(request, env) {
    // Sites exposes the Flutter build packaged under dist/client here.
    const response = await env.ASSETS.fetch(request);
    if (response.status !== 404) return response;

    const url = new URL(request.url);
    if (request.method !== "GET" || url.pathname.includes(".")) {
      return response;
    }

    url.pathname = "/index.html";
    return env.ASSETS.fetch(new Request(url, request));
  },
};
