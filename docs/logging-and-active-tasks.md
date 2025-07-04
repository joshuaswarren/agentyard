# Session Logging and Active Task Management

## Overview

Agentyard provides comprehensive logging and task tracking capabilities to help you monitor ongoing work, review past sessions, and manage multiple concurrent development tasks. Every `starttask` session is automatically logged and tracked.

## Session Logging

### Automatic Logging Setup

When you run `starttask`, logging begins immediately:

1. **Log Directory Creation**
   - Base directory: `~/logs/<project>/`
   - Created automatically if it doesn't exist
   - One directory per project

2. **Log File Naming**
   ```
   ~/logs/<project>/<project>-<slug>-<branch>.log
   ```
   - Example: `~/logs/myapp/myapp-003-feature_user-auth.log`
   - Branch slashes converted to underscores
   - Unique name prevents conflicts

3. **What Gets Logged**
   - All terminal output from the tmux session
   - Claude Code interactions
   - Command executions and their output
   - Git operations
   - Error messages
   - Timestamps preserved from terminal

### How Logging Works

The logging mechanism uses tmux's `pipe-pane` feature:

```bash
tmux pipe-pane -o "cat >> '/path/to/logfile'"
```

This captures everything displayed in the tmux pane and appends it to the log file in real-time.

### Viewing Logs

#### Real-time Log Monitoring
```bash
# Watch log as it's being written
tail -f ~/logs/myproject/myproject-001-feature_api.log

# Watch last 50 lines
tail -n 50 -f ~/logs/myproject/myproject-001-feature_api.log
```

#### Searching Logs
```bash
# Search for specific text
grep "error" ~/logs/myproject/myproject-001-feature_api.log

# Search across all logs for a project
grep -r "database" ~/logs/myproject/

# Find logs by date (using ls -lt for time sorting)
ls -lt ~/logs/myproject/
```

#### Log Analysis
```bash
# Count occurrences of a pattern
grep -c "git commit" ~/logs/myproject/myproject-001-feature_api.log

# Extract git commands
grep "^git" ~/logs/myproject/myproject-001-feature_api.log

# Find all test runs
grep -E "(pytest|npm test|cargo test)" ~/logs/myproject/*.log
```

### Log Retention

- Logs are **never automatically deleted**
- Persist after `finishtask` completes
- Useful for:
  - Debugging past issues
  - Reviewing implementation decisions
  - Audit trails
  - Learning from previous sessions

### Log Management Best Practices

1. **Regular Cleanup**
   ```bash
   # Archive old logs (older than 30 days)
   find ~/logs -name "*.log" -mtime +30 -exec gzip {} \;
   
   # Remove very old logs (older than 90 days)
   find ~/logs -name "*.log" -mtime +90 -delete
   ```

2. **Backup Important Logs**
   ```bash
   # Copy logs for completed features
   cp ~/logs/myproject/myproject-001-feature_api.log ~/project-archives/
   ```

3. **Log Rotation Script** (optional)
   ```bash
   #!/bin/bash
   # Archive logs older than 7 days
   find ~/logs -name "*.log" -mtime +7 -exec gzip {} \;
   ```

## Active Task Management

### Viewing Active Tasks

#### Using `list-tasks` Command

The primary way to see all active tasks:

```bash
list-tasks
```

Output example:
```
Active Tasks (3 total):

myapp-001 (feature/user-auth)
  Created: 2024-01-20 10:30:15
  Directory: ~/work/myapp-wt/001
  Session: ✓ Running

myapp-002 (bugfix/memory-leak)
  Created: 2024-01-20 14:22:03
  Directory: ~/work/myapp-wt/002
  Session: ✓ Running

deckard-003 (feature/api-update)
  Created: 2024-01-21 09:15:42
  Directory: ~/work/deckard-wt/003
  Session: ✗ Not found (needs cleanup)
```

#### Direct Tmux Commands

See all tmux sessions:
```bash
# List all sessions
tmux ls

# Output example:
myapp-001: 1 windows (created Sat Jan 20 10:30:15 2024) [80x24]
myapp-002: 1 windows (created Sat Jan 20 14:22:03 2024) [80x24]
deckard-003: 1 windows (created Sun Jan 21 09:15:42 2024) [80x24]
```

#### Using Jump Commands

Quick session picker for a specific project:
```bash
# For project 'myapp'
jump-myapp

# Shows fuzzy finder with:
# myapp-001
# myapp-002
# (select with arrow keys or type to filter)
```

### Active Tasks File

The system maintains a YAML file tracking all active tasks:

**Location**: `~/agentyard/state/active-tasks.txt`

**Format**:
```yaml
- session_name: myapp-001
  project: myapp
  branch: feature/user-auth
  worktree_path: /Users/username/work/myapp-wt/001
  creation_timestamp: 2024-01-20T10:30:15Z
  log_file_path: /Users/username/logs/myapp/myapp-001-feature_user-auth.log

- session_name: myapp-002
  project: myapp
  branch: bugfix/memory-leak
  worktree_path: /Users/username/work/myapp-wt/002
  creation_timestamp: 2024-01-20T14:22:03Z
  log_file_path: /Users/username/logs/myapp/myapp-002-bugfix_memory-leak.log
```

