import type { ExtensionAPI, ExtensionCommandContext, ExtensionContext, ToolResultEvent } from "@mariozechner/pi-coding-agent";
import { DynamicBorder } from "@mariozechner/pi-coding-agent";
import { Container, Key, Text, matchesKey, type Component, type TUI } from "@mariozechner/pi-tui";
import os from "node:os";
import path from "node:path";
import fs from "node:fs/promises";
import { existsSync } from "node:fs";

const formatUsd = (cost: number): string => {
    if (!Number.isFinite(cost) || cost <= 0) return "$0.00";
    if (cost >= 1) return `$${cost.toFixed(2)}`;
    if (cost >= 0.1) return `$${cost.toFixed(3)}`;
    return `$${cost.toFixed(4)}`;
};

const estimateTokens = (text: string) => Math.max(0, Math.ceil(text.length / 4));

function normalizePath(p: string, cwd: string): string {
    if (p.startsWith("@")) p = p.slice(1);
    if (p === "~") p = os.homedir();
    else if (p.startsWith("~/")) p = path.join(os.homedir(), p.slice(2));
    if (!path.isAbsolute(p)) p = path.resolve(cwd, p);
    return path.resolve(p);
}

function getAgentDir(): string {
    for (const k of ["PI_CODING_AGENT_DIR", "TAU_CODING_AGENT_DIR"]) {
        if (process.env[k]) return expandHome(process.env[k]!);
    }
    for (const [k, v] of Object.entries(process.env)) {
        if (k.endsWith("_CODING_AGENT_DIR") && v) return expandHome(v);
    }
    return path.join(os.homedir(), ".pi", "agent");
}

function expandHome(p: string): string {
    if (p === "~") return os.homedir();
    if (p.startsWith("~/")) return path.join(os.homedir(), p.slice(2));
    return p;
}

async function loadContextFiles(cwd: string): Promise<Array<{ path: string; tokens: number; bytes: number }>> {
    const out: Array<{ path: string; tokens: number; bytes: number }> = [];
    const seen = new Set<string>();

    const tryDir = async (dir: string) => {
        for (const name of ["AGENTS.md", "CLAUDE.md"]) {
            const p = path.join(dir, name);
            if (!existsSync(p) || seen.has(p)) continue;
            try {
                const buf = await fs.readFile(p);
                seen.add(p);
                out.push({ path: p, tokens: estimateTokens(buf.toString("utf8")), bytes: buf.byteLength });
                return;
            } catch { /* skip */ }
        }
    };

    await tryDir(getAgentDir());
    const stack: string[] = [];
    let cur = path.resolve(cwd);
    while (true) {
        stack.push(cur);
        const parent = path.resolve(cur, "..");
        if (parent === cur) break;
        cur = parent;
    }
    for (const dir of stack.reverse()) await tryDir(dir);
    return out;
}

const normalizeSkillName = (name: string) => name.startsWith("skill:") ? name.slice(6) : name;

type SkillEntry = { name: string; skillFilePath: string; skillDir: string };

function buildSkillIndex(pi: ExtensionAPI, cwd: string): SkillEntry[] {
    return pi.getCommands()
        .filter((c) => c.source === "skill")
        .map((c) => {
            const p = c.sourceInfo?.path ? normalizePath(c.sourceInfo.path, cwd) : "";
            return { name: normalizeSkillName(c.name), skillFilePath: p, skillDir: p ? path.dirname(p) : "" };
        })
        .filter((x) => x.name && x.skillDir);
}

const SKILL_LOADED_ENTRY = "context:skill_loaded";
type SkillLoadedData = { name: string; path: string };

function getLoadedSkills(ctx: ExtensionContext): Set<string> {
    const out = new Set<string>();
    for (const e of ctx.sessionManager.getEntries()) {
        if ((e as any)?.type !== "custom" || (e as any)?.customType !== SKILL_LOADED_ENTRY) continue;
        const d = (e as any)?.data as SkillLoadedData | undefined;
        if (d?.name) out.add(d.name);
    }
    return out;
}

