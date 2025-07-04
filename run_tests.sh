#!/usr/bin/env bash
# Simple test script for agentyard enhancements

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "Testing agentyard enhancements..."
echo "================================="

# Test counters
PASSED=0
FAILED=0

# Simple test function
test_case() {
  local name="$1"
  local condition="$2"
  
  echo -n "Testing $name... "
  if eval "$condition"; then
    echo -e "${GREEN}PASSED${NC}"
    ((PASSED++))
  else
    echo -e "${RED}FAILED${NC}"
    ((FAILED++))
  fi
}

# Test 1: Check if new commands exist
test_case "list-tasks exists" "[[ -f bin/list-tasks ]]"
test_case "sync-active-tasks exists" "[[ -f bin/sync-active-tasks ]]"
test_case "list-tasks is executable" "[[ -x bin/list-tasks ]]"
test_case "sync-active-tasks is executable" "[[ -x bin/sync-active-tasks ]]"

# Test 2: Check starttask modifications
echo ""
echo "Checking starttask modifications..."
test_case "Claude Code check" "grep -q 'command -v claude' bin/starttask"
test_case "Claude Code install" "grep -q 'npm install -g @anthropic-ai/claude-code' bin/starttask"
test_case "Log directory creation" "grep -q 'mkdir -p \"\$log_dir\"' bin/starttask"
test_case "Branch sanitization" "grep -q 'tr ./.._' bin/starttask"
test_case "Active tasks update" "grep -q 'active_tasks_file=' bin/starttask"
test_case "Tmux pipe configuration" "grep -q 'tmux pipe-pane' bin/starttask"
test_case "Claude launch command" "grep -q 'claude --dangerously-skip-permissions' bin/starttask"

# Test 3: Check finishtask modifications
echo ""
echo "Checking finishtask modifications..."
test_case "Active tasks removal" "grep -q 'active_tasks_file=' bin/finishtask"
test_case "AWK session removal" "grep -q 'awk -v session=' bin/finishtask"

# Test 4: Check cleanup-worktrees modifications
echo ""
echo "Checking cleanup-worktrees modifications..."
test_case "Active tasks function" "grep -q 'remove_from_active_tasks' bin/cleanup-worktrees"
test_case "Function call" "grep -q 'remove_from_active_tasks \"\$project_name\" \"\$slug\"' bin/cleanup-worktrees"

# Summary
echo ""
echo "================================="
echo "Test Summary:"
echo "  Passed: $PASSED"
echo "  Failed: $FAILED"
echo ""

if [[ $FAILED -eq 0 ]]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed!${NC}"
  exit 1
fi