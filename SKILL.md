---
name: ran-bar-zik
license: MIT
description: >-
  Security code review against Ran Bar-Zik's ten commandments. סקירת אבטחת-קוד
  לפי "עשרת הדיברות" של רן בר-זיק. Trigger when the user runs /ran-bar-zik (with
  or without arguments), or asks: "security review", "review this for security",
  "check for XSS", "check for IDOR", "is this secure", "audit this endpoint",
  "סקירת אבטחה", "בדוק אבטחה", "האם זה בטוח" - and before any merge/deploy of
  code touching auth, authorization, user input, file upload, or personal data.
  Subcommands: fix, xss, idor, secrets, deps, privacy, llm, harden, explain,
  checklist, community. Do NOT use for CVE/dependency scanning or regulatory
  compliance (use israeli-appsec-scanner), nor for general correctness/bug
  review (use code-review). Hebrew companion: SKILL_HE.md.
metadata:
  display_name:
    he: "סקירת אבטחה - עשרת הדיברות של רן בר-זיק"
    en: "Ran Bar-Zik Security Review"
  display_description:
    he: "סקירת אבטחת-קוד לפי עשרת הדיברות של רן בר-זיק: אל תבטח בצד הלקוח, ולידציה והרשאה בשרת, מניעת XSS ו-IDOR, סודות מחוץ ל-frontend, מזעור חשיפת מידע, הצפנה, אבטחת תלויות והגנה על LLM."
    en: "Security code review against Ran Bar-Zik's ten commandments: never trust the client, server-side validation and authorization, XSS and IDOR prevention, no secrets in the frontend, minimize data exposure, encryption, dependency safety, and LLM guardrails."
  tags:
    he: ["אבטחה", "סקירת-קוד", "אבטחת-אפליקציות", "XSS", "IDOR", "פרטיות", "OWASP", "ישראל", "עברית", "אבטחת-LLM"]
    en: ["security", "code-review", "appsec", "xss", "idor", "privacy", "owasp", "israel", "hebrew", "llm-safety"]
---

# Ran Bar-Zik's Ten Commandments - Security Reviewer

Run a security code review against the ten commandments. Guiding principle:
**"the browser is the attacker's tool"** - anything sent to the client is
visible and editable in F12. (Hebrew version: `SKILL_HE.md`.)

**Language:** write the report in the user's language. If the user writes in
Hebrew, the whole report is in Hebrew, including field names and commandment
names. Don't mix languages.

## Step 1 - pick a target

`/ran-bar-zik` **always reviews something**. Don't ask "what should I review?"
before trying to find it yourself.

Argument given? That's the target: a file/dir path · `pr <n>` (run
`gh pr diff <n>`) · sha/branch (run `git diff <ref>`) · a pasted snippet ·
`all`/`repo` for the whole codebase.

**No argument? Go in this order and stop at the first that returns something:**

1. `git diff` - uncommitted changes.
2. `git diff main...HEAD` (or `master`) - the branch diff.
3. The project's sensitive files: routes/endpoints, auth, models, forms, config.

Only if all three are empty and nothing was pasted - ask the user to point at
something.

## Step 2 - scan for red flags

Locate `scan.sh` and run it against the target. The path isn't known up front -
search for it:

```bash
SCAN=$(ls ~/.claude/skills/ran-bar-zik/scripts/scan.sh \
          .claude/skills/ran-bar-zik/scripts/scan.sh 2>/dev/null | head -1)
[ -n "$SCAN" ] && bash "$SCAN" <path>        # or: bash "$SCAN" --diff [ref]
```

Not found? Run `find ~/.claude ~/.claude/plugins . -name scan.sh -path '*ran-bar-zik*' 2>/dev/null | head -1`.
Still not? Grep manually by the flags in `references/commandments.md` - don't
skip this step.

The output is **leads, not findings**. If the script prints `PATTERN FAILED` or
exits with 2 - the scan is partial; say so in the report.

## Step 3 - read every lead in context

A lead without context is a guess. `innerHTML` on a constant string - not a
finding. `findById(id)` inside a function that already verified ownership - not
a finding. Read the surrounding code, and `references/commandments.md`, before
you score anything.

## Step 4 - rule commandment by commandment

For each of the ten: ✅ pass / ⚠️ suspect / ❌ violation / ➖ not applicable.

