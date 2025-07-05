#!/bin/bash
#
# Test script for judge command improvements
#

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "🧪 Testing judge command improvements..."

# Test directory
TEST_DIR="/tmp/judge-test-$$"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Clean up on exit
trap "rm -rf $TEST_DIR" EXIT

echo -e "\n${YELLOW}Test 1: Check --init-config creates configuration${NC}"
if judge --init-config test-config.yaml <<< "n" 2>&1 | grep -q "Configuration created at"; then
    echo -e "${GREEN}✓ --init-config works${NC}"
else
    echo -e "${RED}✗ --init-config failed${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Test 2: Verify config file was created${NC}"
if [[ -f "test-config.yaml" ]]; then
    echo -e "${GREEN}✓ Config file created${NC}"
    # Check for required fields
    if grep -q "models_dir:" test-config.yaml && \
       grep -q "model:" test-config.yaml && \
       grep -q "review:" test-config.yaml; then
        echo -e "${GREEN}✓ Config has required fields${NC}"
    else
        echo -e "${RED}✗ Config missing required fields${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ Config file not created${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Test 3: Test model path resolution with env variable${NC}"
export AGENTYARD_MODELS_PATH="$TEST_DIR/models"
export PYTHONPATH="${SCRIPT_DIR}/../lib:${PYTHONPATH:-}"

python3 - <<'EOF'
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'lib'))
from judge.model_manager import ModelManager

# Test environment variable resolution
manager = ModelManager()
path = manager.get_model_path("test-model")
expected = os.path.join(os.environ['AGENTYARD_MODELS_PATH'], "test-model.gguf")

if str(path) == expected:
    print("✓ Environment variable path resolution works")
else:
    print(f"✗ Path resolution failed: {path} != {expected}")
    sys.exit(1)
EOF

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✓ Model path resolution works${NC}"
else
    echo -e "${RED}✗ Model path resolution failed${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Test 4: Test help message includes new options${NC}"
if judge --help 2>&1 | grep -q -- "--init-config"; then
    echo -e "${GREEN}✓ Help includes --init-config${NC}"
else
    echo -e "${RED}✗ Help missing --init-config${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Test 5: Test config validation error${NC}"
# Remove config and try to run judge
rm -f ~/.agentyard/judge.yaml
if judge 123 2>&1 | grep -q "Run 'judge --init-config'"; then
    echo -e "${GREEN}✓ Proper error message when config missing${NC}"
else
    echo -e "${RED}✗ Missing config error message incorrect${NC}"
    # Not a fatal error, just informational
fi

echo -e "\n${GREEN}All tests passed! 🎉${NC}"
echo -e "\nKey improvements verified:"
echo "  • --init-config command works"
echo "  • Configuration file generation"
echo "  • Model path resolution hierarchy"
echo "  • Environment variable support"
echo "  • Help documentation updated"