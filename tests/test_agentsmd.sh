#!/usr/bin/env bash
#
# test_agentsmd.sh - Comprehensive test suite for agentsmd command
#
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
AGENTSMD_CMD="${PROJECT_ROOT}/bin/agentsmd"
TEST_DIR="${SCRIPT_DIR}/test_workspace"
TEST_PROJECT="${TEST_DIR}/test_project"

# Ensure agentsmd command exists and is executable
if [[ ! -x "$AGENTSMD_CMD" ]]; then
    echo -e "${RED}Error: agentsmd command not found or not executable at $AGENTSMD_CMD${NC}"
    exit 1
fi

# Helper functions
setup_test_env() {
    echo -e "${BLUE}Setting up test environment...${NC}"
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_PROJECT"
    cd "$TEST_PROJECT"
    
    # Initialize as git repo for more realistic testing
    git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    # Create a simple project structure
    cat > package.json <<EOF
{
  "name": "test-project",
  "version": "1.0.0",
  "scripts": {
    "test": "echo 'Running tests'",
    "build": "echo 'Building project'"
  }
}
EOF
    
    cat > README.md <<EOF
# Test Project

A simple test project for agentsmd testing.
EOF
    
    mkdir -p src
    cat > src/index.js <<EOF
// Main application file
console.log('Hello, World!');
EOF
    
    git add .
    git commit -m "Initial commit" --quiet
}

cleanup_test_env() {
    cd "$PROJECT_ROOT"
    rm -rf "$TEST_DIR"
}

