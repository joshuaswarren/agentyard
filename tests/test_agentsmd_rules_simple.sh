#!/usr/bin/env bash
#
# Simple test script for agentsmd rule syncing functionality
# Tests only the rule sync logic without full agentsmd migration system
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the agentsmd script path
AGENTSMD_SCRIPT="/Users/joshuawarren/agentyard/bin/agentsmd"

# Source the functions we need to test
source "$AGENTSMD_SCRIPT" --help > /dev/null 2>&1 || true

# Override some functions to avoid running the full script
main() { :; }

# Test directory setup
TEST_DIR=$(mktemp -d)
PROJECT_DIR="$TEST_DIR/test-project"
RULES_DIR="$TEST_DIR/rules"

# Create test structure
mkdir -p "$RULES_DIR"
mkdir -p "$PROJECT_DIR"

# Function to run tests
run_test() {
    local test_name="$1"
    echo -e "\n${YELLOW}Test: $test_name${NC}"
}

# Function to check result
check_result() {
    local condition="$1"
    local message="$2"
    if eval "$condition"; then
        echo -e "${GREEN}✓${NC} $message"
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        return 1
    fi
}

# Test 1: Calculate checksum
run_test "Calculate checksum function"
echo "test content" > "$TEST_DIR/test.txt"
checksum=$(calculate_checksum "$TEST_DIR/test.txt")
check_result "[[ -n '$checksum' ]]" "Checksum calculated: ${checksum:0:8}..."

# Test 2: Rule tracking file functions
run_test "Rule tracking file functions"
test_rules_content="# Agentyard rules tracking
rules:
- path: test.mdc
  checksum: abc123
  synced_at: 2025-01-01T00:00:00Z"

write_rules_file "$TEST_DIR/rules.yml" "$test_rules_content"
read_content=$(read_rules_file "$TEST_DIR/rules.yml")
check_result "[[ '$read_content' == '$test_rules_content' ]]" "Read/write rules file works"

# Test 3: Get rule entry
run_test "Get rule entry from tracking"
entry=$(get_rule_entry "$test_rules_content" "test.mdc")
check_result "[[ -n '$entry' ]]" "Found rule entry"
check_result "[[ '$entry' == *'abc123'* ]]" "Entry contains correct checksum"

# Test 4: Get project rules
run_test "Get project rules function"
mkdir -p "$PROJECT_DIR/docs/agentyard/rules/subdir"
touch "$PROJECT_DIR/docs/agentyard/rules/rule1.mdc"
touch "$PROJECT_DIR/docs/agentyard/rules/subdir/rule2.mdc"
touch "$PROJECT_DIR/docs/agentyard/rules/not-mdc.txt"

rules=$(get_project_rules "$PROJECT_DIR")
check_result "[[ '$rules' == *'docs/agentyard/rules/rule1.mdc'* ]]" "Found rule1.mdc"
check_result "[[ '$rules' == *'docs/agentyard/rules/subdir/rule2.mdc'* ]]" "Found nested rule2.mdc"
check_result "[[ '$rules' != *'not-mdc.txt'* ]]" "Ignored non-.mdc file"

# Test 5: Basic sync logic (without full sync_rules function)
run_test "Checksum comparison logic"
echo "original content" > "$TEST_DIR/original.txt"
echo "original content" > "$TEST_DIR/same.txt"
echo "modified content" > "$TEST_DIR/modified.txt"

orig_checksum=$(calculate_checksum "$TEST_DIR/original.txt")
same_checksum=$(calculate_checksum "$TEST_DIR/same.txt")
mod_checksum=$(calculate_checksum "$TEST_DIR/modified.txt")

check_result "[[ '$orig_checksum' == '$same_checksum' ]]" "Same content produces same checksum"
check_result "[[ '$orig_checksum' != '$mod_checksum' ]]" "Different content produces different checksum"

# Cleanup
rm -rf "$TEST_DIR"

echo -e "\n${GREEN}All tests passed!${NC}"
exit 0