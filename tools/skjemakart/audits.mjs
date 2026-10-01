// Shared audit-file helpers for the standalone server and the canvas extension.
import { readFile, readdir, stat } from "node:fs/promises";
import { basename, dirname, join } from "node:path";

export function auditFiles(facts) {
    const base = facts.replace(/\.facts\.json$/, "");
    // Audits are per DSL trial: <base>.align.<tag>.json + <base>.findings.<tag>.json (tag e.g. trial7, trial8)
    const tagOf = (u) => { const t = u.searchParams.get("audit") ?? ""; return /^[\w-]+$/.test(t) ? t : ""; };
    const tagFile = (kind, tag) => `${base}.${kind}.${tag}.json`;
    async function audits() {
        const pre = basename(base) + ".align.";
        const names = (await readdir(dirname(base))).filter((n) => n.startsWith(pre) && n.endsWith(".json"));
        const out = [];
        for (const n of names) {
            const tag = n.slice(pre.length, -5);
            const al = JSON.parse(await readFile(join(dirname(base), n), "utf8"));
            const cells = {}; for (const v of Object.values(al.cells ?? {})) cells[v.status] = (cells[v.status] ?? 0) + 1;
            const fd = JSON.parse(await readFile(tagFile("findings", tag), "utf8").catch(() => "{}"));
            const items = {}; for (const f of fd.findings ?? []) items[f.id] = f.items?.length ?? 0;
            out.push({ tag, cells, dslOnly: (al.dslOnly ?? []).length, untriaged: (fd.untriaged ?? []).length, items });
        }
        return out.sort((x, y) => x.tag.localeCompare(y.tag, undefined, { numeric: true }));
    }
    async function derivedRev(tag) {
        const o = { facts: (await stat(facts).catch(() => null))?.mtimeMs ?? 0 };
        for (const k of ["align", "findings"]) o[k] = (await stat(tagFile(k, tag)).catch(() => null))?.mtimeMs ?? 0;
        return JSON.stringify(o);
    }
    // Handles /api/audits|align|findings|rev; returns undefined when the path is not an audit route.
    async function route(u) {
        const tag = tagOf(u), p = u.pathname;
        if (p === "/api/audits") return JSON.stringify(await audits());
        if (p === "/api/align") return (await readFile(tagFile("align", tag)).catch(() => '{"cells":{},"dslOnly":[]}'));
        if (p === "/api/findings") return (await readFile(tagFile("findings", tag)).catch(() => '{"findings":[],"cellFindings":[]}'));
        if (p === "/api/rev") return derivedRev(tag);
    }
    return { route };
}
