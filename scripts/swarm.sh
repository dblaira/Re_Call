#!/usr/bin/env bash
# Launch parallel cursor-agent workers in isolated worktrees.
# Usage: ./scripts/swarm.sh "feature name" "ontology prompt" "ios prompt"
set -euo pipefail
cd "$(dirname "$0")/.."

FEATURE="${1:?feature name}"
ONTOLOGY_PROMPT="${2:?ontology worker prompt}"
IOS_PROMPT="${3:?ios worker prompt}"

cursor-agent -p --trust --worktree "${FEATURE}-ontology" --worktree-base HEAD \
  "Re_Call repo. ${ONTOLOGY_PROMPT} Run ontology/validate.sh and npm test for touched engine files. Stop when done." &

cursor-agent -p --trust --worktree "${FEATURE}-ios" --worktree-base HEAD \
  "Re_Call repo. ${IOS_PROMPT} Read HANDOFF.md first. Run ./qc.sh when done. Stop when done." &

wait
echo "Workers finished. Review worktrees under ~/.cursor/worktrees/Re_Call/"