function extractCost(usage: any): number {
    if (!usage) return 0;
    const c = usage?.cost;
    if (typeof c === "number") return Number.isFinite(c) ? c : 0;
    if (typeof c === "string") return isFinite(+c) ? +c : 0;
    const t = c?.total;
    if (typeof t === "number") return Number.isFinite(t) ? t : 0;
    if (typeof t === "string") return isFinite(+t) ? +t : 0;
    return 0;
}

function sumSession(ctx: ExtensionCommandContext) {
    let input = 0, output = 0, cacheRead = 0, cacheWrite = 0, totalCost = 0;
    for (const entry of ctx.sessionManager.getEntries()) {
        if ((entry as any)?.type !== "message") continue;
        const u = (entry as any)?.message?.usage;
        if (!u) continue;
        input += Number(u.inputTokens ?? 0) || 0;
        output += Number(u.outputTokens ?? 0) || 0;
        cacheRead += Number(u.cacheRead ?? 0) || 0;
        cacheWrite += Number(u.cacheWrite ?? 0) || 0;
        totalCost += extractCost(u);
    }
    return { input, output, cacheRead, cacheWrite, totalTokens: input + output + cacheRead + cacheWrite, totalCost };
}

function shortenPath(p: string, cwd: string): string {
    const rp = path.resolve(p), rc = path.resolve(cwd);
    if (rp === rc) return ".";
    if (rp.startsWith(rc + path.sep)) return "./" + rp.slice(rc.length + 1);
    return rp;
}

function renderBar(theme: any, parts: { system: number; tools: number; convo: number; remaining: number }, total: number, width: number): string {
    if (total <= 0) return "";
    const w = Math.max(10, width);
    const toCols = (n: number) => Math.round((n / total) * w);
    let sys = toCols(parts.system), tools = toCols(parts.tools), con = toCols(parts.convo);
    let rem = Math.max(0, w - sys - tools - con);
    while (sys + tools + con + rem < w) rem++;
    while (sys + tools + con + rem > w && rem > 0) rem--;
    const b = "█";
    return theme.fg("accent", b.repeat(sys)) + theme.fg("warning", b.repeat(tools)) +
        theme.fg("success", b.repeat(con)) + theme.fg("dim", b.repeat(rem));
}

type ViewData = {
    usage: { messageTokens: number; contextWindow: number; effectiveTokens: number; percent: number; remainingTokens: number; systemPromptTokens: number; agentTokens: number; toolsTokens: number; activeTools: number } | null;
    agentFiles: string[];
    extensions: string[];
    skills: string[];
    loadedSkills: string[];
    session: { totalTokens: number; totalCost: number };
};

class ContextView implements Component {
    private container: Container;
    private body: Text;
    private cachedWidth?: number;

    constructor(private tui: TUI, private theme: any, private data: ViewData, private onDone: () => void) {
        this.container = new Container();
        this.container.addChild(new DynamicBorder((s) => theme.fg("accent", s)));
        this.container.addChild(new Text(theme.fg("accent", theme.bold("Context")) + theme.fg("dim", "  (Esc/q/Enter to close)"), 1, 0));
        this.container.addChild(new Text("", 1, 0));
        this.body = new Text("", 1, 0);
        this.container.addChild(this.body);
        this.container.addChild(new Text("", 1, 0));
        this.container.addChild(new DynamicBorder((s) => theme.fg("accent", s)));
    }

