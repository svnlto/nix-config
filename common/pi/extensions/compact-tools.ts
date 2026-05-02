import type {
    BashToolDetails,
    EditToolDetails,
    ExtensionAPI,
    ReadToolDetails,
} from "@mariozechner/pi-coding-agent";
import {
    createBashTool,
    createEditTool,
    createFindTool,
    createGrepTool,
    createLsTool,
    createReadTool,
    createWriteTool,
} from "@mariozechner/pi-coding-agent";
import { Text } from "@mariozechner/pi-tui";
import os from "node:os";
import path from "node:path";

function shorten(p: string): string {
    if (!p) return p;
    const home = os.homedir();
    if (p === home) return "~";
    if (p.startsWith(home + path.sep)) return "~" + p.slice(home.length);
    return p;
}

const dot = (t: any) => t.fg("dim", "  ·  ");
const muted = (t: any, s: string) => t.fg("muted", s);
const dim = (t: any, s: string) => t.fg("dim", s);
const accent = (t: any, s: string) => t.fg("subtext1", s);
const ok = (t: any, s: string) => t.fg("success", s);
const err = (t: any, s: string) => t.fg("error", s);
const warn = (t: any, s: string) => t.fg("warning", s);

// Claude Code-style status dot: yellow=running, green=done, red=error
function statusDot(t: any, ctx: any): string {
    if (ctx?.isPartial !== false) return t.fg("warning", "● ");
    if (ctx?.isError) return t.fg("error", "● ");
    return t.fg("success", "● ");
}
const resultPrefix = (t: any) => t.fg("dim", "  └ ");

function truncCmd(cmd: string, maxLen = 72): string {
    return cmd.length <= maxLen ? cmd : cmd.slice(0, maxLen - 1) + "…";
}

function firstText(result: any): string {
    return result?.content?.find((x: any) => x.type === "text")?.text ?? "";
}

function countLines(text: string): number {
    return text ? text.split("\n").length : 0;
}

function nonEmptyLines(text: string): number {
    return text ? text.split("\n").filter((l) => l.trim()).length : 0;
}

function expandedOutput(text: string, theme: any, maxLines = 30): string {
    if (!text) return "";
    const lines = text.split("\n");
    const display = lines.slice(0, maxLines);
    let out = "\n" + display.map((l) => dim(theme, l)).join("\n");
    if (lines.length > maxLines) out += "\n" + muted(theme, `… ${lines.length - maxLines} more lines`);
    return out;
}

const toolCache = new Map<string, ReturnType<typeof makeTools>>();
function makeTools(cwd: string) {
    return {
        read: createReadTool(cwd), bash: createBashTool(cwd), edit: createEditTool(cwd),
        write: createWriteTool(cwd), find: createFindTool(cwd), grep: createGrepTool(cwd),
        ls: createLsTool(cwd),
    };
}
function tools(cwd: string) {
    let t = toolCache.get(cwd);
    if (!t) { t = makeTools(cwd); toolCache.set(cwd, t); }
    return t;
}

