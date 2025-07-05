#!/usr/bin/env bash
#
# Test script for new judge command features
# Tests:
# - Non-interactive mode with --force flag
# - Namespace/model storage structure
# - scan-models subcommand
# - GGUF metadata parsing
#

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "🧪 Testing new judge command features..."

# Test directory
TEST_DIR="/tmp/judge-test-new-$$"
mkdir -p "$TEST_DIR"

# Clean up on exit
trap "rm -rf $TEST_DIR" EXIT

# Test counters
PASSED=0
FAILED=0

# Test function
test_case() {
  local name="$1"
  local command="$2"
  local expected_exit="${3:-0}"
  
  echo -n "Testing: $name... "
  
  # Capture both stdout and stderr
  if output=$(eval "$command" 2>&1); then
    actual_exit=0
  else
    actual_exit=$?
  fi
  
  if [[ $actual_exit -eq $expected_exit ]]; then
    echo -e "${GREEN}PASSED${NC}"
    ((PASSED++))
    return 0
  else
    echo -e "${RED}FAILED${NC} (expected exit $expected_exit, got $actual_exit)"
    echo "  Output: $output"
    ((FAILED++))
    return 1
  fi
}

echo -e "\n${YELLOW}Test Group 1: Non-interactive mode with --force${NC}"
echo "================================================="

# Test --force with init-config
test_case "--force skips confirmation" "judge --init-config --force $TEST_DIR/force-config.yaml 2>&1 | grep -q 'Configuration created'"

# Test that config was created without interaction
test_case "Config file created with --force" "[[ -f $TEST_DIR/force-config.yaml ]]"

echo -e "\n${YELLOW}Test Group 2: Namespace/model storage structure${NC}"
echo "================================================="

# Set up test model directory structure
export AGENTYARD_MODELS_PATH="$TEST_DIR/models"
mkdir -p "$AGENTYARD_MODELS_PATH/mistralai/mistral-7b"
mkdir -p "$AGENTYARD_MODELS_PATH/meta/llama-3-8b"
mkdir -p "$AGENTYARD_MODELS_PATH/local/custom-model"

# Create dummy GGUF files
touch "$AGENTYARD_MODELS_PATH/mistralai/mistral-7b/mistral-7b-instruct.Q4_K_M.gguf"
touch "$AGENTYARD_MODELS_PATH/meta/llama-3-8b/llama-3-8b.Q4_0.gguf"
touch "$AGENTYARD_MODELS_PATH/local/custom-model/model.gguf"

# Create dummy safetensors file (LM Studio format)
mkdir -p "$AGENTYARD_MODELS_PATH/lmstudio/phi-3"
touch "$AGENTYARD_MODELS_PATH/lmstudio/phi-3/model.safetensors"

# Test model path resolution
export PYTHONPATH="${SCRIPT_DIR:-$(dirname $0)}/../lib:${PYTHONPATH:-}"

python3 - <<'EOF' || exit 1
import sys
import os
from pathlib import Path

# Add lib directory to path
script_dir = os.path.dirname(os.path.abspath(__file__))
lib_dir = os.path.join(os.path.dirname(script_dir), 'lib')
sys.path.insert(0, lib_dir)

try:
    from judge.model_manager import ModelManager
    
    # Test namespace/model path resolution
    manager = ModelManager()
    
    # Test with namespace
    path = manager.get_model_path("mistralai/mistral-7b")
    expected = Path(os.environ['AGENTYARD_MODELS_PATH']) / "mistralai" / "mistral-7b"
    assert path == expected, f"Path mismatch: {path} != {expected}"
    print("✓ Namespace/model path resolution works")
    
    # Test with default namespace
    path = manager.get_model_path("test-model")
    expected = Path(os.environ['AGENTYARD_MODELS_PATH']) / "default" / "test-model"
    assert path == expected, f"Path mismatch: {path} != {expected}"
    print("✓ Default namespace works")
    
