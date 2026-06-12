// Compile the knowledge graph into the app's deterministic recommendation bundle.
//
//   node scripts/build-recommendations.mjs
//   → ios/ReCall/Web/recommendations.js   (window.RECALL_RECS = {...})
//
// Two sources, zero LLM, zero network:
//   1. Personal cards — walked straight out of ontology/recall-seed.ttl:
//      every `X recall:resurfaces Y`, every flagged-important open loop and
//      pattern becomes a card whose why-chain IS the graph path.
//   2. Depth cards — the existing reminder-recommendation engine's template
//      candidates (depth doctrine), with strengths + adjacency included so
//      the device can re-rank from locally recorded signals.

import { readFileSync, writeFileSync } from "node:fs";
import { Parser, Store, DataFactory } from "n3";
import {
  getReminderRecommendations,
  loadReminderRecommendationStore,
  ReminderTemplate,
  ReminderFeedback,
} from "../src/reminder-recommendation-engine.js";
import { buildStrengthAdjacency } from "../src/strength-graph.js";

const { namedNode } = DataFactory;
const RECALL = "http://recall.app/ontology#";
const ADAM = "http://recall.app/data/adam#";
const RDFS_LABEL = "http://www.w3.org/2000/01/rdf-schema#label";
const SEED_PATH = new URL("../ontology/recall-seed.ttl", import.meta.url).pathname;
const OUT_PATH = new URL("../ios/ReCall/Web/recommendations.js", import.meta.url).pathname;

// ---------- load the seed KG ----------
const store = new Store(new Parser().parse(readFileSync(SEED_PATH, "utf8")));
const local = (iri) => iri.split("#").pop();
const labelOf = (iri) => {
  const q = store.getQuads(namedNode(iri), namedNode(RDFS_LABEL), null, null)[0];
  return q ? q.object.value : local(iri);
};

const RELATIONS = ["causes", "blocks", "repairedBy", "conflictsWith", "resurfaces", "correlatesWith", "triggers", "leadsTo", "verifies"];
const REL_GLYPH = { causes: "causes", blocks: "blocks", repairedBy: "repaired by", conflictsWith: "conflicts with", resurfaces: "resurfaces", correlatesWith: "correlates with", triggers: "triggers", leadsTo: "leads to", verifies: "verifies" };

// every edge touching a node, formatted "A — rel → B"
function whyChain(seedIri, max = 3) {
  const lines = [];
  for (const rel of RELATIONS) {
    const p = namedNode(RECALL + rel);
    for (const q of store.getQuads(null, p, namedNode(seedIri), null))
      lines.push(`${labelOf(q.subject.value)} — ${REL_GLYPH[rel]} → ${labelOf(seedIri)}`);
    for (const q of store.getQuads(namedNode(seedIri), p, null, null))
      lines.push(`${labelOf(seedIri)} — ${REL_GLYPH[rel]} → ${labelOf(q.object.value)}`);
  }
  const out = [...new Set(lines)].slice(0, max);
  return out.length ? out : [labelOf(seedIri)];
}

// ---------- personal cards (allowlist = curated copy, KG = structure) ----------
const COPY = {
  MilesProtocol: { title: "Next dose: ½ dose every 3–4 days", sub: "Miles' protocol vs your current 3×2mg/day", type: "reminder" },
  OpenLoop_AskStephanie: { title: "Before the next big spend — ask Stephanie first", sub: "Pattern: unilateral decision → hurt → repair", type: "reminder" },
  OpenLoop_SemanticWeb: { title: "Commit or pivot: the semantic web", sub: "Flagged IMPORTANT twice. Decide the test.", type: "task" },
  TrustContract: { title: "Run ./qc.sh before any “it works”", sub: "Green run + SHA match, every time", type: "task" },
  Pattern_CaptureAntidote: { title: "Capture today's friction, raw", sub: "Capture is your antidote to horizon-anxiety", type: "task" },
  Pattern_AmbitionAvoidance: { title: "Feeling the freeze? Write one small next step", sub: "Ambition spike → anxiety → avoidance", type: "reminder" },
};

const personal = [];
const seen = new Set();
const addCard = (seedLocal, weight) => {
  if (seen.has(seedLocal) || !COPY[seedLocal]) return;
  seen.add(seedLocal);
  personal.push({
    id: `kg:${seedLocal}`,
    source: "kg",
    weight,
    ...COPY[seedLocal],
    why: whyChain(ADAM + seedLocal),
  });
};

// resurface targets are the strongest signal — the KG explicitly says "bring this back"
for (const q of store.getQuads(null, namedNode(RECALL + "resurfaces"), null, null))
  addCard(local(q.object.value), 1.0);
// flagged-important open loops and patterns
for (const q of store.getQuads(null, namedNode(RECALL + "flaggedImportant"), null, null))
  if (q.object.value === "true") addCard(local(q.subject.value), 0.8);

// ---------- depth cards from the existing engine ----------
const recStore = loadReminderRecommendationStore();
const { adjacency, strengths } = buildStrengthAdjacency(recStore);
const depth = [];
for (const templateId of Object.values(ReminderTemplate)) {
  const result = getReminderRecommendations(
    { templateId, rating: ReminderFeedback.Positive },
    { store: recStore, limit: 2 }
  );
  for (const rec of result.recommendations ?? []) {
    depth.push({
      id: `depth:${rec.id}`,
      source: "depth",
      type: "task",
      title: rec.text ?? rec.templateText ?? rec.id,
      sub: result.reason ?? "Goes deeper, not broader",
      why: [`${templateId} — recommends → ${rec.id}`],
      score: rec.score ?? rec.depthScore ?? 0,
      deepensStrengths: (rec.deepensStrengths ?? []).map((s) => s.id ?? s),
    });
  }
}

// ---------- seed templates (the tiles' contract) ----------
// tap tile → composer prefilled with KG template text → edit until owned →
// add records the reveal signal, which lifts that strength's deeper cards
const RECALL_ONT = "https://understood.app/ontology/project-recall#";
const seeds = {};
for (const templateId of Object.values(ReminderTemplate)) {
  const node = namedNode(RECALL_ONT + templateId);
  const get = (pred) => recStore.getQuads(node, namedNode(pred), null, null);
  seeds[templateId] = {
    id: templateId,
    label: get(RDFS_LABEL)[0]?.object.value ?? templateId,
    text: get(RECALL_ONT + "templateText")[0]?.object.value ?? "",
    revealsStrengths: get(RECALL_ONT + "revealsStrength").map((q) => q.object.value.split("#").pop()),
  };
}

// ---------- emit ----------
// no timestamp: output must be byte-identical for the same KG (determinism gate in qc.sh)
const bundle = {
  builtFrom: "ontology/recall-seed.ttl + ontology/reminder-recommendation.ttl",
  personal,
  depth,
  seeds,
  strengths,
  adjacency,
  signalDeltas: { edit: 0.3, positive: 0.15, accept: 0.1, dismiss: -0.1 },
};
writeFileSync(OUT_PATH, "window.RECALL_RECS = " + JSON.stringify(bundle, null, 1) + ";\n");
console.log(`recommendations.js: ${personal.length} personal + ${depth.length} depth cards, ${strengths.length} strengths`);
