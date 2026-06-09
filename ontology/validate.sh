#!/usr/bin/env bash
# Re_Call ontology validation pipeline.
# Three checks, one command: syntax -> machine-readable -> queryable.
# Requires Docker (uses the stain/jena image; no host install needed).
#
# Usage:  ./validate.sh            # validate every .ttl + run the trace query
#         ./validate.sh foo.ttl    # validate a single file
set -euo pipefail

cd "$(dirname "$0")"
JENA=(docker run --rm -v "$PWD":/data stain/jena)
FILES=("${@:-}")
if [ -z "${FILES[0]}" ]; then
  FILES=(*.ttl)
fi

echo "== 1/3  Syntactic validation (riot --validate) =="
for f in "${FILES[@]}"; do
  if "${JENA[@]}" riot --validate "/data/$f" >/dev/null 2>&1; then
    n=$("${JENA[@]}" riot --output=NT "/data/$f" 2>/dev/null | wc -l | tr -d ' ')
    printf "  ok   %-32s %s triples\n" "$f" "$n"
  else
    printf "  FAIL %s\n" "$f"
    "${JENA[@]}" riot --validate "/data/$f" 2>&1 | sed 's/^/       /'
    exit 1
  fi
done

echo
echo "== 2/3  Canonical N-Triples snapshot =="
"${JENA[@]}" riot --output=NT /data/recall-seed.ttl 2>/dev/null > recall-seed.nt
echo "  wrote recall-seed.nt ($(wc -l < recall-seed.nt | tr -d ' ') triples)"

echo
echo "== 3/3  Undertow traversal (SPARQL) =="
"${JENA[@]}" sparql --data=/data/recall-seed.ttl --query=/data/queries/trace.rq --results=text 2>/dev/null

echo
echo "All checks passed. For logical consistency (OWL reasoning), open recall-seed.ttl"
echo "in Protege and run Reasoner > HermiT > Start reasoner."
