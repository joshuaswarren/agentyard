#!/usr/bin/env bash
#
# Test script for agentsmd multi-repo functionality
#
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test directory setup
TEST_BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURES_DIR="${TEST_BASE_DIR}/fixtures/multi-repo-test"
AGENTSMD_BIN="${TEST_BASE_DIR}/../bin/agentsmd"

# Create a temporary test project
TEST_PROJECT_DIR=$(mktemp -d "${TEST_BASE_DIR}/test-project.XXXXXX")
trap "rm -rf '$TEST_PROJECT_DIR'" EXIT

echo "Testing agentsmd multi-repo functionality..."
echo "Test project: $TEST_PROJECT_DIR"

# Initialize test project
cd "$TEST_PROJECT_DIR"
git init --quiet

# Test 1: List migrations from multiple repos
echo -e "\n${YELLOW}Test 1: List migrations from multiple repos${NC}"
export HOME="${FIXTURES_DIR}"
export AGENTSMD_ROOT="${FIXTURES_DIR}/public/agentsmd"

# Create some test migrations
mkdir -p "${FIXTURES_DIR}/public/agentsmd/best-practices"
echo "# Description: Public migration" > "${FIXTURES_DIR}/public/agentsmd/best-practices/001-public.md"
mkdir -p "${FIXTURES_DIR}/team/agentsmd/best-practices"
echo "# Description: Team migration" > "${FIXTURES_DIR}/team/agentsmd/best-practices/002-team.md"

if "$AGENTSMD_BIN" --list-migrations | grep -q "From.*public"; then
    echo -e "${GREEN}✓ Multi-repo migration listing works${NC}"
else
    echo -e "${RED}✗ Multi-repo migration listing failed${NC}"
fi

# Test 2: Check rules syncing from multiple repos
echo -e "\n${YELLOW}Test 2: Rules syncing from multiple repos${NC}"
"$AGENTSMD_BIN" --check-only --verbose 2>&1 | tee test-output.log

# Check if rules from different repos are detected
if grep -q "Would sync.*base-rule.mdc.*from.*private" test-output.log || \
   grep -q "Would sync.*team-rule.mdc.*from.*team" test-output.log || \
   grep -q "Skipping.*base-rule.mdc.*already processed" test-output.log; then
    echo -e "${GREEN}✓ Multi-repo rule discovery works${NC}"
else
    echo -e "${RED}✗ Multi-repo rule discovery failed${NC}"
    echo "Debug: Checking log for rule-related messages..."
    grep -E "(rule|sync:|Skipping)" test-output.log || echo "No rule-related messages found"
fi

# Test 3: Verify precedence (private > team > public)
echo -e "\n${YELLOW}Test 3: Verify repo precedence${NC}"
# This test would require actually running the sync and checking which version of base-rule.mdc is used
# For now, we'll check the verbose output for skip messages

if grep -q "already processed" test-output.log; then
    echo -e "${GREEN}✓ Repo precedence handling detected${NC}"
else
    echo -e "${YELLOW}⚠ Could not verify repo precedence from check-only mode${NC}"
fi

# Cleanup test migrations
rm -f "${FIXTURES_DIR}/public/agentsmd/best-practices/001-public.md"
rm -f "${FIXTURES_DIR}/team/agentsmd/best-practices/002-team.md"

echo -e "\n${GREEN}Multi-repo testing complete${NC}"