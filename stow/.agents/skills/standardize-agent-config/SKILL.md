---
name: "standardize-agent-config"
description: "Migrate tool-specific AI agent config (Cursor rules, CLAUDE.md, Copilot, Windsurf, etc.) in a repo to the tool-agnostic AGENTS.md + .agents/ structure."
---

# Standardize agent config

Convert tool-specific agent instructions in the current repo (or the path given as an argument) into one tool-agnostic structure.

## Target structure

| Path                             | Description                                                                                                                              |
| -------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `AGENTS.md`                      | Always-applied rules, kept short, plus an index of conditional rules; each index entry states WHEN to read the file, in imperative form. |
| `.agents/rules/*.md`             | Conditional rules, plain Markdown with no tool-specific frontmatter. Every file is referenced from `AGENTS.md`.                          |
| `.agents/skills/<name>/SKILL.md` | Skills, triggered by the agent or invoked manually.                                                                                      |
| `.claude/skills`                 | A relative symlink to `../.agents/skills` (Claude does not read `.agents/skills`).                                                       |

## Steps

1. **Inventory.** Search the repo (and subdirectories, for monorepos) for: `AGENTS.md`, `CLAUDE.md`, `CLAUDE.local.md`, `.claude/rules/`, `.claude/skills/`, `.claude/commands/`, `.cursor/rules/*.mdc`, `.cursor/skills/`, `.cursor/commands/`, `.cursorrules`, `.github/copilot-instructions.md`, `.github/instructions/`, `.windsurfrules`, `.windsurf/rules/`, `GEMINI.md`, `.gemini/`, `.clinerules`, `.codex/`, `.agents/`. Read them all.
2. **Present a plan before changing anything.** Short list: each source file -> destination, plus conflicts, duplicates, contradictory instructions, and anything ambiguous. Ask the user about ambiguities, then proceed.
3. **Always-applied content** (Cursor `alwaysApply: true`, `CLAUDE.md` body, `copilot-instructions`, `.cursorrules`, `.windsurfrules`) -> merge into `AGENTS.md`, deduplicated. If a block is long, put it in `.agents/rules/` and reference it with an unconditional line ("Always read ...").
4. **Cursor `.mdc` rules** -> for each file:
   - Create `.agents/rules/<name>.md`, using `git mv` then edit, to keep history; remove the frontmatter.
   - Convert Cursor `@file` references to plain relative paths.
   - Add an entry to `AGENTS.md` stating the condition, derived from the frontmatter:
     - `globs` set: "When creating or editing files matching `<globs>`, read `.agents/rules/<name>.md` first."
     - `description` only (agent-requested): "When <description rephrased as a task condition>, read `.agents/rules/<name>.md`."
     - `alwaysApply: true`: handle as in step 3.
     - No globs, description, or alwaysApply (manual): "Only when the user asks for <topic>, read `.agents/rules/<name>.md`."
   - Write conditions as imperatives that the model can match from the prompt or the files being touched.
5. **`.claude/rules/*.md`** (with or without `paths:`) -> treat like step 4, mapping `paths:` globs to the condition. Tell the user that `paths:` rules are loaded deterministically by Claude Code while the index is model-judgment, and ask whether to keep any as a Claude-only backstop.
6. **Skills** in `.claude/skills/` or `.cursor/skills/` -> `git mv` into `.agents/skills/`. If two skills share a name with different content, ask. Then create the symlink `.claude/skills -> ../.agents/skills`.
7. **Commands** in `.claude/commands/` or `.cursor/commands/` -> ask whether to convert each into a skill under `.agents/skills/` (so it can be invoked manually). Do not convert without confirmation.
8. **`CLAUDE.md` files** (root and subdirectories): merge the content into the `AGENTS.md` in the same directory (create it if missing), then remove the `CLAUDE.md` with `git rm`. This removal is part of the migration and needs no extra confirmation, but list every removed file in the report. Exception: if the user explicitly asked to keep `CLAUDE.md`, replace its body with `@AGENTS.md` plus any genuinely Claude-only section. Leave `CLAUDE.local.md` (personal, usually gitignored) untouched and flag it in the report, since a leftover Claude-specific file may affect which instruction file Claude Code loads.
9. **Other tool files** (`GEMINI.md`, `.clinerules`, copilot instructions, `.windsurfrules`, `.cursorrules`) -> merge into `AGENTS.md` or `.agents/rules/` per steps 3-4.
10. **Leave alone and list in the report:** settings, hooks, permissions, `.mcp.json` and other MCP config. These are tool-specific and not portable.
11. **Verify.** Every file in `.agents/rules/` is referenced from `AGENTS.md`; every path in `AGENTS.md` exists; the symlink resolves; `AGENTS.md` is short; no secrets were copied; no `CLAUDE.md` remains (unless explicitly requested); `git status` is clean of unintended changes.

## Output

End with a concise report: what moved where, what was merged or dropped, files removed, conflicts the user needs to resolve, and tool-specific config left untouched.

## Rules

- Prefer `git mv` over copy and delete.
- Keep `AGENTS.md` short: it loads every session.
- Do not invent rules or rewrite their meaning; only restructure and rephrase conditions.
- Repo-level files only, unless the user asks about user-level config (`~/.claude`, `~/.cursor`).
