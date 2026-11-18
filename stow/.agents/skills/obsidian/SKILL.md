---
name: "obsidian"
description: "Read and write the user's Obsidian vaults (personal, mobinteg). Use when asked to read, create or update notes, daily notes, issue/task notes, the backlog, or anything about the user's notes or vault."
---

# Obsidian

## Vaults

Vaults live in `~/Documents/obsidian/`. They are plain Markdown folders; edit them with normal file tools.

| Vault      | Path                              | Purpose                    |
| ---------- | --------------------------------- | -------------------------- |
| `mobinteg` | `~/Documents/obsidian/mobinteg/`  | Work (the user's company)  |
| `personal` | `~/Documents/obsidian/personal/`  | Personal                   |

### Picking the vault

Use the first rule that matches:

1. The prompt names a vault. This always wins.
2. The current directory is inside `~/mobinteg/`: `mobinteg`.
3. `git config user.email` ends in `@mobinteg.com`: `mobinteg`.
4. Otherwise ask the user. Don't guess.

## `mobinteg` vault

Before writing, read `_meta/daily-notes-guide.md` (routine and conventions) and look at a recent note of the same kind to match the current style.

```
backlog-and-blocked.md        # Task backlog + blocked list
daily/YYYY-MM-DD.md           # Daily notes
projects/<project>/issues/    # Notes on a reported issue
projects/<project>/tasks/     # Notes/plans for a task
templates/daily.md            # Daily note template
templates/issue.md            # Issue note template
_meta/                        # Vault docs (guides)
```

### Conventions

- Write ticket IDs exactly using the project management tool's format (e.g. Jira `ABCD-123`, DevOps `#123`), and link them when possible.
- Tag each daily/backlog item with its project tag at the start of the line.
- Link notes with wikilinks, e.g. `[[2026-11-17-assignment-chat-multi-image]]`. Use the file name without extension.
- Use tabs for nested bullets.
- Write in English unless the source material is in another language.
- Don't commit.

### Daily notes (`daily/YYYY-MM-DD.md`)

- Create from `templates/daily.md`; use today's date.
- Add items under the right section, one bullet per item, with project tag and ticket link. Nest details as sub-bullets.
- Only work done or in progress today belongs here; queued or waiting items go in `backlog-and-blocked.md`.
- Carrying over: the next day's note starts with yesterday's unfinished items under `## In Progress`.
- Don't edit past days unless asked.

### Projects

Each `projects/<project>/` can have `issues/` and `tasks/`. These hold notes that don't fit in the project management tool (e.g. Jira).

- **Issue** (`issues/YYYY-MM-DD-<slug>/index.md`): an investigation of something reported. Create from `templates/issue.md` (sections: Report, Notes, Follow-up). Extra material goes in sibling files in the same dir (e.g. `logs.md`).
- **Task** (`tasks/YYYY-MM-DD-<slug>.md`): a plan or notes for work. A single file by default. If it needs attachments or several files, use a dir `tasks/YYYY-MM-DD-<slug>/` with `notes.md` and `docs/`.
- Slugs are lowercase kebab-case. The date is when the note was created.
- If the backlog item has a plan note, link it from the backlog line: `Plan: [[<note-name>]]`.

### Backlog (`backlog-and-blocked.md`)

Two numbered lists, `## Backlog` and `## Blocked`:

```
1. #abcd [ABCD-123 Task title here](https://mobinteg.atlassian.net/browse/ABCD-123) (extra context)
```

- Order is priority. If asked to add something to the backlog without a specified priority, append it to the end.
- Blocked items say what blocks them, in parentheses.
- When work starts, move the item to the daily note's `## In Progress` and remove it from the backlog.
