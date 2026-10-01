# 05 Improvements for a publicly useful repo (incl. international statistical orgs)

## Positioning
- Problem statement: modernising legacy survey/e-form definitions (XML4DR, Blaise, IDEAS/Colectica, paper PDFs) with a **verifiable, agent-assisted audit**, not one-off conversion.
- Align with community vocabulary: **DDI (Lifecycle/Codebook)**, **SDMX**, **GSBPM** (phase 4 Collect), **CSPA**, **UNECE HLG-MOS**. Provide a mapping table DSL ↔ DDI questionnaire concepts.

## Technical generalisation
1. **Source adapters** behind the neutral facts model: XML4DR today; add Blaise, DDI-L, XLSForm/ODK, Excel questionnaires, OCR of PDFs/screenshots.
2. **Target adapters**: Altinn 3 today; add generic JSON Schema + JSON Forms, XLSForm/ODK, DDI export, Blaise skeleton, static HTML preview. Document `adding-a-target.md`.
3. **i18n**: nb/nn today; make languages a first-class list (text resources per language, fallback rules); English docs and UI.
4. **Rules**: formalise the rule language (calculation, check with severity, gating) with a documented semantics and an interpreter shared by simulator and audit (single source of truth).
5. **Accessibility** (WCAG, Designsystemet) and **plain-language** guidance in simulator.
6. **Stable machine-readable outputs**: versioned JSON Schemas for facts, audit report and DSL AST; SARIF-like gap report for CI.
7. **Plugin points** for organisation-specific conventions (naming, bolk grouping, code lists).

## Trust and governance
- Licence + CLA/DCO, CONTRIBUTING, issue/PR templates, code of conduct, SECURITY (data-handling statement: tool runs locally, no data leaves).
- **AI usage statement**: which steps are agent-driven, human review points, reproducibility (tools are deterministic; agent only orchestrates).
- Synthetic demo dataset + hosted simulator demo (GitHub Pages) so people try it without Altinn or private data.
- Docs site (mdBook/Docusaurus), screencast of the audit → explorer → compile loop, DOI via Zenodo/CITATION.cff.
- Engage: present at UNECE/Eurostat workshops (e.g. ESS, HLG-MOS), invite statistical offices as co-maintainers; open "good first adapter" issues.
- Security/privacy: respondent data never needed; document that only form *definitions* are processed; secret scanning in CI.
