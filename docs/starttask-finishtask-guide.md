# Starttask and Finishtask Usage Guide

## Overview

The `starttask` and `finishtask` commands form the core of Agentyard's ephemeral development workflow. They provide a streamlined way to create isolated development environments for each task, with automatic git worktree management, tmux session creation, and Claude Code integration.

## Core Concepts

### Ephemeral Worktrees
- **One task = One worktree = One branch = One tmux session**
- Each worktree is disposable and single-purpose
- Always starts fresh from origin/main
- Never reused after task completion

### Automatic Session Management
- Tmux sessions are automatically created and configured
- Claude Code launches automatically in each session
- All session output is logged for future reference
- Sessions persist across network disconnections

## The Starttask Command

### Basic Syntax
```bash
starttask <project> <branch> [slug]
```

### Parameters
- `<project>`: The name of your project (must have a git repo at `~/work/<project>`)
- `<branch>`: The git branch name to create (e.g., `feature/new-ui`, `bugfix/login-issue`)
- `[slug]`: Optional 3-digit identifier (001-999). If omitted, auto-increments from highest existing

### What Starttask Does

1. **Pre-flight checks**
   - Installs Claude Code if not present (via npm)
   - Validates git repository exists at `~/work/<project>`
   - Checks for branch naming conflicts (e.g., can't create `foo/bar` if branch `foo` exists)
   - Fetches latest changes from origin

2. **Creates a numbered git worktree**
   - Location: `~/work/<project>-wt/<slug>/`
   - Auto-detects base branch (origin/main or origin/master)
   - Creates worktree in detached HEAD state first
   - Then creates fresh branch using `git switch -c <branch> <base>`
   - Avoids checkout conflicts by using detached HEAD approach

3. **Generates tmuxp configuration**
   - Creates YAML config in `~/agentyard/tmuxp/private/`
   - Configures windows and panes for optimal workflow
   - Sets up Claude Code auto-launch with --dangerously-skip-permissions flag
   - Configures automatic session logging via tmux pipe-pane

4. **Launches tmux session**
   - Session name: `<project>-<slug>`
   - Runs in detached mode initially
   - Automatically starts Claude Code
   - Begins logging all output to `~/logs/<project>/<session>-<branch>.log`
   - Auto-attaches to session after creation

5. **Updates tracking**
   - Records task in `~/agentyard/state/active-tasks.txt`
   - Includes UTC timestamp, branch name, worktree path, and log file location
   - YAML format for easy parsing by humans and LLMs

6. **Creates helpers**
   - Auto-generates `jump-<project>` command on first use
   - Uses sesh + fzf for fuzzy project session selection

### Examples

```bash
# Auto-numbered worktree (will be 001 if first, or next available)
starttask myapp feature/user-auth

# Explicitly numbered worktree
starttask myapp bugfix/crash-on-save 042

# Working with existing project
starttask deckard feature/api-update
```

### Auto-numbering Details
- Scans `~/work/<project>-wt/` for existing numbered directories
- Finds highest number and increments by 1
- Handles octal interpretation correctly (e.g., 007, 008, 009)
- Always formats as 3 digits with leading zeros (001-999)

### Output Example
```
✔ Disposable worktree created: /Users/username/work/deckard-wt/003
✔ Fresh branch: feature/api-update (from origin/main)
✔ tmux session: deckard-003 (detached)

When done with this task:
  finishtask        # (run inside the tmux session)

Attaching to session...
```

## The Finishtask Command

### Basic Syntax
```bash
finishtask
```

### Prerequisites
- Must be run from inside a tmux session created by `starttask`
- Checks for uncommitted changes before proceeding

### What Finishtask Does

1. **Session validation**
   - Verifies you're in a tmux session
   - Validates session name format (project-slug)
   - Confirms you're in the expected worktree directory

2. **Safety checks**
   - Checks for uncommitted changes (staged and unstaged)
   - Warns about untracked files
   - Shows branch info and commit count
   - Prompts for confirmation if untracked files exist

3. **Cleans up git worktree**
   - Uses `git worktree remove --force`
   - Removes from the main repository's worktree list
   - Deletes the worktree directory

4. **Removes configuration**
   - Deletes tmuxp YAML file
   - Updates active tasks tracking file (removes current session)
   - Uses awk to cleanly remove multi-line YAML entries

5. **Ends session**
   - Shows success message with branch and commit info
   - Detaches from tmux before killing (prevents auto-switch)
   - Kills the tmux session
   - Preserves log files for history

### Safety Features
- Won't run outside of starttask sessions
- Warns about uncommitted changes
- Prevents accidental data loss
- Logs are never deleted

## Complete Workflow Example

### 1. Start a new task
```bash
starttask myproject feature/add-search
```

### 2. Work in the session
```bash
# Either attach immediately
tmux attach -t myproject-001

# Or use the jump command
jump-myproject

# Inside the session:
# - Claude Code is already running
# - You're in the correct worktree directory
# - Git branch is created and checked out
```

### 3. Develop your feature
- Write code
- Run tests
- Commit changes
- Push to remote

### 4. Complete the task
```bash
# Inside the tmux session
finishtask
```

### 5. The branch remains on remote
- Create PR from GitHub/GitLab
- Worktree is gone but branch exists remotely
- Logs are preserved in `~/logs/<project>/`

## Advanced Usage

### Session Logging
All sessions are automatically logged to:
```
~/logs/<project>/<project>-<slug>-<branch>.log
```

Features:
- Branch names with slashes are converted to underscores in filenames
- Logs capture all terminal output via `tmux pipe-pane`
- Log files are created immediately when session starts
- Logs persist even after `finishtask` for historical reference

Example: `~/logs/deckard/deckard-003-feature_api-update.log`

### Active Task Management

View all active tasks:
```bash
list-tasks
```

Sync task tracking (fixes inconsistencies):
```bash
sync-active-tasks
```

### Weekly Cleanup

Remove merged worktrees:
```bash
cleanup-worktrees
```

Preview what would be cleaned:
```bash
cleanup-worktrees --dry-run
```

Interactive cleanup (includes unmerged):
```bash
cleanup-worktrees --all
```

### Multiple Concurrent Tasks

You can have multiple tasks running simultaneously:
```bash
starttask myapp feature/search 001
starttask myapp bugfix/memory-leak 002
starttask myapp feature/notifications 003

# Switch between them
jump-myapp  # Shows picker with all three
```

## Integration with AI Workflows

### Claude Code Integration
- Automatically launches in each session
- Has access to the full worktree
- Can see git status and branch info
- Isolated from other tasks

### LLM-Friendly Features
- Structured active-tasks.txt file (YAML format)
- Consistent naming patterns
- Clear session boundaries
- Logged output for context

### Using with Claude Commands
```bash
# Start task for GitHub issue
starttask myapp issue-123

# In the session, Claude can:
# - Read the issue details
# - Implement the solution
# - Run tests
# - Create commits
# - Prepare PR
```

## Best Practices

### 1. Branch Naming
- Use descriptive branch names
- Follow your team's conventions
- Examples: `feature/user-auth`, `bugfix/login-issue`, `chore/update-deps`

### 2. Task Granularity
- One feature/fix per task
- Keep tasks focused and atomic
- Complete tasks before starting new ones

### 3. Regular Cleanup
- Run `cleanup-worktrees` weekly
- Remove completed tasks promptly
- Keep active task list manageable

### 4. Commit Early and Often
- Make regular commits in your worktree
- Push to remote before using `finishtask`
- This ensures your work is safe

### 5. Session Management
- Use `jump-<project>` for quick switching
- Detach with `Ctrl-B D` (default tmux)
- Reattach with `tmux attach -t <session>`

## Troubleshooting

### Common Issues

**"Not in a tmux session created by starttask"**
- Ensure you're running `finishtask` from inside the session
- Check session name matches pattern: `<project>-<number>`

**"You have uncommitted changes"**
- Commit or stash your changes first
- Or confirm you want to proceed anyway

**"Worktree already exists"**
- Use a different slug number
- Or clean up the existing worktree first

**"Claude Code not launching"**
- Check if npm is installed
- Claude Code auto-installs on first use
- Manual install: `npm install -g @anthropic-ai/claude-code`
- Try manual launch: `claude --dangerously-skip-permissions`

**"Error: git worktree add failed"**
- Check for branch naming conflicts
- Ensure origin/main or origin/master exists
- Run `git fetch --all` in main repo

### Recovery Procedures

**Orphaned worktree:**
```bash
# Manually remove
git worktree remove ~/work/<project>-wt/<slug>
rm -rf ~/work/<project>-wt/<slug>
```

**Orphaned tmux session:**
```bash
tmux kill-session -t <project>-<slug>
```

**Fix task tracking:**
```bash
sync-active-tasks
```

## Technical Details for LLMs

### File Locations
- Worktrees: `~/work/<project>-wt/<slug>/`
- Configs: `~/agentyard/tmuxp/private/<project>-<slug>.yaml`
- Logs: `~/logs/<project>/<project>-<slug>-<branch>.log`
- State: `~/agentyard/state/active-tasks.txt`

### Active Tasks File Format
```yaml
- session_name: myapp-001
  project: myapp
  branch: feature/search
  worktree_path: /Users/username/work/myapp-wt/001
  creation_timestamp: 2024-01-20T10:30:00Z
  log_file_path: /Users/username/logs/myapp/myapp-001-feature_search.log

- session_name: myapp-002
  project: myapp
  branch: bugfix/crash
  worktree_path: /Users/username/work/myapp-wt/002
  creation_timestamp: 2024-01-20T14:15:00Z
  log_file_path: /Users/username/logs/myapp/myapp-002-bugfix_crash.log
```

### Environment Variables
- `TMUX`: Set when inside tmux session
- `TMUX_PANE`: Current pane identifier
- Standard git environment in worktree

### Tmuxp Configuration Generated
```yaml
session_name: <project>-<slug>
start_directory: ~/work/<project>-wt/<slug>
windows:
  - window_name: <project>
    panes:
      - shell_command:
          - tmux pipe-pane -o "cat >> '<log_file>'"
          - claude --dangerously-skip-permissions || exec $SHELL -l
```

The `|| exec $SHELL -l` fallback ensures you get a shell if Claude Code fails to start.

### Git Worktree Commands Used
```bash
# Fetch updates (in starttask)
git fetch -q --all --prune

# Creation (in starttask) - two-step process
git worktree add --detach <path>
git -C <path> switch -c <branch> origin/main

# Removal (in finishtask)
git worktree remove <path> --force
```

### Branch Naming Conflict Prevention
The system prevents creating branches like `foo/bar` if a branch `foo` already exists, as Git doesn't allow this hierarchy conflict. Error message suggests alternative naming schemes.

## Summary

The `starttask`/`finishtask` workflow provides:
- **Isolation**: Each task in its own environment
- **Automation**: Session and git management handled automatically
- **Persistence**: Work continues across disconnections
- **Cleanliness**: Easy cleanup when tasks complete
- **Integration**: Seamless Claude Code and AI workflow support

This approach eliminates common development friction points while maintaining a clean, organized workspace suitable for both human developers and AI assistants.