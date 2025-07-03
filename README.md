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

starttask yourproject feature/new-feature   # create disposable worktree & session
jump-yourproject                            # fuzzy‑select a session
finishtask                                  # clean up worktree when done (run inside session)

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
