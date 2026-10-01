# 04 Build, dependencies, CI

- **One-command setup**: `scripts/setup.sh` checks/installs GHC+cabal (ghcup), Node ≥ 20, Python ≥ 3.10 (venv, `requirements.txt`: pymupdf), then `cabal build all` and `npm ci`.
- **Reproducible**: pin GHC via `cabal.project` + `index-state`; commit `cabal.project.freeze`; `package-lock.json`.
- **Dev container / Nix flake** (optional) for zero-install onboarding and for agents in cloud sandboxes.
- **Single entry point**: `make` (or `just`) targets: `build`, `test`, `audit CASE=…`, `compile CASE=…`, `simulate`, `check`.
- **Config, no hardcoded paths**: `skjemantikk.toml`/env for workspace dir, altinn app output dir, simulator sync target.
- **CI (GitHub Actions)**: build+test Haskell (cache), lint (hlint, ormolu), simulator typecheck/build, golden tests on example schemas, a secret/PII scan, and a check that no `workspace/` files are tracked.
- **Tests**: golden tests for DSL→JSON/Altinn on synthetic examples; property tests for the Eval parser round-trip; a "tiny synthetic XML4DR" fixture so audit tools are testable without real data.
- **Releases**: tagged versions, changelog, prebuilt `schema-dsl-cli`/`schema-audit` binaries (macOS/Linux/Windows) via release workflow.
