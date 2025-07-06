#!/usr/bin/env bash
#
# Simplified test for starttask --plan and --implement flags
#

set -euo pipefail

echo "🧪 Testing starttask flag enhancements..."

# Count tests
PASSED=0
FAILED=0
TOTAL=0

# Simple test function
run_test() {
  local name="$1"
  local result="$2"
  ((TOTAL++))
  
  if [ "$result" = "true" ]; then
    echo "✅ $name"
    ((PASSED++))
  else
    echo "❌ $name"
    ((FAILED++))
  fi
}

# Test 1: Check if starttask exists
test -f bin/starttask && result="true" || result="false"
run_test "Starttask exists" "$result"

# Test 2: Check for --plan flag
grep -q -- "--plan" bin/starttask && result="true" || result="false"
run_test "Contains --plan flag" "$result"

# Test 3: Check for --implement flag
grep -q -- "--implement" bin/starttask && result="true" || result="false"
run_test "Contains --implement flag" "$result"

# Test 4: Check for -p flag
grep -q -- "-p)" bin/starttask && result="true" || result="false"
run_test "Contains -p short flag" "$result"

# Test 5: Check for -i flag
grep -q -- "-i)" bin/starttask && result="true" || result="false"
run_test "Contains -i short flag" "$result"

# Test 6: Check for tmux send-keys
grep -q "tmux send-keys" bin/starttask && result="true" || result="false"
run_test "Contains tmux send-keys" "$result"

# Test 7: Check for sleep delay
grep -q "sleep 3" bin/starttask && result="true" || result="false"
run_test "Contains sleep delay" "$result"

# Test 8: Check for claude_command variable
grep -q "claude_command=" bin/starttask && result="true" || result="false"
run_test "Contains claude_command variable" "$result"

# Test 9: Check for /plan command
grep -q "/plan GitHub issue" bin/starttask && result="true" || result="false"
run_test "Contains /plan command format" "$result"

# Test 10: Check for /implement-gh-issue command
grep -q "/implement-gh-issue" bin/starttask && result="true" || result="false"
run_test "Contains /implement-gh-issue command" "$result"

# Test 11: Check for error when both flags used
grep -q "Cannot use both --plan and --implement" bin/starttask && result="true" || result="false"
run_test "Contains both flags error" "$result"

# Test 12: Check help includes new flags
bin/starttask --help 2>&1 | grep -q -- "--plan" && result="true" || result="false"
run_test "Help includes --plan" "$result"

# Test 13: Check help includes examples
bin/starttask --help 2>&1 | grep -q "With Claude commands:" && result="true" || result="false"
run_test "Help includes examples" "$result"

# Summary
echo ""
echo "==============================="
echo "Test Summary"
echo "==============================="
echo "Total: $TOTAL"
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [ $FAILED -eq 0 ]; then
  echo ""
  echo "✅ All tests passed!"
  exit 0
else
  echo ""
  echo "❌ Some tests failed"
  exit 1
fi