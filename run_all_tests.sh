#!/usr/bin/env bash
#
# Run all test suites for agentyard
#

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}       Agentyard Test Suite Runner      ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Track overall results
TOTAL_PASSED=0
TOTAL_FAILED=0
FAILED_TESTS=()

# Function to run a test script
run_test() {
  local test_name="$1"
  local test_script="$2"
  
  echo -e "\n${YELLOW}Running: $test_name${NC}"
  echo "----------------------------------------"
  
  if [[ -f "$test_script" && -x "$test_script" ]]; then
    if "$test_script"; then
      echo -e "${GREEN}✓ $test_name completed successfully${NC}"
      ((TOTAL_PASSED++))
    else
      echo -e "${RED}✗ $test_name failed${NC}"
      ((TOTAL_FAILED++))
      FAILED_TESTS+=("$test_name")
    fi
  else
    echo -e "${RED}✗ Test script not found or not executable: $test_script${NC}"
    ((TOTAL_FAILED++))
    FAILED_TESTS+=("$test_name (script missing)")
  fi
}

# Run all test suites
run_test "Basic Judge Tests" "./tests/test_judge.sh"
run_test "Judge Improvements Tests" "./tests/test_judge_improvements.sh"
run_test "Judge New Features Tests" "./tests/test_judge_new_features.sh"
run_test "Plan Command Tests" "./tests/test_plan_command.sh"
run_test "Agentsmd Tests" "./tests/test_agentsmd.sh"

# Summary
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}           Overall Test Summary         ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Test Suites Passed: ${GREEN}$TOTAL_PASSED${NC}"
echo -e "Test Suites Failed: ${RED}$TOTAL_FAILED${NC}"

if [[ $TOTAL_FAILED -gt 0 ]]; then
  echo -e "\n${RED}Failed test suites:${NC}"
  for test in "${FAILED_TESTS[@]}"; do
    echo -e "  - $test"
  done
  echo -e "\n${RED}OVERALL RESULT: FAILED${NC}"
  exit 1
else
  echo -e "\n${GREEN}OVERALL RESULT: ALL TESTS PASSED! 🎉${NC}"
  exit 0
fi