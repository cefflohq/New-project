/* CEFFLO push client — "Alerts when Cefflo is closed" on this device.
   window.cefPush.{supported, permission, isOn, enable, disable}. Used by
   Vendor Web and (through JS interop) the Flutter web apps.
   docs/cefflo/security/PUSH_NOTIFICATIONS.md */
(function () {
  'use strict';
  if (window.cefPush) return;
  var me = document.currentScript;
  var dir = me ? me.src.replace(/[^/]*(\?.*)?$/, '') : '';
  var SW = dir + 'push-sw.js';

  function supported() {
    return !!(window.isSecureContext && 'serviceWorker' in navigator && 'PushManager' in window && 'Notification' in window);
  }
  function permission() { return supported() ? Notification.permission : 'unsupported'; }
  function b64ToBytes(s) {
    var b = atob(s.replace(/-/g, '+').replace(/_/g, '/') + '==='.slice((s.length + 3) % 4));
    var out = new Uint8Array(b.length);
    for (var i = 0; i < b.length; i++) out[i] = b.charCodeAt(i);
    return out;
  }
  function registration() {
    return navigator.serviceWorker.getRegistration(dir).then(function (r) {
      return r || navigator.serviceWorker.register(SW, { scope: dir });
    });
  }
  function rpc(o, name, args) {
    return fetch(o.supabaseUrl.replace(/\/$/, '') + '/rest/v1/rpc/' + name, {
      method: 'POST',
      headers: { apikey: o.anonKey, authorization: 'Bearer ' + o.accessToken, 'content-type': 'application/json' },
      body: JSON.stringify(args),
    }).then(function (r) {
      if (!r.ok) return r.text().then(function (t) { throw new Error(t || ('HTTP ' + r.status)); });
    });
  }

  // true when this device has a live subscription.
  function isOn() {
    if (!supported() || Notification.permission !== 'granted') return Promise.resolve(false);
    return navigator.serviceWorker.getRegistration(dir).then(function (r) {
      return r ? r.pushManager.getSubscription().then(function (s) { return !!s; }) : false;
    });
  }

  // o: { supabaseUrl, anonKey, accessToken, app: 'vendor'|'rider', baseUrl? }
  // Resolves 'on' | 'denied' | 'unsupported'. Must start from a user gesture.
  function enable(o) {
    if (!supported()) return Promise.resolve('unsupported');
    return Notification.requestPermission().then(function (p) {
      if (p !== 'granted') return 'denied';
      return fetch(o.supabaseUrl.replace(/\/$/, '') + '/functions/v1/push/vapid')
        .then(function (r) { return r.json(); })
        .then(function (v) {
          if (!v.key) throw new Error('Push is not configured.');
          return registration().then(function (reg) {
            return navigator.serviceWorker.ready.then(function () { return reg; });
          }).then(function (reg) {
            return reg.pushManager.getSubscription().then(function (s) {
              return s || reg.pushManager.subscribe({ userVisibleOnly: true, applicationServerKey: b64ToBytes(v.key) });
            });
          });
        })
        .then(function (sub) {
          var j = sub.toJSON();
          return rpc(o, 'push_register', {
            p_app: o.app, p_endpoint: j.endpoint, p_p256dh: j.keys.p256dh, p_auth: j.keys.auth,
            p_base_url: o.baseUrl || (location.origin + location.pathname), p_user_agent: navigator.userAgent,
          });
        })
        .then(function () { return 'on'; });
    });
  }

  // Removes this device (server row first, then the browser subscription).
  function disable(o) {
    if (!supported()) return Promise.resolve();
    return navigator.serviceWorker.getRegistration(dir).then(function (r) {
      return r && r.pushManager.getSubscription();
    }).then(function (s) {
      if (!s) return;
      var done = function () { return s.unsubscribe(); };
      return (o && o.accessToken ? rpc(o, 'push_unregister', { p_endpoint: s.endpoint }) : Promise.resolve()).then(done, done);
    });
  }

  window.cefPush = { supported: supported, permission: permission, isOn: isOn, enable: enable, disable: disable };
})();
