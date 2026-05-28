// src/ontology-terms.js
import { DataFactory } from "n3";

const { namedNode } = DataFactory;

export const RECALL = "https://understood.app/ontology/project-recall#";
export const term = (id) => namedNode(`${RECALL}${id}`);
export const localName = (node) => node.value.replace(RECALL, "");

export function objects(store, subjectTerm, predicate) {
  return store.getObjects(subjectTerm, term(predicate), null);
}

export function literal(store, subjectTerm, predicate) {
  return objects(store, subjectTerm, predicate)[0]?.value ?? "";
}

export function decimal(store, subjectTerm, predicate) {
  return Number.parseFloat(literal(store, subjectTerm, predicate) || "0");
}
