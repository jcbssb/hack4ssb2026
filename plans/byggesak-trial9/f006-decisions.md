# F-006 Decision Record: DSL-Only Consistency & Plausibility Checks

**Form:** 20 Byggesak  
**Scope:** Finding F-006 (297 DSL-only constraints and check partner diffs)  
**Status:** Decided & implemented in Trial 9 (`SchemaDSL.Examples.ByggesakTrial9`)

---

## Background
The legacy XML4DR form (2012–2020) omitted many cross-table consistency and plausibility checks that were introduced in modern Dialogue Schema DSL (Trial 5 onwards) from SSB guidance and form definitions. In the alignment audit against `20Byggesak.xml`, these checks were reported as a 297-item finding (F-006).

In Trial 9, F-006 was split into 6 domain families and evaluated:

| Family | Sub-Finding | Title | Items | Decision | Severity | Rationale |
|---|---|---|---|---|---|---|
| 1 | **F-006a** | `overFrist <= behandlet` | 81 | **Keep as Warning** | `SevWarning` | Plausibility check. Cases processed over deadline cannot exceed total cases processed in that category, but non-blocking warning prevents edge-case blocking. |
| 2 | **F-006b** | `ikkeNegativ` | 12 | **Keep as Error** | `SevError` | Physical integrity rule. Number of applications/decisions cannot be negative numbers (`< 0`). Enforced strictly. |
| 3 | **F-006c** | Outcome sums (`utfall`, `innvilget`, `konklusjon`) | 72 | **Keep as Warning** | `SevWarning` | Logical consistency. Approved + rejected cases should not exceed total processed cases, but reporting edge cases make a soft warning appropriate. |
| 4 | **F-006d** | Processed vs received (`behandlet <= mottatt`) | 18 | **Keep as Warning** | `SevWarning` | Prior-year backlog reality. Cases received in year N-1 can be processed in year N, causing `behandlet > mottatt`. Must be non-blocking. |
| 5 | **F-006e** | Plan & 3-week deadlines (`samsvar`, `treUker`, `mangelfulle`) | 9 | **Keep as Warning** | `SevWarning` | Domain sanity check. 3-week cases should not exceed plan-compliant totals. Soft warning alerts caseworker without blocking. |
| 6 | **F-006f** | Domain sub-breakdowns (`herav`, `typer`, `universell`) | 105 | **Keep as Warning** | `SevWarning` | Category integrity. Sub-types should not exceed category totals. Soft warning highlights inconsistencies. |

---

## Implementation in Trial 9
- In `SchemaDSL.Examples.ByggesakTrial9`:
  - `t9bConstraintSeverities` softens families F-006a, F-006c, F-006d, F-006e, and F-006f to `SevWarning`.
  - F-006b (`ikkeNegativ`) retains `SevError`.
- In `dsl/audit/findings/byggesak.json`:
  - Split into findings `F-006a` through `F-006f`, all marked `status: "accepted"`.
  - Untriaged diffs: **0**.
- In Simulators & Altinn:
  - `SevWarning` renders as non-blocking amber warning badges in both the React simulator and Altinn expression validations.
