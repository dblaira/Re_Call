type ReminderRecommendationInput = {
  templateId: string;
  rating: string;
};

const graph = {
  ScanCalendarReminder: {
    strengths: ["TimeAwareness"],
    rule: "CalendarDepthRecommendationRule",
    reason:
      "A positively rated calendar scan reminder reveals time awareness; recommend deeper nearby uses of that strength rather than broader generic calendar reminders.",
    recommendations: [
      "Scan tomorrow's calendar for transition stress.",
      "Identify the meeting that needs emotional preparation.",
      "Find the one calendar item that deserves a pre-brief.",
      "Notice where the calendar overestimates available energy."
    ]
  },
  FindLeveragePointReminder: {
    strengths: ["LeverageAwareness", "ExecutionLeverage"],
    rule: "LeverageDepthRecommendationRule",
    reason:
      "A positively rated leverage reminder reveals leverage awareness and execution leverage; recommend deeper nearby ways to name the small input, visible proof, bottleneck, or next move rather than broader productivity reminders.",
    recommendations: [
      "Name the small input and the larger outcome before calling this leverage.",
      "Archive the good ideas; give the great idea the next move.",
      "Find the bottleneck that is blocking several outcomes at once.",
      "Ask for the full ordered draft before analyzing the decision."
    ]
  },
  ChooseCommunicationFormatReminder: {
    strengths: ["FormatJudgment", "CommunicationFit"],
    rule: "CommunicationFormatDepthRecommendationRule",
    reason:
      "A positively rated communication-format reminder reveals format judgment and communication fit; recommend deeper nearby ways to choose answer shape, preserve evidence, and diagnose format mismatch rather than rewriting the same message.",
    recommendations: [
      "Convert the idea into one table, node tree, route, or test path.",
      "Choose whether this should be a table, matrix, tree, or short note.",
      "Sort feedback into Like, Dislike, Undecided, and exact quote before interpreting.",
      "Ask for provenance, constraints used, and one verification step before accepting it."
    ]
  }
} as const;

Deno.serve(async (request: Request) => {
  if (request.method !== "POST") {
    return Response.json({ error: "Method not allowed. Use POST." }, { status: 405 });
  }

  const input = (await request.json()) as ReminderRecommendationInput;

  if (input.rating !== "PositiveReminderRating") {
    return Response.json({
      decision: "fallback",
      confidence: "low",
      recommendations: [],
      reason: "No RDF recommendation rule matched this reminder and feedback signal yet."
    });
  }

  const match = graph[input.templateId as keyof typeof graph];

  if (!match) {
    return Response.json({
      decision: "fallback",
      confidence: "low",
      recommendations: [],
      reason: "No RDF recommendation rule matched this reminder and feedback signal yet."
    });
  }

  return Response.json({
    decision: "rdf-graph-match",
    confidence: "high",
    sourceTemplate: input.templateId,
    revealedStrengths: match.strengths,
    recommendations: match.recommendations,
    reason: match.reason,
    graphTrace: {
      matchedRuleIds: [match.rule],
      rankingMethod: "RDF-derived recommendation order mirrored from Re_Call local graph"
    }
  });
});
