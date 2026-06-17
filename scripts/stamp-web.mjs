// Stamp local web dev fingerprints into index.html (replaced again on each run).
import { readFileSync, writeFileSync, readdirSync, statSync } from "node:fs";
import { execSync } from "node:child_process";
import { createHash } from "node:crypto";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const WEB = resolve(dirname(fileURLToPath(import.meta.url)), "../ios/ReCall/Web");
const INDEX = resolve(WEB, "index.html");

function listFiles(dir, base = dir) {
  const entries = readdirSync(dir).filter((name) => !name.startsWith("."));
  const files = [];
  for (const name of entries) {
    const path = join(dir, name);
    const stat = statSync(path);
    if (stat.isDirectory()) files.push(...listFiles(path, base));
    else files.push(path);
  }
  return files.sort();
}

function withPlaceholders(html) {
  return html
    .replace(/data-src-md5="[^"]+"/, 'data-src-md5="__SRC_MD5__"')
    .replace(/(id="build-info"[^>]*>)[^<]+/, "$1__BUILD_SHA__");
}

function webBundleMd5() {
  const hash = createHash("md5");
  for (const file of listFiles(WEB)) {
    let content = readFileSync(file);
    if (file === INDEX) {
      content = Buffer.from(withPlaceholders(content.toString("utf8")), "utf8");
    }
    hash.update(content);
  }
  return hash.digest("hex");
}

let sha = "dev";
try {
  sha = execSync("git rev-parse --short HEAD", { encoding: "utf8" }).trim();
  if (execSync("git status --porcelain", { encoding: "utf8" }).trim()) sha += "*";
} catch {
  sha = "no-git";
}

const srcMd5 = webBundleMd5();
let html = readFileSync(INDEX, "utf8");
html = html.replace(/__BUILD_SHA__/g, sha).replace(/__SRC_MD5__/g, srcMd5);
writeFileSync(INDEX, html);
writeFileSync(resolve(WEB, ".bundle-stamp.json"), JSON.stringify({ sha, srcMd5 }, null, 2));

console.log(`stamped web bundle: sha=${sha} md5=${srcMd5}`);
