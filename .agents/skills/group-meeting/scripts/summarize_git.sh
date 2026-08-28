#!/usr/bin/env bash
# Print commit summary for a repo since a date (or ~7 days). Does not write PPT.
set -euo pipefail

REPO="${1:-}"
SINCE="${2:-}"

if [[ -z "$REPO" ]]; then
  echo "Usage: summarize_git.sh <repo-path> [since-YYYY-MM-DD]" >&2
  exit 1
fi

REPO="${REPO/#\~/$HOME}"
if [[ ! -d "$REPO" ]]; then
  echo "Not a directory: $REPO" >&2
  exit 1
fi

if [[ -z "$SINCE" ]]; then
  if date -v-7d +%Y-%m-%d >/dev/null 2>&1; then
    SINCE="$(date -v-7d +%Y-%m-%d)"
  else
    SINCE="$(date -d '7 days ago' +%Y-%m-%d)"
  fi
fi

GIT=(git -C "$REPO")
if ! "${GIT[@]}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not a git repo: $REPO" >&2
  exit 1
fi

echo "# git progress: $REPO"
echo "# since: $SINCE"
echo

COUNT="$("${GIT[@]}" rev-list --count --since="$SINCE" HEAD 2>/dev/null || echo 0)"
if [[ "$COUNT" -eq 0 ]]; then
  echo "(no commits since $SINCE)"
  exit 0
fi

echo "## by day ($COUNT commits)"
"${GIT[@]}" log --since="$SINCE" --date=short --pretty=format:'%ad %h %s' --reverse
echo
echo
echo "## shortstat"
"${GIT[@]}" log --since="$SINCE" --pretty=format:'%h %s' --shortstat --reverse
echo
