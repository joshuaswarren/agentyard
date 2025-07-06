#!/usr/bin/env bash
#
# test_agentsmd_wrapping.sh - Test suite for agentsmd line wrapping functionality
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

# Extract just the functions we need from agentsmd without running the main code
# This prevents the script from executing when sourced
AGENTSMD_SOURCED=true

# Define minimal versions of dependencies
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Source only the function definitions
eval "$(sed -n '/^wrap_markdown_content()/,/^}/p' "${PROJECT_ROOT}/bin/agentsmd")"
eval "$(sed -n '/^process_migration()/,/^}/p' "${PROJECT_ROOT}/bin/agentsmd")"

# Define minimal versions of logging functions used by process_migration
log_error() { echo "ERROR: $*" >&2; }
log_verbose() { :; }  # no-op for tests

# Mock functions for process_migration test
generate_cache_key() { echo "test-cache-key"; }
get_cache_path() { echo "/tmp/test-cache"; }
run_claude_analysis() {
    # This will be overridden in specific tests
    echo "Mock Claude response"
}

# Define log_warning for tests
log_warning() {
    echo "[WARNING] $*" >&2
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
        echo -e "  Expected: '$expected'"
        echo -e "  Actual:   '$actual'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_line_length() {
    local content="$1"
    local max_length="$2"
    local test_name="$3"
    local allow_urls="${4:-false}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    local all_good=true
    local line_num=0
    
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        local len=${#line}
        
        # Skip URL lines if allowed
        if [[ "$allow_urls" == "true" ]] && [[ "$line" =~ https?://[^[:space:]]+ ]]; then
            continue
        fi
        
        if [[ $len -gt $max_length ]]; then
            if [[ "$all_good" == "true" ]]; then
                echo -e "${RED}✗${NC} $test_name"
                all_good=false
            fi
            echo -e "  Line $line_num exceeds $max_length chars (length: $len)"
            echo -e "  Content: '${line:0:50}...'"
        fi
    done <<< "$content"
    
    if [[ "$all_good" == "true" ]]; then
        echo -e "${GREEN}✓${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_contains() {
    local content="$1"
    local pattern="$2"
    local test_name="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    if echo "$content" | grep -q "$pattern"; then
        echo -e "${GREEN}✓${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} $test_name"
        echo -e "  Pattern not found: $pattern"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_not_contains() {
    local content="$1"
    local pattern="$2"
    local test_name="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    if ! echo "$content" | grep -q "$pattern"; then
        echo -e "${GREEN}✓${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} $test_name"
        echo -e "  Pattern found but should not be: $pattern"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Test functions
test_basic_wrapping() {
    echo -e "\n${YELLOW}Testing basic text wrapping...${NC}"
    
    local input="This is a very long line that definitely exceeds 120 characters and should be wrapped to fit within the specified limit without breaking words in the middle of them."
    local output=$(wrap_markdown_content "$input")
    
    assert_line_length "$output" 120 "Basic text wrapped to 120 chars"
    assert_contains "$output" "This is a very long line" "Content preserved"
}

test_header_preservation() {
    echo -e "\n${YELLOW}Testing header preservation...${NC}"
    
    local input="# This is a very long header that exceeds 120 characters and normally would be wrapped but headers should be preserved as-is without any wrapping applied to them"
    local output=$(wrap_markdown_content "$input")
    
    # Headers should not be wrapped
    local line_count=$(echo "$output" | wc -l | tr -d ' ')
    assert_equals "1" "$line_count" "Header remains on single line"
    assert_contains "$output" "# This is a very long header" "Header content preserved"
}

test_code_block_preservation() {
    echo -e "\n${YELLOW}Testing code block preservation...${NC}"
    
    local input='```bash
This is a very long line inside a code block that definitely exceeds 120 characters and should NOT be wrapped because code blocks must be preserved exactly as they are written.
echo "Another line in the code block"
```'
    
    local output=$(wrap_markdown_content "$input")
    
    assert_contains "$output" "This is a very long line inside a code block that definitely exceeds 120 characters" "Long code line preserved"
    assert_contains "$output" '```bash' "Code block start preserved"
    assert_contains "$output" '```' "Code block end preserved"
}

test_list_formatting() {
    echo -e "\n${YELLOW}Testing list formatting...${NC}"
    
    local input="- This is a very long list item that exceeds 120 characters and should be wrapped while preserving the list marker and proper indentation for continuation lines
- Short item
  - This is a nested list item that is also very long and exceeds 120 characters so it needs to be wrapped while maintaining the nested indentation properly"
    
    local output=$(wrap_markdown_content "$input")
    
    assert_line_length "$output" 120 "List items wrapped to 120 chars"
    assert_contains "$output" "^- This is a very long list item" "List marker preserved"
    assert_contains "$output" "^  - This is a nested list item" "Nested list marker preserved"
}

test_numbered_list_formatting() {
    echo -e "\n${YELLOW}Testing numbered list formatting...${NC}"
    
    local input="1. This is a very long numbered list item that exceeds 120 characters and should be wrapped while preserving the number marker and proper indentation
2. Another item
   1. Nested numbered item that is also quite long and exceeds the 120 character limit so it needs proper wrapping"
    
    local output=$(wrap_markdown_content "$input")
    
    assert_line_length "$output" 120 "Numbered list items wrapped"
    assert_contains "$output" "^1\. This is a very long numbered" "Numbered marker preserved"
    assert_contains "$output" "^   1\. Nested numbered item" "Nested numbering preserved"
}

test_url_preservation() {
    echo -e "\n${YELLOW}Testing URL preservation...${NC}"
    
    local input="Check out this documentation at https://github.com/very/long/url/that/exceeds/120/characters/but/should/not/be/broken/because/urls/must/remain/intact/documentation.html for more information."
    local output=$(wrap_markdown_content "$input")
    
    assert_contains "$output" "https://github.com/very/long/url/that/exceeds/120/characters/but/should/not/be/broken/because/urls/must/remain/intact/documentation.html" "URL preserved intact"
}

test_blockquote_formatting() {
    echo -e "\n${YELLOW}Testing blockquote formatting...${NC}"
    
    local input="> This is a very long blockquote that exceeds 120 characters and should be wrapped while preserving the blockquote marker on each wrapped line to maintain proper formatting"
    local output=$(wrap_markdown_content "$input")
    
    assert_line_length "$output" 120 "Blockquote wrapped to 120 chars"
    # Check that each line starts with >
    local lines_without_marker=$(echo "$output" | grep -v "^>" | wc -l | tr -d ' ')
    assert_equals "0" "$lines_without_marker" "All blockquote lines have > marker"
}

test_empty_lines_preservation() {
    echo -e "\n${YELLOW}Testing empty line preservation...${NC}"
    
    local input="First paragraph.

Second paragraph.


Third paragraph with double empty line above."
    
    local output=$(wrap_markdown_content "$input")
    
    # Count empty lines
    local empty_lines=$(echo "$output" | grep -c "^$" || true)
    assert_equals "3" "$empty_lines" "Empty lines preserved"
}

test_mixed_content() {
    echo -e "\n${YELLOW}Testing mixed content...${NC}"
    
    local input='# Header

This is a paragraph with a very long line that needs wrapping because it exceeds the 120 character limit we have set for line wrapping.

- List item one
- A very long list item that needs to be wrapped because it exceeds 120 characters and we want to maintain readability

```python
# This code should not be wrapped even if it is very long
def very_long_function_name_that_exceeds_120_characters_but_should_not_be_wrapped():
    pass
```

> A blockquote with a long line that needs wrapping to stay within the 120 character limit while preserving the quote marker'
    
    local output=$(wrap_markdown_content "$input")
    
    assert_line_length "$output" 120 "Mixed content respects line limits" "true"
    assert_contains "$output" "# Header" "Header preserved"
    assert_contains "$output" "def very_long_function_name_that_exceeds_120_characters_but_should_not_be_wrapped" "Code block preserved"
    assert_contains "$output" "^- List item one" "List items preserved"
    assert_contains "$output" "^> A blockquote" "Blockquote preserved"
}

test_special_characters() {
    echo -e "\n${YELLOW}Testing special characters...${NC}"
    
    local input="This line contains special characters like \$HOME and \`backticks\` and should wrap properly without breaking the special character sequences or escape codes."
    local output=$(wrap_markdown_content "$input")
    
    assert_line_length "$output" 120 "Special chars line wrapped"
    assert_contains "$output" '\$HOME' "Dollar sign preserved"
    assert_contains "$output" '`backticks`' "Backticks preserved"
}

test_no_fmt_fallback() {
    echo -e "\n${YELLOW}Testing fallback when fmt is not available...${NC}"
    
    # Override command_exists for this test
    local original_command_exists=$(declare -f command_exists)
    command_exists() {
        if [[ "$1" == "fmt" ]]; then
            return 1
        else
            command -v "$1" >/dev/null 2>&1
        fi
    }
    
    # Capture both stdout and stderr
    local input="This is a test line"
    local output=$(wrap_markdown_content "$input" 2>&1)
    
    # Check if warning was logged (it goes to stderr via log_warning)
    if [[ "$output" == *"fmt command not found"* ]] || [[ "$output" == *"This is a test line"* ]]; then
        echo -e "${GREEN}✓${NC} Handles missing fmt gracefully"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Should handle missing fmt"
        echo "  Output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
    
    # Restore original command_exists
    eval "$original_command_exists"
}

test_prompt_marker_removal() {
    echo -e "\n${YELLOW}Testing Claude prompt marker removal...${NC}"
    
    # Create a test migration file
    local test_migration=$(mktemp)
    cat > "$test_migration" <<'EOF'
# Test Migration

This is before the prompt.

{{CLAUDE_PROMPT}}
This is the prompt content that should not appear in output.
List three fruits.
{{/CLAUDE_PROMPT}}

This is after the prompt.
EOF
    
    # Override run_claude_analysis for this test
    local original_run_claude=$(declare -f run_claude_analysis)
    run_claude_analysis() {
        echo "Apple, Banana, Orange"
    }
    
    # Process the migration
    local output=$(process_migration "$test_migration" ".")
    
    # Restore original function
    eval "$original_run_claude"
    
    # Clean up
    rm -f "$test_migration"
    
    assert_contains "$output" "This is before the prompt" "Content before prompt preserved"
    assert_contains "$output" "This is after the prompt" "Content after prompt preserved"
    assert_contains "$output" "Apple, Banana, Orange" "Claude response included"
    assert_not_contains "$output" "{{CLAUDE_PROMPT}}" "Start marker removed"
    assert_not_contains "$output" "{{/CLAUDE_PROMPT}}" "End marker removed"
    assert_not_contains "$output" "This is the prompt content" "Prompt content removed"
    assert_not_contains "$output" "List three fruits" "Prompt instruction removed"
}

# Main test runner
main() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}Running agentsmd wrapping tests${NC}"
    echo -e "${BLUE}================================${NC}"
    
    # Run all tests
    test_basic_wrapping
    test_header_preservation
    test_code_block_preservation
    test_list_formatting
    test_numbered_list_formatting
    test_url_preservation
    test_blockquote_formatting
    test_empty_lines_preservation
    test_mixed_content
    test_special_characters
    test_no_fmt_fallback
    test_prompt_marker_removal
    
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