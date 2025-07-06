#!/usr/bin/env bash
#
# Test script for agentsmd rule syncing functionality
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test directory setup
TEST_DIR=$(mktemp -d)
PROJECT_DIR="$TEST_DIR/test-project"
AGENTSMD_ROOT="$TEST_DIR/agentsmd"

# Create mock agentsmd structure
mkdir -p "$AGENTSMD_ROOT/best-practices"
mkdir -p "$AGENTSMD_ROOT/rules"
mkdir -p "$AGENTSMD_ROOT/cache"

# Create simple migrations without Claude prompts
cat > "$AGENTSMD_ROOT/best-practices/001-test.md" << 'EOF'
# Test Migration

This is a test migration without Claude prompts.
EOF

cat > "$AGENTSMD_ROOT/best-practices/002-another.md" << 'EOF'
# Another Test Migration

This ensures we have content in AGENTS.md.
EOF

# Create test rule files
cat > "$AGENTSMD_ROOT/rules/test-rule.mdc" << 'EOF'
---
description: Test rule
---

# Test Rule

This is a test rule file.
EOF

mkdir -p "$AGENTSMD_ROOT/rules/subcategory"
cat > "$AGENTSMD_ROOT/rules/subcategory/nested-rule.mdc" << 'EOF'
---
description: Nested test rule
---

# Nested Rule

This is a nested rule file.
EOF

# Create test project
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Initialize git repo
git init --quiet
git config user.email "test@example.com"
git config user.name "Test User"
echo "test" > test.txt
git add .
git commit -m "Initial commit" --quiet

# Export test environment
export AGENTSMD_ROOT="$AGENTSMD_ROOT"

# Function to run agentsmd with test environment
run_agentsmd() {
    # Use the actual agentsmd script with our test root
    local agentsmd_path="/Users/joshuawarren/agentyard/bin/agentsmd"
    # Override development mode detection by ensuring our test dir is used
    bash -c "cd '$PROJECT_DIR' && AGENTSMD_ROOT='$AGENTSMD_ROOT' $agentsmd_path $*"
}

# Function to check if file exists
assert_file_exists() {
    local file="$1"
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✓${NC} File exists: $file"
        return 0
    else
        echo -e "${RED}✗${NC} File missing: $file"
        return 1
    fi
}

# Function to check if file contains text
assert_file_contains() {
    local file="$1"
    local text="$2"
    if grep -q "$text" "$file"; then
        echo -e "${GREEN}✓${NC} File contains expected text: $text"
        return 0
    else
        echo -e "${RED}✗${NC} File missing expected text: $text"
        return 1
    fi
}

# Test 1: Basic rule syncing
echo -e "\n${YELLOW}Test 1: Basic rule syncing${NC}"
run_agentsmd --verbose

# Check if rules were synced
assert_file_exists "$PROJECT_DIR/docs/agentyard/rules/test-rule.mdc"
assert_file_exists "$PROJECT_DIR/docs/agentyard/rules/subcategory/nested-rule.mdc"
assert_file_exists "$PROJECT_DIR/.agentyard-rules.yml"

# Check if AGENTS.md contains rule references
assert_file_exists "$PROJECT_DIR/AGENTS.md"
assert_file_contains "$PROJECT_DIR/AGENTS.md" "## Additional Rules and References"
assert_file_contains "$PROJECT_DIR/AGENTS.md" "@docs/agentyard/rules/test-rule.mdc"
assert_file_contains "$PROJECT_DIR/AGENTS.md" "@docs/agentyard/rules/subcategory/nested-rule.mdc"

# Test 2: Local modifications are preserved
echo -e "\n${YELLOW}Test 2: Local modifications are preserved${NC}"

# Modify a local rule
echo "Local modification" >> "$PROJECT_DIR/docs/agentyard/rules/test-rule.mdc"

# Update the source rule
echo "Upstream change" >> "$AGENTSMD_ROOT/rules/test-rule.mdc"

# Run agentsmd again
run_agentsmd --verbose 2>&1 | tee "$TEST_DIR/output.log"

# Check that local modification was preserved
if grep -q "Local modification" "$PROJECT_DIR/docs/agentyard/rules/test-rule.mdc"; then
    echo -e "${GREEN}✓${NC} Local modifications preserved"
else
    echo -e "${RED}✗${NC} Local modifications were overwritten"
    exit 1
fi

# Check for skip warning
if grep -q "Skipped.*with local modifications" "$TEST_DIR/output.log"; then
    echo -e "${GREEN}✓${NC} Skip warning displayed"
else
    echo -e "${RED}✗${NC} No skip warning found"
    exit 1
fi

# Test 3: New rules are added
echo -e "\n${YELLOW}Test 3: New rules are added${NC}"

# Add a new rule
cat > "$AGENTSMD_ROOT/rules/new-rule.mdc" << 'EOF'
---
description: New rule
---

# New Rule

This is a new rule file.
EOF

# Run agentsmd again
run_agentsmd --verbose

# Check if new rule was synced
assert_file_exists "$PROJECT_DIR/docs/agentyard/rules/new-rule.mdc"
assert_file_contains "$PROJECT_DIR/AGENTS.md" "@docs/agentyard/rules/new-rule.mdc"

# Test 4: Check-only mode
echo -e "\n${YELLOW}Test 4: Check-only mode${NC}"

# Add another new rule
cat > "$AGENTSMD_ROOT/rules/check-only-rule.mdc" << 'EOF'
# Check Only Rule
EOF

# Run in check-only mode
run_agentsmd --check-only 2>&1 | tee "$TEST_DIR/check-output.log"

# Verify rule was not actually synced
if [[ -f "$PROJECT_DIR/docs/agentyard/rules/check-only-rule.mdc" ]]; then
    echo -e "${RED}✗${NC} Check-only mode created file"
    exit 1
else
    echo -e "${GREEN}✓${NC} Check-only mode did not create file"
fi

# Cleanup
cd /
rm -rf "$TEST_DIR"

echo -e "\n${GREEN}All tests passed!${NC}"
exit 0