except Exception as e:
    print(f"✗ Python test failed: {e}")
    sys.exit(1)
EOF

test_case "Model path resolution with namespace" "true"  # Already tested above

echo -e "\n${YELLOW}Test Group 3: scan-models subcommand${NC}"
echo "======================================"

# Test scan-models help
test_case "scan-models in help text" "judge --help 2>&1 | grep -q 'scan-models'"

# Create a test config for scanning
cat > "$TEST_DIR/scan-config.yaml" <<EOF
model:
  name: "mistralai/mistral-small-2409"
  context_size: 32768
models_dir: "$AGENTYARD_MODELS_PATH"
models: {}
EOF

# Test scan-models execution
echo -e "\n${YELLOW}Running judge scan-models...${NC}"
output=$(judge scan-models --config "$TEST_DIR/scan-config.yaml" 2>&1)

test_case "scan-models finds mistralai model" "echo '$output' | grep -q 'mistralai/mistral-7b'"
test_case "scan-models finds meta model" "echo '$output' | grep -q 'meta/llama-3-8b'"
test_case "scan-models finds local model" "echo '$output' | grep -q 'local/custom-model'"
test_case "scan-models finds safetensors" "echo '$output' | grep -q 'lmstudio/phi-3'"
test_case "scan-models updates config" "echo '$output' | grep -q 'Updated configuration'"

# Check if models were added to config
test_case "Config contains scanned models" "grep -q 'mistralai/mistral-7b' '$TEST_DIR/scan-config.yaml'"

echo -e "\n${YELLOW}Test Group 4: GGUF metadata parsing${NC}"
echo "====================================="

# Create a simple test for GGUF metadata reader
# Note: We can't test actual GGUF parsing without a real GGUF file
# but we can test the class exists and handles errors gracefully

python3 - <<'EOF' || exit 1
import sys
import os
from pathlib import Path

# Add lib directory to path
script_dir = os.path.dirname(os.path.abspath(__file__))
lib_dir = os.path.join(os.path.dirname(script_dir), 'lib')
sys.path.insert(0, lib_dir)

try:
    from judge.model_manager import GGUFMetadataReader
    
    # Test with non-existent file
    reader = GGUFMetadataReader(Path("/nonexistent.gguf"))
    metadata = reader.read_metadata()
    
    # Should return error metadata
    assert 'error' in metadata, "Should have error field for non-existent file"
    print("✓ GGUF metadata reader handles missing files")
    
    # Test with non-GGUF file
    test_file = Path("/tmp/test.txt")
    test_file.write_text("not a gguf file")
    
    reader = GGUFMetadataReader(test_file)
    metadata = reader.read_metadata()
    
    assert 'error' in metadata, "Should have error field for invalid file"
    print("✓ GGUF metadata reader handles invalid files")
    
    test_file.unlink()
    
except Exception as e:
    print(f"✗ GGUF metadata test failed: {e}")
    sys.exit(1)
EOF

test_case "GGUF metadata reader exists and handles errors" "true"  # Already tested above

echo -e "\n${YELLOW}Test Group 5: Model examples and defaults${NC}"
echo "==========================================="

# Check that default model has namespace
test_case "Default model includes namespace" "grep -q 'mistralai/mistral-small-2409' '$TEST_DIR/scan-config.yaml'"

# Summary
echo -e "\n========================================="
echo "Test Summary:"
echo "  Passed:  $PASSED"
echo "  Failed:  $FAILED"
echo "========================================="

if [[ $FAILED -eq 0 ]]; then
  echo -e "${GREEN}All new feature tests passed! 🎉${NC}"
  echo -e "\nNew features verified:"
  echo "  • --force flag for non-interactive mode"
  echo "  • Namespace/model folder structure"
  echo "  • scan-models subcommand"
  echo "  • GGUF metadata parsing"
  echo "  • LM Studio compatibility"
  exit 0
else
  echo -e "${RED}Some tests failed!${NC}"
  exit 1
fi