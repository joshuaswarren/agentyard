Agentyard
=========

# agentyard

**Agentyard** is a workflow orchestration system designed for developers working with AI coding assistants. Born from real-world experience managing many concurrent AI coding sessions, it provides the infrastructure layer between human developers and AI agents. The system creates isolated, disposable workspaces for each coding task, automatically integrates with Claude Code and other AI assistants, and maintains clean git hygiene through its one-worktree-per-branch architecture. Whether you're exploring agentic coding patterns, building AI-powered development workflows, or scaling AI-assisted engineering across teams, Agentyard provides practical tools for managing AI-enhanced development workflows. This is workspace-as-code for the AI era.

Public scaffolding for running multiple AI coding sessions with tmux.
- bin/: CLI helpers (starttask, finishtask, sesh-pick, jump-*)
- tmuxp/public/: example layouts
License: GPL‑3.0‑or‑later

## Shell setup

Put the *bin* folders from all three packs on your PATH and tell **tmuxp** where to find layouts.

```sh
# Path – order matters: public first, then team, then private
export PATH="$HOME/agentyard/bin:$HOME/agentyard-team/bin:$HOME/agentyard-private/bin:$PATH"

# tmuxp scans these folders for *.yaml session files
export TMUXP_CONFIGDIR="$HOME/agentyard/tmuxp:$HOME/agentyard-team/tmuxp:$HOME/agentyard-private/tmuxp"

# (optional) sesh & zoxide hooks
eval "$(zoxide init zsh)"

# For mentor command - OpenAI API key
export OPENAI_API_KEY="your-api-key-here"  # Required for mentor command
# export OPENAI_MODEL="gpt-4"              # Optional: override default model (o3)
```

Add the lines above to ~/.zshrc (or ~/.bashrc), source the file, and you’re ready:

starttask yourproject feature/new-feature   # create disposable worktree & session with Claude Code
starttask yourproject bugfix/issue -p 123   # create session and send /plan command for issue #123
starttask yourproject feature/auth --implement 456  # create session and implement issue #456
jump-yourproject                            # fuzzy‑select a session
finishtask                                  # clean up worktree when done (run inside session)
cleanup-worktrees                           # weekly cleanup of merged worktrees
list-tasks                                  # show all active tasks
sync-active-tasks                           # sync active tasks file with actual state
judge 45                                    # AI-powered review of PR #45 using local LLM
judge scan-models                           # Scan for models and update configuration
agentsmd                                    # Create/update AGENTS.md with AI analysis
agentsmd-dedupe                             # Deduplicate rules in AGENTS.md files
mentor                                      # AI-powered code review of recent commits using OpenAI
setup-claude-commands.sh                    # Link Claude commands to ~/.claude/commands

## New Features

### Claude Code Integration
- **Auto-launch**: `starttask` now automatically launches Claude Code in the tmux session
- **Auto-install**: If Claude Code isn't installed, it will be installed automatically via npm
- **Fallback**: If Claude Code fails to launch, the session falls back to a regular shell
- **Direct Command Flags**: New `--plan`/`-p` and `--implement`/`-i` flags for immediate task execution:
  - `starttask project branch -p 123` - Launches Claude and sends `/plan GitHub issue 123`
  - `starttask project branch --implement 456 "prioritize performance"` - Sends `/implement-gh-issue 456 prioritize performance`
  - Flags can include optional issue numbers and additional message text
  - Commands are sent automatically 3 seconds after session attachment

### Session Logging
- All tmux session output is automatically logged to `~/logs/<project>/<session>-<branch>.log`
- Branch names with slashes are sanitized (e.g., `feature/ui` becomes `feature_ui` in the log filename)
- Logging continues even if you exit Claude Code and return to the shell
- Log files are preserved after `finishtask` for future reference

### Active Tasks Tracking
- All active tasks are tracked in `~/agentyard/state/active-tasks.txt` (YAML format)
- Use `list-tasks` to see all active sessions with their details
- Use `sync-active-tasks` to recover from manual tmux kills or sync the state file
- The tracking file is automatically updated by `starttask`, `finishtask`, and `cleanup-worktrees`

### AI-Powered PR Reviews with Judge
- **Local LLM Integration**: Uses llama.cpp for private, fast code reviews
- **GitHub CLI Integration**: Fetches PR data using `gh` CLI
- **Metal Acceleration**: Automatic GPU support on macOS
- **Namespace Model Storage**: Models organized as `namespace/model/` (e.g., `mistralai/mistral-7b/`)
- **Model Discovery**: `judge scan-models` finds models in multiple locations including LM Studio
- **GGUF Metadata Parsing**: Extracts architecture, quantization, and parameters from model files
- **Non-Interactive Mode**: `--force` flag for CI/automation use
- **Automatic Model Download**: Downloads models from HuggingFace with smart quantization selection
- **Flexible Model Storage**: Environment variable, config file, or per-model path settings
- **Easy Setup**: `judge --init-config` creates configuration with sensible defaults
- **Model Validation**: Checks for model availability before starting review
- **Configurable Models**: Support for any GGUF-format model
- **Structured Output**: Markdown-formatted reviews with severity levels
- **Smart PR Resolution**: Review by PR number or branch name
- See [Judge Command Guide](docs/judge-command-guide.md) for setup and usage

