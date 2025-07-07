#!/usr/bin/env bash
set -euo pipefail

# Create isolated test environment
TEST_DIR=$(mktemp -d)
echo "Test directory: $TEST_DIR"

# Set up fixture structure
mkdir -p "$TEST_DIR/home/agentyard/agentsmd/rules"
mkdir -p "$TEST_DIR/home/agentyard-team/agentsmd/rules"
mkdir -p "$TEST_DIR/home/agentyard-private/agentsmd/rules"

# Create test rules
echo "Public rule" > "$TEST_DIR/home/agentyard/agentsmd/rules/test.mdc"
echo "Team rule" > "$TEST_DIR/home/agentyard-team/agentsmd/rules/team.mdc"
echo "Private override" > "$TEST_DIR/home/agentyard-private/agentsmd/rules/test.mdc"

# Create test project
mkdir -p "$TEST_DIR/project"
cd "$TEST_DIR/project"
git init --quiet

# Run agentsmd with custom HOME
echo -e "\nRunning agentsmd with multi-repo setup..."
HOME="$TEST_DIR/home" /Users/joshuawarren/agentyard/bin/agentsmd --verbose 2>&1 | grep -E "(Syncing rules|sync:|from.*agentyard|Skipping.*rules|Would create directory|new rule)"

# Check if docs/agentyard/rules was created
if [[ -d "$TEST_DIR/project/docs/agentyard/rules" ]]; then
    echo -e "\n✓ Rules directory created"
    ls -la "$TEST_DIR/project/docs/agentyard/rules/"
else
    echo -e "\n✗ Rules directory not created"
fi

# Cleanup
rm -rf "$TEST_DIR"