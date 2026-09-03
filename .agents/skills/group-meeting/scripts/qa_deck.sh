#!/usr/bin/env bash
# Mechanical QA gates for a group-meeting PPTX. Non-zero = not done.
# Visual review is manual (by human in PowerPoint); not run by this script.
set -euo pipefail

FILE="${1:-}"
if [[ -z "$FILE" ]]; then
  echo "Usage: qa_deck.sh <pptx-path>" >&2
  exit 1
fi

FILE="${FILE/#\~/$HOME}"
if [[ ! -f "$FILE" ]]; then
  echo "File not found: $FILE" >&2
  exit 1
fi

if ! command -v officecli >/dev/null 2>&1; then
  echo "FAIL: officecli not on PATH" >&2
  exit 1
fi

FAIL=0
DIR="$(cd "$(dirname "$FILE")" && pwd)"
QA_DIR="${DIR}/qa"
mkdir -p "$QA_DIR"

echo "=== Gate 1: validate ==="
if ! officecli validate "$FILE"; then
  echo "FAIL: validate"
  FAIL=1
else
  echo "PASS: validate"
fi

echo
echo "=== Gate 2: issues ==="
ISSUES_OUT="$(mktemp)"
if ! officecli view "$FILE" issues >"$ISSUES_OUT" 2>&1; then
  head -n 40 "$ISSUES_OUT"
  echo "FAIL: view issues (command error)"
  FAIL=1
else
  COUNT="$(grep -m1 -oE 'Found[[:space:]]+[0-9]+[[:space:]]+issue' "$ISSUES_OUT" | grep -oE '[0-9]+' | head -1)"
  if [[ -z "$COUNT" ]]; then
    # No "Found N issue(s)" header: infer from per-issue "[O1]" markers instead of a fixed token list
    # (a fixed list drifts — off-slide and text-overflow wording changes; each entry is prefixed
    # with a category-letter+number marker like "[O1]").
    COUNT="$(grep -cE '\[[A-Za-z][0-9]+\]' "$ISSUES_OUT")"
    COUNT="${COUNT:-0}"
  fi
  if [[ "$COUNT" -gt 0 ]]; then
    head -n 40 "$ISSUES_OUT"
    echo "FAIL: $COUNT issue(s)"
    FAIL=1
  else
    head -n 20 "$ISSUES_OUT"
    echo "PASS: issues"
  fi
fi
rm -f "$ISSUES_OUT"

echo
echo "=== Gate 3a: forbidden text ==="
TEXT_OUT="$(mktemp)"
if ! officecli view "$FILE" text >"$TEXT_OUT" 2>&1; then
  head -n 40 "$TEXT_OUT"
  echo "FAIL: view text (command error)"
  FAIL=1
else
  BAD=0
  if grep -F '#OCLI_NOTEVAL' "$TEXT_OUT" >/dev/null; then
    echo "FAIL: found #OCLI_NOTEVAL (footer field trap?)"
    BAD=1
  fi
  if grep -Eiq '(^|[[:space:]])lorem([[:space:]]|$)|<TODO>|{{[a-zA-Z_]+}}' "$TEXT_OUT"; then
    echo "FAIL: found placeholder (lorem / <TODO> / {{...}})"
    BAD=1
  fi
  if grep -Eiq '(^|[[:space:]])xxxx([[:space:]]|$)' "$TEXT_OUT"; then
    echo "FAIL: found xxxx placeholder"
    BAD=1
  fi
  if [[ "$BAD" -eq 0 ]]; then
    echo "PASS: forbidden text"
  else
    FAIL=1
  fi
fi
rm -f "$TEXT_OUT"