    private rebuild(width: number): void {
        const { theme: t, data: d } = this;
        const muted = (s: string) => t.fg("muted", s);
        const dim = (s: string) => t.fg("dim", s);
        const text = (s: string) => t.fg("text", s);
        const lines: string[] = [];

        if (!d.usage) {
            lines.push(muted("Window: ") + dim("(unknown)"));
        } else {
            const u = d.usage;
            lines.push(muted("Window: ") + text(`~${u.effectiveTokens.toLocaleString()} / ${u.contextWindow.toLocaleString()}`) + muted(`  (${u.percent.toFixed(1)}% used, ~${u.remainingTokens.toLocaleString()} left)`));
            const barWidth = Math.max(10, Math.min(36, width - 10));
            const sysInMsg = Math.min(u.systemPromptTokens, u.messageTokens);
            const bar = renderBar(t, { system: sysInMsg, tools: u.toolsTokens, convo: Math.max(0, u.messageTokens - sysInMsg), remaining: u.remainingTokens }, u.contextWindow, barWidth)
                + " " + dim("sys") + t.fg("accent", "█") + " " + dim("tools") + t.fg("warning", "█")
                + " " + dim("convo") + t.fg("success", "█") + " " + dim("free") + t.fg("dim", "█");
            lines.push(bar);
            lines.push("");
            lines.push(muted("System: ") + text(`~${u.systemPromptTokens.toLocaleString()} tok`) + muted(` (AGENTS ~${u.agentTokens.toLocaleString()})`));
            lines.push(muted("Tools: ") + text(`~${u.toolsTokens.toLocaleString()} tok`) + muted(` (${u.activeTools} active)`));
        }

        lines.push(muted(`AGENTS (${d.agentFiles.length}): `) + text(d.agentFiles.length ? d.agentFiles.join(", ") : "(none)"));
        lines.push("");
        lines.push(muted(`Extensions (${d.extensions.length}): `) + text(d.extensions.length ? d.extensions.join(", ") : "(none)"));

        const loaded = new Set(d.loadedSkills);
        const skillsStr = d.skills.length
            ? d.skills.map((n) => loaded.has(n) ? t.fg("success", n) : t.fg("muted", n)).join(t.fg("muted", ", "))
            : "(none)";
        lines.push(muted(`Skills (${d.skills.length}): `) + skillsStr);
        lines.push("");
        lines.push(muted("Session: ") + text(`${d.session.totalTokens.toLocaleString()} tokens`) + muted(" · ") + text(formatUsd(d.session.totalCost)));

        this.body.setText(lines.join("\n"));
        this.cachedWidth = width;
    }

    handleInput(data: string): void {
        if (matchesKey(data, Key.escape) || matchesKey(data, Key.ctrl("c")) || data.toLowerCase() === "q" || data === "\r")
            this.onDone();
    }

    invalidate(): void { this.container.invalidate(); this.cachedWidth = undefined; }
    render(width: number): string[] { if (this.cachedWidth !== width) this.rebuild(width); return this.container.render(width); }
}