Severity: 🔴 critical (remote exploit / personal-data exposure) · 🟠 high ·
🟡 medium · 🔵 note.

Verdict: "pass" / "pass with reservations" / "fail: fix before deploy".

### Iron rules

- **No exploit scenario = no finding.** Every finding needs `file:line` + a
  concrete scenario ("attacker changes `id` in the request and gets another
  user's record") + a fix, ideally as a diff.
- **Don't invent violations.** Not visible in the code → ➖. A short, true report
  beats a long, inflated one.
- **⚠️ means "check this", not "you're breached".** Separate certain from
  suspected.
- **Fix at the root.** Same flaw in 5 places → fix the shared helper. Grep the
  other callers before proposing a point fix.
- **Speed doesn't buy security.** An optimization that moves data or
  authorization decisions to the client is a regression - say so even if the
  user asked to speed things up.
- **Israeli PII** (national ID / ת"ז, health, children, contact details) is
  regulated under the Privacy Protection Law - exposure is legal risk, not just
  a bug. Mark 🔴.

## Subcommands

| Command | What it does |
|---|---|
| *(default)* | Full review, all 10 commandments |
| `fix` | Review, then fix the 🔴/🟠 in code - each fix separate and reviewable |
| `xss` `idor` `secrets` `deps` `privacy` `llm` `<commandment number>` | Focused deep review of one commandment (3/4/5/8/10/9), including code outside the diff |
| `harden` | Not bugs but missing defense layers - per `references/harden.md` |
| `explain <number>` | Learning mode: explain one commandment with bad→good examples. No review |
| `checklist` | Emit a markdown checklist to file in a PR. No analysis |
| `community` | Review with community-app emphases (UGC + CSV import) - `references/community-app.md` |

## Report format

```
# Security review /ran-bar-zik
Verdict: <pass / pass with reservations / fail>
Reviewed: <files / diff / PR>   ·   Findings: 🔴 N · 🟠 N · 🟡 N · 🔵 N

## By the ten commandments
1. Don't trust the client - <✅/⚠️/❌/➖> <one line>
... (up to 10)

## Findings (most to least severe)
### 🔴 [Commandment 4 · IDOR] `api/doc.js:42`
**What:** ... · **Exploit:** ... · **Fix:** <diff>

## What's good (strengths)
## Fix first
```

End with: *"Reviewed against Ran Bar-Zik's ten commandments. An assistive
review - not a substitute for a penetration test or a full security audit."*

## The ten commandments (summary)

1. **Don't trust the client.** Client-side validation is UX; the truth is on the
   server. Price, role, ownership and permission are decided on the server only.
2. **Every input is hostile until proven otherwise.** Validate on the server:
   body, query, params, headers, cookies, filenames, CSV cells. Allow-list, not
   deny-list.
3. **Encode output by context (XSS).** Encode per context (HTML/attr/JS/URL),
   auto-escaping, Trusted Types, CSP. **A WAF and blacklist filtering won't save
   you.**
4. **Authorize every object (IDOR).** On every request verify on the server that
   the user may access *this specific* object. An "opaque" identifier is not
   authorization.
5. **No secrets in client-side code.** No keys/tokens in the frontend or the
   repo. A leaked secret is rotated, not hidden.
6. **"You weren't hacked - you leaked."** Don't return more from the API than the
   screen needs.
7. **Encrypt everything.** HTTPS + HSTS, bcrypt/argon2 (not MD5/SHA1), encrypt
   sensitive data, cookies with Secure/HttpOnly/SameSite.
8. **The supply chain is an attack surface.** Lockfile, pinned versions, SRI,
   minimize third-party, dependency scanning in CI.
9. **Guard your LLM/agent.** Model output = untrusted input. Prompt injection,
   safeguards on input and output, least-privilege tool permissions.
10. **Privacy, transparency and accountability.** Minimize PII, don't leak it in
    errors/logs, deletion policy, rate-limiting, and plan for responsible
    disclosure.

Files: `SKILL_HE.md` (Hebrew version) · `references/commandments.md` (detail +
examples) · `references/harden.md` (defense layers) · `references/community-app.md`
(UGC + CSV) · `scripts/scan.sh` (scanner; self-check: `scripts/test_scan.sh`).
Use in non-Claude agents: see `adapters/` and the README.
