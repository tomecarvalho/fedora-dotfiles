---
name: "commit-message"
description: "Generate commit messages based on Git changes. Use when changes are ready to commit, when asked to prepare or suggest a commit message, or when wrapping up a coding task. Supports multiple affected repositories."
---

# Commit Messages

## Goal

When changes are ready to commit, provide a commit message for each affected repository.

## Steps

- Check each affected repository independently.
- Determine the issue ID from the current branch name by running `git branch --show-current`.
  - Support formats such as `ABCD-123`, `#123`, and other obvious ones.
  - If the branch contains no issue ID, check the conversation context for one.
  - If no issue ID can be found, omit it.
- Review the actual changes using Git diff and other relevant Git information.
- First line: start with the issue ID (if available), followed by a concise summary of the changes.
- Body: use bullet points to describe additional changes and relevant details. Omit for trivial changes.
- Don't commit automatically. Only provide the suggested commit message.

## Output

Present each commit message in a fenced code block, ready to copy, with the repository name immediately before it.

### Example

Repo: `books-web-app`

```text
BOOK-123 feat(reviews): allow half-star ratings

- Allow rating books in .5 star increments, rather than just integers
- Display half-star icons in fractional ratings
- Update rating FAQ to mention half-star ratings
```
