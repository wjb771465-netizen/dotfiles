#!/usr/bin/env bash
# Create <skill>/ppt/<YYYY-MM-DD>/ with template copy + session.yaml + session.md stub.
set -euo pipefail

DATE="${1:-}"
if [[ -z "$DATE" || ! "$DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "Usage: init_session.sh YYYY-MM-DD" >&2
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
DOT_DATE="${DATE:0:4}.${DATE:5:2}.${DATE:8:2}"

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

DRAFT="${DIR}/session.md"
if [[ ! -f "$DRAFT" ]]; then
  cat > "$DRAFT" <<EOF
# 组会草稿 ${DATE}
# 审核通过后运行: fill_deck.py <deck> session.md 填入 PPT。
# 格式: 每页以 \`## 页面标题\` 开头; \`- \` 为项目符号; \`** **\` 加粗; \`![](assets/x.png)\` 插图。

## 封面
${DOT_DATE}

## 页面标题
- 要点一
- 要点二
EOF
  echo "Wrote $DRAFT"
else
  echo "session.md already exists (left untouched): $DRAFT"
fi

echo "FILE=${FILE}"
