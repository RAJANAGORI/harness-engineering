# AI Security Harness – OWASP ASVS 5.0 + NIST SSDF + CSF 2.0

This harness prevents AI coding agents from generating insecure code. It is language‑agnostic and works with Claude Code, Cursor, GitHub Copilot, Codex, and any MCP‑compatible agent.

## Installation

1. Copy all files to your project root.
2. Install dependencies:
   - `jq` (for hook JSON output)
   - `pre-commit`, `semgrep`, `detect-secrets`, `safety`, `grype`
   - (Optional) SigmaShake or MCPKernel for full governance gateway.

3. For Claude Code:
   - Ensure `.claude/settings.json` and `.claude/hooks/bash-firewall.sh` exist.
   - `chmod +x .claude/hooks/bash-firewall.sh`

4. For Cursor:
   - Place `.cursor/rules/security-rules.mdc`. Cursor will auto‑load.

5. For GitHub Copilot:
   - Place `.github/copilot-instructions.md` in repo root (Copilot reads it automatically).

6. Pre‑commit:
   - `pre-commit install`

## Testing the Harness

Try asking an agent to generate a SQL injection:
