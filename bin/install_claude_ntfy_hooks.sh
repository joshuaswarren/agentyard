#!/usr/bin/env bash
# install_claude_ntfy_hooks.sh
# Usage: ./install_claude_ntfy_hooks.sh <NTFY_IP> <NTFY_PORT>

set -e

if [ $# -ne 2 ]; then
  echo "Usage: $0 <NTFY_SERVER_IP> <NTFY_SERVER_PORT>"
  exit 1
fi

IP="$1"
PORT="$2"
URL="http://$IP:$PORT/claudecode"
CLAUDE_DIR="$HOME/.claude"
CFG="$CLAUDE_DIR/settings.json"

# 1) Make sure ~/.claude exists and settings.json too
mkdir -p "$CLAUDE_DIR"
[ -f "$CFG" ] || echo '{}' > "$CFG"

# 2) Write a tiny notify script
cat > "$CLAUDE_DIR/notify.sh" <<EOF
#!/usr/bin/env bash
# reads hook JSON on stdin, extracts .message, posts to ntfy with dir prefix
URL="$URL"
read -r input
msg=\$(echo "\$input" | jq -r .message)
dir=\$(basename "\$PWD")
curl -s -X POST "\$URL" -d "\$dir: \$msg"
EOF
chmod +x "$CLAUDE_DIR/notify.sh"

# 3) Write a stop-session script
cat > "$CLAUDE_DIR/notify_stop.sh" <<EOF
#!/usr/bin/env bash
# sends a “session finished” alert
URL="$URL"
dir=\$(basename "\$PWD")
curl -s -X POST "\$URL" -d "\$dir: Claude Code session finished"
EOF
chmod +x "$CLAUDE_DIR/notify_stop.sh"

# 4) Update settings.json to point at those scripts
jq --arg ncmd "$CLAUDE_DIR/notify.sh" \
   --arg scmd "$CLAUDE_DIR/notify_stop.sh" \
   '
   .hooks.Notification = [ { matcher:"", hooks:[{type:"command",command:$ncmd}] } ] |
   .hooks.Stop         = [ { matcher:"", hooks:[{type:"command",command:$scmd}] } ]
   ' "$CFG" > "${CFG}.tmp" && mv "${CFG}.tmp" "$CFG"

echo "✅ hooks installed. Notify: $CLAUDE_DIR/notify.sh  Stop: $CLAUDE_DIR/notify_stop.sh"