export default function contextExtension(pi: ExtensionAPI) {
    let lastSessionId: string | null = null;
    let cachedLoadedSkills = new Set<string>();
    let cachedSkillIndex: SkillEntry[] = [];

    const ensureCaches = (ctx: ExtensionContext) => {
        const sid = ctx.sessionManager.getSessionId();
        if (sid !== lastSessionId) {
            lastSessionId = sid;
            cachedLoadedSkills = getLoadedSkills(ctx);
            cachedSkillIndex = buildSkillIndex(pi, ctx.cwd);
        }
        if (cachedSkillIndex.length === 0) cachedSkillIndex = buildSkillIndex(pi, ctx.cwd);
    };

    const matchSkillForPath = (absPath: string): string | null => {
        let best: SkillEntry | null = null;
        for (const s of cachedSkillIndex) {
            if (!s.skillDir) continue;
            if (absPath === s.skillFilePath || absPath.startsWith(s.skillDir + path.sep)) {
                if (!best || s.skillDir.length > best.skillDir.length) best = s;
            }
        }
        return best?.name ?? null;
    };

    pi.on("tool_result", (event: ToolResultEvent, ctx: ExtensionContext) => {
        if ((event as any).toolName !== "read" || (event as any).isError) return;
        const p = typeof (event as any).input?.path === "string" ? (event as any).input.path : "";
        if (!p) return;
        ensureCaches(ctx);
        const abs = normalizePath(p, ctx.cwd);
        const skillName = matchSkillForPath(abs);
        if (!skillName || cachedLoadedSkills.has(skillName)) return;
        cachedLoadedSkills.add(skillName);
        pi.appendEntry<SkillLoadedData>(SKILL_LOADED_ENTRY, { name: skillName, path: abs });
    });

    pi.registerCommand("context", {
        description: "Show loaded context overview",
        handler: async (_args, ctx: ExtensionCommandContext) => {
            const commands = pi.getCommands();
            const extensionFiles = [...new Map(
                commands.filter((c) => c.source === "extension").map((c) => [c.sourceInfo?.path ?? "<unknown>", true])
            ).keys()].map((p) => p === "<unknown>" ? p : path.basename(p)).sort();

            const skills = commands.filter((c) => c.source === "skill")
                .map((c) => normalizeSkillName(c.name)).sort();

            const agentFiles = await loadContextFiles(ctx.cwd);
            const agentFilePaths = agentFiles.map((f) => shortenPath(f.path, ctx.cwd));
            const agentTokens = agentFiles.reduce((a, f) => a + f.tokens, 0);

            const systemPromptTokens = ctx.getSystemPrompt() ? estimateTokens(ctx.getSystemPrompt()!) : 0;
            const usage = ctx.getContextUsage();
            const messageTokens = usage?.tokens ?? 0;
            const ctxWindow = usage?.contextWindow ?? 0;

            const activeToolNames = pi.getActiveTools();
            const toolInfoByName = new Map(pi.getAllTools().map((t) => [t.name, t] as const));
            let toolsTokens = 0;
            for (const name of activeToolNames) {
                toolsTokens += estimateTokens(`${name}\n${toolInfoByName.get(name)?.description ?? ""}`);
            }
            toolsTokens = Math.round(toolsTokens * 1.5);

            const effectiveTokens = messageTokens + toolsTokens;
            const percent = ctxWindow > 0 ? (effectiveTokens / ctxWindow) * 100 : 0;
            const remainingTokens = ctxWindow > 0 ? Math.max(0, ctxWindow - effectiveTokens) : 0;
            const sessionUsage = sumSession(ctx);

            if (!ctx.hasUI) {
                const lines = [
                    "Context",
                    usage ? `Window: ~${effectiveTokens.toLocaleString()} / ${ctxWindow.toLocaleString()} (${percent.toFixed(1)}% used)` : "Window: (unknown)",
                    `System: ~${systemPromptTokens.toLocaleString()} tok (AGENTS ~${agentTokens.toLocaleString()})`,
                    `Tools: ~${toolsTokens.toLocaleString()} tok (${activeToolNames.length} active)`,
                    `AGENTS: ${agentFilePaths.join(", ") || "(none)"}`,
                    `Extensions (${extensionFiles.length}): ${extensionFiles.join(", ") || "(none)"}`,
                    `Skills (${skills.length}): ${skills.join(", ") || "(none)"}`,
                    `Session: ${sessionUsage.totalTokens.toLocaleString()} tokens · ${formatUsd(sessionUsage.totalCost)}`,
                ];
                pi.sendMessage({ customType: "context", content: lines.join("\n"), display: true }, { triggerTurn: false });
                return;
            }

            const viewData: ViewData = {
                usage: usage ? { messageTokens, contextWindow: ctxWindow, effectiveTokens, percent, remainingTokens, systemPromptTokens, agentTokens, toolsTokens, activeTools: activeToolNames.length } : null,
                agentFiles: agentFilePaths,
                extensions: extensionFiles,
                skills,
                loadedSkills: Array.from(getLoadedSkills(ctx)).sort(),
                session: { totalTokens: sessionUsage.totalTokens, totalCost: sessionUsage.totalCost },
            };

            await ctx.ui.custom<void>((tui, theme, _kb, done) => new ContextView(tui, theme, viewData, done));
        },
    });
}
