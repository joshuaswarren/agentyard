#!/usr/bin/env bash
#
# Simple demonstration of agentsmd multi-repo functionality
#
set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Demonstrating agentsmd multi-repo support${NC}"
echo "================================================"

# Create a demo environment
DEMO_DIR="/tmp/agentsmd-demo-$$"
mkdir -p "$DEMO_DIR"/{agentyard,agentyard-team,agentyard-private}/agentsmd/{rules,best-practices}

# Create demo rules
echo "Creating demo rules..."
cat > "$DEMO_DIR/agentyard/agentsmd/rules/coding-style.mdc" << 'EOF'
---
description: Basic coding style guide
---
# Coding Style (Public)
Use 4 spaces for indentation.
EOF

cat > "$DEMO_DIR/agentyard-team/agentsmd/rules/team-practices.mdc" << 'EOF'
---
description: Team-specific practices
---
# Team Practices
Always run tests before committing.
EOF

cat > "$DEMO_DIR/agentyard-private/agentsmd/rules/coding-style.mdc" << 'EOF'
---
description: Personal override of coding style
---
# Coding Style (Personal Override)
Use 2 spaces for indentation (personal preference).
EOF

# Create demo migrations
echo "# Description: Basic setup" > "$DEMO_DIR/agentyard/agentsmd/best-practices/001-basic.md"
echo "# Description: Team conventions" > "$DEMO_DIR/agentyard-team/agentsmd/best-practices/002-team.md"

# Show structure
echo -e "\n${YELLOW}Repository structure:${NC}"
echo "├── $DEMO_DIR/agentyard-private/     (highest priority)"
echo "├── $DEMO_DIR/agentyard-team/        (medium priority)"
echo "└── $DEMO_DIR/agentyard/             (lowest priority)"

# List migrations
echo -e "\n${YELLOW}Available migrations:${NC}"
HOME="$DEMO_DIR" /Users/joshuawarren/agentyard/bin/agentsmd --list-migrations 2>&1 | grep -A20 "Available migrations"

# Create test project
mkdir -p "$DEMO_DIR/test-project"
cd "$DEMO_DIR/test-project"
git init --quiet

# Show what would happen
echo -e "\n${YELLOW}Preview of agentsmd execution:${NC}"
HOME="$DEMO_DIR" /Users/joshuawarren/agentyard/bin/agentsmd --check-only 2>&1 | grep -E "(Would|Found|that would)"

echo -e "\n${GREEN}Demo complete!${NC}"
echo "The multi-repo support allows:"
echo "- Private repositories to override public rules"
echo "- Team-specific configurations alongside public ones"
echo "- Flexible organization of best practices and rules"

# Cleanup
rm -rf "$DEMO_DIR"