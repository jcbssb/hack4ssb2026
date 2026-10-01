#!/usr/bin/env bash
# Regenerate the derived Skjemakart audit inputs for 20Byggesak, one set per DSL trial:
#   .derived/20Byggesak.{align,findings}.<tag>.json  where <tag> is e.g. trial7 for dsl/schemas/trial7-byggesak.json.
# Usage: refresh.sh [tag...]   (default: every dsl/schemas/trialN-byggesak.json with N >= 7)
# Facts: `schema-audit extract` (only when the XML changes). The DSL JSON must be current (`cabal run schema-dsl-cli` writes schemas/).
set -euo pipefail
cd "$(dirname "$0")/../../dsl"
X=../incoming-skjema-observations/byggesak-20/20Byggesak.xml
D=../incoming-skjema-observations/.derived

# Ensure schemas are generated from the DSL if missing
if [ ! -d schemas ] || ! compgen -G "schemas/trial*-byggesak.json" > /dev/null; then
  echo "Schemas missing; generating via schema-dsl-cli --update-all..."
  cabal run -v0 schema-dsl-cli -- --update-all
fi

tags=("$@"); [ ${#tags[@]} -eq 0 ] && for f in schemas/trial*-byggesak.json; do t=${f#schemas/}; t=${t%-byggesak.json}; [ "${t#trial}" -ge 7 ] && tags+=("$t"); done
for t in "${tags[@]}"; do
  DSL=schemas/$t-byggesak.json
  if [ ! -f "$DSL" ]; then
    echo "$DSL missing; generating via schema-dsl-cli --update-all..."
    cabal run -v0 schema-dsl-cli -- --update-all
  fi
  [ -f "$DSL" ] || { echo "no $DSL" >&2; exit 1; }
  # Only trials with a field-level DSL for this form are auditable (alignment needs the t7+ field naming); skip failures quietly for older trials.
  if cabal run -v0 schema-audit -- align-json "$X" "$DSL" audit/alignment/byggesak.json "$D/20Byggesak.align.$t.json" >/dev/null 2>&1; then
    echo "== $t"
    cabal run -v0 schema-audit -- audit "$X" "$DSL" audit/alignment/byggesak.json audit/findings/byggesak.json "$D/20Byggesak.findings.$t.json" 2>/dev/null | grep -v '^  ?' | tail -3 || true
  else echo "== $t skipped (not alignable)"; fi
done
echo "refreshed; open Skjemakart pages will offer a reload"
