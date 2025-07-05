#!/usr/bin/env bash
#
# Test script for /plan command enhancements
# Tests:
# - Codebase analysis phase
# - Interactive questions format
# - Plan-only behavior (no implementation)
# - GitHub issue update format
#

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "🧪 Testing /plan command enhancements..."

# Test counters
PASSED=0
FAILED=0

# Test function
test_case() {
  local name="$1"
  local command="$2"
  local expected_pattern="$3"
  
  echo -n "Testing: $name... "
  
  # Check if file/pattern exists
  if eval "$command" | grep -q "$expected_pattern"; then
    echo -e "${GREEN}PASSED${NC}"
    ((PASSED++))
    return 0
  else
    echo -e "${RED}FAILED${NC}"
    echo "  Expected pattern: $expected_pattern"
    ((FAILED++))
    return 1
  fi
}

echo -e "\n${YELLOW}Test Group 1: Command file structure${NC}"
echo "====================================="

# Test that plan.md exists and has correct content
test_case "Plan command file exists" "ls claude-commands/plan.md 2>/dev/null" "plan.md"
test_case "Contains codebase analysis phase" "cat claude-commands/plan.md" "Phase 1: Analyze Codebase First"
test_case "Contains interactive questions phase" "cat claude-commands/plan.md" "Phase 3: Interactive Questions"
test_case "Contains planning only warning" "cat claude-commands/plan.md" "YOU ARE A PLANNER ONLY"
test_case "Contains implementation warning" "cat claude-commands/plan.md" "Do NOT start implementing"
test_case "Contains example interaction" "cat claude-commands/plan.md" "Example Interaction Flow"

echo -e "\n${YELLOW}Test Group 2: Documentation updates${NC}"
echo "===================================="

# Test documentation updates
test_case "Plan docs exist" "ls docs/plan-command.md 2>/dev/null" "plan-command.md"
test_case "Docs mention codebase analysis" "cat docs/plan-command.md" "Codebase Analysis"
test_case "Docs mention interactive questions" "cat docs/plan-command.md" "Interactive Questions"
test_case "Docs emphasize planning only" "cat docs/plan-command.md" "planning only"
test_case "Docs include example flow" "cat docs/plan-command.md" "Interactive Example"

echo -e "\n${YELLOW}Test Group 3: GitHub integration${NC}"
echo "================================="

# Test GitHub issue update format in plan.md
test_case "Contains GitHub issue update code" "cat claude-commands/plan.md" "gh issue edit"
test_case "Adds Implementation Plan header" "cat claude-commands/plan.md" "Implementation Plan"
test_case "Includes generation date" "cat claude-commands/plan.md" "Generated on"
test_case "Preserves existing content" "cat claude-commands/plan.md" "CURRENT_BODY"

echo -e "\n${YELLOW}Test Group 4: Question handling${NC}"
echo "================================"

# Test question format and limits
test_case "Mentions 3 round limit" "cat claude-commands/plan.md" "maximum 3 rounds"
test_case "Batch question format" "cat claude-commands/plan.md" "Present all questions at once"
test_case "Check for issue references" "cat claude-commands/plan.md" "Check responses for GitHub issue references"

echo -e "\n${YELLOW}Test Group 5: Integration points${NC}"
echo "================================="

# Test agentyard integration
test_case "Suggests starttask command" "cat claude-commands/plan.md" "starttask"
test_case "Example includes starttask" "cat docs/plan-command.md" "starttask"
test_case "Never auto-implements" "cat claude-commands/plan.md" "Your role ends with the plan"

echo -e "\n${YELLOW}Test Group 6: File validation${NC}"
echo "=============================="

# Ensure no references to "Claude Planner" remain
if grep -r "by Claude Planner" claude-commands/ docs/ 2>/dev/null; then
  echo -e "${RED}FAILED${NC} - Found 'by Claude Planner' references"
  ((FAILED++))
else
  echo -e "${GREEN}PASSED${NC} - No 'by Claude Planner' references found"
  ((PASSED++))
fi

# Summary
echo -e "\n========================================="
echo "Test Summary:"
echo "  Passed:  $PASSED"
echo "  Failed:  $FAILED"
echo "========================================="

if [[ $FAILED -eq 0 ]]; then
  echo -e "${GREEN}All plan command tests passed! 🎉${NC}"
  echo -e "\nPlan command features verified:"
  echo "  • Codebase pre-analysis phase"
  echo "  • Interactive question flow"
  echo "  • Planning-only behavior"
  echo "  • GitHub issue integration"
  echo "  • Proper documentation"
  exit 0
else
  echo -e "${RED}Some tests failed!${NC}"
  exit 1
fi