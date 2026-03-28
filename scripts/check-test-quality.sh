#!/usr/bin/env bash
# Anti-Test-Theater: Test Quality Checker
# Usage: bash check-test-quality.sh [directory]

DIR="${1:-.}"
ISSUES=0
WARNINGS=0

echo ""
echo "  Anti-Test-Theater Quality Check"
echo "  ================================"
echo ""

# Collect test files
TMPFILE=$(mktemp)
find "$DIR" -type f \( -name "*.test.*" -o -name "*.spec.*" -o -name "*_test.*" -o -name "test_*" \) \
  ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/dist/*" 2>/dev/null > "$TMPFILE"

FILE_COUNT=$(wc -l < "$TMPFILE" | tr -d ' ')

if [ "$FILE_COUNT" -eq 0 ]; then
  echo "  No test files found in $DIR"
  rm -f "$TMPFILE"
  exit 0
fi

echo "  Scanning $FILE_COUNT test files..."
echo ""

# Check: Snapshot abuse
COUNT=$(xargs grep -rl "toMatchSnapshot\|toMatchInlineSnapshot" < "$TMPFILE" 2>/dev/null | wc -l | tr -d ' ')
if [ "$COUNT" -gt 0 ]; then
  echo "  ⚠ Snapshot usage: $COUNT files use toMatchSnapshot"
  WARNINGS=$((WARNINGS + COUNT))
fi

# Check: setTimeout/sleep in tests
COUNT=$(xargs grep -rn "setTimeout" < "$TMPFILE" 2>/dev/null | grep -v "useFakeTimers\|clearTimeout" | wc -l | tr -d ' ')
if [ "$COUNT" -gt 0 ]; then
  echo "  ✗ Flaky async: $COUNT lines use setTimeout in tests"
  ISSUES=$((ISSUES + COUNT))
fi

# Check: "renders without crashing"
COUNT=$(xargs grep -rin "renders without crashing\|renders correctly" < "$TMPFILE" 2>/dev/null | wc -l | tr -d ' ')
if [ "$COUNT" -gt 0 ]; then
  echo "  ⚠ Shallow render tests: $COUNT tests only check if component renders"
  WARNINGS=$((WARNINGS + COUNT))
fi

# Check: Vague test names
COUNT=$(xargs grep -rn "test('works\|test('should work\|test('test[0-9]\|it('works" < "$TMPFILE" 2>/dev/null | wc -l | tr -d ' ')
if [ "$COUNT" -gt 0 ]; then
  echo "  ⚠ Vague test names: $COUNT tests have non-descriptive names"
  WARNINGS=$((WARNINGS + COUNT))
fi

# Check: Brittle DOM selectors
COUNT=$(xargs grep -rn "querySelector\|nth-child\|nth-of-type" < "$TMPFILE" 2>/dev/null | wc -l | tr -d ' ')
if [ "$COUNT" -gt 0 ]; then
  echo "  ⚠ Brittle selectors: $COUNT lines use querySelector/nth-child"
  WARNINGS=$((WARNINGS + COUNT))
fi

# Check: console.log in tests
COUNT=$(xargs grep -rn "console\.log" < "$TMPFILE" 2>/dev/null | wc -l | tr -d ' ')
if [ "$COUNT" -gt 0 ]; then
  echo "  ⚠ Debug logs: $COUNT lines have console.log in test files"
  WARNINGS=$((WARNINGS + COUNT))
fi

rm -f "$TMPFILE"

# Summary
echo ""
TOTAL=$((ISSUES + WARNINGS))
if [ "$TOTAL" -eq 0 ]; then
  echo "  ✔ No anti-patterns detected. Nice work."
else
  echo "  $ISSUES issues, $WARNINGS warnings found."
fi
echo ""
