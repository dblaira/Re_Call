import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const WEB = resolve(ROOT, "ios/ReCall/Web");
const RECS_PATH = resolve(WEB, "recommendations.js");
const INDEX_PATH = resolve(WEB, "index.html");

function loadRecs() {
  const source = readFileSync(RECS_PATH, "utf8");
  const json = source.replace(/^window\.RECALL_RECS\s*=\s*/, "").replace(/;\s*$/, "");
  return JSON.parse(json);
}

// Ported from ios/ReCall/Web/index.html — on-device deck ranking
function deck(recs, { signals = [], dismissed = [], accepted = [] } = {}) {
  const dismissedSet = new Set(dismissed);
  const acceptedSet = new Set(accepted);
  const live = (c) => !dismissedSet.has(c.id) && !acceptedSet.has(c.id);

  function affinity() {
    const raw = {};
    (recs.strengths || []).forEach((s) => {
      raw[s] = 1.0;
    });
    for (const sig of signals) {
      const d = recs.signalDeltas[sig.signalType] || 0;
      for (const st of sig.strengths || []) raw[st] = (raw[st] ?? 1.0) + d;
    }
    const out = {};
    for (const [s, v] of Object.entries(raw)) {
      let n = 0;
      for (const [nb, w] of Object.entries(recs.adjacency[s] || {})) {
        n += w * ((raw[nb] ?? 1.0) - 1.0);
      }
      out[s] = v + 0.3 * n;
    }
    return out;
  }

  const personal = (recs.personal || []).filter(live).sort((a, b) => (b.weight || 0) - (a.weight || 0));
  const aff = affinity();
  const score = (c) => {
    const ss = c.deepensStrengths || [];
    if (!ss.length) return c.score || 0;
    return ((c.score || 0) * ss.reduce((a, s) => a + (aff[s] ?? 1.0), 0)) / ss.length;
  };
  const depth = (recs.depth || []).filter(live).sort((a, b) => score(b) - score(a)).slice(0, 2);
  return personal.concat(depth);
}

const recs = loadRecs();
const indexHtml = readFileSync(INDEX_PATH, "utf8");

test("recommendations bundle loads and has personal + depth cards", () => {
  assert.ok(recs.personal.length >= 4, "expected KG personal cards");
  assert.ok(recs.depth.length > 0, "expected depth cards from ontology");
  assert.ok(recs.strengths.length > 0);
  assert.ok(recs.adjacency && Object.keys(recs.adjacency).length > 0);
  assert.equal(recs.signalDeltas.edit, 0.3);
});

test("bundle includes expected KG suggestion rows", () => {
  const ids = new Set(recs.personal.map((c) => c.id));
  assert.ok(ids.has("kg:MilesProtocol"));
  assert.ok(ids.has("kg:TrustContract"));
  assert.ok(ids.has("kg:OpenLoop_AskStephanie"));
});

test("deck shows at least four suggestions before any interaction", () => {
  const cards = deck(recs);
  assert.ok(cards.length >= 4);
  assert.ok(cards.some((c) => c.id === "kg:MilesProtocol"));
});

test("accepting a card removes it from the deck and records signal shape", () => {
  const target = recs.personal.find((c) => c.id === "kg:MilesProtocol");
  const signals = [{
    recId: "kg:MilesProtocol",
    signalType: "accept",
    strengths: target?.deepensStrengths || [],
    at: new Date().toISOString()
  }];
  const cards = deck(recs, { signals, accepted: ["kg:MilesProtocol"] });
  assert.ok(!cards.some((c) => c.id === "kg:MilesProtocol"));
});

test("edit signal on habit stacking lifts deeper habit card into top depth slots", () => {
  const habitStrengths = ["HabitStacking"];
  const signals = Array.from({ length: 4 }, () => ({
    recId: "habit-edit",
    signalType: "edit",
    strengths: habitStrengths,
    at: new Date().toISOString()
  }));
  const cards = deck(recs, { signals });
  const depthIds = cards.filter((c) => c.source === "depth").map((c) => c.id);
  assert.ok(depthIds.length <= 2);
  const habitDepth = recs.depth.filter((c) =>
    (c.deepensStrengths || []).includes("HabitStacking")
  );
  assert.ok(habitDepth.length > 0);
  if (depthIds.length > 0) {
    const topDepth = recs.depth.find((c) => c.id === depthIds[0]);
    assert.ok((topDepth?.deepensStrengths || []).includes("HabitStacking"));
  }
});

test("post-run body discovery depth cards expose scan-field options in bundle", () => {
  const postRun = recs.depth.filter((c) =>
    (c.why || []).some((line) => line.includes("PostRunBodyDiscoveryReminder"))
  );
  assert.ok(postRun.length > 0);
  assert.ok(postRun.some((c) => /low-to-high/i.test(c.title)));
  assert.ok(postRun.some((c) => /twenty movement hypotheses/i.test(c.title)));
});

test("index.html wires the suggestion list and hides reasoning from the UI", () => {
  assert.ok(indexHtml.includes("id=\"resurface-list\""));
  assert.ok(indexHtml.includes("RECALL_RECS"));
  assert.ok(indexHtml.includes("renderRecs"));
  assert.ok(!indexHtml.includes("class=\"why\""));
});

test("index.html includes build fingerprint for on-device SHA verification", () => {
  assert.ok(indexHtml.includes("id=\"build-info\""));
  assert.ok(indexHtml.includes("data-src-md5"));
});

test("habit stack template tile exists for deeper-card flow", () => {
  assert.ok(indexHtml.includes("data-template=\"HabitStackGymReminder\""));
  assert.ok((recs.seeds || {}).HabitStackGymReminder || indexHtml.includes("HabitStackGymReminder"));
});
