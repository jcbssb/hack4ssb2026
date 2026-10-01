// Extension: skjemakart
// Canvas to navigate the XML4DR analysis (sections, cells) and highlight relations:
// calculation chains, gating (light-grey opens), and constraint partners.

import { createServer } from "node:http";
import { readFile, access } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { joinSession, createCanvas, CanvasError } from "@github/copilot-sdk/extension";
import { auditFiles } from "./audits.mjs";
import { buildIndex, summarize } from "./relations.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const FACTS_REL = "incoming-skjema-observations/.derived/20Byggesak.facts.json";
const entries = new Map(); // instanceId -> { server, url, state }

async function findFacts(explicit) {
    if (explicit) return resolve(explicit);
    let dir = resolve(here, "..", "..");
    const p = join(dir, FACTS_REL);
    await access(p).catch(() => { throw new CanvasError("facts_missing", `Facts not found at ${p}. Run: cd dsl && cabal run -v0 schema-audit -- extract <xml> ../${FACTS_REL}`); });
    return p;
}

async function startServer(state) {
    const server = createServer(async (req, res) => {
        try {
            const url = new URL(req.url, "http://x");
            if (url.pathname === "/") return send(res, "text/html; charset=utf-8", await readFile(join(here, "ui.html")));
            if (url.pathname === "/relations.mjs") return send(res, "text/javascript", await readFile(join(here, "relations.mjs")));
            if (url.pathname === "/api/facts") return send(res, "application/json", await readFile(state.factsPath));
            { const ar = await auditFiles(state.factsPath).route(url); if (ar !== undefined) return send(res, "application/json", ar); }
            if (url.pathname === "/api/state") return send(res, "application/json", JSON.stringify({ selected: state.selected, rev: state.rev }));
            if (url.pathname === "/api/select" && req.method === "POST") {
                let body = ""; for await (const ch of req) body += ch;
                state.selected = JSON.parse(body).key; // UI-originated, no rev bump
                return send(res, "application/json", "{}");
            }
            res.statusCode = 404; res.end("not found");
        } catch (e) { res.statusCode = 500; res.end(String(e)); }
    });
    await new Promise((r) => server.listen(0, "127.0.0.1", r));
    return { server, url: `http://127.0.0.1:${server.address().port}/` };
}

function send(res, type, body) { res.setHeader("Content-Type", type); res.end(body); }

const session = await joinSession({
    canvases: [
        createCanvas({
            id: "skjemakart",
            displayName: "Skjemakart",
            description: "Navigate the XML4DR form analysis: pick a cell to highlight calculation chains, gating and constraint relations.",
            inputSchema: { type: "object", properties: { factsPath: { type: "string", description: "Facts JSON from `schema-audit extract` (default: 20Byggesak)" }, select: { type: "string", description: "Initial cell key, e.g. Section7/V2015_92" } } },
            actions: [
                {
                    name: "select",
                    description: "Select a cell by key (e.g. Section7/V2015_92) in the UI and return its relations summary.",
                    inputSchema: { type: "object", properties: { key: { type: "string" }, depth: { type: "number" } }, required: ["key"] },
                    handler: async (ctx) => {
                        const e = entries.get(ctx.instanceId);
                        if (!e) throw new CanvasError("not_open", "Canvas instance is not open");
                        const idx = buildIndex(JSON.parse(await readFile(e.state.factsPath, "utf8")));
                        const s = summarize(idx, ctx.input.key, ctx.input.depth ?? 3);
                        if (!s) throw new CanvasError("unknown_cell", `No cell ${ctx.input.key}`);
                        e.state.selected = ctx.input.key; e.state.rev++;
                        return s;
                    },
                },
            ],
            open: async (ctx) => {
                let e = entries.get(ctx.instanceId);
                if (!e) {
                    const state = { factsPath: await findFacts(ctx.input?.factsPath), selected: ctx.input?.select ?? null, rev: 0 };
                    e = { ...(await startServer(state)), state };
                    entries.set(ctx.instanceId, e);
                }
                return { title: "Skjemakart", url: e.url };
            },
            onClose: async (ctx) => {
                const e = entries.get(ctx.instanceId);
                if (e) { entries.delete(ctx.instanceId); await new Promise((r) => e.server.close(() => r())); }
            },
        }),
    ],
});
