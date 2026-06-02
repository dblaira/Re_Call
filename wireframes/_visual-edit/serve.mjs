// Visual-edit server — serves the wireframe HTML with a direct-manipulation
// editor injected on the fly, and writes your changes back to disk on Save.
//
//   node wireframes/_visual-edit/serve.mjs
//   → open http://localhost:5173/template-gallery-ios.html
//
// The source HTML files stay clean: the editor is injected only when served,
// and stripped back out before the file is written on Save.

import { createServer } from 'node:http';
import { readFile, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { dirname, join, basename, extname } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const WF_DIR = join(__dirname, '..');           // wireframes/
const PORT = 5173;

const TYPES = { '.html': 'text/html', '.css': 'text/css', '.js': 'text/javascript',
                '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg',
                '.svg': 'image/svg+xml', '.webp': 'image/webp' };

// Only these files may be served/written — no path traversal.
const editable = (name) => /^[\w.-]+\.html$/.test(name);

const readBody = (req) => new Promise((res, rej) => {
  let b = ''; req.on('data', c => (b += c)); req.on('end', () => res(b)); req.on('error', rej);
});

const server = createServer(async (req, res) => {
  try {
    if (req.method === 'POST' && req.url === '/__ve/save') {
      const { file, tokens = {}, rules = {} } = JSON.parse(await readBody(req));
      if (!editable(basename(file))) { res.writeHead(400); return res.end('bad file'); }
      const target = join(WF_DIR, basename(file));
      let src = await readFile(target, 'utf8');

      // 1) Patch design-token values in place (e.g.  --gold: #C49E30; ).
      for (const [name, val] of Object.entries(tokens)) {
        const re = new RegExp('(' + name.replace(/[-]/g, '\\-') + '\\s*:\\s*)([^;]+)(;)');
        src = src.replace(re, `$1${val}$3`);
      }

      // 2) Element edits → CSS rules in a single managed <style id="__ve-overrides">.
      //    Merge with any rules already saved there so reloads don't drop prior work.
      if (Object.keys(rules).length) {
        const existing = /<style id="__ve-overrides">([\s\S]*?)<\/style>/;
        const prior = {};
        const m = src.match(existing);
        if (m) for (const r of m[1].matchAll(/([^{}\/]+)\{([^}]*)\}/g)) {
          const selector = r[1].trim(); if (!selector) continue;
          const decls = prior[selector] || (prior[selector] = {});
          for (const d of r[2].matchAll(/([\w-]+)\s*:\s*([^;]+);/g)) decls[d[1].trim()] = d[2].trim();
        }
        for (const [selector, decls] of Object.entries(rules))
          Object.assign(prior[selector] || (prior[selector] = {}), decls);

        const css = Object.entries(prior).map(([selector, decls]) => {
          const body = Object.entries(decls).map(([p, v]) => `  ${p}: ${v};`).join('\n');
          return `${selector} {\n${body}\n}`;
        }).join('\n');
        const block = `<style id="__ve-overrides">\n/* Visual-edit overrides — restyle the kind, every instance follows. */\n${css}\n</style>`;
        src = m ? src.replace(existing, block) : src.replace(/<\/head>/i, block + '\n</head>');
      }

      await writeFile(target, src, 'utf8');
      res.writeHead(200, { 'content-type': 'application/json' });
      return res.end(JSON.stringify({ ok: true, file: basename(file), tokens: Object.keys(tokens).length, rules: Object.keys(rules).length }));
    }

    // Editor assets
    if (req.url === '/__ve/editor.js' || req.url === '/__ve/editor.css') {
      const f = join(__dirname, basename(req.url));
      const body = await readFile(f);
      res.writeHead(200, { 'content-type': TYPES[extname(f)] });
      return res.end(body);
    }

    // Static files from wireframes/
    let path = decodeURIComponent((req.url || '/').split('?')[0]);
    if (path === '/') path = '/template-gallery-ios.html';
    const file = join(WF_DIR, path);
    if (!file.startsWith(WF_DIR)) { res.writeHead(403); return res.end('nope'); }

    let body = await readFile(file);
    const ext = extname(file);
    if (ext === '.html') {
      const inject = `
<link rel="stylesheet" href="/__ve/editor.css" data-ve>
<script>window.__VE_FILE=${JSON.stringify(basename(file))}</script>
<script src="/__ve/editor.js" data-ve></script>`;
      body = body.toString().replace(/<\/body>/i, inject + '\n</body>');
    }
    res.writeHead(200, { 'content-type': TYPES[ext] || 'application/octet-stream' });
    res.end(body);
  } catch (e) {
    res.writeHead(e.code === 'ENOENT' ? 404 : 500);
    res.end(String(e.message || e));
  }
});

server.listen(PORT, () => {
  console.log(`\n  Visual edit running:\n  → http://localhost:${PORT}/template-gallery-ios.html\n`);
});
