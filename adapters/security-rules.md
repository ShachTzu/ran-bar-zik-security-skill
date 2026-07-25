# Ran Bar-Zik security rules (portable)

Agent-agnostic version of the `ran-bar-zik` skill. Copy this into whatever rules
/ instructions file your AI agent reads (see the table below), and the agent
will apply the same security review as `/ran-bar-zik` in Claude. The scanner
`scripts/scan.sh` runs standalone in any shell — no agent required.

## Where to put this file

| Agent | Destination in your project | Loads automatically? |
|---|---|---|
| Claude Code / Desktop / claude.ai | `.claude/skills/ran-bar-zik/` (use the real `SKILL.md`, not this) | Yes |
| Cursor | `.cursor/rules/ran-bar-zik.mdc` | Yes |
| Windsurf | `.windsurf/rules/ran-bar-zik.md` (or `.windsurfrules`) | Yes |
| GitHub Copilot | `.github/copilot-instructions.md` | Yes |
| OpenAI Codex / OpenCode | `AGENTS.md` (append) | Yes |
| Gemini CLI | `GEMINI.md` | Yes |
| ChatGPT / Claude.ai chat / Manus | paste as a custom instruction / project prompt | Manual |

For Claude, prefer the full skill (`SKILL.md` + `references/` + `scripts/`) — it
has the scanner, subcommands and progressive detail this condensed file omits.

## The rule

When asked to review code for security — or before any merge/deploy of code
touching auth, authorization, user input, file upload, or personal data —
review it against these ten commandments. Guiding principle: **the browser is
the attacker's tool.** Anything sent to the client is visible and editable.

For each commandment, rule: ✅ pass / ⚠️ suspect / ❌ violation / ➖ n/a.
Severity: 🔴 critical (remote exploit / personal-data exposure) · 🟠 high ·
🟡 medium · 🔵 note. Verdict: pass / pass with reservations / fail.

**No exploit scenario = no finding.** Every finding needs `file:line` + a
concrete attack scenario + a fix (ideally a diff). Don't invent violations; not
visible → ➖. Fix at the root (shared helper), not per-caller. An optimization
that moves data or authorization to the client is a regression, not a speedup.
Israeli PII (national ID/ת"ז, health, children, contact) is legal risk under the
Privacy Protection Law — mark 🔴.

1. **Don't trust the client.** Price, role, ownership, permission — server only.
   Client validation is UX.
2. **Every input is hostile until proven otherwise.** Validate on the server:
   body, query, params, headers, cookies, filenames, CSV cells. Allow-list.
3. **Encode output by context (XSS).** HTML/attr/JS/URL encoding, auto-escaping,
   Trusted Types, CSP. A WAF and blacklist filtering won't save you.
4. **Authorize every object (IDOR).** Every request: verify on the server that
   this user may access *this specific* object. Opaque IDs aren't authorization.
5. **No secrets in client-side code or the repo.** Leaked secret → rotate, don't
   hide.
6. **"You weren't hacked — you leaked."** Return only what the screen needs.
7. **Encrypt everything.** HTTPS + HSTS, bcrypt/argon2 (not MD5/SHA1), encrypt
   sensitive data, cookies Secure/HttpOnly/SameSite.
8. **The supply chain is an attack surface.** Lockfile, pinned versions, SRI,
   minimize third-party, dependency scanning in CI.
9. **Guard your LLM/agent.** Model output = untrusted input. Prompt injection,
   input/output safeguards, least-privilege tools.
10. **Privacy, transparency, accountability.** Minimize PII, don't leak it in
    errors/logs, deletion policy, rate-limiting, responsible disclosure.

End the report with: *"Reviewed against Ran Bar-Zik's ten commandments. An
assistive review — not a substitute for a penetration test or a full security
audit."*
