#!/usr/bin/env bash
# install_claude_ntfy_hooks.sh
# Usage: ./install_claude_ntfy_hooks.sh <IP> <PORT>
set -e

if [ $# -ne 2 ]; then
  echo "Usage: $0 <NTFY_SERVER_IP> <NTFY_SERVER_PORT>"
  exit 1
fi

IP="$1"
PORT="$2"
CFG="$HOME/.claude/settings.json"

# Ensure settings.json exists
if [ ! -f "$CFG" ]; then
  mkdir -p "$(dirname "$CFG")"
  echo '{"hooks":{}}' > "$CFG"
fi

# Build new hooks via jq
jq --arg url "http://$IP:$PORT/claudecode" '
  .hooks.Notification = [
    {
      matcher: "",
      hooks: [
        {
          type: "command",
          command: ("bash -c '\''read -r input; msg=$(echo \"$input\" | jq -r .message); curl -X POST \"" + $url + "\" -d \"$msg\"'\''")
        }
      ]
    }
  ] |
  .hooks.Stop = [
    {
      matcher: "",
      hooks: [
        {
          type: "command",
          command: ("curl -X POST \"" + $url + "\" -d \"Claude Code session finished\"")
        }
      ]
    }
  ]
' "$CFG" > "${CFG}.tmp" && mv "${CFG}.tmp" "$CFG"

echo "✅ Updated hooks in $CFG to point at $IP:$PORT (topic: claudecode)"

