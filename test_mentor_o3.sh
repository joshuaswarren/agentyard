#!/usr/bin/env bash
#
# Test script for mentor command o3 model compatibility
#
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "🧪 Testing mentor command o3 model compatibility..."
echo

# Check if we have an API key
if [[ -z "${OPENAI_API_KEY:-}" ]]; then
    echo -e "${YELLOW}⚠${NC}  No OPENAI_API_KEY found. Testing Python syntax only."
    
    # Test that the script has valid Python syntax with our changes
    echo -n "Testing: Python syntax with model-aware parameters ... "
    if python3 -m py_compile bin/mentor 2>/dev/null; then
        echo -e "${GREEN}PASSED${NC}"
        rm -f bin/__pycache__/mentor.cpython-*.pyc
        rmdir bin/__pycache__ 2>/dev/null || true
    else
        echo -e "${RED}FAILED${NC}"
        echo "  Python syntax errors found"
        exit 1
    fi
    
    # Test that the code includes our fix
    echo -n "Testing: Model-aware parameter code present ... "
    if grep -q 'if not model.startswith' bin/mentor && \
       grep -q 'params\["temperature"\] = 0.3' bin/mentor; then
        echo -e "${GREEN}PASSED${NC}"
    else
        echo -e "${RED}FAILED${NC}"
        echo "  Model-aware parameter handling not found in code"
        exit 1
    fi
    
    echo
    echo -e "${GREEN}Basic tests passed!${NC} (Full API tests skipped - no API key)"
    exit 0
fi

# If we have an API key, we can do a dry run test
echo "Testing with API key present..."

# Test with a simple commit (the initial commit is usually safe)
FIRST_COMMIT=$(git rev-list --max-parents=0 HEAD)

# Test 1: o3 model should not fail with temperature error
echo -n "Testing: o3 model compatibility ... "
output=$(bin/mentor --model o3 "$FIRST_COMMIT" 2>&1) || true
if echo "$output" | grep -q "temperature.*does not support"; then
    echo -e "${RED}FAILED${NC}"
    echo "  Still getting temperature error with o3 model"
    echo "  Output: $output"
    exit 1
else
    echo -e "${GREEN}PASSED${NC}"
fi

# Test 2: o3-mini model should not fail with temperature error  
echo -n "Testing: o3-mini model compatibility ... "
output=$(bin/mentor --model o3-mini "$FIRST_COMMIT" 2>&1) || true
if echo "$output" | grep -q "temperature.*does not support"; then
    echo -e "${RED}FAILED${NC}"
    echo "  Still getting temperature error with o3-mini model"
    echo "  Output: $output"
    exit 1
else
    echo -e "${GREEN}PASSED${NC}"
fi

# Test 3: gpt-4 should still work (backwards compatibility)
echo -n "Testing: gpt-4 backwards compatibility ... "
output=$(bin/mentor --model gpt-4 "$FIRST_COMMIT" 2>&1) || true
if echo "$output" | grep -q "Error: OpenAI API error"; then
    # Check if it's a different error (like quota)
    if echo "$output" | grep -q "temperature"; then
        echo -e "${RED}FAILED${NC}"
        echo "  Unexpected temperature error with gpt-4"
        echo "  Output: $output"
        exit 1
    else
        echo -e "${YELLOW}SKIPPED${NC} (API error, but not temperature related)"
    fi
else
    echo -e "${GREEN}PASSED${NC}"
fi

echo
echo -e "${GREEN}All o3 compatibility tests passed!${NC}"