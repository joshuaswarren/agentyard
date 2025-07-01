#!/usr/bin/env bash
#
# setup-claude-commands.sh
#
# This script symlinks all files from multiple source "claude-commands" directories
# into the user's ~/.claude/commands directory, so Claude Code can load them globally.
# It skips missing directories and existing non-symlink files; updates broken or outdated symlinks.
# Usage: ./setup-claude-commands.sh
#        ./setup-claude-commands.sh --test    # run built-in tests

set -euo pipefail

# Default target directory for Claude Code personal commands
TARGET_DIR="${HOME}/.claude/commands"

# Source directories to scan for command files
SRC_DIRS=(
  "${HOME}/agentyard/claude-commands"
  "${HOME}/agentyard-team/claude-commands"
  "${HOME}/agentyard-private/claude-commands"
)

# Ensure target directory exists
mkdir -p "${TARGET_DIR}"

# Function: create or update symlinks
link_commands() {
  for DIR in "${SRC_DIRS[@]}"; do
    if [[ ! -d "$DIR" ]]; then
      echo "Skipping missing directory: $DIR"
      continue
    fi
    for SRC_PATH in "$DIR"/*; do
      # Skip glob if no files
      [[ -e "$SRC_PATH" ]] || continue

      FILE_NAME="$(basename "$SRC_PATH")"
      LINK_PATH="${TARGET_DIR}/${FILE_NAME}"

      if [[ -L "$LINK_PATH" ]]; then
        # Already a symlink; check target
        CURRENT_TARGET="$(readlink "$LINK_PATH")"
        if [[ "$CURRENT_TARGET" == "$SRC_PATH" ]]; then
          echo "Up-to-date symlink: $LINK_PATH -> $CURRENT_TARGET"
        else
          echo "Updating symlink: $LINK_PATH (was -> $CURRENT_TARGET)"
          ln -sf "$SRC_PATH" "$LINK_PATH"
        fi
      elif [[ -e "$LINK_PATH" ]]; then
        # Exists but not a symlink
        echo "Warning: $LINK_PATH exists and is not a symlink. Skipping."
      else
        # Create new symlink
        ln -s "$SRC_PATH" "$LINK_PATH"
        echo "Created symlink: $LINK_PATH -> $SRC_PATH"
      fi
    done
  done
}

# Test harness for the script
run_tests() {
  echo "Running tests..."
  # Create a temporary HOME to isolate
  TMP_HOME="$(mktemp -d)"
  export HOME="$TMP_HOME"

  # Setup fake structure
  mkdir -p "$HOME/agentyard/claude-commands"
  mkdir -p "$HOME/agentyard-team/claude-commands"
  mkdir -p "$HOME/agentyard-private/claude-commands"
  mkdir -p "$HOME/.claude/commands"

  # Create dummy files
  echo "foo" > "$HOME/agentyard/claude-commands/foo.md"
  echo "bar" > "$HOME/agentyard-team/claude-commands/bar.md"

  # Run linking
  link_commands

  # Verify results
  if [[ ! -L "$HOME/.claude/commands/foo.md" ]]; then
    echo "Test failed: foo.md symlink missing"
    exit 1
  fi
  if [[ ! -L "$HOME/.claude/commands/bar.md" ]]; then
    echo "Test failed: bar.md symlink missing"
    exit 1
  fi

  echo "All tests passed."
  # Clean up
  rm -rf "$TMP_HOME"
  exit 0
}

# Entrypoint
if [[ "${1:-}" == "--test" ]]; then
  run_tests
else
  link_commands
fi

