import { readFileSync, readdirSync, statSync } from "node:fs";
import { createHash } from "node:crypto";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const WEB = resolve(dirname(fileURLToPath(import.meta.url)), "../ios/ReCall/Web");

function listFiles(dir) {
  const files = [];
  for (const name of readdirSync(dir).filter((n) => !n.startsWith("."))) {
    const path = join(dir, name);
    if (statSync(path).isDirectory()) files.push(...listFiles(path));
    else files.push(path);
  }
  return files.sort();
}

const hash = createHash("md5");
for (const file of listFiles(WEB)) hash.update(readFileSync(file));
process.stdout.write(hash.digest("hex"));
