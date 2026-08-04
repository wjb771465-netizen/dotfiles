#!/usr/bin/env bash
# Mechanical QA gates for a group-meeting PPTX. Non-zero = not done.
# Visual Gate 3 (screenshots) is still judged by agent / human.
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
  COUNT="$(sed -nE 's/^Found ([0-9]+) issue\(s\):/\1/p' "$ISSUES_OUT" | head -1)"
  if [[ -z "$COUNT" ]]; then
    # Fallback: any known issue tokens
    if grep -Eiq 'OCLI_NOTEVAL|shape_off_slide|low_contrast|text overflow|Format Issues' "$ISSUES_OUT"; then
      head -n 40 "$ISSUES_OUT"
      echo "FAIL: issues reported"
      FAIL=1
    else
      head -n 20 "$ISSUES_OUT"
      echo "PASS: issues"
    fi
  elif [[ "$COUNT" -eq 0 ]]; then
    echo "Found 0 issue(s)"
    echo "PASS: issues"
  else
    head -n 40 "$ISSUES_OUT"
    echo "FAIL: $COUNT issue(s)"
    FAIL=1
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
echo "=== Outline (informational) ==="
officecli view "$FILE" outline 2>/dev/null | head -n 60 || echo "(outline unavailable)"

echo
echo "=== Visual export (best-effort; does not fail mechanical gates) ==="
if officecli view "$FILE" svg --start 1 --end 1 -o "${QA_DIR}/slide1.svg" 2>/dev/null; then
  echo "Wrote ${QA_DIR}/slide1.svg (review Gate 3 visually)"
elif officecli view "$FILE" screenshot --page 1 -o "${QA_DIR}/slide1.png" 2>/dev/null; then
  echo "Wrote ${QA_DIR}/slide1.png (review Gate 3 visually)"
else
  echo "Visual export skipped (no Chrome/svg). Agent must still run Gate 3."
fi
echo "请按 officecli-pptx skill Gate 3 检查导出图/svg；脚本不代替视觉判定。"

echo
if [[ "$FAIL" -ne 0 ]]; then
  echo "RESULT: FAIL (mechanical gates)"
  exit 1
fi
echo "RESULT: PASS (mechanical gates)"
exit 0
