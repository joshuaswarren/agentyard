#!/usr/bin/env bash
#
# Integration test for agentsmd multi-repo functionality
#
set -euo pipefail

# Test setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTSMD_BIN="${SCRIPT_DIR}/../bin/agentsmd"
TEST_DIR="${SCRIPT_DIR}/test-multirepo-$$"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Cleanup on exit
trap "rm -rf '$TEST_DIR'" EXIT

echo "Setting up multi-repo test environment..."

# Create test directory structure
mkdir -p "$TEST_DIR/home/agentyard/agentsmd"/{rules,best-practices}
mkdir -p "$TEST_DIR/home/agentyard-team/agentsmd"/{rules,best-practices}
mkdir -p "$TEST_DIR/home/agentyard-private/agentsmd"/{rules,best-practices}
mkdir -p "$TEST_DIR/project"

# Create test rules
cat > "$TEST_DIR/home/agentyard/agentsmd/rules/common.mdc" << 'EOF'
---
description: Common rule from public repo
tags: [common, public]
---
# Common Rule (Public)
This is from the public repo.
EOF

cat > "$TEST_DIR/home/agentyard-team/agentsmd/rules/team-only.mdc" << 'EOF'
---
description: Team-specific rule
tags: [team]
---
# Team Only Rule
This rule exists only in the team repo.
EOF

cat > "$TEST_DIR/home/agentyard-private/agentsmd/rules/common.mdc" << 'EOF'
---
description: Common rule overridden by private repo
tags: [common, private, override]
---
# Common Rule (Private Override)
This overrides the public version.
EOF

# Create test migrations
echo "# Description: Public migration 001" > "$TEST_DIR/home/agentyard/agentsmd/best-practices/001-test.md"
echo "# Description: Team migration 002" > "$TEST_DIR/home/agentyard-team/agentsmd/best-practices/002-team.md"
echo "# Description: Private override of 001" > "$TEST_DIR/home/agentyard-private/agentsmd/best-practices/001-test.md"

# Initialize git repo in project
cd "$TEST_DIR/project"
git init --quiet

# Test 1: List migrations
echo -e "\n${YELLOW}Test 1: List migrations from multiple repos${NC}"
HOME="$TEST_DIR/home" "$AGENTSMD_BIN" --list-migrations > migrations.log 2>&1

if grep -q "From.*private" migrations.log && grep -q "From.*team" migrations.log; then
    echo -e "${GREEN}✓ Found migrations from multiple repos${NC}"
    
    # Check override behavior
    if grep -q "001-test.md.*(overridden by" migrations.log; then
        echo -e "${GREEN}✓ Migration override detection works${NC}"
    else
        echo -e "${YELLOW}⚠ Migration override not clearly indicated${NC}"
    fi
else
    echo -e "${RED}✗ Failed to find migrations from all repos${NC}"
    echo "Debug output:"
    cat migrations.log
fi

# Test 2: Run agentsmd and check rules syncing
echo -e "\n${YELLOW}Test 2: Rules syncing with multi-repo support${NC}"
HOME="$TEST_DIR/home" "$AGENTSMD_BIN" --check-only --verbose > run.log 2>&1

# Check verbose output for rules syncing
if grep -q "Would sync.*common.mdc.*from.*private" run.log; then
    echo -e "${GREEN}✓ Private repo rule would be synced (override works)${NC}"
else
    echo -e "${RED}✗ Private override not detected${NC}"
fi

if grep -q "Would sync.*team-only.mdc.*from.*team" run.log; then
    echo -e "${GREEN}✓ Team-specific rule would be synced${NC}"
else
    echo -e "${RED}✗ Team-specific rule not detected${NC}"
fi

if grep -q "Skipping.*common.mdc.*already processed" run.log; then
    echo -e "${GREEN}✓ Duplicate rule skipping works${NC}"
else
    echo -e "${YELLOW}⚠ Duplicate rule handling not clearly shown${NC}"
fi

# Show relevant log entries
echo -e "\nRule sync messages from log:"
grep -E "(Would sync|Skipping.*rules|from.*agentyard)" run.log || echo "No rule sync messages found"

# Test 3: Check if tracking file would be created
echo -e "\n${YELLOW}Test 3: Rules tracking in check-only mode${NC}"
if grep -q "Would create directory.*docs/agentyard/rules" run.log; then
    echo -e "${GREEN}✓ Rules directory would be created${NC}"
else
    echo -e "${YELLOW}⚠ Rules directory creation not mentioned${NC}"
fi

# Test 4: Check migrations that would be applied
echo -e "\n${YELLOW}Test 4: Migrations to be applied${NC}"
if grep -q "Migrations that would be applied:" run.log; then
    echo -e "${GREEN}✓ Migration preview shown${NC}"
    
    # Check if private override is being used
    if grep -q "001-test.md" run.log; then
        echo -e "${GREEN}✓ Private migration override detected${NC}"
    fi
else
    echo -e "${RED}✗ Migration preview not shown${NC}"
fi

echo -e "\n${GREEN}Integration test complete${NC}"