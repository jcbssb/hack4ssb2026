"""Extract the input cells of the 20Byggesak PDF with their background colour.

Dark grey (0.47) = calculated or prefilled by SSB, light grey (0.82) = opens on "Ja" or a
number > 0 elsewhere, none = normal field. Writes pdfboxes.json and prints one grid per
section (E/D/L kind, sample value, * = required mark detected above the box; the latter is
unreliable and was checked on page images). Used for research/byggesak-trial6-audit.md.

    pip install pymupdf
    python research/pdf-audit/pdfgrid.py
"""
import pymupdf, json, re, os
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
doc = pymupdf.open(os.path.join(ROOT, "screenshots", "20Byggesak (utfylt).pdf"))
HEADINGS = ["B Gebyrer", "C10. Antall byggesøknader", "C11. Rammesøknader. Antall", "C12. Ett-trinnssøknader MED", "C13. Ett-trinnssøknader UTEN",
            "C14. TIL SUMMERINGSKONTROLL", "C15. Dispensasjonssøknader. Antall", "C16. Igangsettingstillatelser", "C2. Oppretting og endring",
            "C11 - C2 Byggesøknader", "C3. Oppmålingsforretninger. Antall", "C4. Eierseksjoneringssaker. Antall", "D1. Resultat av byggesaksbehandling",
            "D2. Resultat av behandling", "D1 - D2. Resultat", "E Klagesaksbehandling", "E1. Antall klagesaker", "E2. Klagesaker oversendt",
            "F Utøvelse av tilsyn", "F1. Antall tiltak som det er", "F2. Antall tilsyn og", "F3. Antall utførte tilsyn", "F4. Konklusjon av tilsynet",
            "G Pålegg, sanksjoner", "G1. Antall pålegg gitt", "G2. Antall oppfølginger", "G3. Antall sanksjoner brukt", "G4. Antall andre virkemidler",
            "H Kommentarer", "I Grunnlag for rapportering"]
marks = []  # (page, y, heading)
for pno, page in enumerate(doc):
    for h in HEADINGS:
        for r in page.search_for(h):
            marks.append((pno, r.y0, h))
marks.sort()
def section(pno, y):
    cur = "A"
    for (p, yy, h) in marks:
        if (p, yy) <= (pno, y): cur = h
    return cur
def gray(f): return None if f is None else round(f[0], 2)
boxes = []
for pno, page in enumerate(doc):
    drawings = page.get_drawings()
    bgs = [(d["rect"], gray(d["fill"])) for d in drawings if d.get("fill") is not None and gray(d["fill"]) in (0.47, 0.82) and d["rect"].width > 30 and d["rect"].height > 15]
    words = page.get_text("words")
    for d in drawings:
        r = d["rect"]
        if d.get("fill") is not None and gray(d["fill"]) == 0.96 and 30 <= r.width <= 110 and 10 <= r.height <= 13:
            bg = next((g for (br, g) in bgs if br.contains(pymupdf.Point(r.x0 + 2, r.y0 + 2))), None)
            val = " ".join(w[4] for w in words if r.x0 - 1 <= w[0] and w[2] <= r.x1 + 1 and r.y0 - 1 <= w[1] and w[3] <= r.y1 + 2)
            star = any(w[4] == "*" and abs(w[0] - r.x0) < 8 and 0 < r.y0 - w[3] < 8 for w in words)
            label = " ".join(w[4] for w in words if w[2] < 215 and abs(w[1] - r.y0) < 7)[:60]
            boxes.append(dict(page=pno + 1, x=round(r.x0), y=round(r.y0), w=round(r.width), kind={0.47: "D", 0.82: "L", None: "E"}[bg],
                              val=val, star=star, label=label, sec=section(pno, r.y0)))
json.dump(boxes, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "pdfboxes.json"), "w"), ensure_ascii=False, indent=1)
# print grid per section
from itertools import groupby
for sec, bs in groupby(boxes, key=lambda b: b["sec"]):
    bs = list(bs)
    xs = sorted({b["x"] for b in bs})
    print(f"\n== {sec}  ({len(bs)} boxes)")
    for (p, y), row in groupby(sorted(bs, key=lambda b: (b["page"], b["y"], b["x"])), key=lambda b: (b["page"], b["y"])):
        row = list(row)
        cells = {b["x"]: b for b in row}
        line = " ".join((("*" if cells[x]["star"] else " ") + cells[x]["kind"] + ":" + (cells[x]["val"] or "-")[:6]).ljust(10) if x in cells else " " * 10 for x in xs)
        print(f"  p{p} {row[0]['label'][:38]:38} | {line}")
