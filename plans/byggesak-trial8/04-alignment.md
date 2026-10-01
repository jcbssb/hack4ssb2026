# Step 3 – Alignment

_Part of [Trial 8 plan](README.md). Phase P3._

DSL field names (`t7_c11_1_1_a`) and XML4DR ids (set `Section12`, tuple `Row3_…`,
data `C11_1_1_a`?) use different schemes, and PDF is positional. Align in layers, each
reporting confidence:

1. **Structural id mapping** – derive (section, row, col) from XML4DR tuple/data ids and from
   the DSL naming convention (`t<N>_<bolk>_<row>_<col>`); exact match first.
2. **Label match** – normalized nb text (row label + column label) fuzzy match for the remainder.
3. **PDF position/value** – use example values (e.g. 12, 45, 579) as tie-breakers; the Trial 6
   audit already established row/col grids for the PDF.
4. **Manual override file** `alignment-overrides.json` (checked in) for the leftovers; every
   override lists a reason. Goal: ≥ 95 % auto-aligned, rest explained.

Output: `matched`, `xml-only`, `pdf-only`, `dsl-only`, `ambiguous`.
