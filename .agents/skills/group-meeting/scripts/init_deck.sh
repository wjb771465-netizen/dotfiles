#!/usr/bin/env bash
# Create <skill>/ppt/<YYYY-MM-DD>/ with template copy + session.yaml stub.
set -euo pipefail

DATE="${1:-}"
if [[ -z "$DATE" || ! "$DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "Usage: init_deck.sh YYYY-MM-DD" >&2
  exit 1
fi

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PPT_DIR="${SKILL_DIR}/ppt"
TEMPLATE="${PPT_DIR}/组会模版.pptx"
DIR="${PPT_DIR}/${DATE}"

if [[ ! -f "$TEMPLATE" ]]; then
  echo "Template not found: $TEMPLATE" >&2
  exit 1
fi

# 组会M.D王俊博.pptx (no leading zero on month/day)
MONTH=$((10#${DATE:5:2}))
DAY=$((10#${DATE:8:2}))
PPTX_NAME="组会${MONTH}.${DAY}王俊博.pptx"
FILE="${DIR}/${PPTX_NAME}"

mkdir -p "${DIR}/assets/formulas/images"

if [[ ! -f "$FILE" ]]; then
  cp "$TEMPLATE" "$FILE"
  echo "Copied template → $FILE"
else
  echo "PPTX already exists (left untouched): $FILE"
fi

SESSION="${DIR}/session.yaml"
if [[ ! -f "$SESSION" ]]; then
  sed "s/YYYY-MM-DD/${DATE}/" "${SKILL_DIR}/templates/session.yaml" > "$SESSION"
  echo "Wrote $SESSION"
else
  echo "session.yaml already exists (left untouched): $SESSION"
fi

echo "FILE=${FILE}"
