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
   "deepensStrengths": [
    "TimeAwareness",
    "TransitionPreparation"
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
   "deepensStrengths": [
    "LeverageAwareness",
    "ExecutionLeverage"
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
   "deepensStrengths": [
    "FormatJudgment",
    "CommunicationFit"
   ]
  },
  {
   "id": "depth:FoamRollFiveByFive",
   "source": "depth",
   "type": "task",
   "title": "The stack graduates: foam roll five times this week, five minutes each.",
   "sub": "A positively rated gym habit stack reveals habit stacking; recommend leveling the same stack up toward the ultimate goal rather than broader fitness reminders.",
   "why": [
    "HabitStackGymReminder — recommends → FoamRollFiveByFive"
   ],
   "score": 1,
   "deepensStrengths": [
    "HabitStacking"
   ]
  },
  {
   "id": "depth:StackSecondMicrodose",
   "source": "depth",
   "type": "task",
   "title": "Attach one more two-minute microdose to an anchor habit you already love.",
   "sub": "A positively rated gym habit stack reveals habit stacking; recommend leveling the same stack up toward the ultimate goal rather than broader fitness reminders.",
   "why": [
    "HabitStackGymReminder — recommends → StackSecondMicrodose"
   ],
   "score": 0.93,
   "deepensStrengths": [
    "HabitStacking"
   ]
  },
  {
   "id": "depth:StandingAIDigestGesture",
   "source": "depth",
   "type": "task",
   "title": "Make it a standing gesture: a weekly AI briefing for a named circle — Stephanie, the sauna crew, or bigger.",
   "sub": "A positively rated AI translation reminder reveals knowledge synthesis; recommend grander, more organized gestures of the same service — never smaller steps, which the user dismisses.",
   "why": [
    "TranslateAIWeekReminder — recommends → StandingAIDigestGesture"
   ],
   "score": 1.01,
   "deepensStrengths": [
    "KnowledgeSynthesis"
   ]
  },
  {
   "id": "depth:TranslateForOneDecision",
   "source": "depth",
   "type": "task",
   "title": "Translate this week's AI shift into one decision someone you know should make differently.",
   "sub": "A positively rated AI translation reminder reveals knowledge synthesis; recommend grander, more organized gestures of the same service — never smaller steps, which the user dismisses.",
   "why": [
    "TranslateAIWeekReminder — recommends → TranslateForOneDecision"
   ],
   "score": 0.95,
   "deepensStrengths": [
    "KnowledgeSynthesis"
   ]
  },
  {
   "id": "depth:TwoWeekVerdictLedger",
   "source": "depth",
   "type": "task",
   "title": "Day 14: rule on the MacBook — benefits and drawbacks, read straight from your captured memos.",
   "sub": "A positively rated in-the-moment capture reveals tool integration timing; recommend the verdict checkpoints that read from those captures — capture cadence and verdict cadence are different clocks.",
   "why": [
    "CaptureMacBookUnlocksReminder — recommends → TwoWeekVerdictLedger"
   ],
   "score": 0.99,
   "deepensStrengths": [
    "ToolIntegrationTiming"
   ]
  },
  {
   "id": "depth:WeekOneAdamPatternCheck",
   "source": "depth",
   "type": "task",
   "title": "Day 7: Adam Pattern steps 1-3 done? Log what the third machine does that the other two can't.",
   "sub": "A positively rated in-the-moment capture reveals tool integration timing; recommend the verdict checkpoints that read from those captures — capture cadence and verdict cadence are different clocks.",
   "why": [
    "CaptureMacBookUnlocksReminder — recommends → WeekOneAdamPatternCheck"
   ],
   "score": 0.95,
   "deepensStrengths": [
    "ToolIntegrationTiming"
   ]
  },
  {
   "id": "depth:ScheduleElectrifyingSource",
   "source": "depth",
   "type": "task",
   "title": "Block the when: put your most electrifying source on the calendar before entertainment fills it.",
   "sub": "A positively rated source-taste reminder reveals strategic learning; recommend deeper uses of the same taste — the what and when of meaningful information, never the where.",
   "why": [
    "NameMeaningfulSourceReminder — recommends → ScheduleElectrifyingSource"
   ],
   "score": 0.98,
   "deepensStrengths": [
    "StrategicLearning"
   ]
  },
  {
   "id": "depth:MeditateOnVisualPerception",
   "source": "depth",
   "type": "task",
   "title": "Open 'Drawing by Seeing' — meditate on visual perception for ten minutes.",
   "sub": "A positively rated source-taste reminder reveals strategic learning; recommend deeper uses of the same taste — the what and when of meaningful information, never the where.",
   "why": [
    "NameMeaningfulSourceReminder — recommends → MeditateOnVisualPerception"
   ],
   "score": 0.94,
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
