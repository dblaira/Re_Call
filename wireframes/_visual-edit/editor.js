/* Direct-manipulation editor. Click an element, then drag / resize / restyle it
   on the real rendered page. Everything snaps to a 4px grid. Save writes a clean
   copy of the file back to disk — none of this editor chrome is saved. */
(() => {
  const GRID = 4;
  const snap = (n) => Math.round(n / GRID) * GRID;
  const FILE = window.__VE_FILE || 'page.html';

  let editMode = true;
  let sel = null;            // selected element
  const undo = [];           // stack of revert fns

  // Persisted deltas (the page builds its tiles in JS, so we save by patching
  // the source: palette tokens + style rules keyed on the element's own class —
  // restyle the KIND of tile, and every tile of that kind updates).
  const tokenEdits = {};     // { '--name': '#hex' }
  const ruleEdits = {};      // { '.selector': { prop: val } }

  function selectorFor(node) {
    const own = [...node.classList].filter(c => !c.startsWith('__ve'));
    if (own.length) return '.' + own[own.length - 1];   // most-specific own class
    if (node.id) return '#' + node.id;
    return null;                                         // can't persist this one
  }
  function persistRule(node, prop, val) {
    const s = selectorFor(node);
    if (!s) { flash('No class on this element — change shows live but won\'t save', ''); return; }
    (ruleEdits[s] || (ruleEdits[s] = {}))[prop] = val;
  }

  /* ---------- chrome ---------- */
  document.body.classList.add('__ve-on');

  const bar = el('div', '__ve-bar', `
    <button class="__ve-save">Save</button>
    <button class="__ve-undo">Undo</button>
    <button class="__ve-tokens">Palette</button>
    <button class="__ve-toggle">Preview</button>
    <span class="__ve-spacer"></span>
    <span class="__ve-hint">Click an element → drag to move · corners to resize</span>`);
  document.body.appendChild(bar);

  const insp = el('div', '__ve-insp', '');
  document.body.appendChild(insp);

  const handles = el('div', '__ve-handles', '');
  for (const p of ['nw','n','ne','e','se','s','sw','w']) handles.appendChild(el('div', '__ve-h ' + p, ''));
  handles.style.display = 'none';
  document.body.appendChild(handles);

  /* ---------- helpers ---------- */
  function el(tag, cls, html) { const e = document.createElement(tag); e.className = cls; e.innerHTML = html; return e; }
  function isChrome(n) { return !n || (n.closest && n.closest('.__ve-bar,.__ve-insp,.__ve-handles')); }
  const hint = bar.querySelector('.__ve-hint');
  function flash(msg, cls) { hint.textContent = msg; hint.className = '__ve-hint ' + (cls||''); }

  function record(fn) { undo.push(fn); if (undo.length > 200) undo.shift(); }
  function setStyle(node, prop, val) {
    const old = node.style.getPropertyValue(prop);
    record(() => { old ? node.style.setProperty(prop, old) : node.style.removeProperty(prop); if (node === sel) refreshHandles(); });
    node.style.setProperty(prop, val);
    if (node === sel) refreshHandles();
  }

  /* ---------- hover + select ---------- */
  document.addEventListener('mouseover', (e) => {
    if (!editMode || isChrome(e.target)) return;
    if (e.target !== sel) e.target.classList.add('__ve-hover');
  }, true);
  document.addEventListener('mouseout', (e) => { e.target.classList && e.target.classList.remove('__ve-hover'); }, true);

  document.addEventListener('click', (e) => {
    if (!editMode || isChrome(e.target)) return;
    e.preventDefault(); e.stopPropagation();
    select(e.target);
  }, true);

  function select(node) {
    if (sel) sel.classList.remove('__ve-sel');
    sel = node; sel.classList.remove('__ve-hover'); sel.classList.add('__ve-sel');
    refreshHandles(); buildInspector();
  }

  /* ---------- inspector ---------- */
  const cs = (n, p) => getComputedStyle(n).getPropertyValue(p);
  const px = (v) => parseFloat(v) || 0;
  const toHex = (rgb) => {
    const m = rgb.match(/\d+/g); if (!m) return '#000000';
    return '#' + m.slice(0,3).map(x => (+x).toString(16).padStart(2,'0')).join('');
  };

  function buildInspector() {
    if (!sel) { insp.classList.remove('show'); return; }
    const tag = sel.tagName.toLowerCase() + (sel.id ? '#' + sel.id : '') +
                (sel.classList.length ? '.' + [...sel.classList].filter(c => !c.startsWith('__ve')).slice(0,2).join('.') : '');
    insp.innerHTML = `<h4>Selected <span class="__ve-tag">${tag}</span></h4>`;
    colorRow('Background', 'background-color');
    colorRow('Text', 'color');
    sep();
    stepRow('Font size', 'font-size', 1);
    stepRow('Padding', 'padding', GRID);
    stepRow('Radius', 'border-radius', GRID);
    stepRow('Width', 'width', GRID);
    stepRow('Height', 'height', GRID);
    sep();
    insp.appendChild(el('div', '__ve-row', `<label>Double-click element to edit its text</label>`));
    insp.classList.add('show');
  }
  function sep() { insp.appendChild(document.createElement('hr')); }
  function colorRow(label, prop) {
    const row = el('div', '__ve-row', `<label>${label}</label>`);
    const inp = document.createElement('input'); inp.type = 'color'; inp.value = toHex(cs(sel, prop));
    inp.addEventListener('input', () => { setStyle(sel, prop, inp.value); persistRule(sel, prop, inp.value); });
    row.appendChild(inp); insp.appendChild(row);
  }
  function stepRow(label, prop, step) {
    const row = el('div', '__ve-row', `<label>${label}</label>`);
    const box = el('div', '__ve-step', `<button data-d="-1">–</button><span></span><button data-d="1">+</button>`);
    const val = box.querySelector('span');
    const show = () => { val.textContent = Math.round(px(cs(sel, prop))) + ''; };
    show();
    box.querySelectorAll('button').forEach(b => b.addEventListener('click', () => {
      const cur = px(cs(sel, prop)); const next = Math.max(0, snap(cur + (+b.dataset.d) * step) || cur + (+b.dataset.d) * step);
      setStyle(sel, prop, next + 'px'); persistRule(sel, prop, next + 'px'); show();
    }));
    row.appendChild(box); insp.appendChild(row);
  }

  /* ---------- edit text ---------- */
  document.addEventListener('dblclick', (e) => {
    if (!editMode || isChrome(e.target)) return;
    e.preventDefault();
    const n = e.target; const before = n.innerHTML;
    n.setAttribute('contenteditable', 'true'); n.focus();
    const done = () => {
      n.removeAttribute('contenteditable'); n.removeEventListener('blur', done);
      if (n.innerHTML !== before) record(() => { n.innerHTML = before; });
    };
    n.addEventListener('blur', done);
  }, true);

  /* ---------- resize handles ---------- */
  function refreshHandles() {
    if (!sel) { handles.style.display = 'none'; return; }
    const r = sel.getBoundingClientRect();
    handles.style.display = 'block';
    handles.style.left = (r.left + scrollX) + 'px'; handles.style.top = (r.top + scrollY) + 'px';
    handles.style.width = r.width + 'px'; handles.style.height = r.height + 'px';
    const pos = { nw:[0,0], n:[.5,0], ne:[1,0], e:[1,.5], se:[1,1], s:[.5,1], sw:[0,1], w:[0,.5] };
    handles.querySelectorAll('.__ve-h').forEach(h => {
      const k = [...h.classList].find(c => pos[c]); const [x,y] = pos[k];
      h.style.left = `calc(${x*100}% - 5px)`; h.style.top = `calc(${y*100}% - 5px)`;
    });
  }
  window.addEventListener('scroll', refreshHandles, true);
  window.addEventListener('resize', refreshHandles);

  handles.querySelectorAll('.__ve-h').forEach(h => {
    h.addEventListener('mousedown', (e) => {
      e.preventDefault(); e.stopPropagation();
      const dir = [...h.classList].find(c => c.length <= 2);
      const r = sel.getBoundingClientRect();
      const startW = r.width, startH = r.height, sx = e.clientX, sy = e.clientY;
      const ow = sel.style.width, oh = sel.style.height;
      record(() => { sel.style.width = ow; sel.style.height = oh; refreshHandles(); });
      const move = (ev) => {
        let w = startW, hh = startH;
        if (dir.includes('e')) w = startW + (ev.clientX - sx);
        if (dir.includes('w')) w = startW - (ev.clientX - sx);
        if (dir.includes('s')) hh = startH + (ev.clientY - sy);
        if (dir.includes('n')) hh = startH - (ev.clientY - sy);
        if (dir.match(/[ew]/)) sel.style.width = Math.max(GRID, snap(w)) + 'px';
        if (dir.match(/[ns]/)) sel.style.height = Math.max(GRID, snap(hh)) + 'px';
        refreshHandles();
      };
      const up = () => { document.removeEventListener('mousemove', move); document.removeEventListener('mouseup', up); };
      document.addEventListener('mousemove', move); document.addEventListener('mouseup', up);
    });
  });

  /* ---------- drag to move / reorder ---------- */
  let dragInfo = null;
  document.addEventListener('mousedown', (e) => {
    if (!editMode || isChrome(e.target) || e.target !== sel) return;
    const free = ['absolute','fixed','sticky'].includes(cs(sel, 'position'));
    dragInfo = { sx: e.clientX, sy: e.clientY, moved: false, free,
                 ol: sel.style.left, ot: sel.style.top,
                 startL: px(cs(sel,'left')), startT: px(cs(sel,'top')) };
  }, true);
  document.addEventListener('mousemove', (e) => {
    if (!dragInfo) return;
    if (!dragInfo.moved && Math.abs(e.clientX-dragInfo.sx) + Math.abs(e.clientY-dragInfo.sy) < 4) return;
    dragInfo.moved = true;
    if (dragInfo.free) {
      sel.style.left = snap(dragInfo.startL + (e.clientX - dragInfo.sx)) + 'px';
      sel.style.top  = snap(dragInfo.startT + (e.clientY - dragInfo.sy)) + 'px';
      refreshHandles();
    } else {
      sel.style.pointerEvents = 'none';
      const t = document.elementFromPoint(e.clientX, e.clientY);
      sel.style.pointerEvents = '';
      if (t && t.parentElement === sel.parentElement && t !== sel && !isChrome(t)) {
        const r = t.getBoundingClientRect();
        const after = (e.clientY - r.top) > r.height / 2;
        t.parentElement.insertBefore(sel, after ? t.nextSibling : t);
        refreshHandles();
      }
    }
  }, true);
  document.addEventListener('mouseup', () => {
    if (dragInfo && dragInfo.moved) {
      if (dragInfo.free) { const ol = dragInfo.ol, ot = dragInfo.ot; record(() => { sel.style.left = ol; sel.style.top = ot; refreshHandles(); }); }
      else { /* reorder recorded coarsely: undo re-selects, simplest is leave DOM */ }
    }
    dragInfo = null;
  }, true);

  /* ---------- palette tokens ---------- */
  function styleElForToken(name) {
    for (const s of document.querySelectorAll('style:not([data-ve])'))
      if (s.textContent.includes(name + ':')) return s;
    return null;
  }
  function tokenColors() {
    const out = [];
    for (const s of document.querySelectorAll('style:not([data-ve])')) {
      const re = /(--[\w-]+)\s*:\s*(#[0-9a-fA-F]{3,8})\b/g; let m;
      while ((m = re.exec(s.textContent))) if (!out.find(o => o.name === m[1])) out.push({ name: m[1], val: m[2] });
    }
    return out;
  }
  let tokensOpen = false;
  bar.querySelector('.__ve-tokens').addEventListener('click', () => {
    tokensOpen = !tokensOpen;
    if (!tokensOpen) { buildInspector(); return; }
    if (sel) sel.classList.remove('__ve-sel'); sel = null; handles.style.display = 'none';
    insp.innerHTML = '<h4>Palette tokens</h4><div class="__ve-sw"></div>';
    const wrap = insp.querySelector('.__ve-sw');
    for (const t of tokenColors()) {
      const row = el('div', '__ve-tok', `<code>${t.name}</code>`);
      const inp = document.createElement('input'); inp.type = 'color'; inp.value = t.val.length === 4
        ? '#' + t.val.slice(1).split('').map(c => c+c).join('') : t.val.slice(0,7);
      inp.addEventListener('input', () => {
        const s = styleElForToken(t.name); if (!s) return;
        const old = s.textContent;
        s.textContent = old.replace(new RegExp('(' + t.name + '\\s*:\\s*)' + t.val.replace(/[.*+?^${}()|[\]\\]/g,'\\$&')), '$1' + inp.value);
        t.val = inp.value; tokenEdits[t.name] = inp.value;
      });
      row.appendChild(inp); wrap.appendChild(row);
    }
    insp.classList.add('show');
  });

  /* ---------- toolbar ---------- */
  bar.querySelector('.__ve-undo').addEventListener('click', () => { const f = undo.pop(); if (f) f(); buildInspector(); });
  bar.querySelector('.__ve-toggle').addEventListener('click', (e) => {
    editMode = !editMode;
    e.target.textContent = editMode ? 'Preview' : 'Edit';
    if (!editMode) { if (sel) sel.classList.remove('__ve-sel'); handles.style.display='none'; insp.classList.remove('show'); }
    flash(editMode ? 'Click an element → drag to move · corners to resize' : 'Preview mode — prototype is live');
  });

  bar.querySelector('.__ve-save').addEventListener('click', async () => {
    const tokenCount = Object.keys(tokenEdits).length;
    const ruleCount = Object.keys(ruleEdits).length;
    if (!tokenCount && !ruleCount) { flash('Nothing to save yet — recolor a palette token or restyle an element'); return; }
    flash('Saving…');
    try {
      const r = await fetch('/__ve/save', { method: 'POST', headers: {'content-type':'application/json'},
        body: JSON.stringify({ file: FILE, tokens: tokenEdits, rules: ruleEdits }) });
      flash(r.ok ? `Saved ✓  ${tokenCount} token${tokenCount!==1?'s':''}, ${ruleCount} rule${ruleCount!==1?'s':''} → ${FILE}`
                 : 'Save failed', r.ok ? '__ve-saved' : '');
    } catch (err) { flash('Save failed: ' + err.message); }
  });

  flash('Click an element → drag to move · corners to resize');
})();
