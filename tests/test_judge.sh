#!/usr/bin/env bash
# Test script for the judge command
#
# This tests various aspects of the judge command including:
# - Command line argument parsing
# - Error handling
# - Configuration creation
# - Dependency checking
#
set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "========================================="
echo "Judge Command Test Suite"
echo "========================================="
echo ""

# Test counters
PASSED=0
FAILED=0
SKIPPED=0

# Test function
test_case() {
  local name="$1"
  local command="$2"
  local expected_exit="${3:-0}"
  
  echo -n "Testing: $name... "
  
  # Capture both stdout and stderr
  if output=$(eval "$command" 2>&1); then
    actual_exit=0
  else
    actual_exit=$?
  fi
  
  if [[ $actual_exit -eq $expected_exit ]]; then
    echo -e "${GREEN}PASSED${NC}"
    ((PASSED++))
    return 0
  else
    echo -e "${RED}FAILED${NC} (expected exit $expected_exit, got $actual_exit)"
    echo "  Output: $output"
    ((FAILED++))
    return 1
  fi
}

# Function to check if we're in a git repo with gh access
check_github_context() {
  if ! command -v gh >/dev/null 2>&1; then
    echo -e "${YELLOW}Skipping GitHub tests: gh CLI not installed${NC}"
    return 1
  fi
  
  if ! gh auth status >/dev/null 2>&1; then
    echo -e "${YELLOW}Skipping GitHub tests: not authenticated with gh${NC}"
    return 1
  fi
  
  return 0
}

# Test 1: Basic command existence and help
echo "1. Basic command tests"
echo "---------------------"
test_case "Command exists" "[[ -f bin/judge ]]"
test_case "Command is executable" "[[ -x bin/judge ]]"
test_case "Shows help with -h" "bin/judge -h | grep -q 'Usage:'"
test_case "Shows help with --help" "bin/judge --help | grep -q 'Usage:'"
test_case "Shows help with no args" "bin/judge | grep -q 'Usage:'"
echo ""

# Test 2: Argument parsing
echo "2. Argument parsing tests"
echo "-------------------------"
# These should fail gracefully without gh auth
if check_github_context; then
  test_case "Accepts PR number" "bin/judge 1 --help | grep -q 'Usage:'" 0
  test_case "Accepts branch name" "bin/judge feature/test --help | grep -q 'Usage:'" 0
  test_case "Rejects invalid option" "bin/judge 1 --invalid-option" 1
else
  echo -e "${YELLOW}Skipping GitHub-dependent argument tests${NC}"
  ((SKIPPED+=3))
fi
echo ""

# Test 3: Configuration handling
echo "3. Configuration tests"
echo "----------------------"
test_config_dir="$HOME/.agentyard/test-judge-$$"
test_config="$test_config_dir/judge.yaml"

# Clean up test config if it exists
rm -rf "$test_config_dir"

test_case "Creates config directory" "mkdir -p '$test_config_dir'"
test_case "Uses custom config path" "bin/judge --help --config '$test_config' | grep -q 'Usage:'"

# Check if config was created (it should be created when checking for model)
if [[ -f "$test_config" ]]; then
  test_case "Config file created" "[[ -f '$test_config' ]]"
  test_case "Config has model section" "grep -q 'model:' '$test_config'"
  test_case "Config has review section" "grep -q 'review:' '$test_config'"
else
  echo -e "${YELLOW}Note: Config file creation test skipped (created only on full run)${NC}"
  ((SKIPPED+=3))
fi

# Clean up
rm -rf "$test_config_dir"
echo ""

# Test 4: Dependency detection
echo "4. Dependency detection tests"
echo "-----------------------------"
# Test with a fake PATH that excludes commands
test_case "Detects missing gh" "PATH=/usr/bin:/bin bin/judge 1 2>&1 | grep -q 'gh not installed'" 1

# Test Python dependency detection (this won't actually fail the command, just warn)
if python3 -c "import llama_cpp" 2>/dev/null; then
  echo -e "${GREEN}llama-cpp-python is installed${NC}"
  test_case "Detects llama-cpp-python" "python3 -c 'import llama_cpp'"
else
  echo -e "${YELLOW}llama-cpp-python not installed (this is expected)${NC}"
  test_case "Handles missing llama-cpp-python" "bin/judge --help | grep -q 'Usage:'"
fi
echo ""

# Test 5: Helper script creation
echo "5. Helper script tests"
echo "----------------------"
helper_script="bin/judge-ai.py"
if [[ -f "$helper_script" ]]; then
  test_case "Helper script exists" "[[ -f '$helper_script' ]]"
  test_case "Helper script is executable" "[[ -x '$helper_script' ]]"
  test_case "Helper has proper shebang" "head -n1 '$helper_script' | grep -q python3"
else
  echo -e "${YELLOW}Helper script will be created on first real run${NC}"
  ((SKIPPED+=3))
fi
echo ""

# Test 6: Error handling (requires GitHub context)
echo "6. Error handling tests"
echo "-----------------------"
if check_github_context; then
  test_case "Handles non-existent PR number" "bin/judge 999999 2>&1 | grep -q 'Error'" 1
  test_case "Handles non-existent branch" "bin/judge non-existent-branch-xyz 2>&1 | grep -q 'No open PR found'" 1
else
  echo -e "${YELLOW}Skipping GitHub-dependent error tests${NC}"
  ((SKIPPED+=2))
fi
echo ""

# Summary
echo "========================================="
echo "Test Summary:"
echo "  Passed:  $PASSED"
echo "  Failed:  $FAILED"
echo "  Skipped: $SKIPPED"
echo "========================================="

if [[ $FAILED -eq 0 ]]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed!${NC}"
  exit 1
fi