#!/usr/bin/env bash
# Validate a session.md draft before fill_deck.py. Non-zero = not ready to fill.
# (Layout QA is manual in PowerPoint; this only guards the draft's structure.)
set -euo pipefail

DRAFT="${1:-}"
if [[ -z "$DRAFT" ]]; then
  echo "Usage: check_draft.sh <session.md>" >&2
  exit 1
fi
DRAFT="${DRAFT/#\~/$HOME}"
if [[ ! -f "$DRAFT" ]]; then
  echo "File not found: $DRAFT" >&2
  exit 1
fi
DIR="$(cd "$(dirname "$DRAFT")" && pwd)"
FAIL=0
BUDGET=400

echo "=== Gate 1: pages & titles ==="
TITLES=$(grep -cE '^##\s+' "$DRAFT" || true)
if [[ "$TITLES" -lt 2 ]]; then
  echo "FAIL: need cover + >=1 content page (## lines = $TITLES)"
  FAIL=1
else
  echo "PASS: $TITLES page(s)"
fi

echo
echo "=== Gate 2: referenced images exist ==="
if grep -qE '!\[[^]]*\]\(' "$DRAFT"; then
  grep -oE '!\[[^]]*\]\([^)]*\)' "$DRAFT" | while read -r ref; do
    IMG="${ref#*(}"; IMG="${IMG%)}"; IMG="${IMG%%)}"
    if [[ "$IMG" == http* || "$IMG" =~ ^~/ ]]; then
      echo "  WARN: external image (verify manually): $IMG"
      continue
    fi
    if [[ "$IMG" != /* ]]; then IMG="${DIR}/${IMG}"; fi
    if [[ ! -f "$IMG" ]]; then
      echo "  FAIL: image not found: $IMG"
      FAIL=1
    else
      echo "  ok: $(basename "$IMG")"
    fi
  done
else
  echo "PASS: no images referenced"
fi

echo
echo "=== Gate 3: unpaired ** and per-page char budget ==="
if ! /Users/wjb/miniconda3/bin/python3 - "$DRAFT" "$BUDGET" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
budget = int(sys.argv[2])
pages = []
cur = None
for ln in text.splitlines():
    m = re.match(r"^##\s+(.*)", ln)
    if m:
        cur = [m.group(1).strip(), []]
        pages.append(cur)
    elif cur is not None and ln.strip():
        cur[1].append(ln)

exit_code = 0
for title, body in pages:
    if any(l.count("**") % 2 for l in body):
        print(f"  FAIL: page '{title}' has unpaired **")
        exit_code = 1
    real = " ".join(l for l in body if not re.match(r"^\s*!\[", l))
    n = len(re.sub(r"\*\*", "", real).strip())
    if n > budget:
        print(f"  WARN: page '{title}' body ~{n} chars (> {budget}) — consider splitting")
    else:
        print(f"  ok: '{title}' {n} chars")
sys.exit(exit_code)
PY
then
  FAIL=1
fi

echo
if [[ "$FAIL" -ne 0 ]]; then
  echo "RESULT: FAIL (draft not ready — fix above then re-run)"
  exit 1
fi
echo "RESULT: PASS (draft ready to fill)"
exit 0
