---
name: git-commit-push
description: Generate a commit message, commit, and optionally push. Use when the user says commit / 提交 / 交一下 / save changes / commit and push / 提交并推送. Do NOT trigger on a bare "push" / "推送" (push existing commits only).
---

# Git Commit & Push

Generate a conventional commit message from the current diff, commit, and push — with safety checks for force-push and conflicts.

## Workflow

### Step 1 — Collect context

Run these commands in parallel:

```bash
git status
git diff --stat
git diff --cached --stat
git log --oneline -5
git rev-parse --abbrev-ref HEAD
```

If there are no changes (nothing staged, nothing modified), tell the user and stop.

### Step 2 — Stage changes

If there are unstaged changes but nothing staged, stage all tracked modifications:

```bash
git add -u
```

For new (untracked) files, ask the user which files to include.

### Step 3 — Generate commit message

Analyze the diff (`git diff --cached`) and produce a message following this format:

```
<type><scope>: <concise description in English>
```

**Type rules:**

| type | when to use |
|------|-------------|
| `fix` | Bug fix, error correction, lint fix |
| `feat` | New file, new feature, new module |
| `refactor` | Code restructure without behavior change |
| `docs` | Documentation, comments, skill files |
| `test` | Test additions or modifications |
| `chore` | Config, CI, build, dependency updates |

**Message rules:**
- First line max 72 characters
- Use English for the type and description
- If multiple types apply, use the dominant one
- Add a blank line + bullet list body only for 3+ distinct changes

**Examples:**

```
fix: resolve conflict markers in issue_dashboard.py
```

```
add: freespace eval task with dataloader, metric, and dashboard

- Register TaskType.FREESPACE in types.py
- Implement FreespaceMetric with IoU calculation
- Add FreespaceDashboard with webviz link support
```

```
refactor: replace inline handlers with dashboard registry pattern
```

### Step 4 — Commit

Present the proposed message to the user for confirmation. Then commit:

```bash
git commit -m "<message>"
```

### Step 5 — Push safety checks

Before pushing, check the branch state:

```bash
git status -sb
git rev-list --count --left-right HEAD...@{upstream} 2>/dev/null
```

| Situation | Action |
|-----------|--------|
| Branch has upstream, is ahead only | `git push` |
| Branch has no upstream | `git push -u origin HEAD` |
| Branch has diverged (rebase happened) | **Warn the user**: "分支已与远程分叉（可能因为 rebase），需要 force push。是否继续？" Only `git push --force-with-lease` after explicit confirmation |
| Upstream is ahead (remote has new commits) | **Warn the user**: "远程分支有新提交，建议先 `git pull --rebase` 再推送" |

### Step 6 — Report

After push succeeds, show:
- The commit hash and message

## Safety Rules

- **NEVER** force push without user confirmation
- **NEVER** commit files matching `.env`, `*secret*`, `*credential*`, `*token*` — warn the user
- **NEVER** use `--no-verify` unless the user explicitly requests it
- If `make lint` has not been run in the current session, suggest running it before committing
