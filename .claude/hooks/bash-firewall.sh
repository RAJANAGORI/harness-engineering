#!/bin/bash
# Claude Code pre‑tool hook – blocks dangerous commands, encoded payloads, reverse shells
HOOK_OUTPUT="${CLAUDE_HOOK_OUTPUT:-/tmp/claude_hook_output.json}"

INPUT=$(echo "$1" | jq -r '.tool_input.command // ""')

# Block reverse shells
if echo "$INPUT" | grep -qE 'bash -i >& /dev/tcp/|nc -e /bin/sh|sh -i >& /dev/tcp/|python -c '"'"'.*socket.*subprocess.*'"'"''; then
  echo '{"decision":"deny","reason":"Reverse shell blocked (ASVS V1.2.5)"}' > $HOOK_OUTPUT
  exit 0
fi

# Block base64 encoded payloads
if echo "$INPUT" | grep -qE 'echo.*\|.*base64 -d.*\|.*sh|echo.*\|.*base64 --decode.*\|.*bash'; then
  echo '{"decision":"deny","reason":"Encoded payload blocked"}' > $HOOK_OUTPUT
  exit 0
fi

# Block credential exfiltration (curl/wget to external with file content)
if echo "$INPUT" | grep -qE '(cat|tail|head).*\.(env|pem|key|secret).*\|.*(curl|wget|nc)'; then
  echo '{"decision":"deny","reason":"Credential exfiltration attempt blocked (ASVS V13.3)"}' > $HOOK_OUTPUT
  exit 0
fi

# Block mass deletion
if echo "$INPUT" | grep -qE 'rm -rf \/|rm -rf \*|rm -rf \. |del \/s'; then
  echo '{"decision":"deny","reason":"Mass deletion blocked"}' > $HOOK_OUTPUT
  exit 0
fi

echo '{"decision":"allow"}' > $HOOK_OUTPUT