### Interactive Planning with Claude Code's /plan Command
- **Note**: `/plan` is a Claude Code command, not a shell command
- **Usage**: After running `starttask`, use `/plan` within Claude Code
- **Codebase Analysis**: Automatically analyzes relevant files before planning
- **Interactive Questions**: Asks clarifying questions to create better plans
- **GitHub Integration**: Updates issue descriptions with generated plans
- **Planning Only**: Never implements code - purely for planning
- **Structured Output**: Detailed tasks with complexity estimates
- **Agentyard Integration**: Suggests `starttask` commands for implementation
- See [Plan Command Guide](docs/plan-command.md) for details

### AI-Powered Commit Reviews with Mentor
- **OpenAI Integration**: Uses OpenAI's API for comprehensive code quality analysis
- **Git Integration**: Reviews single commits, specific commits, or commit ranges
- **Existing Guidelines Awareness**: Checks AGENTS.md and CLAUDE.md to avoid duplicate suggestions
- **Smart Filtering**: Automatically filters out third-party code (node_modules, vendor, etc.)
- **Language-Specific Standards**: Enforces PEP 8 for Python, PSR-12 for PHP, and other standards
- **Actionable Feedback**: Provides specific before/after code examples with explanations
- **Dual Output**: Shows findings in terminal and appends to AGENTS.md/CLAUDE.md
- **Flexible Model Selection**: Default to o3, configurable via --model flag, env var, or .env file
  - **Note**: o3 models (o3, o3-mini) use fixed reasoning parameters and don't support temperature control
- **Usage Examples**:
  - `mentor` - Review most recent commit
  - `mentor abc123def` - Review specific commit
  - `mentor abc123 def456` - Review commit range
  - `mentor --model gpt-4` - Use specific model origin/main

### AI Agent Instruction Files Management
- **agentsmd**: Manages AGENTS.md files with migration system and Claude analysis
- **agentsmd-dedupe**: Removes duplicate rules from AGENTS.md files
  - Detects exact duplicates and multi-line duplicates
  - Optionally uses LLM for intelligent deduplication
  - Usage: `agentsmd-dedupe` or `agentsmd-dedupe --llm` for AI-powered deduplication
- **Note**: CLAUDE.md and GEMINI.md are created as symlinks to AGENTS.md by agentsmd

### AI-Powered AGENTS.md Management with agentsmd
- **Migration System**: Uses numbered best practice files that apply in order
- **Claude Analysis**: Automatically analyzes your codebase for project-specific content
- **Version Tracking**: Prevents duplicate migrations with `.agentyard-version.yml`
- **Smart Caching**: Caches Claude analysis results with automatic invalidation
- **Symlink Management**: Creates CLAUDE.md and GEMINI.md as symlinks to AGENTS.md
- **Key Features**:
  - `agentsmd` - Apply all new migrations to current project
  - `agentsmd --check-only` - Preview what would be done
  - `agentsmd --list-migrations` - Show available migrations
  - `agentsmd --project ~/work/myapp` - Run on specific directory
  - `agentsmd --no-cache` - Force fresh Claude analysis
- See [Agentsmd Guide](docs/agentsmd-guide.md) for detailed usage

### Using Claude Code Hooks to Send Ntfy.sh Notifications
Prerequisites

- Docker installed and running (any recent Docker Desktop on macOS, or Docker Engine on Linux).
- jq (command-line JSON processor) for the helper script (install with brew install jq on macOS or your distro’s package manager). 
- Claude Code installed and authenticated; its user settings live in ~/.claude/settings.json.

1. Run your ntfy.sh server in Docker

Choose a port (e.g. 8948) that’s free on your host.

Create config/cache dirs (optional defaults suffice):
 mkdir -p ~/ntfy/etc ~/ntfy/cache

Launch the container, mapping host port ⇢ container port 80:
docker run -d \
  --name ntfy \
  -p 8948:80 \
  -v ~/ntfy/etc:/etc/ntfy \
  -v ~/ntfy/cache:/var/cache/ntfy \
  binwiederhier/ntfy serve

This uses the official image, which bundles the server binary in a Docker container 

Verify health:
curl http://localhost:8948/v1/health
# expects: {"healthy":true}

If you see {"healthy":true}, your server’s ready to receive messages.

I recommend setting this up on a device that's connected to Tailscale and also connecting your other devices to Tailscale so that this will work when you're outside of your home network. 

2. run install_claude_ntfy_hooks.sh to install the notification hooks

3. Subscribe to the topic claudecode on your ntfy server using the ntfy app on your mobile device(s)

### Additional Setup
- **Claude Commands**: Run `setup-claude-commands.sh` to link command templates from all three repos to `~/.claude/commands`