#### Viewing Raw Task File
```bash
# View all active tasks
cat ~/agentyard/state/active-tasks.txt

# Count active tasks
grep "session_name:" ~/agentyard/state/active-tasks.txt | wc -l

# Find tasks for specific project
grep -A5 "project: myapp" ~/agentyard/state/active-tasks.txt
```

### Synchronizing Task State

Sometimes the active tasks file can get out of sync (e.g., if tmux sessions were killed manually). Use:

```bash
sync-active-tasks
```

This command:
- Checks each task in the file
- Verifies tmux session exists
- Verifies worktree exists
- Removes entries for non-existent tasks
- Reports what was cleaned up

### Task Information Queries

#### Find Task by Branch
```bash
# Search active tasks for a branch
grep -B1 -A4 "branch: feature/user-auth" ~/agentyard/state/active-tasks.txt
```

#### List Tasks by Age
```bash
# Sort sessions by creation time
tmux ls -F "#{session_created} #{session_name}" | sort -n | awk '{print $2}'
```

#### Check Worktree Status
```bash
# See all worktrees for a project
ls -la ~/work/myapp-wt/

# Check git status in all worktrees
for dir in ~/work/myapp-wt/*/; do
  echo "=== $(basename $dir) ==="
  git -C "$dir" status --short
done
```

## Integration with LLMs

### Structured Data Access

Both logs and task tracking use LLM-friendly formats:

1. **Logs**: Plain text with preserved formatting
2. **Task File**: YAML structure for easy parsing
3. **Consistent Paths**: Predictable file locations

### Using with Claude Code

When Claude Code is running in a session, it can:

```bash
# Check what session it's in
echo $TMUX
tmux display-message -p '#S'

# View its own log
tail -n 100 ~/logs/${PROJECT}/${SESSION}-*.log

# Check sibling tasks
cat ~/agentyard/state/active-tasks.txt
```

### Automated Analysis Scripts

Example script to summarize all active work:

```bash
#!/bin/bash
# summarize-work.sh

echo "=== Active Development Tasks ==="
echo

while IFS= read -r line; do
  if [[ $line =~ ^-\ session_name:\ (.+)$ ]]; then
    session="${BASH_REMATCH[1]}"
  elif [[ $line =~ ^\ \ branch:\ (.+)$ ]]; then
    branch="${BASH_REMATCH[1]}"
  elif [[ $line =~ ^\ \ creation_timestamp:\ (.+)$ ]]; then
    timestamp="${BASH_REMATCH[1]}"
    echo "• $session: $branch (started $timestamp)"
  fi
done < ~/agentyard/state/active-tasks.txt

echo
echo "Total active tasks: $(grep -c "session_name:" ~/agentyard/state/active-tasks.txt)"
```

## Best Practices

### For Logging

1. **Review logs before PR creation**
   - Check for accidentally logged secrets
   - Verify all tests passed
   - Review git operations

2. **Use logs for debugging**
   - When something went wrong
   - To understand Claude Code's actions
   - To replay command sequences

3. **Archive completed work**
   - Compress logs after task completion
   - Keep important session logs
   - Delete trivial or failed attempts

### For Task Management

1. **Regular cleanup**
   - Run `cleanup-worktrees` weekly
   - Use `sync-active-tasks` if inconsistencies appear
   - Complete tasks with `finishtask`

2. **Naming discipline**
   - Use descriptive branch names
   - Keep consistent project names
   - Document task purpose in commits

3. **Monitor active work**
   - Check `list-tasks` daily
   - Don't leave zombie sessions
   - Finish tasks before starting similar ones

## Troubleshooting

### Missing Logs

If logs aren't being created:
1. Check `~/logs/<project>/` directory exists
2. Verify tmux pipe-pane is active: `tmux show-options -p`
3. Check disk space: `df -h ~/logs`

### Stale Task Entries

If tasks show in file but not in tmux:
1. Run `sync-active-tasks`
2. Manually verify worktree: `ls ~/work/<project>-wt/`
3. Check tmux sessions: `tmux ls`

### Log File Too Large

For very long sessions:
```bash
# Rotate the log
mv ~/logs/project/session.log ~/logs/project/session.log.1
touch ~/logs/project/session.log

# Or compress in place
gzip ~/logs/project/old-session.log
```

## Summary

The logging and task management system provides:

- **Complete session history** via automatic logging
- **Real-time task visibility** through multiple interfaces
- **Persistent records** for debugging and auditing
- **LLM-friendly formats** for automation
- **Simple maintenance** commands for cleanup

This infrastructure ensures you never lose work context and can always track what's in progress across multiple projects and tasks.