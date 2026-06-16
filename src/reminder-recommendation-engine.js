import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { DataFactory, Parser, Store } from "n3";

const { namedNode } = DataFactory;

const RECALL = "https://understood.app/ontology/project-recall#";
const RDF_TYPE = "http://www.w3.org/1999/02/22-rdf-syntax-ns#type";
const RDFS_LABEL = "http://www.w3.org/2000/01/rdf-schema#label";
const RDFS_COMMENT = "http://www.w3.org/2000/01/rdf-schema#comment";

const DEFAULT_ONTOLOGY_PATH = resolve(
  dirname(fileURLToPath(import.meta.url)),
  "../ontology/reminder-recommendation.ttl"
);

export const ReminderFeedback = Object.freeze({
  Positive: "PositiveReminderRating"
});

export const ReminderTemplate = Object.freeze({
  ScanCalendar: "ScanCalendarReminder",
  FindLeveragePoint: "FindLeveragePointReminder",
  ChooseCommunicationFormat: "ChooseCommunicationFormatReminder",
  HabitStackGym: "HabitStackGymReminder",
  TranslateAIWeek: "TranslateAIWeekReminder",
  CaptureMacBookUnlocks: "CaptureMacBookUnlocksReminder",
  NameMeaningfulSource: "NameMeaningfulSourceReminder",
  PostRunBodyDiscovery: "PostRunBodyDiscoveryReminder"
});

export function getReminderRecommendations(input, options = {}) {
  if (!input || typeof input !== "object") {
    throw new TypeError("getReminderRecommendations requires an input object.");
  }

  const store = options.store || loadReminderRecommendationStore(options.ontologyPath);
  const sourceTemplate = toRecallNode(input.templateId);
  const feedback = toRecallNode(input.rating);
  const rules = findMatchingRules(store, sourceTemplate, feedback);

  if (rules.length === 0) {
    return {
      decision: "fallback",
      confidence: "low",
      sourceTemplate: describeNode(store, sourceTemplate),
      revealedStrengths: [],
      recommendations: [],
      reason: "No RDF recommendation rule matched this reminder and feedback signal yet."
    };
  }

  const contextText = [input.text, input.context, input.note].filter(Boolean).join(" ");
  const revealedStrengths = getObjects(store, sourceTemplate, "revealsStrength")
    .map((strength) => describeNode(store, strength));
  const generationFrame = describeGenerationFrame(store, rules[0]);

  const recommendations = dedupeById(
    rules.flatMap((rule) =>
      getObjects(store, rule, "recommendsTemplate").map((candidate) => {
        const depthScore = getDecimal(store, candidate, "depthScore");
        const sharedGraphFeatures = getSharedGraphFeatures(store, sourceTemplate, candidate);

        return {
          ...describeNode(store, candidate),
          text: getLiteral(store, candidate, "templateText"),
          deepensStrengths: getObjects(store, candidate, "deepensStrength")
            .map((strength) => describeNode(store, strength)),
          sharedGraphFeatures,
          score: rankRecommendation({
            depthScore,
            sharedFeatureCount: sharedGraphFeatures.length,
            contextText,
            candidate: describeNode(store, candidate)
          }),
          sourceRule: describeNode(store, rule)
        };
      })
    )
  )
    .sort((left, right) => right.score - left.score)
    .slice(0, options.limit || 4);

  return {
    decision: "rdf-graph-match",
    confidence: "high",
    sourceTemplate: describeNode(store, sourceTemplate),
    feedback: describeNode(store, feedback),
    revealedStrengths,
    generationFrame,
    recommendations,
    reason: getLiteral(store, rules[0], "recommendationReason"),
    graphTrace: {
      matchedRuleIds: rules.map((rule) => localName(rule)),
      sourceTriple: `${localName(sourceTemplate)} -> revealsStrength -> ${revealedStrengths.map((strength) => strength.id).join(", ")}`,
      recommendationTriplePattern: "RecommendationRule -> recommendsTemplate -> ReminderTemplate",
      rankingMethod: "depthScore + shared graph feature overlap + small context boost"
    }
  };
}

function describeGenerationFrame(store, rule) {
  const frame = getObjects(store, rule, "usesFeedbackFrame")[0];
  if (!frame) return null;

  return {
    ...describeNode(store, frame),
    intent: getLiteral(store, frame, "generationIntent"),
    mustInclude: getObjects(store, frame, "mustInclude").map((value) => value.value),
    mustAvoid: getObjects(store, frame, "mustAvoid").map((value) => value.value)
  };
}

export function loadReminderRecommendationStore(ontologyPath = DEFAULT_ONTOLOGY_PATH) {
  const turtle = readFileSync(ontologyPath, "utf8");
  const parser = new Parser();
  return new Store(parser.parse(turtle));
}

function findMatchingRules(store, sourceTemplate, feedback) {
  return store
    .getSubjects(namedNode(RDF_TYPE), recallNode("ReminderRecommendationRule"), null)
    .filter((rule) => hasObject(store, rule, "triggeredByTemplate", sourceTemplate))
    .filter((rule) => hasObject(store, rule, "requiresFeedback", feedback));
}

function getSharedGraphFeatures(store, sourceTemplate, candidate) {
  const sourceStrengths = getObjects(store, sourceTemplate, "revealsStrength");
  const candidateStrengths = getObjects(store, candidate, "deepensStrength");

  return sourceStrengths
    .filter((sourceStrength) => candidateStrengths.some((candidateStrength) => candidateStrength.equals(sourceStrength)))
    .map((strength) => ({
      predicate: "revealsStrength/deepensStrength",
      ...describeNode(store, strength)
    }));
}

function rankRecommendation({ depthScore, sharedFeatureCount, contextText, candidate }) {
  const context = contextText.toLowerCase();
  const label = candidate.label.toLowerCase();
  const comment = candidate.comment.toLowerCase();
  const contextBoost = context && [label, comment].some((value) => sharesWord(context, value)) ? 0.03 : 0;
  return Number((depthScore + sharedFeatureCount * 0.05 + contextBoost).toFixed(3));
}

function sharesWord(left, right) {
  const importantWords = left
    .split(/[^a-z0-9]+/i)
    .filter((word) => word.length > 5);
  return importantWords.some((word) => right.includes(word));
}

function dedupeById(items) {
  return [...new Map(items.map((item) => [item.id, item])).values()];
}

function getObjects(store, subject, predicate) {
  return store.getObjects(subject, recallNode(predicate), null);
}

function hasObject(store, subject, predicate, object) {
  return getObjects(store, subject, predicate).some((candidate) => candidate.equals(object));
}

function getLiteral(store, subject, predicate) {
  return getObjects(store, subject, predicate)[0]?.value || "";
}

function getDecimal(store, subject, predicate) {
  return Number.parseFloat(getLiteral(store, subject, predicate) || "0");
}

function describeNode(store, node) {
  return {
    id: localName(node),
    iri: node.value,
    label: store.getObjects(node, namedNode(RDFS_LABEL), null)[0]?.value || localName(node),
    comment: store.getObjects(node, namedNode(RDFS_COMMENT), null)[0]?.value || ""
  };
}

function toRecallNode(value) {
  if (!value || typeof value !== "string") {
    throw new TypeError("Expected a Re_Call ontology identifier string.");
  }

  return value.startsWith("http") ? namedNode(value) : recallNode(value);
}

function recallNode(localId) {
  return namedNode(`${RECALL}${localId}`);
}

function localName(node) {
  return node.value.replace(RECALL, "");
}
