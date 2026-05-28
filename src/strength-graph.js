// src/strength-graph.js
import { loadReminderRecommendationStore } from "./reminder-recommendation-engine.js";
import { RECALL, term, localName, objects } from "./ontology-terms.js";

const STRENGTH_PREDICATES = ["revealsStrength", "deepensStrength"];

export function templateStrengths(store, templateId) {
  const subject = term(templateId);
  const found = new Set();
  for (const predicate of STRENGTH_PREDICATES) {
    for (const object of objects(store, subject, predicate)) {
      found.add(localName(object));
    }
  }
  return [...found];
}

export function buildStrengthAdjacency(store = loadReminderRecommendationStore()) {
  const cooccur = {};
  const strengthSet = new Set();
  const templateIris = new Set();

  for (const predicate of STRENGTH_PREDICATES) {
    for (const quad of store.getQuads(null, term(predicate), null, null)) {
      templateIris.add(quad.subject.value);
    }
  }

  for (const iri of templateIris) {
    const ids = templateStrengths(store, iri.replace(RECALL, ""));
    ids.forEach((id) => strengthSet.add(id));
    for (let i = 0; i < ids.length; i++) {
      for (let j = i + 1; j < ids.length; j++) {
        bump(cooccur, ids[i], ids[j]);
        bump(cooccur, ids[j], ids[i]);
      }
    }
  }

  const adjacency = {};
  for (const id of strengthSet) {
    const row = cooccur[id] || {};
    const total = Object.values(row).reduce((sum, n) => sum + n, 0);
    adjacency[id] = {};
    if (total > 0) {
      for (const [neighbor, count] of Object.entries(row)) {
        adjacency[id][neighbor] = count / total;
      }
    }
  }

  return { strengths: [...strengthSet], adjacency };
}

function bump(cooccur, a, b) {
  cooccur[a] = cooccur[a] || {};
  cooccur[a][b] = (cooccur[a][b] || 0) + 1;
}
