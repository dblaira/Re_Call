window.RECALL_RECS = {
 "builtFrom": "ontology/recall-seed.ttl + ontology/reminder-recommendation.ttl",
 "personal": [
  {
   "id": "kg:MilesProtocol",
   "source": "kg",
   "weight": 1,
   "title": "Next dose: ½ dose every 3–4 days",
   "sub": "Miles' protocol vs your current 3×2mg/day",
   "type": "reminder",
   "why": [
    "Retatrutide (GLP-3) — conflicts with → Miles' dosing protocol: 1/2 dose every 3-4 days",
    "Retatrutide (GLP-3) — resurfaces → Miles' dosing protocol: 1/2 dose every 3-4 days"
   ]
  },
  {
   "id": "kg:OpenLoop_AskStephanie",
   "source": "kg",
   "weight": 1,
   "title": "Before the next big spend — ask Stephanie first",
   "sub": "Pattern: unilateral decision → hurt → repair",
   "type": "reminder",
   "why": [
    "Unilateral decision -> hurt -> repair — resurfaces → Ask Stephanie what she wants rather than guessing (before next non-negotiable spend)"
   ]
  },
  {
   "id": "kg:TrustContract",
   "source": "kg",
   "weight": 1,
   "title": "Run ./qc.sh before any “it works”",
   "sub": "Green run + SHA match, every time",
   "type": "task",
   "why": [
    "Adam's trust broken — 'it works' claim failed on device, right before leaving — repaired by → Trust contract: 'works' = qc.sh green + on-device SHA matches repo",
    "Verification before claim: evidence the user can check beats assurances — resurfaces → Trust contract: 'works' = qc.sh green + on-device SHA matches repo",
    "Trust contract: 'works' = qc.sh green + on-device SHA matches repo — resurfaces → The claim 'it works'"
   ]
  },
  {
   "id": "kg:Pattern_AmbitionAvoidance",
   "source": "kg",
   "weight": 0.8,
   "title": "Feeling the freeze? Write one small next step",
   "sub": "Ambition spike → anxiety → avoidance",
   "type": "reminder",
   "why": [
    "Ambition spike -> anxiety -> avoidance/freeze"
   ]
  },
  {
   "id": "kg:Pattern_CaptureAntidote",
   "source": "kg",
   "weight": 0.8,
   "title": "Capture today's friction, raw",
   "sub": "Capture is your antidote to horizon-anxiety",
   "type": "task",
   "why": [
    "Real-time capture is the antidote to horizon-anxiety"
   ]
  },
  {
   "id": "kg:OpenLoop_SemanticWeb",
   "source": "kg",
   "weight": 0.8,
   "title": "Commit or pivot: the semantic web",
   "sub": "Flagged IMPORTANT twice. Decide the test.",
   "type": "task",
   "why": [
    "Commit or pivot on the semantic web; how to reliably test its importance"
   ]
  }
 ],
 "depth": [
  {
   "id": "depth:ScanTomorrowForTransitionStress",
   "source": "depth",
   "type": "task",
   "title": "Scan tomorrow's calendar for transition stress.",
   "sub": "A positively rated calendar scan reminder reveals time awareness; recommend deeper nearby uses of that strength rather than broader generic calendar reminders.",
   "why": [
    "ScanCalendarReminder — recommends → ScanTomorrowForTransitionStress"
   ],
   "score": 0.99,
   "generationFrame": null,
   "deepensStrengths": [
    "TimeAwareness",
    "TransitionPreparation"
   ]
  },
  {
   "id": "depth:IdentifyMeetingNeedingEmotionalPrep",
   "source": "depth",
   "type": "task",
   "title": "Identify the meeting that needs emotional preparation.",
   "sub": "A positively rated calendar scan reminder reveals time awareness; recommend deeper nearby uses of that strength rather than broader generic calendar reminders.",
   "why": [
    "ScanCalendarReminder — recommends → IdentifyMeetingNeedingEmotionalPrep"
   ],
   "score": 0.96,
   "generationFrame": null,
   "deepensStrengths": [
    "TimeAwareness",
    "TransitionPreparation"
   ]
  },
  {
   "id": "depth:FindCalendarItemForPrebrief",
   "source": "depth",
   "type": "task",
   "title": "Find the one calendar item that deserves a pre-brief.",
   "sub": "A positively rated calendar scan reminder reveals time awareness; recommend deeper nearby uses of that strength rather than broader generic calendar reminders.",
   "why": [
    "ScanCalendarReminder — recommends → FindCalendarItemForPrebrief"
   ],
   "score": 0.93,
   "generationFrame": null,
   "deepensStrengths": [
    "TimeAwareness"
   ]
  },
  {
   "id": "depth:NoticeEnergyOverestimate",
   "source": "depth",
   "type": "task",
   "title": "Notice where the calendar overestimates available energy.",
   "sub": "A positively rated calendar scan reminder reveals time awareness; recommend deeper nearby uses of that strength rather than broader generic calendar reminders.",
   "why": [
    "ScanCalendarReminder — recommends → NoticeEnergyOverestimate"
   ],
   "score": 0.91,
   "generationFrame": null,
   "deepensStrengths": [
    "TimeAwareness"
   ]
  },
  {
   "id": "depth:NameSmallInputAndOutcome",
   "source": "depth",
   "type": "task",
   "title": "Name the small input and the larger outcome before calling this leverage.",
   "sub": "A positively rated leverage reminder reveals leverage awareness and execution leverage; recommend deeper nearby ways to name the small input, visible proof, bottleneck, or next move rather than broader productivity reminders.",
   "why": [
    "FindLeveragePointReminder — recommends → NameSmallInputAndOutcome"
   ],
   "score": 1.05,
   "generationFrame": null,
   "deepensStrengths": [
    "LeverageAwareness"
   ]
  },
  {
   "id": "depth:ClearGoodIdeasForGreatIdea",
   "source": "depth",
   "type": "task",
   "title": "Archive the good ideas; give the great idea the next move.",
   "sub": "A positively rated leverage reminder reveals leverage awareness and execution leverage; recommend deeper nearby ways to name the small input, visible proof, bottleneck, or next move rather than broader productivity reminders.",
   "why": [
    "FindLeveragePointReminder — recommends → ClearGoodIdeasForGreatIdea"
   ],
   "score": 1.03,
   "generationFrame": null,
   "deepensStrengths": [
    "LeverageAwareness",
    "ExecutionLeverage"
   ]
  },
  {
   "id": "depth:AskForVisibleProcessDraft",
   "source": "depth",
   "type": "task",
   "title": "Ask for the full ordered draft before analyzing the decision.",
   "sub": "A positively rated leverage reminder reveals leverage awareness and execution leverage; recommend deeper nearby ways to name the small input, visible proof, bottleneck, or next move rather than broader productivity reminders.",
   "why": [
    "FindLeveragePointReminder — recommends → AskForVisibleProcessDraft"
   ],
   "score": 0.95,
   "generationFrame": null,
   "deepensStrengths": [
    "ExecutionLeverage"
   ]
  },
  {
   "id": "depth:FindBottleneckBlockingOutcomes",
   "source": "depth",
   "type": "task",
   "title": "Find the bottleneck that is blocking several outcomes at once.",
   "sub": "A positively rated leverage reminder reveals leverage awareness and execution leverage; recommend deeper nearby ways to name the small input, visible proof, bottleneck, or next move rather than broader productivity reminders.",
   "why": [
    "FindLeveragePointReminder — recommends → FindBottleneckBlockingOutcomes"
   ],
   "score": 0.93,
   "generationFrame": null,
   "deepensStrengths": [
    "LeverageAwareness"
   ]
  },
  {
   "id": "depth:ConvertAbstractTalkToInspectableShape",
   "source": "depth",
   "type": "task",
   "title": "Convert the idea into one table, node tree, route, or test path.",
   "sub": "A positively rated communication-format reminder reveals format judgment and communication fit; recommend deeper nearby ways to choose answer shape, preserve evidence, and diagnose format mismatch rather than rewriting the same message.",
   "why": [
    "ChooseCommunicationFormatReminder — recommends → ConvertAbstractTalkToInspectableShape"
   ],
   "score": 1.07,
   "generationFrame": null,
   "deepensStrengths": [
    "FormatJudgment",
    "CommunicationFit"
   ]
  },
  {
   "id": "depth:ChooseTableMatrixTreeOrNote",
   "source": "depth",
   "type": "task",
   "title": "Choose whether this should be a table, matrix, tree, or short note.",
   "sub": "A positively rated communication-format reminder reveals format judgment and communication fit; recommend deeper nearby ways to choose answer shape, preserve evidence, and diagnose format mismatch rather than rewriting the same message.",
   "why": [
    "ChooseCommunicationFormatReminder — recommends → ChooseTableMatrixTreeOrNote"
   ],
   "score": 1.02,
   "generationFrame": null,
   "deepensStrengths": [
    "FormatJudgment",
    "CommunicationFit"
   ]
  },
  {
   "id": "depth:SortFeedbackBeforeInterpreting",
   "source": "depth",
   "type": "task",
   "title": "Sort feedback into Like, Dislike, Undecided, and exact quote before interpreting.",
   "sub": "A positively rated communication-format reminder reveals format judgment and communication fit; recommend deeper nearby ways to choose answer shape, preserve evidence, and diagnose format mismatch rather than rewriting the same message.",
   "why": [
    "ChooseCommunicationFormatReminder — recommends → SortFeedbackBeforeInterpreting"
   ],
   "score": 0.94,
   "generationFrame": null,
   "deepensStrengths": [
    "CommunicationFit",
    "EvidenceTrust"
   ]
  },
  {
   "id": "depth:AskForProvenanceConstraintsVerification",
   "source": "depth",
   "type": "task",
   "title": "Ask for provenance, constraints used, and one verification step before accepting it.",
   "sub": "A positively rated communication-format reminder reveals format judgment and communication fit; recommend deeper nearby ways to choose answer shape, preserve evidence, and diagnose format mismatch rather than rewriting the same message.",
   "why": [
    "ChooseCommunicationFormatReminder — recommends → AskForProvenanceConstraintsVerification"
   ],
   "score": 0.92,
   "generationFrame": null,
   "deepensStrengths": [
    "FormatJudgment",
    "EvidenceTrust"
   ]
  },
  {
   "id": "depth:FoamRollFiveByFive",
   "source": "depth",
   "type": "task",
   "title": "Run a readiness bet: 30 seconds before the first shot, then mark the first five minutes better, same, or worse.",
   "sub": "A positively rated gym habit stack reveals habit stacking; recommend leveling the same stack up toward the ultimate goal rather than broader fitness reminders.",
   "why": [
    "HabitStackGymReminder — recommends → FoamRollFiveByFive"
   ],
   "score": 1,
   "generationFrame": {
    "id": "HabitStackReadinessExperimentFrame",
    "iri": "https://understood.app/ontology/project-recall#HabitStackReadinessExperimentFrame",
    "label": "Habit stack readiness experiment frame",
    "comment": "",
    "intent": "Generate feedback that turns the gym habit stack into a tiny readiness experiment with a verdict, not a repeated foam-rolling reminder.",
    "mustInclude": [
     "a tiny timed experiment",
     "a judgment moment",
     "a keep, kill, or replace branch"
    ],
    "mustAvoid": [
     "repeating the user's foam-rolling wording",
     "generic fitness advice",
     "motivation without a test"
    ]
   },
   "deepensStrengths": [
    "HabitStacking"
   ]
  },
  {
   "id": "depth:StackSecondMicrodose",
   "source": "depth",
   "type": "task",
   "title": "Make the warmup earn its place: if the test does not change readiness after three tries, kill it or replace it.",
   "sub": "A positively rated gym habit stack reveals habit stacking; recommend leveling the same stack up toward the ultimate goal rather than broader fitness reminders.",
   "why": [
    "HabitStackGymReminder — recommends → StackSecondMicrodose"
   ],
   "score": 0.93,
   "generationFrame": {
    "id": "HabitStackReadinessExperimentFrame",
    "iri": "https://understood.app/ontology/project-recall#HabitStackReadinessExperimentFrame",
    "label": "Habit stack readiness experiment frame",
    "comment": "",
    "intent": "Generate feedback that turns the gym habit stack into a tiny readiness experiment with a verdict, not a repeated foam-rolling reminder.",
    "mustInclude": [
     "a tiny timed experiment",
     "a judgment moment",
     "a keep, kill, or replace branch"
    ],
    "mustAvoid": [
     "repeating the user's foam-rolling wording",
     "generic fitness advice",
     "motivation without a test"
    ]
   },
   "deepensStrengths": [
    "HabitStacking"
   ]
  },
  {
   "id": "depth:ScoreFirstFiveMinutes",
   "source": "depth",
   "type": "task",
   "title": "Score the first five minutes: legs, breath, and first-step pop; keep only the ritual that changes one.",
   "sub": "A positively rated gym habit stack reveals habit stacking; recommend leveling the same stack up toward the ultimate goal rather than broader fitness reminders.",
   "why": [
    "HabitStackGymReminder — recommends → ScoreFirstFiveMinutes"
   ],
   "score": 0.91,
   "generationFrame": {
    "id": "HabitStackReadinessExperimentFrame",
    "iri": "https://understood.app/ontology/project-recall#HabitStackReadinessExperimentFrame",
    "label": "Habit stack readiness experiment frame",
    "comment": "",
    "intent": "Generate feedback that turns the gym habit stack into a tiny readiness experiment with a verdict, not a repeated foam-rolling reminder.",
    "mustInclude": [
     "a tiny timed experiment",
     "a judgment moment",
     "a keep, kill, or replace branch"
    ],
    "mustAvoid": [
     "repeating the user's foam-rolling wording",
     "generic fitness advice",
     "motivation without a test"
    ]
   },
   "deepensStrengths": [
    "HabitStacking"
   ]
  },
  {
   "id": "depth:ChangeAnchorNotAmbition",
   "source": "depth",
   "type": "task",
   "title": "Change the anchor, not the ambition: test before the first shot, after the first game, or before leaving, then keep the slot that actually fires.",
   "sub": "A positively rated gym habit stack reveals habit stacking; recommend leveling the same stack up toward the ultimate goal rather than broader fitness reminders.",
   "why": [
    "HabitStackGymReminder — recommends → ChangeAnchorNotAmbition"
   ],
   "score": 0.89,
   "generationFrame": {
    "id": "HabitStackReadinessExperimentFrame",
    "iri": "https://understood.app/ontology/project-recall#HabitStackReadinessExperimentFrame",
    "label": "Habit stack readiness experiment frame",
    "comment": "",
    "intent": "Generate feedback that turns the gym habit stack into a tiny readiness experiment with a verdict, not a repeated foam-rolling reminder.",
    "mustInclude": [
     "a tiny timed experiment",
     "a judgment moment",
     "a keep, kill, or replace branch"
    ],
    "mustAvoid": [
     "repeating the user's foam-rolling wording",
     "generic fitness advice",
     "motivation without a test"
    ]
   },
   "deepensStrengths": [
    "HabitStacking"
   ]
  },
  {
   "id": "depth:StandingAIDigestGesture",
   "source": "depth",
   "type": "task",
   "title": "Send the so-what before the news: one change, one risk, and one move the person can make this week.",
   "sub": "A positively rated AI translation reminder reveals knowledge synthesis; recommend grander, more organized gestures of the same service — never smaller steps, which the user dismisses.",
   "why": [
    "TranslateAIWeekReminder — recommends → StandingAIDigestGesture"
   ],
   "score": 1.01,
   "generationFrame": {
    "id": "KnowledgeConsequenceFrame",
    "iri": "https://understood.app/ontology/project-recall#KnowledgeConsequenceFrame",
    "label": "Knowledge consequence frame",
    "comment": "",
    "intent": "Generate feedback that converts fast AI knowledge into a consequence for one real person, not a news summary.",
    "mustInclude": [
     "one named audience or recipient",
     "one consequence",
     "one decision or move this week"
    ],
    "mustAvoid": [
     "repeating the user's AI briefing wording",
     "generic AI headlines",
     "interesting information without a consequence"
    ]
   },
   "deepensStrengths": [
    "KnowledgeSynthesis"
   ]
  },
  {
   "id": "depth:TranslateForOneDecision",
   "source": "depth",
   "type": "task",
   "title": "Make the briefing earn its place: if it does not change a decision, it was interesting but not useful.",
   "sub": "A positively rated AI translation reminder reveals knowledge synthesis; recommend grander, more organized gestures of the same service — never smaller steps, which the user dismisses.",
   "why": [
    "TranslateAIWeekReminder — recommends → TranslateForOneDecision"
   ],
   "score": 0.95,
   "generationFrame": {
    "id": "KnowledgeConsequenceFrame",
    "iri": "https://understood.app/ontology/project-recall#KnowledgeConsequenceFrame",
    "label": "Knowledge consequence frame",
    "comment": "",
    "intent": "Generate feedback that converts fast AI knowledge into a consequence for one real person, not a news summary.",
    "mustInclude": [
     "one named audience or recipient",
     "one consequence",
     "one decision or move this week"
    ],
    "mustAvoid": [
     "repeating the user's AI briefing wording",
     "generic AI headlines",
     "interesting information without a consequence"
    ]
   },
   "deepensStrengths": [
    "KnowledgeSynthesis"
   ]
  },
  {
   "id": "depth:NameRecipientDecision",
   "source": "depth",
   "type": "task",
   "title": "Pick the person before the headline: name the decision they face, then translate only the AI change that alters it.",
   "sub": "A positively rated AI translation reminder reveals knowledge synthesis; recommend grander, more organized gestures of the same service — never smaller steps, which the user dismisses.",
   "why": [
    "TranslateAIWeekReminder — recommends → NameRecipientDecision"
   ],
   "score": 0.93,
   "generationFrame": {
    "id": "KnowledgeConsequenceFrame",
    "iri": "https://understood.app/ontology/project-recall#KnowledgeConsequenceFrame",
    "label": "Knowledge consequence frame",
    "comment": "",
    "intent": "Generate feedback that converts fast AI knowledge into a consequence for one real person, not a news summary.",
    "mustInclude": [
     "one named audience or recipient",
     "one consequence",
     "one decision or move this week"
    ],
    "mustAvoid": [
     "repeating the user's AI briefing wording",
     "generic AI headlines",
     "interesting information without a consequence"
    ]
   },
   "deepensStrengths": [
    "KnowledgeSynthesis"
   ]
  },
  {
   "id": "depth:CutInterestingParagraph",
   "source": "depth",
   "type": "task",
   "title": "Cut the interesting paragraph unless it changes a move: send the implication, the risk, and the next action.",
   "sub": "A positively rated AI translation reminder reveals knowledge synthesis; recommend grander, more organized gestures of the same service — never smaller steps, which the user dismisses.",
   "why": [
    "TranslateAIWeekReminder — recommends → CutInterestingParagraph"
   ],
   "score": 0.91,
   "generationFrame": {
    "id": "KnowledgeConsequenceFrame",
    "iri": "https://understood.app/ontology/project-recall#KnowledgeConsequenceFrame",
    "label": "Knowledge consequence frame",
    "comment": "",
    "intent": "Generate feedback that converts fast AI knowledge into a consequence for one real person, not a news summary.",
    "mustInclude": [
     "one named audience or recipient",
     "one consequence",
     "one decision or move this week"
    ],
    "mustAvoid": [
     "repeating the user's AI briefing wording",
     "generic AI headlines",
     "interesting information without a consequence"
    ]
   },
   "deepensStrengths": [
    "KnowledgeSynthesis"
   ]
  },
  {
   "id": "depth:TwoWeekVerdictLedger",
   "source": "depth",
   "type": "task",
   "title": "Run the expensive-tool audit: what did this machine unlock that the old setup actually blocked?",
   "sub": "A positively rated in-the-moment capture reveals tool integration timing; recommend the verdict checkpoints that read from those captures — capture cadence and verdict cadence are different clocks.",
   "why": [
    "CaptureMacBookUnlocksReminder — recommends → TwoWeekVerdictLedger"
   ],
   "score": 0.99,
   "generationFrame": {
    "id": "ToolLeverageVerdictFrame",
    "iri": "https://understood.app/ontology/project-recall#ToolLeverageVerdictFrame",
    "label": "Tool leverage verdict frame",
    "comment": "",
    "intent": "Generate feedback that separates expensive-tool delight from actual leverage while reactions are still fresh.",
    "mustInclude": [
     "evidence from a real task",
     "a leverage-versus-luxury verdict",
     "a time box for the verdict"
    ],
    "mustAvoid": [
     "repeating the user's MacBook wording",
     "spec comparison",
     "purchase justification"
    ]
   },
   "deepensStrengths": [
    "ToolIntegrationTiming"
   ]
  },
  {
   "id": "depth:WeekOneAdamPatternCheck",
   "source": "depth",
   "type": "task",
   "title": "Separate delight from leverage: capture the moment a task became possible, faster, or less emotionally costly.",
   "sub": "A positively rated in-the-moment capture reveals tool integration timing; recommend the verdict checkpoints that read from those captures — capture cadence and verdict cadence are different clocks.",
   "why": [
    "CaptureMacBookUnlocksReminder — recommends → WeekOneAdamPatternCheck"
   ],
   "score": 0.95,
   "generationFrame": {
    "id": "ToolLeverageVerdictFrame",
    "iri": "https://understood.app/ontology/project-recall#ToolLeverageVerdictFrame",
    "label": "Tool leverage verdict frame",
    "comment": "",
    "intent": "Generate feedback that separates expensive-tool delight from actual leverage while reactions are still fresh.",
    "mustInclude": [
     "evidence from a real task",
     "a leverage-versus-luxury verdict",
     "a time box for the verdict"
    ],
    "mustAvoid": [
     "repeating the user's MacBook wording",
     "spec comparison",
     "purchase justification"
    ]
   },
   "deepensStrengths": [
    "ToolIntegrationTiming"
   ]
  },
  {
   "id": "depth:BlockedByOldSetupReceipt",
   "source": "depth",
   "type": "task",
   "title": "Write the blocked-by-old-setup receipt: task, old friction, new unlock, and whether it matters again.",
   "sub": "A positively rated in-the-moment capture reveals tool integration timing; recommend the verdict checkpoints that read from those captures — capture cadence and verdict cadence are different clocks.",
   "why": [
    "CaptureMacBookUnlocksReminder — recommends → BlockedByOldSetupReceipt"
   ],
   "score": 0.93,
   "generationFrame": {
    "id": "ToolLeverageVerdictFrame",
    "iri": "https://understood.app/ontology/project-recall#ToolLeverageVerdictFrame",
    "label": "Tool leverage verdict frame",
    "comment": "",
    "intent": "Generate feedback that separates expensive-tool delight from actual leverage while reactions are still fresh.",
    "mustInclude": [
     "evidence from a real task",
     "a leverage-versus-luxury verdict",
     "a time box for the verdict"
    ],
    "mustAvoid": [
     "repeating the user's MacBook wording",
     "spec comparison",
     "purchase justification"
    ]
   },
   "deepensStrengths": [
    "ToolIntegrationTiming"
   ]
  },
  {
   "id": "depth:RefundFantasyHour",
   "source": "depth",
   "type": "task",
   "title": "Refund the fantasy hour: if the machine did not save or create one real hour this week, name what still blocks leverage.",
   "sub": "A positively rated in-the-moment capture reveals tool integration timing; recommend the verdict checkpoints that read from those captures — capture cadence and verdict cadence are different clocks.",
   "why": [
    "CaptureMacBookUnlocksReminder — recommends → RefundFantasyHour"
   ],
   "score": 0.91,
   "generationFrame": {
    "id": "ToolLeverageVerdictFrame",
    "iri": "https://understood.app/ontology/project-recall#ToolLeverageVerdictFrame",
    "label": "Tool leverage verdict frame",
    "comment": "",
    "intent": "Generate feedback that separates expensive-tool delight from actual leverage while reactions are still fresh.",
    "mustInclude": [
     "evidence from a real task",
     "a leverage-versus-luxury verdict",
     "a time box for the verdict"
    ],
    "mustAvoid": [
     "repeating the user's MacBook wording",
     "spec comparison",
     "purchase justification"
    ]
   },
   "deepensStrengths": [
    "ToolIntegrationTiming"
   ]
  },
  {
   "id": "depth:ScheduleElectrifyingSource",
   "source": "depth",
   "type": "task",
   "title": "Name the source, then protect the hour after it; the afterglow is where the useful output appears.",
   "sub": "A positively rated source-taste reminder reveals strategic learning; recommend deeper uses of the same taste — the what and when of meaningful information, never the where.",
   "why": [
    "NameMeaningfulSourceReminder — recommends → ScheduleElectrifyingSource"
   ],
   "score": 0.98,
   "generationFrame": {
    "id": "StrategicLearningOutputFrame",
    "iri": "https://understood.app/ontology/project-recall#StrategicLearningOutputFrame",
    "label": "Strategic learning output frame",
    "comment": "",
    "intent": "Generate feedback that traces an energizing source to a protected output window or concrete decision.",
    "mustInclude": [
     "the source-to-state change",
     "the output or decision it should produce",
     "when to protect the useful window"
    ],
    "mustAvoid": [
     "repeating the user's source wording",
     "a generic reading list",
     "tracking entertainment instead of leverage"
    ]
   },
   "deepensStrengths": [
    "StrategicLearning"
   ]
  },
  {
   "id": "depth:MeditateOnVisualPerception",
   "source": "depth",
   "type": "task",
   "title": "Track the spark-to-output chain: what input made you sharper, and what did it make you build or decide?",
   "sub": "A positively rated source-taste reminder reveals strategic learning; recommend deeper uses of the same taste — the what and when of meaningful information, never the where.",
   "why": [
    "NameMeaningfulSourceReminder — recommends → MeditateOnVisualPerception"
   ],
   "score": 0.94,
   "generationFrame": {
    "id": "StrategicLearningOutputFrame",
    "iri": "https://understood.app/ontology/project-recall#StrategicLearningOutputFrame",
    "label": "Strategic learning output frame",
    "comment": "",
    "intent": "Generate feedback that traces an energizing source to a protected output window or concrete decision.",
    "mustInclude": [
     "the source-to-state change",
     "the output or decision it should produce",
     "when to protect the useful window"
    ],
    "mustAvoid": [
     "repeating the user's source wording",
     "a generic reading list",
     "tracking entertainment instead of leverage"
    ]
   },
   "deepensStrengths": [
    "StrategicLearning"
   ]
  },
  {
   "id": "depth:CaptureTimingFingerprint",
   "source": "depth",
   "type": "task",
   "title": "Capture the timing fingerprint: what time, state, and source made the idea land hard enough to use?",
   "sub": "A positively rated source-taste reminder reveals strategic learning; recommend deeper uses of the same taste — the what and when of meaningful information, never the where.",
   "why": [
    "NameMeaningfulSourceReminder — recommends → CaptureTimingFingerprint"
   ],
   "score": 0.92,
   "generationFrame": {
    "id": "StrategicLearningOutputFrame",
    "iri": "https://understood.app/ontology/project-recall#StrategicLearningOutputFrame",
    "label": "Strategic learning output frame",
    "comment": "",
    "intent": "Generate feedback that traces an energizing source to a protected output window or concrete decision.",
    "mustInclude": [
     "the source-to-state change",
     "the output or decision it should produce",
     "when to protect the useful window"
    ],
    "mustAvoid": [
     "repeating the user's source wording",
     "a generic reading list",
     "tracking entertainment instead of leverage"
    ]
   },
   "deepensStrengths": [
    "StrategicLearning"
   ]
  },
  {
   "id": "depth:TurnSourceIntoAppointment",
   "source": "depth",
   "type": "task",
   "title": "Turn the source into an appointment: protect the next window where it can become a draft, decision, or call.",
   "sub": "A positively rated source-taste reminder reveals strategic learning; recommend deeper uses of the same taste — the what and when of meaningful information, never the where.",
   "why": [
    "NameMeaningfulSourceReminder — recommends → TurnSourceIntoAppointment"
   ],
   "score": 0.9,
   "generationFrame": {
    "id": "StrategicLearningOutputFrame",
    "iri": "https://understood.app/ontology/project-recall#StrategicLearningOutputFrame",
    "label": "Strategic learning output frame",
    "comment": "",
    "intent": "Generate feedback that traces an energizing source to a protected output window or concrete decision.",
    "mustInclude": [
     "the source-to-state change",
     "the output or decision it should produce",
     "when to protect the useful window"
    ],
    "mustAvoid": [
     "repeating the user's source wording",
     "a generic reading list",
     "tracking entertainment instead of leverage"
    ]
   },
   "deepensStrengths": [
    "StrategicLearning"
   ]
  }
 ],
 "seeds": {
  "ScanCalendarReminder": {
   "id": "ScanCalendarReminder",
   "label": "Scan calendar reminder",
   "text": "Scan my calendar before the day starts.",
   "revealsStrengths": [
    "TimeAwareness"
   ]
  },
  "FindLeveragePointReminder": {
   "id": "FindLeveragePointReminder",
   "label": "Find leverage point reminder",
   "text": "Before adding effort, find the smallest move that could change the most outcomes.",
   "revealsStrengths": [
    "LeverageAwareness",
    "ExecutionLeverage"
   ]
  },
  "ChooseCommunicationFormatReminder": {
   "id": "ChooseCommunicationFormatReminder",
   "label": "Choose communication format reminder",
   "text": "Before replying, choose the format that lets the other person use the message.",
   "revealsStrengths": [
    "FormatJudgment",
    "CommunicationFit"
   ]
  },
  "HabitStackGymReminder": {
   "id": "HabitStackGymReminder",
   "label": "Habit stack at the gym",
   "text": "First arrival at the gym: after shooting around, foam roll the lower body for two minutes.",
   "revealsStrengths": [
    "HabitStacking"
   ]
  },
  "TranslateAIWeekReminder": {
   "id": "TranslateAIWeekReminder",
   "label": "Translate the week in AI",
   "text": "Pick one person. Give them the full picture: what changed in AI this week and what it means for them.",
   "revealsStrengths": [
    "KnowledgeSynthesis"
   ]
  },
  "CaptureMacBookUnlocksReminder": {
   "id": "CaptureMacBookUnlocksReminder",
   "label": "Capture the MacBook unlocks",
   "text": "Jot two incredible unlocks the beast-of-a-laptop has delivered today — or has it been a joke how average $7,000 feels?",
   "revealsStrengths": [
    "ToolIntegrationTiming"
   ]
  },
  "NameMeaningfulSourceReminder": {
   "id": "NameMeaningfulSourceReminder",
   "label": "Name the electrifying source",
   "text": "What new information mattered today — and when did it matter? Name the source worth keeping.",
   "revealsStrengths": [
    "StrategicLearning"
   ]
  }
 },
 "strengths": [
  "TimeAwareness",
  "LeverageAwareness",
  "ExecutionLeverage",
  "FormatJudgment",
  "CommunicationFit",
  "HabitStacking",
  "KnowledgeSynthesis",
  "ToolIntegrationTiming",
  "StrategicLearning",
  "TransitionPreparation",
  "EvidenceTrust"
 ],
 "adjacency": {
  "TimeAwareness": {
   "TransitionPreparation": 1
  },
  "LeverageAwareness": {
   "ExecutionLeverage": 1
  },
  "ExecutionLeverage": {
   "LeverageAwareness": 0.6666666666666666,
   "EvidenceTrust": 0.3333333333333333
  },
  "FormatJudgment": {
   "CommunicationFit": 0.75,
   "EvidenceTrust": 0.25
  },
  "CommunicationFit": {
   "FormatJudgment": 0.75,
   "EvidenceTrust": 0.25
  },
  "HabitStacking": {},
  "KnowledgeSynthesis": {},
  "ToolIntegrationTiming": {},
  "StrategicLearning": {},
  "TransitionPreparation": {
   "TimeAwareness": 1
  },
  "EvidenceTrust": {
   "ExecutionLeverage": 0.3333333333333333,
   "FormatJudgment": 0.3333333333333333,
   "CommunicationFit": 0.3333333333333333
  }
 },
 "signalDeltas": {
  "edit": 0.3,
  "positive": 0.15,
  "accept": 0.1,
  "dismiss": -0.1
 }
};
