AGENTS.md

This file answers three questions:
	1.	What is Agentyard?
	2.	Why do we keep three folders?
	3.	How do you work inside this system?

⸻

1 · What Agentyard is

Agentyard is a tiny tool‑belt that lets you spin up, name, and jump into many AI coding sessions (agents) without losing your mind.
	•	One command (mkworktree) ⟶ a fresh Git work‑tree and a detached tmux session.
	•	One keystroke (jump‑<project>) ⟶ a fuzzy list of live sessions for that project.
	•	You can hop in from any device (SSH, mosh, Blink, VS Code Remote‑SSH).

No big framework, just shell scripts and tmux.

⸻

2 · Why there are three folders

Folder	GitHub repo	Who sees it	What lives inside
~/agentyard	public (joshuaswarren/agentyard)	Anyone	Core scripts (mkworktree, sesh‑pick, jump‑*), public docs, example tmuxp layouts.
~/agentyard-team	private 	Team	Shared proof‑of‑concept stacks, team prompts, run‑books, tmuxp files.
~/agentyard-private	private	 .  User only	Personal code, personal prompts, local MCP servers, anything you don’t share.

Three roots keep public, team, and personal work cleanly apart. Ensure nothing sensitive ever lands in the public repo by accident.

⸻

3 · Path and tmuxp setup

Add this to ~/.zshrc (order matters):

export PATH="$HOME/agentyard/bin:$HOME/agentyard-team/bin:$HOME/agentyard-private/bin:$PATH"
export TMUXP_CONFIGDIR="$HOME/agentyard/tmuxp:$HOME/agentyard-team/tmuxp:$HOME/agentyard-private/tmuxp"

# Helpful extras
eval "$(sesh init zsh)"     # fuzzy tmux picker
eval "$(zoxide init zsh)"   # smarter cd

source ~/.zshrc and you’re done.

⸻

4 · Daily loop

mkworktree deckard codex/feature-x   # new numbered work‑tree + session
jump-deckard                         # pick and attach
codex                                # run the agent, assign tasks
Ctrl‑b d                             # detach, back to shell

Everything just works on mosh, Blink, or a normal SSH terminal.

⸻

5 · Adding the next project
	1.	Clone or create ~/work/<project> (primary repo).
	2.	mkworktree <project> <branch> – first run also writes jump‑<project>.
	3.	Commit any project‑specific tmuxp files to the right pack:
	•	Public example ➜ agentyard/tmuxp/public
	•	Team asset    ➜ agentyard-team/tmuxp
	•	Personal only ➜ agentyard-private/tmuxp

Keep it light, ship real code, repeat.
