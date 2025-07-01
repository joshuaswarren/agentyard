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

mkworktree yourproject your-project   # create new work‑tree
jump-yourproject                               # fuzzy‑select a session

