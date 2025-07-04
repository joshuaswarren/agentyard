# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Agentyard is a lightweight toolbelt for managing multiple AI coding sessions using tmux. It follows a three-folder architecture to separate public, team, and private work:

- `~/agentyard` - Public core scripts and documentation
- `~/agentyard-team` - Team-specific configurations (private repo)
- `~/agentyard-private` - Personal configurations and code (private repo)

## Core Commands

### Creating Work Sessions
```bash
# Create a new disposable git worktree + tmux session with Claude Code
starttask <project> <branch> [slug]

# Examples:
starttask deckard feature/cleanup          # Creates deckard-001 (auto-numbered)
starttask deckard bugfix/login-issue 007   # Creates deckard-007 (explicit slug)

# Clean up when task is complete (run inside the tmux session)
finishtask

# Weekly cleanup - remove merged worktrees (run on Monday/Friday)
cleanup-worktrees              # Remove only merged worktrees
cleanup-worktrees --dry-run    # Preview what would be removed
cleanup-worktrees --all        # Interactive mode for all worktrees

# View and manage active tasks
list-tasks                     # Show all active tasks with details
sync-active-tasks              # Sync active tasks file with actual state
```

Each worktree is single-branch and disposable. The `starttask` command always creates a fresh branch from origin/main using `git switch -c`, avoiding checkout conflicts.

### Session Management
```bash
# Jump to any session for a project
jump-<project>              # Uses fuzzy finder to select session

# General session picker
sesh-pick <slug>           # Find any tmux session containing <slug>

# Direct tmux commands
tmux ls                    # List all sessions
tmux attach -t <session>   # Attach to specific session
```

### Claude Command Setup
```bash
# Link Claude commands from all three repos to ~/.claude/commands
./bin/setup-claude-commands.sh

# Test the command linking
./bin/setup-claude-commands.sh --test
```

### MCP Server Management
```bash
# Start the Context7 MCP Docker container
cd mcp && ./start-docker.sh

# Add MCP configuration to Claude
./mcp/add-claude-mcps.sh
```

## Architecture

### Key Components

1. **starttask** (`bin/starttask`)
   - Creates numbered git worktrees under `~/work/<project>-wt/<slug>/`
   - Always creates fresh branch from origin/main using `git switch -c`
   - Generates tmuxp configuration in `~/agentyard/tmuxp/private/`
   - Launches detached tmux session with Claude Code auto-launched
   - Logs all session output to `~/logs/<project>/<session>-<branch>.log`
   - Updates active tasks tracking in `~/agentyard/state/active-tasks.txt`
   - Auto-installs Claude Code if not present
   - Auto-creates `jump-<project>` helper on first use
   - Each worktree is disposable - one branch per worktree

2. **finishtask** (`bin/finishtask`)
   - Run from inside a tmux session created by starttask
   - Checks for uncommitted changes (safety)
   - Removes the git worktree
   - Deletes the worktree directory
   - Removes tmuxp config file
   - Updates active tasks tracking file
   - Kills the tmux session
   - Preserves log files for historical reference

3. **cleanup-worktrees** (`bin/cleanup-worktrees`)
   - Weekly maintenance command for cleaning up old worktrees
   - Removes worktrees whose branches are fully merged
   - Cleans up associated tmux sessions and tmuxp configs
   - Updates active tasks tracking file
   - `--dry-run` option to preview changes
   - `--all` option for interactive cleanup of unmerged worktrees
   - Runs git gc for maintenance after cleanup

4. **Session Helpers**
   - `sesh-pick`: Fuzzy finder for tmux sessions
   - `jump-<project>`: Project-specific session picker (auto-generated)
   - `list-tasks`: Display all active tasks with details
   - `sync-active-tasks`: Sync active tasks file with actual tmux sessions and worktrees
   - Depends on: sesh, fzf, tmux

5. **Claude Integration**
   - Command templates in `claude-commands/` directories
   - MCP server support via Docker
   - Commands are symlinked to `~/.claude/commands/`

### Directory Structure

```
~/work/<project>/           # Primary git repository
~/work/<project>-wt/        # Worktree container
  ├── 001/                  # First worktree
  ├── 002/                  # Second worktree
  └── ...

~/agentyard/tmuxp/private/  # Session configurations
  ├── <project>-001.yaml
  ├── <project>-002.yaml
  └── ...

~/agentyard/state/          # State tracking
  └── active-tasks.txt      # YAML file tracking all active sessions

~/logs/<project>/           # Session logs
  ├── <project>-001-feature_new-ui.log
  ├── <project>-002-bugfix_issue.log
  └── ...
```

## Working with Git Worktrees

The `starttask` command creates disposable worktrees following these principles:
- One worktree = one branch = one task
- Always creates fresh branches from origin/main using `git switch -c`
- Never reuses worktrees after the task is complete
- Use `finishtask` to clean up when done

This approach prevents git index corruption and ensures clean starting points for each task.

## Dependencies

- git 2.5+ (for worktree support)
- tmux & tmuxp
- sesh (tmux session manager)
- fzf (fuzzy finder)
- npm (for Claude Code installation)
- Docker & docker-compose (for MCP servers)
- zoxide (optional, for smarter cd)

## Shell Configuration Required

Add to `~/.zshrc` or `~/.bashrc`:
```bash
# Path - order matters: public, team, private
export PATH="$HOME/agentyard/bin:$HOME/agentyard-team/bin:$HOME/agentyard-private/bin:$PATH"

# tmuxp configuration directories
export TMUXP_CONFIGDIR="$HOME/agentyard/tmuxp:$HOME/agentyard-team/tmuxp:$HOME/agentyard-private/tmuxp"

# Optional enhancements
eval "$(sesh init zsh)"     # or bash
eval "$(zoxide init zsh)"   # or bash
```

## Claude Commands

The repository includes command templates for Claude AI workflows:

- `implement-gh-issue.md`: Full GitHub issue implementation workflow including planning, coding, testing, PR creation, and monitoring CI/CD

Commands from all three repositories are symlinked to `~/.claude/commands/` for global access.

## Remote Access

The system is designed for remote development and works seamlessly with:
- SSH
- mosh
- Blink Shell
- VS Code Remote-SSH

Sessions persist across disconnections, allowing you to resume work from any device.