---
name: task-status-update
description: Produce a concise, high-level status update of what the user has been working on in the current project, based on git activity across all of the project's repos. Use when the user asks for a status update, standup notes, "what I did", or describes a piece of work to report on.
---

# Task Status Update

Turn the user's recent work into a short, non-technical status update they can paste into a standup, chat, or ticket.

## Inputs

The user's request may contain:
- **Focus**: the work to report on (e.g. "dev migration"). Use it to filter and frame the update. If absent, cover all of their work in the window.
- **Time window**: e.g. "this morning", "yesterday", "the last 3 days", "this week".

## Process

### 1. Identify the project

Determine which project you're running in (repo root name, README, AGENTS.md title). Don't assume the current directory is the only repo involved.

### 2. Read project context (only what's relevant)

Skim,read don't exhaustively :
- `AGENTS.md`/`CLAUDE.md`, if present
- `.cursor/` (rules and skills) - only files relevant to the focus or to understanding project structure
- Docs directories (`docs/`, `documentation/`, `wiki/`, `notes/`, or similar) - look especially for descriptions of the project's repos, services, and environments

Goal: learn the project's vocabulary, its repos, and how the pieces relate, so the update uses names the user's audience recognises.

### 3. Find all repos in the project

Projects often span multiple repos. Identify them from:
- Project docs and AGENTS.md (repo lists, architecture sections, links)
- Sibling directories of the current repo that are git repos and match names in the docs
- Git submodules

Only include repos that docs/structure indicate belong to this project. If a repo is documented but not found locally, note it in one line at the end rather than guessing.

### 4. Determine the time window

Parse the user's wording. If unspecified, assume based on the commits and justify your assumption.

### 5. Gather activity

For each repo, using the user's identity (`git config user.name` / `user.email`):
- Commits across all local branches within the window, e.g. `git log --all --author="<email>" --since="<window>" --no-merges --format="%h %ad %s" --date=short`
- Uncommitted/in-progress work: `git status --short` and `git diff --stat`
- Current branch names (often indicate the task)

Read commit messages and branch names for meaning. Only open diffs when needed to understand what a change was *for*.

### 6. Synthesise

- Group work into a few themes/workstreams aligned with the user's focus and the project's own terminology.
- Describe outcomes and progress, not implementation.
- Mark state where clear: done, in progress, blocked, up for review.
- Drop noise (formatting, merge commits, trivial fixes) unless they're the whole story.

## Output format

- A one-line header stating the project and the time window assumed (e.g. `Project X - since 2026-11-11`).
- A few high-level bullets. One line each, ideally.
- Optional sub-bullet only where status/next step genuinely needs it.

## Style rules

- Concise: no repetition, no preamble or closing commentary.
- Written for a non-technical or semi-technical reader.
- No file names, function names, commit hashes, or code unless the user asks.
- Don't invent work. If the evidence is thin, say so briefly and ask what's missing.

## Example output

```
Project X - since 2026-11-11
- Dev environment migration completed; services running on the new platform
- QA migration in progress: core services moved, test data setup remaining
- Fixed deployment issues found during the migration (affected API and web repos)
- Updated project docs to reflect the new environment setup
- PR for the QA config changes is up for review
```