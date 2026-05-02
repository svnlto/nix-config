/**
 * Permissions extension — Claude Code-compatible allow/deny rules.
 *
 * Reads from (merged): ~/.pi/settings.json, <cwd>/.pi/settings.json
 *
 * Format: { "permissions": { "allow": ["Bash(git *)", "Read"], "deny": ["Bash(rm -rf *)"] } }
 * Rule syntax: "ToolName" | "ToolName(glob)"
 * Evaluation: deny wins → allow list (if non-empty, must match) → pass
 * Use /permissions to inspect active rules.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

interface PermissionsConfig { allow?: string[]; deny?: string[]; }
interface Settings { permissions?: PermissionsConfig; }
interface ParsedRule { tool: string; pattern?: string; }

function globToRegex(glob: string): RegExp {
    const escaped = glob.replace(/[.+^${}()|[\]\\]/g, "\\$&").replace(/\*/g, ".*").replace(/\?/g, ".");
    return new RegExp(`^${escaped}$`, "i");
}

function matchesGlob(value: string, glob: string): boolean {
    return globToRegex(glob).test(value);
}

function parseRule(rule: string): ParsedRule {
    const m = rule.match(/^(\w+)(?:\((.+)\))?$/);
    return m ? { tool: m[1].toUpperCase(), pattern: m[2] } : { tool: rule.toUpperCase() };
}

function ruleMatches(rule: ParsedRule, toolName: string, arg?: string): boolean {
    if (rule.tool !== toolName.toUpperCase()) return false;
    if (!rule.pattern) return true;
    if (arg === undefined) return false;
    return matchesGlob(arg, rule.pattern);
}

function loadSettings(p: string): Settings {
    try { return JSON.parse(readFileSync(p, "utf8")) as Settings; } catch { return {}; }
}

function mergePermissions(a: PermissionsConfig, b: PermissionsConfig): PermissionsConfig {
    return { allow: [...(a.allow ?? []), ...(b.allow ?? [])], deny: [...(a.deny ?? []), ...(b.deny ?? [])] };
}

function getPrimaryArg(toolName: string, input: Record<string, unknown>): string | undefined {
    switch (toolName.toUpperCase()) {
        case "BASH": return input.command as string | undefined;
        case "READ": case "EDIT": case "WRITE": case "FIND": return input.path as string | undefined;
        case "GREP": return input.pattern as string | undefined;
        default: return undefined;
    }
}

export default function (pi: ExtensionAPI) {
    let permissions: PermissionsConfig = {};

    function reload(cwd: string) {
        const global = loadSettings(resolve(process.env.HOME ?? "~", ".pi", "settings.json"));
        const local = loadSettings(resolve(cwd, ".pi", "settings.json"));
        permissions = mergePermissions(global.permissions ?? {}, local.permissions ?? {});
    }

    pi.on("session_start", async (_event, ctx) => { reload(ctx.cwd); });

    pi.on("tool_call", async (event, _ctx) => {
        const allow = permissions.allow ?? [];
        const deny = permissions.deny ?? [];
        if (allow.length === 0 && deny.length === 0) return undefined;

        const arg = getPrimaryArg(event.toolName, event.input as Record<string, unknown>);

        for (const raw of deny) {
            if (ruleMatches(parseRule(raw), event.toolName, arg))
                return { block: true, reason: `Blocked by deny rule: ${raw}` };
        }

        if (allow.length > 0 && !allow.some((raw) => ruleMatches(parseRule(raw), event.toolName, arg)))
            return { block: true, reason: `No allow rule matched ${event.toolName}${arg ? `(${arg})` : ""}` };

        return undefined;
    });

    pi.registerCommand("permissions", {
        description: "Show active allow/deny permission rules",
        handler: async (_args, ctx) => {
            const allow = permissions.allow ?? [];
            const deny = permissions.deny ?? [];
            if (allow.length === 0 && deny.length === 0) {
                ctx.ui.notify("No permission rules configured — all tools allowed", "info");
                return;
            }
            let msg = "";
            if (allow.length > 0) msg += `Allow (${allow.length}):\n` + allow.map((r) => `  ✓ ${r}`).join("\n");
            if (deny.length > 0) { if (msg) msg += "\n"; msg += `Deny (${deny.length}):\n` + deny.map((r) => `  ✗ ${r}`).join("\n"); }
            ctx.ui.notify(msg, "info");
        },
    });
}
