// Pure relation logic over the facts JSON written by `schema-audit extract`.
// Shared by the canvas server (agent summaries) and the browser UI.

const REF = /"([^"]+)"\s*,\s*"([^"]+)"/g;

export function refsOfEval(ev) {
    const out = [];
    for (const m of (ev || "").matchAll(REF)) out.push(`${m[1]}/${m[2]}`);
    return out;
}

export function buildIndex(facts) {
    const byKey = new Map(facts.cells.map((c) => [c.key, c]));
    const calcIn = new Map(), checkRefs = new Map(), gates = new Map();
    const calcOut = new Map(), checkBy = new Map(), gatedByRev = new Map();
    const push = (m, k, v) => { if (!m.has(k)) m.set(k, new Set()); m.get(k).add(v); };
    for (const c of facts.cells) {
        for (const hid of c.handlers) {
            const h = facts.handlers[hid];
            if (!h) continue;
            const add = (m1, m2, r) => { if (r !== c.key && byKey.has(r)) { push(m1, c.key, r); push(m2, r, c.key); } };
            if (h.type === "calculation") for (const r of refsOfEval(h.eval)) add(calcIn, calcOut, r);
            else if (h.type === "guidance") { for (const a of h.actions) for (const e of a.effects) for (const t of e.targets || []) add(gates, gatedByRev, t); }
            else for (const r of refsOfEval(h.eval)) add(checkRefs, checkBy, r);
        }
    }
    const sections = facts.sections;
    return { facts, byKey, calcIn, checkRefs, gates, calcOut, checkBy, gatedByRev, sections };
}

function closure(map, start, depth) {
    const seen = new Map();
    let frontier = [start];
    for (let d = 1; d <= depth && frontier.length; d++) {
        const next = [];
        for (const k of frontier) for (const n of map.get(k) || []) if (n !== start && !seen.has(n)) { seen.set(n, d); next.push(n); }
        frontier = next;
    }
    return seen; // key -> distance
}

export function relationsOf(idx, key, depth = 3) {
    const c = idx.byKey.get(key);
    if (!c) return null;
    const sameSet = [...idx.byKey.values()].filter((o) => o.set === c.set && o.key !== key);
    const chk = new Set([...(idx.checkRefs.get(key) || []), ...(idx.checkBy.get(key) || [])]);
    const gate = new Set([...(idx.gates.get(key) || []), ...(idx.gatedByRev.get(key) || [])]);
    return {
        up: closure(idx.calcIn, key, depth),
        down: closure(idx.calcOut, key, depth),
        chk, gate,
        gates: new Set(idx.gates.get(key) || []),
        gatedBy: new Set(idx.gatedByRev.get(key) || []),
        row: new Set(sameSet.filter((o) => o.row === c.row).map((o) => o.key)),
        col: new Set(sameSet.filter((o) => o.col === c.col).map((o) => o.key)),
    };
}

export function label(c) {
    return (c.text[0] || c.rowLabel[0] || c.header[0] || c.data).slice(0, 80);
}

// Compact text summary for the agent.
export function summarize(idx, key, depth = 3) {
    const c = idx.byKey.get(key);
    if (!c) return null;
    const r = relationsOf(idx, key, depth);
    const fmt = (keys) => [...keys].map((k) => `${k} [${idx.byKey.get(k).kind}] ${label(idx.byKey.get(k))}`);
    return {
        key, kind: c.kind, required: c.required, row: c.row, col: c.col,
        rowLabel: c.rowLabel[0], header: c.header[0],
        feedsFrom: fmt(r.up.keys()), feeds: fmt(r.down.keys()),
        checkedAgainst: fmt(r.chk), gates: fmt(r.gates), gatedBy: fmt(r.gatedBy),
    };
}