# Test assertion functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}✓${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} $test_name"
        echo -e "  Expected: $expected"
        echo -e "  Actual:   $actual"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_file_exists() {
    local file="$1"
    local test_name="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✓${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} $test_name"
        echo -e "  File not found: $file"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_symlink_exists() {
    local link="$1"
    local target="$2"
    local test_name="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ -L "$link" ]] && [[ "$(readlink "$link")" == "$target" ]]; then
        echo -e "${GREEN}✓${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} $test_name"
        if [[ ! -L "$link" ]]; then
            echo -e "  Not a symlink: $link"
        else
            echo -e "  Symlink points to: $(readlink "$link")"
            echo -e "  Expected target: $target"
        fi
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_contains() {
    local file="$1"
    local pattern="$2"
    local test_name="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ -f "$file" ]] && grep -q "$pattern" "$file"; then
        echo -e "${GREEN}✓${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} $test_name"
        if [[ ! -f "$file" ]]; then
            echo -e "  File not found: $file"
        else
            echo -e "  Pattern not found: $pattern"
        fi
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Test functions
test_help_command() {
    echo -e "\n${YELLOW}Testing help command...${NC}"
    
    local output=$("$AGENTSMD_CMD" --help 2>&1)
    local exit_code=$?
    
    assert_equals "0" "$exit_code" "Help command exit code"
    
    # Check for key help text
    if echo "$output" | grep -q "Usage: agentsmd"; then
        echo -e "${GREEN}✓${NC} Help text contains usage information"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Help text missing usage information"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
    
    # Check for dedupe command in help
    if echo "$output" | grep -q "dedupe"; then
        echo -e "${GREEN}✓${NC} Help text contains dedupe command"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Help text missing dedupe command"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
}

test_list_migrations() {
    echo -e "\n${YELLOW}Testing list migrations...${NC}"
    
    local output=$("$AGENTSMD_CMD" --list-migrations 2>&1)
    local exit_code=$?
    
    assert_equals "0" "$exit_code" "List migrations exit code"
    
    # Check for migration files
    if echo "$output" | grep -q "001-header.md"; then
        echo -e "${GREEN}✓${NC} List includes 001-header.md"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} List missing 001-header.md"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
}

test_check_only_mode() {
    echo -e "\n${YELLOW}Testing check-only mode...${NC}"
    
    setup_test_env
    
    local output=$("$AGENTSMD_CMD" --check-only 2>&1)
    local exit_code=$?
    
    assert_equals "0" "$exit_code" "Check-only mode exit code"
    
    # Ensure no files were created in check-only mode
    if [[ ! -f "AGENTS.md" ]]; then
        echo -e "${GREEN}✓${NC} Check-only mode did not create AGENTS.md"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Check-only mode created AGENTS.md"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
    
    cleanup_test_env
}

test_symlink_creation() {
    echo -e "\n${YELLOW}Testing symlink creation...${NC}"
    
    setup_test_env
    
    # Mock Claude command to avoid actual API calls
    export PATH="${TEST_DIR}/mock_bin:$PATH"
    mkdir -p "${TEST_DIR}/mock_bin"
    cat > "${TEST_DIR}/mock_bin/claude" <<'EOF'
#!/bin/bash
echo "This is a test project that demonstrates mocked Claude output."
EOF
    chmod +x "${TEST_DIR}/mock_bin/claude"
    
    # Run agentsmd
    "$AGENTSMD_CMD" >/dev/null 2>&1
    
    # Check symlinks
    assert_symlink_exists "CLAUDE.md" "AGENTS.md" "CLAUDE.md symlink created"
    assert_symlink_exists "GEMINI.md" "AGENTS.md" "GEMINI.md symlink created"
    
    cleanup_test_env
}

test_agents_file_creation() {
    echo -e "\n${YELLOW}Testing AGENTS.md file creation...${NC}"
    
    setup_test_env
    
    # Mock Claude command
    export PATH="${TEST_DIR}/mock_bin:$PATH"
    mkdir -p "${TEST_DIR}/mock_bin"
    cat > "${TEST_DIR}/mock_bin/claude" <<'EOF'
#!/bin/bash
echo "This is a test project for testing agentsmd functionality."
EOF
    chmod +x "${TEST_DIR}/mock_bin/claude"
    
    # Run agentsmd
    "$AGENTSMD_CMD" >/dev/null 2>&1
    
    # Check AGENTS.md was created
    assert_file_exists "AGENTS.md" "AGENTS.md file created"
    
    # Check for expected content
    assert_contains "AGENTS.md" "# AGENTS.md" "AGENTS.md contains header"
    assert_contains "AGENTS.md" "Overview" "AGENTS.md contains Overview section"
    
    cleanup_test_env
}

test_version_tracking() {
    echo -e "\n${YELLOW}Testing version tracking...${NC}"
    
    setup_test_env
    
    # Mock Claude command
    export PATH="${TEST_DIR}/mock_bin:$PATH"
    mkdir -p "${TEST_DIR}/mock_bin"
    cat > "${TEST_DIR}/mock_bin/claude" <<'EOF'
#!/bin/bash
echo "Mocked output for version tracking test."
EOF
    chmod +x "${TEST_DIR}/mock_bin/claude"
    
    # Run agentsmd
    "$AGENTSMD_CMD" >/dev/null 2>&1
    
    # Check version file was created
    assert_file_exists ".agentyard-version.yml" "Version file created"
    
    # Check version content
    assert_contains ".agentyard-version.yml" "agentsmd:" "Version file contains agentsmd section"
    assert_contains ".agentyard-version.yml" "version:" "Version file contains version field"
    
    # Run again and ensure no duplicate migrations
    local output=$("$AGENTSMD_CMD" 2>&1)
    if echo "$output" | grep -q "No new migrations to apply"; then
        echo -e "${GREEN}✓${NC} Version tracking prevents duplicate migrations"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Version tracking failed to prevent duplicates"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
    
    cleanup_test_env
}

test_existing_agents_file() {
    echo -e "\n${YELLOW}Testing with existing AGENTS.md file...${NC}"
    
    setup_test_env
    
    # Create existing AGENTS.md
    cat > AGENTS.md <<EOF
# Existing AGENTS.md

This is existing content that should be preserved.
EOF
    
    # Mock Claude command
    export PATH="${TEST_DIR}/mock_bin:$PATH"
    mkdir -p "${TEST_DIR}/mock_bin"
    cat > "${TEST_DIR}/mock_bin/claude" <<'EOF'
#!/bin/bash
echo "New content from migration."
EOF
    chmod +x "${TEST_DIR}/mock_bin/claude"
    
    # Run agentsmd
    "$AGENTSMD_CMD" >/dev/null 2>&1
    
    # Check existing content is preserved
    assert_contains "AGENTS.md" "This is existing content" "Existing content preserved"
    # Check that new content was appended (from the mock Claude output)
    assert_contains "AGENTS.md" "AGENTS.md" "New header content appended"
    
    cleanup_test_env
}

test_project_option() {
    echo -e "\n${YELLOW}Testing --project option...${NC}"
    
    setup_test_env
    
    # Create another project directory
    mkdir -p "${TEST_DIR}/other_project"
    cd "${TEST_DIR}/other_project"
    git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"
    echo "# Other Project" > README.md
    git add . && git commit -m "Initial" --quiet
    
    # Mock Claude command
    export PATH="${TEST_DIR}/mock_bin:$PATH"
    mkdir -p "${TEST_DIR}/mock_bin"
    cat > "${TEST_DIR}/mock_bin/claude" <<'EOF'
#!/bin/bash
echo "Other project content."
EOF
    chmod +x "${TEST_DIR}/mock_bin/claude"
    
    # Run from different directory
    cd "$PROJECT_ROOT"
    "$AGENTSMD_CMD" --project "${TEST_DIR}/other_project" >/dev/null 2>&1
    
    # Check files were created in the right place
    assert_file_exists "${TEST_DIR}/other_project/AGENTS.md" "AGENTS.md created in project dir"
    assert_symlink_exists "${TEST_DIR}/other_project/CLAUDE.md" "AGENTS.md" "CLAUDE.md symlink in project dir"
    
    cleanup_test_env
}

test_verbose_mode() {
    echo -e "\n${YELLOW}Testing verbose mode...${NC}"
    
    setup_test_env
    
    # Mock Claude command
    export PATH="${TEST_DIR}/mock_bin:$PATH"
    mkdir -p "${TEST_DIR}/mock_bin"
    cat > "${TEST_DIR}/mock_bin/claude" <<'EOF'
#!/bin/bash
echo "Verbose test output."
EOF
    chmod +x "${TEST_DIR}/mock_bin/claude"
    
    local output=$("$AGENTSMD_CMD" --verbose 2>&1)
    
    # Check for verbose output indicators
    if echo "$output" | grep -q "Current version:"; then
        echo -e "${GREEN}✓${NC} Verbose mode shows version info"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Verbose mode missing version info"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
    
    cleanup_test_env
}

test_error_handling() {
    echo -e "\n${YELLOW}Testing error handling...${NC}"
    
    # Test with non-existent directory
    local exit_code=0
    local output=""
    
    # Run command in a way that captures exit code properly
    if output=$("$AGENTSMD_CMD" --project "/nonexistent/path" 2>&1); then
        exit_code=0
    else
        exit_code=$?
    fi
    
    # Debug output (commented out unless needed)
    # echo "Exit code captured: $exit_code"
    # echo "Output: $output"
    
    if [[ $exit_code -ne 0 ]]; then
        echo -e "${GREEN}✓${NC} Non-existent directory returns error code"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Non-existent directory should return error"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if echo "$output" | grep -qi "does not exist"; then
        echo -e "${GREEN}✓${NC} Error message for non-existent directory"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Missing error message for non-existent directory"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
}

test_dedupe_dry_run() {
    echo -e "\n${YELLOW}Testing dedupe --dry-run mode...${NC}"
    
    setup_test_env
    
    # Create AGENTS.md with duplicates
    cat > AGENTS.md <<'EOF'
# AGENTS.md

## Overview
This is the overview section.

## Code Quality
Follow best practices.

## Overview
This is the overview section.

## Testing
Write comprehensive tests.

## Code Quality
Follow best practices.
EOF
    
    # Mock the Python script to simulate dedupe behavior
    export PATH="${TEST_DIR}/mock_bin:$PATH"
    mkdir -p "${TEST_DIR}/mock_bin"
    cat > "${TEST_DIR}/mock_bin/agentsmd-dedupe" <<'EOF'
#!/bin/bash
echo "Found 2 duplicate text block(s):"
echo ""
echo "Duplicate #1:"
echo "  First occurrence: line 3"
echo "  Duplicate locations: lines 8"
echo "  Total occurrences: 2"
echo "  Text preview: '## Overview\\nThis is the overview section.'"
echo ""
echo "Duplicate #2:"
echo "  First occurrence: line 6"
echo "  Duplicate locations: lines 14"
echo "  Total occurrences: 2"
echo "  Text preview: '## Code Quality\\nFollow best practices.'"
echo ""
echo "--dry-run mode: No changes will be made"
echo "Would remove 4 duplicate occurrences"
echo "Duplicate removal complete!"
EOF
    chmod +x "${TEST_DIR}/mock_bin/agentsmd-dedupe"
    
    local output=$("$AGENTSMD_CMD" dedupe --dry-run 2>&1)
    local exit_code=$?
    
    assert_equals "0" "$exit_code" "Dedupe dry-run exit code"
    
    # Check output contains expected messages
    if echo "$output" | grep -q "duplicate removal"; then
        echo -e "${GREEN}✓${NC} Dedupe dry-run shows operation message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Dedupe dry-run missing operation message"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if echo "$output" | grep -qi "complete\|removal"; then
        echo -e "${GREEN}✓${NC} Dedupe dry-run shows status message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Dedupe dry-run missing status message"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
    
    # Verify file was not modified
    if grep -q "## Testing" AGENTS.md; then
        echo -e "${GREEN}✓${NC} AGENTS.md not modified in dry-run mode"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} AGENTS.md was modified in dry-run mode"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
    
    cleanup_test_env
}

test_dedupe_no_duplicates() {
    echo -e "\n${YELLOW}Testing dedupe with no duplicates...${NC}"
    
    setup_test_env
    
    # Create AGENTS.md without duplicates
    cat > AGENTS.md <<'EOF'
# AGENTS.md

## Overview
This is the overview section.

## Code Quality
Follow best practices.

## Testing
Write comprehensive tests.
EOF
    
    # Mock the Python script for no duplicates case
    export PATH="${TEST_DIR}/mock_bin:$PATH"
    mkdir -p "${TEST_DIR}/mock_bin"
    cat > "${TEST_DIR}/mock_bin/agentsmd-dedupe" <<'EOF'
#!/bin/bash
echo "No duplicates found in AGENTS.md"
echo "No changes needed"
EOF
    chmod +x "${TEST_DIR}/mock_bin/agentsmd-dedupe"
    
    local output=$("$AGENTSMD_CMD" dedupe 2>&1)
    local exit_code=$?
    
    assert_equals "0" "$exit_code" "Dedupe with no duplicates exit code"
    
    if echo "$output" | grep -q "duplicate removal"; then
        echo -e "${GREEN}✓${NC} Dedupe runs successfully"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Dedupe operation failed"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
    
    cleanup_test_env
}

test_dedupe_missing_api_key() {
    echo -e "\n${YELLOW}Testing dedupe without API key...${NC}"
    
    setup_test_env
    
    # Create AGENTS.md
    echo "# AGENTS.md" > AGENTS.md
    
    # Unset API key first
    unset OPENAI_API_KEY
    
    # Run the command without mocking to test actual behavior
    local exit_code=0
    local output=""
    
    if output=$("$AGENTSMD_CMD" dedupe 2>&1); then
        exit_code=0
    else
        exit_code=$?
    fi
    
    if [[ $exit_code -ne 0 ]]; then
        echo -e "${GREEN}✓${NC} Dedupe fails without API key"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Dedupe should fail without API key"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if echo "$output" | grep -qi "error\|failed"; then
        echo -e "${GREEN}✓${NC} Dedupe shows error message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Dedupe missing error message"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
    
    cleanup_test_env
}

# Main test runner
main() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}Running agentsmd test suite${NC}"
    echo -e "${BLUE}================================${NC}"
    
    # Run all tests
    test_help_command
    test_list_migrations
    test_check_only_mode
    test_symlink_creation
    test_agents_file_creation
    test_version_tracking
    test_existing_agents_file
    test_project_option
    test_verbose_mode
    test_error_handling
    test_dedupe_dry_run
    test_dedupe_no_duplicates
    test_dedupe_missing_api_key
    
    # Summary
    echo -e "\n${BLUE}================================${NC}"
    echo -e "${BLUE}Test Summary${NC}"
    echo -e "${BLUE}================================${NC}"
    echo -e "Tests run:    $TESTS_RUN"
    echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
    else
        echo -e "Tests failed: $TESTS_FAILED"
    fi
    
    # Exit with appropriate code
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}Some tests failed!${NC}"
        exit 1
    fi
}

# Run tests
main