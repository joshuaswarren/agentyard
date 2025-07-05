# agentyard

Agentyard
=========

Public scaffolding for running multiple AI coding sessions with tmux.
- bin/: CLI helpers (mkworktree, sesh-pick, jump-*)
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
```

Add the lines above to ~/.zshrc (or ~/.bashrc), source the file, and you’re ready:

starttask yourproject feature/new-feature   # create disposable worktree & session with Claude Code
jump-yourproject                            # fuzzy‑select a session
finishtask                                  # clean up worktree when done (run inside session)
cleanup-worktrees                           # weekly cleanup of merged worktrees
list-tasks                                  # show all active tasks
sync-active-tasks                           # sync active tasks file with actual state
judge 45                                    # AI-powered review of PR #45 using local LLM
judge scan-models                           # Scan for models and update configuration  
/plan "implement feature X"                 # Interactive planning with codebase analysis

## New Features

### Claude Code Integration
- **Auto-launch**: `starttask` now automatically launches Claude Code in the tmux session
- **Auto-install**: If Claude Code isn't installed, it will be installed automatically via npm
- **Fallback**: If Claude Code fails to launch, the session falls back to a regular shell

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

### Interactive Planning with /plan Command
- **Codebase Analysis**: Automatically analyzes relevant files before planning
- **Interactive Questions**: Asks clarifying questions to create better plans
- **GitHub Integration**: Updates issue descriptions with generated plans
- **Planning Only**: Never implements code - purely for planning
- **Structured Output**: Detailed tasks with complexity estimates
- **Agentyard Integration**: Suggests `starttask` commands for implementation
- See [Plan Command Guide](docs/plan-command.md) for details

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
