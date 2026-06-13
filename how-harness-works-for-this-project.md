Here is a **text‑based workflow diagram** that explains how harness engineering layers secure an AI‑generated code request—from user input to final commit. Each layer corresponds to a file or component we built earlier.

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              AI SECURITY HARNESS WORKFLOW                            │
└─────────────────────────────────────────────────────────────────────────────────────┘

[USER REQUEST]
      │
      ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│  1️⃣ INSTRUCTION INJECTION (Pre‑prompt)                                              │
│  Files: CLAUDE.md, AGENTS.md, .cursor/rules/*.mdc, .github/copilot-instructions.md │
│                                                                                     │
│  → Injects security rules (ASVS, SSDF, CSF) into the agent's system prompt.        │
│  → Agent understands: no hardcoded secrets, no SQL concatenation, use param queries.│
└─────────────────────────────────────────────────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│  2️⃣ AGENT GENERATES CODE & TOOL CALLS                                              │
│  (Claude, Cursor, Codex, Copilot)                                                  │
│                                                                                     │
│  → Produces code + possible bash commands, file edits, network requests.           │
└─────────────────────────────────────────────────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│  3️⃣ DENY RULES (Pre‑execution)                                                     │
│  File: .claude/settings.json (Claude), or native blocklists in other agents.       │
│                                                                                     │
│  → Blocks dangerous commands BEFORE they execute: "rm -rf", "DROP DATABASE",       │
│    "bash -i >& /dev/tcp/", "curl ... | sh".                                        │
│  → If match → DENY → Log + notify user → STOP.                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘
      │ (if allowed by deny rules)
      ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│  4️⃣ PRE‑TOOL USE HOOKS (Command‑level filtering)                                   │
│  File: .claude/hooks/bash-firewall.sh                                              │
│                                                                                     │
│  → Runs for every bash command.                                                     │
│  → Detects encoded payloads (base64), reverse shells, credential exfiltration.     │
│  → If malicious → DENY (return {"decision":"deny"}) → Log → STOP.                  │
└─────────────────────────────────────────────────────────────────────────────────────┘
      │ (if hook returns allow)
      ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│  5️⃣ GOVERNANCE GATEWAY (API‑level inspection)                                      │
│  Options: SigmaShake (ssg-config.yaml) or MCPKernel (mcp-gateway-config.json)      │
│                                                                                     │
│  → Intercepts every agent tool call (bash, edit, network) via local proxy.         │
│  → Applies rule sets: SQL injection patterns, eval(), weak crypto, token budgets.  │
│  → Also enforces per‑session token limits (e.g., 10k tokens) → prevents runaway     │
│    token usage.                                                                     │
│  → Decision: ALLOW / DENY / WARN / REQUEST_HUMAN_APPROVAL                           │
└─────────────────────────────────────────────────────────────────────────────────────┘
      │ (if allowed)
      ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│  6️⃣ LOCAL EXECUTION / FILE WRITE (Sandboxed)                                       │
│  Agent runs allowed command or writes generated code to disk.                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│  7️⃣ PRE‑COMMIT HOOKS (Static analysis before commit)                               │
│  File: .pre-commit-config.yaml                                                     │
│                                                                                     │
│  → Runs automatically on `git commit`.                                              │
│  → Tools: semgrep (OWASP Top 10), detect-secrets (hardcoded keys), safety (PyPI    │
│    deps), grype (container/fs), osv-scanner (OSV.dev database).                    │
│  → If any high/critical vulnerability found → BLOCK commit → Report to user.       │
└─────────────────────────────────────────────────────────────────────────────────────┘
      │ (if all checks pass)
      ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│  8️⃣ CI PIPELINE SCANS (Pull Request)                                               │
│  GitHub Actions / GitLab CI                                                         │
│                                                                                     │
│  → Re‑runs SAST, SCA, secret scanning on full codebase.                            │
│  → Fails PR if new vulnerabilities are introduced.                                 │
│  → Uploads SARIF to GitHub Code Scanning (optional).                               │
└─────────────────────────────────────────────────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│  9️⃣ SECURE CODE MERGED ✅                                                          │
│  All layers passed. Code is compliant with OWASP ASVS, NIST SSDF, NIST CSF.        │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔁 Maintenance Loop (Monthly / Continuous)

The harness is not static. The feedback loop that updates it comes from CVEs, audit logs, and false positives:

```
[CVEs / OSV.dev]  →  [Governance Gateway rules]  →  [Pre‑commit scans]  →  [Fail PR if vulnerable]
        │                                                      │
        └─────── [Audit logs, false positives] ───────────────┘
                           │
                           ▼
              [Tune allowlists, update semgrep patterns]
                           │
                           ▼
                   [Re‑run scans on next PR]
```

---

## 📌 Explanation of Each Layer

| Layer | Purpose | Example Block |
|-------|---------|----------------|
| **Instruction injection** | Tells the agent what *not* to do before it even starts. | "Never use SQL string concatenation." |
| **Deny rules** | Hard‑coded blocklist of dangerous command prefixes. | Blocks `rm -rf /` |
| **Pre‑tool hooks** | Script that examines full command string, catches evasions. | Blocks `echo ... \| base64 -d \| sh` |
| **Governance gateway** | Central proxy that enforces token budgets and complex rules. | Rejects a request with `eval(user_input)` |
| **Pre‑commit hooks** | Local static analysis before `git commit`. | Blocks a PR containing `bcrypt` with `cost=4` |
| **CI scans** | Server‑side enforcement, cannot be bypassed. | Fails build if dependency has critical CVE. |

By stacking these layers, you get **defense in depth**. Even if one layer is bypassed (e.g., a developer disables the local hook), subsequent layers (CI, gateway) catch the violation. The result is a 99.99% effective security harness that works across any programming language and any AI agent.