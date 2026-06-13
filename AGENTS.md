# Security Harness – For All AI Coding Agents

You are required to follow the security rules defined in OWASP ASVS 5.0, NIST SSDF, and NIST CSF 2.0.

## Critical prohibitions (violation will block output)
- Do NOT output hardcoded credentials, API keys, or any secrets.
- Do NOT concatenate user input into SQL, OS commands, or LDAP queries.
- Do NOT use `eval()`, `exec()`, `system()`, `popen()` with untrusted data.
- Do NOT deserialize untrusted data without type allowlist (ASVS V1.5.2).
- Do NOT enable insecure cipher modes (ECB) or broken hash functions (MD5, SHA1 for crypto).

## Mandatory security patterns (must include in generated code)
- Use parameterized queries / ORM.
- Use output encoding libraries (e.g., OWASP Java Encoder, DOMPurify).
- Use cryptographically secure random number generators.
- Implement short inactivity timeouts (≤30 min) and absolute session lifetime (≤8h).
- Log security events with timestamp, user ID, event type, source IP (if available).

## Code review checklist (self‑verify before final output)
- [ ] All external inputs validated (allowlist where possible).
- [ ] SQL/NoSQL queries parameterized.
- [ ] No hardcoded secrets.
- [ ] Cryptographic algorithms from approved list (Appendix C of ASVS).
- [ ] Error messages do not reveal stack traces or internal paths.
- [ ] Dependencies are from trusted sources and have no known critical vulnerabilities.

If any check fails, do not output the code. Respond with the violation and suggest a secure alternative.