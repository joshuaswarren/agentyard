#!/usr/bin/env bash
#
# Test script for the mentor command
#
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Test counter
TESTS_RUN=0
TESTS_PASSED=0

# Test function
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_exit_code="${3:-0}"
    
    echo -n "Testing: $test_name ... "
    TESTS_RUN=$((TESTS_RUN + 1))
    
    set +e
    output=$($command 2>&1)
    exit_code=$?
    set -e
    
    if [[ $exit_code -eq $expected_exit_code ]]; then
        echo -e "${GREEN}PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAILED${NC}"
        echo "  Expected exit code: $expected_exit_code"
        echo "  Actual exit code: $exit_code"
        echo "  Output: $output"
    fi
}

echo "🧪 Testing mentor command..."
echo

# Test 1: Check if script exists and is executable
if [[ -x "bin/mentor" ]]; then
    echo -e "${GREEN}✓${NC} mentor script exists and is executable"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗${NC} mentor script not found or not executable"
    exit 1
fi

# Test 2: Help output
run_test "Help flag" "bin/mentor -h" 0

# Test 3: Check for git repo (should fail if not in repo)
# Create a temporary non-git directory
temp_dir=$(mktemp -d)
run_test "Not in git repo" "cd $temp_dir && $PWD/bin/mentor" 1
rm -rf "$temp_dir"

# Test 4: Missing API key
# Temporarily unset API key
OLD_API_KEY="${OPENAI_API_KEY:-}"
unset OPENAI_API_KEY
run_test "Missing API key" "bin/mentor" 1
if [[ -n "$OLD_API_KEY" ]]; then
    export OPENAI_API_KEY="$OLD_API_KEY"
fi

# Test 5: Invalid commit hash
if [[ -n "${OPENAI_API_KEY:-}" ]]; then
    run_test "Invalid commit hash" "bin/mentor invalid_commit_hash" 1
else
    echo -e "${YELLOW}⚠${NC}  Skipping invalid commit test (no API key)"
fi

# Test 6: Python syntax check
echo -n "Testing: Python syntax validation ... "
TESTS_RUN=$((TESTS_RUN + 1))
if python3 -m py_compile bin/mentor 2>/dev/null; then
    echo -e "${GREEN}PASSED${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    rm -f bin/__pycache__/mentor.cpython-*.pyc
    rmdir bin/__pycache__ 2>/dev/null || true
else
    echo -e "${RED}FAILED${NC}"
    echo "  Python syntax errors found"
fi

# Test 7: Check imports
echo -n "Testing: Required imports ... "
TESTS_RUN=$((TESTS_RUN + 1))
if python3 -c "import argparse, json, os, re, subprocess, sys" 2>/dev/null; then
    echo -e "${GREEN}PASSED${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}FAILED${NC}"
    echo "  Missing required Python modules"
fi

# Test 8: Model argument parsing
if [[ -n "${OPENAI_API_KEY:-}" ]]; then
    # This should fail at the git commit stage, not API key stage
    run_test "Model argument" "bin/mentor --model gpt-4 invalid_commit" 1
else
    echo -e "${YELLOW}⚠${NC}  Skipping model argument test (no API key)"
fi

echo
echo "========================================="
echo "Test Results: $TESTS_PASSED/$TESTS_RUN passed"
echo "========================================="

if [[ $TESTS_PASSED -eq $TESTS_RUN ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi