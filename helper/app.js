(function () {
  // Cefflo Helper PWA (D-73). Prepare -> Pack -> Ready for one business,
  // without a Vendor account. The access secret arrives once in the link
  // fragment (#<64 hex>), is kept on this device only, and is sent solely
  // to helper_tasks / helper_advance_preparation. The server returns only
  // what preparation needs; nothing else exists on this surface.
  const api = window.CEFFLO;
  const $ = id => document.getElementById(id);
  const KEY = 'cefflo_helper_access';
  const STAGES = [
    ['not_started', 'To prepare', 'Start preparing', 'preparing'],
    ['preparing', 'Preparing', 'Mark packed', 'packed'],
    ['packed', 'Packed', 'Mark ready', 'ready'],
    ['ready', 'Ready', null, null],
  ];
  let tasks = [];
  let tab = 'not_started';
  let busy = new Set();
  let errors = {};

  const store = {
    get() { try { return localStorage.getItem(KEY); } catch (_) { return null; } },
    set(v) { try { localStorage.setItem(KEY, v); } catch (_) {} },
    clear() { try { localStorage.removeItem(KEY); } catch (_) {} },
  };
  // Take the secret out of the address bar as soon as it is read.
  const fromLink = location.hash.slice(1);
  if (/^[0-9a-f]{64}$/i.test(fromLink)) {
    store.set(fromLink.toLowerCase());
  }
  if (location.hash) history.replaceState(null, '', location.pathname + location.search);
  const token = store.get();

  function show(id) {
    ['stLoading', 'stTasks', 'stNoAccess', 'stError'].forEach(s => { $(s).hidden = s !== id; });
  }
  function header(business, helper) {
    const bar = $('barName');
    if (business) { bar.textContent = business; }
    $('barSub').textContent = helper ? `Helper · ${helper}` : '';
  }
  function noAccess(kind) {
    store.clear();
    header('', '');
    $('noAccessTitle').textContent = kind === 'missing' ? 'No Helper access' : 'Access removed';
    $('noAccessBody').textContent = kind === 'missing'
      ? 'Open the Helper workspace link the business owner shared with you.'
      : 'This Helper workspace link no longer works. Ask the business owner to share a new link.';
    show('stNoAccess');
  }
  const denied = error => /invalid access/.test(String(error?.message || ''));

  function time(iso) {
    try { return new Date(iso).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }); } catch (_) { return ''; }
  }
  function itemRows(items) {
    return (Array.isArray(items) ? items : []).map(it => {
      if (typeof it === 'string') return [null, it];
      const qty = it.quantity ?? it.qty ?? null;
      return [qty, it.name || it.title || ''];
    }).filter(([, name]) => name);
  }

  function render() {
    const counts = Object.fromEntries(STAGES.map(([k]) => [k, tasks.filter(t => t.preparation_status === k).length]));
    const tabs = $('tabs');
    tabs.textContent = '';
    for (const [key, label] of STAGES) {
      const b = document.createElement('button');
      b.className = 'tab'; b.type = 'button'; b.setAttribute('role', 'tab');
      b.setAttribute('aria-selected', String(tab === key));
      b.innerHTML = '<b></b><span></span>';
      b.querySelector('b').textContent = counts[key];
      b.querySelector('span').textContent = label;
      b.addEventListener('click', () => { tab = key; render(); });
      tabs.appendChild(b);
    }
    const list = $('taskList');
    list.textContent = '';
    const stage = STAGES.find(s => s[0] === tab);
    const rows = tasks.filter(t => t.preparation_status === tab);
    $('stEmpty').hidden = rows.length > 0;
    $('emptyText').textContent = tasks.length ? `No orders in ${stage[1]}.` : 'New orders will appear here.';
    for (const t of rows) {
      const li = document.createElement('li');
      li.className = 'task';
      li.innerHTML = '<div class="task-head"><span class="task-no"></span><span class="task-time"></span></div><div class="task-name"></div><ul class="items"></ul>';
      li.querySelector('.task-no').textContent = t.order_number || 'Order';
      li.querySelector('.task-time').textContent = time(t.created_at);
      li.querySelector('.task-name').textContent = t.customer_name || '';
      const ul = li.querySelector('.items');
      for (const [qty, name] of itemRows(t.items)) {
        const row = document.createElement('li');
        row.innerHTML = '<span class="qty"></span><span></span>';
        row.firstChild.textContent = qty != null ? `${qty}×` : '•';
        row.lastChild.textContent = name;
        ul.appendChild(row);
      }
      if (t.notes) {
        const n = document.createElement('div'); n.className = 'note'; n.textContent = t.notes; li.appendChild(n);
      }
      if (errors[t.order_id]) {
        const e = document.createElement('div'); e.className = 'task-err'; e.textContent = errors[t.order_id]; li.appendChild(e);
      }
      if (stage[2]) {
        const btn = document.createElement('button');
        btn.className = 'next'; btn.type = 'button';
        btn.disabled = busy.has(t.order_id);
        btn.textContent = busy.has(t.order_id) ? 'Saving…' : stage[2];
        btn.addEventListener('click', () => advance(t, stage[3]));
        li.appendChild(btn);
      } else {
        const d = document.createElement('div'); d.className = 'done';
        d.innerHTML = '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M6 12.5l4 4 8-9"/></svg><span>Ready for pickup</span>';
        li.appendChild(d);
      }
      list.appendChild(li);
    }
  }

  function toast(text, isError) {
    const el = $('toast');
    el.textContent = text; el.className = isError ? 'toast err' : 'toast'; el.hidden = false;
    clearTimeout(toast.t); toast.t = setTimeout(() => { el.hidden = true; }, 2500);
  }

  async function load(quiet) {
    if (!token) return noAccess('missing');
    if (!quiet) show('stLoading');
    try {
      const data = await api.rpc('helper_tasks', { p_token: token }, { token: null });
      header(data.business_name, data.helper_name);
      tasks = data.tasks || [];
      show('stTasks');
      render();
    } catch (error) {
      if (denied(error)) return noAccess('removed');
      if (!quiet) show('stError');
    }
  }

  async function advance(task, next) {
    busy.add(task.order_id); delete errors[task.order_id]; render();
    try {
      const res = await api.rpc('helper_advance_preparation', { p_token: token, p_order_id: task.order_id, p_next: next }, { token: null });
      task.preparation_status = res.preparation_status;
      toast(`${task.order_number || 'Order'} moved to ${STAGES.find(s => s[0] === res.preparation_status)[1]}.`);
    } catch (error) {
      if (denied(error)) return noAccess('removed');
      const raw = String(error?.message || '');
      errors[task.order_id] = /task not available/.test(raw)
        ? 'This order is no longer being prepared.'
        : /invalid preparation transition/.test(raw) ? 'This order was already updated. Refreshing…' : 'Could not save. Try again.';
      if (!/Try again/.test(errors[task.order_id])) load(true);
    } finally {
      busy.delete(task.order_id); render();
    }
  }

  $('refreshBtn').addEventListener('click', () => load(true).then(() => toast('Updated.')));
  $('retryBtn').addEventListener('click', () => load(false));
  // Gentle refresh while the page is visible (no background polling).
  setInterval(() => { if (document.visibilityState === 'visible' && !$('stTasks').hidden) load(true); }, 60000);
  document.addEventListener('visibilitychange', () => { if (document.visibilityState === 'visible' && !$('stTasks').hidden) load(true); });
  load(false);
})();
