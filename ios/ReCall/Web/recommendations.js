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
  }
 ],
 "strengths": [
  "TimeAwareness",
  "LeverageAwareness",
  "ExecutionLeverage",
  "FormatJudgment",
  "CommunicationFit",
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