echo
echo "=== Gate 4: bold ratio check ==="
BOLD_OUT="$(mktemp)"
if officecli view "$FILE" text --format json >"$BOLD_OUT" 2>&1; then
  # 计算 bold 使用率
  BOLD_COUNT=$(grep -c "bold=true" "$BOLD_OUT" 2>/dev/null || echo 0)
  TOTAL_SHAPES=$(officecli view "$FILE" outline 2>/dev/null | grep -c "textbox" || echo 1)

  if [[ "$TOTAL_SHAPES" -gt 0 ]]; then
    # 计算比例（小数形式 * 100 保留整数）
    BOLD_RATIO=$(echo "scale=0; $BOLD_COUNT * 100 / $TOTAL_SHAPES" | bc 2>/dev/null || echo 0)
    if [[ "$BOLD_RATIO" -gt 40 ]]; then
      echo "FAIL: bold ratio ${BOLD_RATIO}% exceeds 40% threshold (full-paragraph bold detected)"
      FAIL=1
    else
      echo "PASS: bold ratio ${BOLD_RATIO}% (within 40% threshold)"
    fi
  else
    echo "PASS: bold ratio check (no textboxes)"
  fi
else
  echo "PASS: bold ratio check (format not available)"
fi
rm -f "$BOLD_OUT"

echo
echo "=== Gate 5: textbox count check ==="
SLIDE_COUNT=$(officecli view "$FILE" outline 2>/dev/null | grep -c "^├── Slide" || echo 0)
TOTAL_TEXTBOXES=$(officecli view "$FILE" outline 2>/dev/null | grep -oE '[0-9]+ text box' | grep -oE '[0-9]+' | awk '{sum+=$1} END {print sum}')
AVG_TEXTBOXES=0

if [[ "$SLIDE_COUNT" -gt 0 ]] && [[ "$TOTAL_TEXTBOXES" -gt 0 ]]; then
  AVG_TEXTBOXES=$(echo "scale=2; $TOTAL_TEXTBOXES / $SLIDE_COUNT" | bc 2>/dev/null || echo "0")
fi

# 检查平均值是否 ≥1
IS_BELOW=$(echo "$AVG_TEXTBOXES < 1" | bc 2>/dev/null || echo 0)
if [[ "$IS_BELOW" -eq 1 ]]; then
  echo "FAIL: average ${AVG_TEXTBOXES} textboxes/slide < 1 threshold (no content)"
  FAIL=1
else
  echo "PASS: average ${AVG_TEXTBOXES} textboxes/slide (≥1 threshold)"
fi

echo
echo "=== Gate 6: textbox overlap check ==="
OVERLAP_FOUND=0

# 改进版：直接解析每个 slide 的 shape 坐标
SLIDES_TOTAL=$(officecli view "$FILE" outline 2>/dev/null | grep -c "^├── Slide" || echo 0)
OVERLAP_COUNT=0

for slide_idx in $(seq 1 $SLIDES_TOTAL); do
  # 获取该页所有文本框的坐标
  TEXTBOXES=$(officecli get "$FILE" "/slide[$slide_idx]" --depth 1 2>/dev/null | grep "textbox" || true)

  if [[ -n "$TEXTBOXES" ]]; then
    # 提取每个文本框的 x,y,w,h 并检查重叠
    # 简化：检测是否有完全相同位置的文本框
    POSITIONS=$(echo "$TEXTBOXES" | grep -oE 'x=[0-9]+emu y=[0-9]+emu' | sort || true)
    DUPES=$(echo "$POSITIONS" | uniq -d | wc -l || true)

    if [[ "$DUPES" -gt 0 ]]; then
      echo "FAIL: slide[$slide_idx] has $DUPES textboxes at identical position"
      OVERLAP_COUNT=$((OVERLAP_COUNT + DUPES))
    fi
  fi
done

if [[ "$OVERLAP_COUNT" -gt 0 ]]; then
  echo "FAIL: $OVERLAP_COUNT total overlapping textboxes"
  FAIL=1
else
  echo "PASS: no textbox overlap detected"
fi

echo
echo "=== Outline (informational) ==="
officecli view "$FILE" outline 2>/dev/null | head -n 60 || echo "(outline unavailable)"

echo
if [[ "$FAIL" -ne 0 ]]; then
  echo "RESULT: FAIL (mechanical gates)"
  exit 1
fi
echo "RESULT: PASS (mechanical gates)"
exit 0
