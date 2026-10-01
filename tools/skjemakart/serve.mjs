// Standalone Skjemakart server (no canvas needed): node tools/skjemakart/serve.mjs [port] [facts.json]
import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const port = Number(process.argv[2] ?? process.env.PORT ?? 8765);
const facts = resolve(process.argv[3] ?? join(here, "../../incoming-skjema-observations/.derived/20Byggesak.facts.json"));
const align = facts.replace(/\.facts\.json$/, ".align.json");
const state = { selected: null, rev: 0 };
const send = (res, type, body) => { res.setHeader("Content-Type", type); res.end(body); };

createServer(async (req, res) => {
    try {
        const p = new URL(req.url, "http://x").pathname;
        if (p === "/") return send(res, "text/html; charset=utf-8", await readFile(join(here, "ui.html")));
        if (p === "/relations.mjs") return send(res, "text/javascript", await readFile(join(here, "relations.mjs")));
        if (p === "/api/facts") return send(res, "application/json", await readFile(facts));
        if (p === "/api/align") return send(res, "application/json", await readFile(align).catch(() => '{"cells":{},"dslOnly":[]}'));
        if (p === "/api/findings") return send(res, "application/json", await readFile(facts.replace(/\.facts\.json$/, ".findings.json")).catch(() => '{"findings":[],"cellFindings":[]}'));
        if (p === "/api/state") return send(res, "application/json", JSON.stringify(state));
        if (p === "/api/select" && req.method === "POST") {
            let b = ""; for await (const c of req) b += c;
            state.selected = JSON.parse(b).key;
            return send(res, "application/json", "{}");
        }
        res.statusCode = 404; res.end("not found");
    } catch (e) { res.statusCode = 500; res.end(String(e)); }
}).listen(port, "127.0.0.1", () => console.log(`Skjemakart on http://127.0.0.1:${port}/`));