export default function compactTools(pi: ExtensionAPI) {
    const read0 = createReadTool(process.cwd());
    pi.registerTool({
        name: "read", label: "read",
        description: read0.description, parameters: read0.parameters,
        async execute(id, params, signal, onUpdate, ctx) {
            return tools(ctx?.cwd ?? process.cwd()).read.execute(id, params, signal, onUpdate);
        },
        renderCall(args, theme, ctx) {
            let t = statusDot(theme, ctx) + muted(theme, "read") + " " + accent(theme, shorten(args.path ?? ""));
            if (args.offset !== undefined || args.limit !== undefined) {
                const from = args.offset ?? 1;
                const to = args.limit !== undefined ? from + args.limit - 1 : "…";
                t += dim(theme, `:${from}-${to}`);
            }
            return new Text(t, 0, 0);
        },
        renderResult(result, { expanded, isPartial }, theme) {
            if (isPartial) return new Text(dim(theme, "reading…"), 0, 0);
            const content = result.content[0];
            if (content?.type === "image") return new Text(ok(theme, "image loaded"), 0, 0);
            if (content?.type !== "text") return new Text(err(theme, "no content"), 0, 0);
            const details = result.details as ReadToolDetails | undefined;
            const lines = countLines(content.text);
            let summary = ok(theme, `${lines} lines`);
            if (details?.truncation?.truncated)
                summary += warn(theme, ` (truncated from ${details.truncation.totalLines})`);
            if (!expanded) return new Text(resultPrefix(theme) + summary, 0, 0);
            return new Text(resultPrefix(theme) + summary + expandedOutput(content.text, theme, 40), 0, 0);
        },
    });

    const bash0 = createBashTool(process.cwd());
    pi.registerTool({
        name: "bash", label: "bash",
        description: bash0.description, parameters: bash0.parameters,
        async execute(id, params, signal, onUpdate, ctx) {
            return tools(ctx?.cwd ?? process.cwd()).bash.execute(id, params, signal, onUpdate);
        },
        renderCall(args, theme, ctx) {
            let t = statusDot(theme, ctx) + muted(theme, "$ ") + accent(theme, truncCmd(args.command ?? ""));
            if (args.timeout) t += dim(theme, ` (${args.timeout}s)`);
            return new Text(t, 0, 0);
        },
        renderResult(result, { expanded, isPartial }, theme) {
            if (isPartial) return new Text(dim(theme, "running…"), 0, 0);
            const output = firstText(result);
            const details = result.details as BashToolDetails | undefined;
            const exitMatch = output.match(/\nexit code: (\d+)\s*$/);
            const exitCode = exitMatch ? parseInt(exitMatch[1], 10) : null;
            const cleanOutput = exitMatch
                ? output.slice(0, output.lastIndexOf("\nexit code:")).trim()
                : output.trim();
            const status = (exitCode === null || exitCode === 0)
                ? ok(theme, "✓ done") : err(theme, `✗ exit ${exitCode}`);
            let summary = status + dot(theme) + dim(theme, `${nonEmptyLines(cleanOutput)} lines`);
            if (details?.truncation?.truncated) summary += warn(theme, " [truncated]");
            if (!expanded) return new Text(resultPrefix(theme) + summary, 0, 0);
            return new Text(resultPrefix(theme) + summary + expandedOutput(cleanOutput, theme, 40), 0, 0);
        },
    });

    const edit0 = createEditTool(process.cwd());
    pi.registerTool({
        name: "edit", label: "edit",
        description: edit0.description, parameters: edit0.parameters,
        renderShell: "self",
        async execute(id, params, signal, onUpdate, ctx) {
            return tools(ctx?.cwd ?? process.cwd()).edit.execute(id, params, signal, onUpdate);
        },
        renderCall(args, theme, ctx) {
            const count = ((args.edits as any[] | undefined) ?? []).length;
            let t = statusDot(theme, ctx) + muted(theme, "edit") + " " + accent(theme, shorten(args.path ?? ""));
            if (count > 1) t += dim(theme, ` ×${count}`);
            return new Text(t, 0, 0);
        },
        renderResult(result, { expanded, isPartial }, theme) {
            if (isPartial) return new Text(dim(theme, "editing…"), 0, 0);
            const text = result.content[0]?.type === "text" ? result.content[0].text : "";
            if (text.toLowerCase().startsWith("error"))
                return new Text(err(theme, text.split("\n")[0] ?? text), 0, 0);
            const details = result.details as EditToolDetails | undefined;
            if (!details?.diff) return new Text(ok(theme, "✓ applied"), 0, 0);
            const diffLines = details.diff.split("\n");
            let added = 0, removed = 0;
            for (const l of diffLines) {
                if (l.startsWith("+") && !l.startsWith("+++")) added++;
                if (l.startsWith("-") && !l.startsWith("---")) removed++;
            }
            const summary = ok(theme, `+${added}`) + dim(theme, " / ") + err(theme, `-${removed}`);
            if (!expanded) return new Text(resultPrefix(theme) + summary, 0, 0);
            let diffOut = "\n";
            for (const l of diffLines.slice(0, 60)) {
                if (l.startsWith("+") && !l.startsWith("+++")) diffOut += ok(theme, l) + "\n";
                else if (l.startsWith("-") && !l.startsWith("---")) diffOut += err(theme, l) + "\n";
                else diffOut += dim(theme, l) + "\n";
            }
            if (diffLines.length > 60) diffOut += muted(theme, `… ${diffLines.length - 60} more diff lines`);
            return new Text(resultPrefix(theme) + summary + diffOut, 0, 0);
        },
    });

    const write0 = createWriteTool(process.cwd());
    pi.registerTool({
        name: "write", label: "write",
        description: write0.description, parameters: write0.parameters,
        async execute(id, params, signal, onUpdate, ctx) {
            return tools(ctx?.cwd ?? process.cwd()).write.execute(id, params, signal, onUpdate);
        },
        renderCall(args, theme, ctx) {
            const lines = args.content ? countLines(args.content) : 0;
            let t = statusDot(theme, ctx) + muted(theme, "write") + " " + accent(theme, shorten(args.path ?? ""));
            if (lines > 0) t += dot(theme) + dim(theme, `${lines} lines`);
            return new Text(t, 0, 0);
        },
        renderResult(result, { isPartial }, theme) {
            if (isPartial) return new Text(dim(theme, "writing…"), 0, 0);
            const text = firstText(result);
            if (text.toLowerCase().startsWith("error"))
                return new Text(resultPrefix(theme) + err(theme, text.split("\n")[0] ?? text), 0, 0);
            return new Text(resultPrefix(theme) + ok(theme, "✓ written"), 0, 0);
        },
    });

    const find0 = createFindTool(process.cwd());
    pi.registerTool({
        name: "find", label: "find",
        description: find0.description, parameters: find0.parameters,
        async execute(id, params, signal, onUpdate, ctx) {
            return tools(ctx?.cwd ?? process.cwd()).find.execute(id, params, signal, onUpdate);
        },
        renderCall(args, theme, ctx) {
            let t = statusDot(theme, ctx) + muted(theme, "find") + " " + accent(theme, args.pattern ?? "") + dim(theme, ` in ${shorten(args.path ?? ".")}`);
            if (args.limit !== undefined) t += dim(theme, ` (limit ${args.limit})`);
            return new Text(t, 0, 0);
        },
        renderResult(result, { expanded, isPartial }, theme) {
            if (isPartial) return new Text(dim(theme, "searching…"), 0, 0);
            const fileLines = firstText(result).trim().split("\n").filter((l) => l && !l.startsWith("["));
            const count = fileLines.length;
            let summary = ok(theme, `${count} file${count !== 1 ? "s" : ""}`);
            if ((result.details as any)?.resultLimitReached) summary += warn(theme, " (limit reached)");
            if (!expanded) return new Text(resultPrefix(theme) + summary, 0, 0);
            return new Text(resultPrefix(theme) + summary + expandedOutput(fileLines.join("\n"), theme, 40), 0, 0);
        },
    });

    const grep0 = createGrepTool(process.cwd());
    pi.registerTool({
        name: "grep", label: "grep",
        description: grep0.description, parameters: grep0.parameters,
        async execute(id, params, signal, onUpdate, ctx) {
            return tools(ctx?.cwd ?? process.cwd()).grep.execute(id, params, signal, onUpdate);
        },
        renderCall(args, theme, ctx) {
            let t = statusDot(theme, ctx) + muted(theme, "grep") + " " + accent(theme, `/${args.pattern ?? ""}/`) + dim(theme, ` in ${shorten(args.path ?? ".")}`);
            if (args.glob) t += dim(theme, ` (${args.glob})`);
            return new Text(t, 0, 0);
        },
        renderResult(result, { expanded, isPartial }, theme) {
            if (isPartial) return new Text(dim(theme, "searching…"), 0, 0);
            const matchLines = firstText(result).trim().split("\n").filter((l) => l.trim() && !l.startsWith("["));
            const count = matchLines.length;
            let summary = ok(theme, `${count} match${count !== 1 ? "es" : ""}`);
            if ((result.details as any)?.resultLimitReached) summary += warn(theme, " (limit reached)");
            if (!expanded) return new Text(resultPrefix(theme) + summary, 0, 0);
            return new Text(resultPrefix(theme) + summary + expandedOutput(matchLines.join("\n"), theme, 40), 0, 0);
        },
    });

    const ls0 = createLsTool(process.cwd());
    pi.registerTool({
        name: "ls", label: "ls",
        description: ls0.description, parameters: ls0.parameters,
        async execute(id, params, signal, onUpdate, ctx) {
            return tools(ctx?.cwd ?? process.cwd()).ls.execute(id, params, signal, onUpdate);
        },
        renderCall(args, theme, ctx) {
            return new Text(statusDot(theme, ctx) + muted(theme, "ls") + " " + accent(theme, shorten(args.path ?? ".")), 0, 0);
        },
        renderResult(result, { expanded, isPartial }, theme) {
            if (isPartial) return new Text(dim(theme, "listing…"), 0, 0);
            const entries = firstText(result).trim().split("\n").filter((l) => l.trim() && !l.startsWith("["));
            const count = entries.length;
            let summary = ok(theme, `${count} entr${count !== 1 ? "ies" : "y"}`);
            if ((result.details as any)?.entryLimitReached) summary += warn(theme, " (limit reached)");
            if (!expanded) return new Text(resultPrefix(theme) + summary, 0, 0);
            return new Text(resultPrefix(theme) + summary + expandedOutput(entries.join("\n"), theme, 40), 0, 0);
        },
    });
}
