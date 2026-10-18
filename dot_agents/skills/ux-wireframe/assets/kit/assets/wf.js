/* Lo-fi wireframe kit: shared layout, review states and overlays. Configure everything in assets/site.js. */
(() => {
  const S = window.SITE || {};
  const $ = (sel, root = document) => root.querySelector(sel);
  const $$ = (sel, root = document) => [...root.querySelectorAll(sel)];
  const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const money = (n) => (S.currency || '$') + Number(n).toLocaleString(S.locale || 'en-NZ', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  const param = (k) => new URLSearchParams(location.search).get(k);
  const ns = (S.storageKey || 'wf') + '-';
  const store = {
    get: (k, d) => { try { const v = localStorage.getItem(ns + k); return v === null ? d : JSON.parse(v); } catch { return d; } },
    set: (k, v) => localStorage.setItem(ns + k, JSON.stringify(v)),
  };

  /* ---------- Review states (e.g. guest / signed in) ---------- */
  const states = S.states && S.states.length ? S.states : [{ key: 'default', label: 'Default' }];
  const state = () => { const s = store.get('state', states[0].key); return states.some((x) => x.key === s) ? s : states[0].key; };
  function applyState() {
    const s = state();
    document.body.dataset.state = s;
    $$('[data-only]').forEach((el) => { el.hidden = !el.dataset.only.split(/\s+/).includes(s); });
  }
  function setState(s) { store.set('state', s); renderHeader(); applyState(); document.dispatchEvent(new CustomEvent('wf:state', { detail: s })); }
  const notesOn = () => store.get('notes', true);
  const popupOn = () => store.get('popup', !!S.popup);

  /* ---------- Toast ---------- */
  let toastTimer;
  function toast(html) {
    let t = $('#wf-toast');
    if (!t) { t = document.createElement('div'); t.id = 'wf-toast'; t.className = 'toast'; t.setAttribute('role', 'status'); document.body.append(t); }
    t.innerHTML = html; t.classList.add('on');
    clearTimeout(toastTimer); toastTimer = setTimeout(() => t.classList.remove('on'), 3600);
  }

  /* ---------- Header ---------- */
  const only = (o) => (o && o.only ? ` data-only="${esc(o.only)}"` : '');
  const link = (l) => `<a href="${esc(l.href || '#')}"${only(l)}${l.open ? ` data-open="${esc(l.open)}"` : ''}>${l.strong ? `<strong>${esc(l.label)}</strong>` : esc(l.label)}</a>`;
  function mega(item) {
    const cols = (item.mega || []).map((c) => `<div${c.span ? ` style="grid-column: span ${c.span}"` : ''}><h4>${esc(c.heading)}</h4><ul>${(c.links || []).map((l) => `<li><a href="${esc(l.href)}"${l.open ? ` data-open="${esc(l.open)}"` : ''}>${l.note ? `<strong>${esc(l.label)}</strong><br><span class="small muted">${esc(l.note)}</span>` : esc(l.label)}</a></li>`).join('')}</ul>${c.html || ''}</div>`).join('');
    const promo = item.promo ? `<div class="promo"><a class="tile" href="${esc(item.promo.href)}"><div class="img"><span>${esc(item.promo.image || 'Promo image')}</span></div><strong>${esc(item.promo.label)}</strong>${item.promo.note ? `<span class="small muted">${esc(item.promo.note)}</span>` : ''}</a></div>` : '';
    return `<div class="mega"><div class="wrap"><div class="cols">${cols}${promo}</div>${item.note ? `<div class="note">${item.note}</div>` : ''}</div></div>`;
  }
  function renderHeader() {
    const host = $('#wf-header');
    if (!host) return;
    const page = document.body.dataset.page || '';
    const u = S.utility || {};
    const nav = (S.nav || []).map((n) => n.mega
      ? `<div class="ni"><button aria-expanded="false">${esc(n.label)}</button>${mega(n)}</div>`
      : `<div class="ni"><a href="${esc(n.href)}"${n.page && n.page === page ? ' aria-current="page"' : ''}>${esc(n.label)}</a></div>`).join('');
    const icons = (S.icons || []).map((i) => `<a class="icon-btn" href="${esc(i.href)}"${only(i)} aria-label="${esc(i.label)}"><span class="ico" aria-hidden="true">${esc(i.ico || '○')}</span>${esc(i.label)}${i.count ? `<span class="count" data-count="${esc(i.count)}" hidden>0</span>` : ''}</a>`).join('');
    const search = S.search ? `<form class="header-search" action="${esc(S.search.action)}" role="search"><label class="sr" for="wf-q">Search</label><input id="wf-q" name="q" type="search" placeholder="${esc(S.search.placeholder || 'Search')}"></form>` : '';
    const strip = S.strip ? `<div class="trade-strip"${only(S.strip)}><div class="wrap">${S.strip.title ? `<strong>${esc(S.strip.title)}</strong><span class="sep">|</span>` : ''}${(S.strip.links || []).map(link).join('')}</div></div>` : '';
    host.innerHTML = `
      <a class="sr" href="#main">Skip to content</a>
      ${u.left || u.right ? `<div class="utility"><div class="wrap"><div class="row">${(u.left || []).map((x) => x.html || link(x)).join('')}</div><div class="row">${(u.right || []).map((x) => x.html ? `<span${only(x)}>${x.html}</span>` : link(x)).join('')}</div></div></div>` : ''}
      ${strip}
      <header class="site-header"><div class="wrap">
        <button class="icon-btn burger" aria-label="Menu" aria-expanded="false" data-burger><span class="ico" aria-hidden="true">☰</span>Menu</button>
        <a class="logo" href="index.html" aria-label="${esc(S.name || 'Home')} home">${esc(S.name || 'Logo')}</a>
        <nav class="mainnav" aria-label="Main">${nav}</nav>
        ${search}
        <div class="header-icons">${icons}</div>
      </div>
      ${S.search ? `<div class="wrap mobile-search"><form action="${esc(S.search.action)}" role="search"><input name="q" type="search" placeholder="${esc(S.search.placeholder || 'Search')}" aria-label="Search"></form></div>` : ''}
      </header>`;
    applyState();
    WF.refreshCounts();
  }
  function wireHeader() {
    document.addEventListener('click', (e) => {
      const btn = e.target.closest('.mainnav > .ni > button');
      $$('.mainnav > .ni.open').forEach((n) => { if (!btn || n !== btn.parentElement) { n.classList.remove('open'); n.firstElementChild.setAttribute('aria-expanded', 'false'); } });
      if (btn) { const open = btn.parentElement.classList.toggle('open'); btn.setAttribute('aria-expanded', String(open)); }
      const burger = e.target.closest('[data-burger]');
      if (burger) {
        const on = document.body.classList.toggle('menu-open');
        burger.setAttribute('aria-expanded', String(on));
        document.documentElement.style.setProperty('--hdr', $('.site-header').getBoundingClientRect().bottom + 'px');
      }
      const st = e.target.closest('[data-set-state]');
      if (st) { e.preventDefault(); setState(st.dataset.setState); }
    });
    document.addEventListener('keydown', (e) => {
      if (e.key !== 'Escape') return;
      $$('.mainnav > .ni.open').forEach((n) => n.classList.remove('open'));
      closeOverlays();
    });
  }

  /* ---------- Footer: full width, columns split by borders, a bottom line per column ---------- */
  function renderFooter() {
    const host = $('#wf-footer');
    if (!host) return;
    const f = S.footer || {};
    const cols = (f.columns || []).map((c) => `<div class="col"><h4>${esc(c.heading)}</h4><ul>${(c.links || []).map((l) => `<li>${link(l)}</li>`).join('')}</ul>${c.foot ? `<div class="foot">${c.foot}</div>` : ''}</div>`).join('');
    host.innerHTML = `<footer class="site-footer"><div class="cols" style="--cols: ${(f.columns || []).length || 1}">
      <div class="col"><a class="flogo" href="index.html">${esc(S.name || 'Logo')}</a>${f.blurb ? `<p class="small muted" style="margin-top:14px;max-width:30ch">${esc(f.blurb)}</p>` : ''}
        ${f.brandFoot ? `<div class="foot">${f.brandFoot}</div>` : ''}</div>
      ${cols}
    </div></footer>`;
  }

  /* ---------- Review bar ---------- */
  function renderReview() {
    const bar = document.createElement('div');
    bar.className = 'review';
    bar.setAttribute('aria-label', 'Wireframe review controls');
    bar.innerHTML = `<strong>Wireframe</strong>
      ${states.length > 1 ? `<span class="hide-sm">View as</span><div class="seg" role="group" aria-label="View as">${states.map((s) => `<button data-state-btn="${esc(s.key)}">${esc(s.label)}</button>`).join('')}</div>` : ''}
      <label><input type="checkbox" data-notes-toggle> Notes</label>
      ${S.popup ? '<label class="hide-sm"><input type="checkbox" data-popup-toggle> Pop-up</label>' : ''}
      <span class="grow"></span><a href="sitemap.html">Site map</a><a href="#" class="hide-sm" data-reset>Reset demo</a>`;
    document.body.append(bar);
    const sync = () => {
      $$('[data-state-btn]', bar).forEach((b) => b.setAttribute('aria-pressed', String(b.dataset.stateBtn === state())));
      $('[data-notes-toggle]', bar).checked = notesOn();
      const p = $('[data-popup-toggle]', bar); if (p) p.checked = popupOn();
    };
    bar.addEventListener('click', (e) => {
      const b = e.target.closest('[data-state-btn]');
      if (b) { setState(b.dataset.stateBtn); sync(); }
      if (e.target.closest('[data-reset]')) { e.preventDefault(); Object.keys(localStorage).filter((k) => k.startsWith(ns)).forEach((k) => localStorage.removeItem(k)); sessionStorage.clear(); location.reload(); }
    });
    bar.addEventListener('change', (e) => {
      if (e.target.matches('[data-notes-toggle]')) { store.set('notes', e.target.checked); document.body.classList.toggle('notes-on', e.target.checked); }
      if (e.target.matches('[data-popup-toggle]')) { store.set('popup', e.target.checked); if (e.target.checked) { sessionStorage.removeItem(ns + 'popup-seen'); open('popup'); } }
    });
    document.addEventListener('wf:state', sync);
    sync();
  }

  /* ---------- Overlays: drawers and modals ---------- */
  function scrim() {
    let s = $('#wf-scrim');
    if (!s) { s = document.createElement('div'); s.id = 'wf-scrim'; s.className = 'scrim'; s.addEventListener('click', () => closeOverlays()); document.body.append(s); }
    return s;
  }
  let lastFocus = null;
  function openOverlay(el) {
    lastFocus = document.activeElement;
    closeOverlays(true);
    scrim().classList.add('on');
    el.classList.add('on');
    document.body.style.overflow = 'hidden';
    setTimeout(() => { const f = el.querySelector('input, select, textarea, button:not(.close)'); (f || el.querySelector('.close'))?.focus(); }, 60);
  }
  function closeOverlays(keepFocus) {
    $$('.drawer.on, .modal.on').forEach((d) => d.classList.remove('on'));
    $('#wf-scrim')?.classList.remove('on');
    document.body.style.overflow = '';
    if (!keepFocus && lastFocus) lastFocus.focus?.();
  }
  /* overlay({ id, kind: 'drawer'|'modal'|'modal narrow', title }) returns { el, body, foot } and creates it once. */
  function overlay({ id, kind = 'drawer', title = '' }) {
    let el = document.getElementById(id);
    if (!el) {
      el = document.createElement(kind === 'drawer' ? 'aside' : 'div');
      el.id = id; el.className = kind; el.setAttribute('role', 'dialog'); el.setAttribute('aria-modal', 'true'); el.setAttribute('aria-labelledby', id + '-title');
      el.innerHTML = `<div class="drawer-head"><h2 id="${id}-title"></h2><button class="close" aria-label="Close" data-close>×</button></div><div class="drawer-body"></div><div class="drawer-foot" hidden></div>`;
      el.addEventListener('click', (e) => { if (e.target.closest('[data-close]')) closeOverlays(); });
      document.body.append(el);
    }
    if (title) $('h2', el).textContent = title;
    return { el, body: $('.drawer-body', el), foot: $('.drawer-foot', el) };
  }
  /* Register openers for data-open="name" triggers: WF.register('quote', (triggerDataset) => {...}). */
  const openers = {};
  const register = (name, fn) => { openers[name] = fn; };
  function open(name, data = {}) { if (openers[name]) openers[name](data); }

  /* ---------- Optional newsletter / promo pop-up from SITE.popup ---------- */
  if (S.popup) {
    register('popup', () => {
      const o = overlay({ id: 'wf-popup', kind: 'modal narrow', title: S.popup.title || 'Stay in touch' });
      o.body.innerHTML = S.popup.html || '';
      o.el.addEventListener('click', (e) => { if (e.target.closest('[data-close]')) sessionStorage.setItem(ns + 'popup-seen', '1'); });
      openOverlay(o.el);
    });
  }
  function schedulePopup() {
    if (!S.popup || !popupOn() || sessionStorage.getItem(ns + 'popup-seen')) return;
    const page = document.body.dataset.page || '';
    if ((S.popup.skipPages || []).some((p) => page.startsWith(p))) return;
    setTimeout(() => { if (!$('.drawer.on, .modal.on') && popupOn()) { sessionStorage.setItem(ns + 'popup-seen', '1'); open('popup'); } }, S.popup.delay || 8000);
  }

  /* ---------- Tabs ---------- */
  function initTabs(root = document) {
    $$('[data-tabs]', root).forEach((wrap) => {
      if (wrap.dataset.tabsReady) return; wrap.dataset.tabsReady = '1';
      const tabs = $$('[role=tab]', wrap);
      const select = (tab) => tabs.forEach((t) => { const on = t === tab; t.setAttribute('aria-selected', String(on)); t.tabIndex = on ? 0 : -1; document.getElementById(t.getAttribute('aria-controls')).hidden = !on; });
      tabs.forEach((t) => t.addEventListener('click', () => select(t)));
      wrap.addEventListener('keydown', (e) => {
        const i = tabs.indexOf(document.activeElement); if (i < 0) return;
        if (e.key === 'ArrowRight' || e.key === 'ArrowLeft') { const n = tabs[(i + (e.key === 'ArrowRight' ? 1 : tabs.length - 1)) % tabs.length]; n.focus(); select(n); }
      });
      select(tabs.find((t) => t.getAttribute('aria-selected') === 'true') || tabs[0]);
    });
  }

  /* ---------- Global triggers ---------- */
  document.addEventListener('click', (e) => {
    const o = e.target.closest('[data-open]');
    if (o && openers[o.dataset.open]) { e.preventDefault(); open(o.dataset.open, { ...o.dataset }); }
    if (e.target.closest('[data-close-filters]')) document.body.classList.remove('filters-open');
    if (e.target.closest('[data-open-filters]')) document.body.classList.add('filters-open');
  });

  /* ---------- Public API (page scripts and site.js extensions use this) ---------- */
  window.WF = {
    S, $, $$, esc, money, param, store, state, setState, applyState, toast,
    overlay, openOverlay, closeOverlays, register, open, initTabs,
    /* Header icons with count: 'cart' read counts from WF.counts[name]() if provided. */
    counts: {},
    refreshCounts() { $$('[data-count]').forEach((el) => { const fn = WF.counts[el.dataset.count]; const n = fn ? fn() : 0; el.textContent = n; el.hidden = !n; }); },
  };

  /* ---------- Boot ---------- */
  document.body.classList.toggle('notes-on', notesOn());
  renderHeader();
  renderFooter();
  renderReview();
  wireHeader();
  applyState();
  schedulePopup();
  queueMicrotask(() => { initTabs(); applyState(); });
})();
