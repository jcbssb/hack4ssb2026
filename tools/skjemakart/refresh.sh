#!/usr/bin/env bash
# Regenerate the derived Skjemakart inputs (align + findings) for 20Byggesak. Facts: `schema-audit extract` (only when the XML changes).
set -euo pipefail
cd "$(dirname "$0")/../../dsl"
X=../incoming-skjema-observations/byggesak-20/20Byggesak.xml
D=../incoming-skjema-observations/.derived
DSL=${DSL:-schemas/trial7-byggesak.json}
cabal run -v0 schema-audit -- align-json "$X" "$DSL" audit/alignment/byggesak.json "$D/20Byggesak.align.json"
cabal run -v0 schema-audit -- audit "$X" "$DSL" audit/alignment/byggesak.json audit/findings/byggesak.json "$D/20Byggesak.findings.json" 2>/dev/null | grep -v '^  ?' || true
echo "refreshed; open Skjemakart pages will offer a reload"
