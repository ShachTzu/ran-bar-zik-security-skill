# ran-bar-zik - security review by the ten commandments

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

[עברית / Hebrew README](README_HE.md)

A skill that reviews code against **Ran Bar-Zik's ten commandments** of secure
web development. Bar-Zik is a veteran developer and security journalist whose
recurring message is that most "hacks" are not magic:

> **"The browser is the attacker's tool."**

Anything sent to the client is visible and editable in F12. The skill catches
the failures before someone with dev tools catches them first. Reports are
written in the user's language (Hebrew or English).

📄 The skill: [`skills/ran-bar-zik/SKILL.md`](skills/ran-bar-zik/SKILL.md)
(English) · [`SKILL_HE.md`](skills/ran-bar-zik/SKILL_HE.md) (Hebrew) ·
[`adapters/`](adapters/security-rules.md) (other agents).

---

## Install

```bash
git clone https://github.com/ShachTzu/ran-bar-zik-security-skill.git
cp -r ran-bar-zik-security-skill/skills/ran-bar-zik ~/.claude/skills/
```

Single project: `cp -r skills/ran-bar-zik .claude/skills/`

## Usage

```
/ran-bar-zik                  # review the current changes (default)
/ran-bar-zik src/api          # review a path
/ran-bar-zik pr 42            # review a PR
/ran-bar-zik fix              # review, then fix the critical findings
/ran-bar-zik xss              # focused review of one commandment (xss/idor/secrets/deps/privacy/llm)
/ran-bar-zik harden           # what's missing: CSP, HSTS, cookie flags, rate-limit, CI scans
/ran-bar-zik explain 4        # learning mode, explain a single commandment
/ran-bar-zik checklist        # markdown checklist for a PR
/ran-bar-zik community        # community-app emphases (UGC + CSV)
```

With no argument the skill picks a target itself: uncommitted changes, then the
branch diff against `main`, then the project's sensitive files. It will not ask
"what should I review?" before trying to find it on its own.

The report is written in the user's language, Hebrew or English. `SKILL.md` is
English; `SKILL_HE.md` is the full Hebrew version.

## Use in other AI agents (Cursor / Codex / Gemini / Copilot ...)

The `SKILL.md` format loads automatically only in the Claude family, but **the
content and the scanner are agent-agnostic**. `adapters/security-rules.md` is a
condensed version of the rules that you copy into any agent's instructions file:

| Agent | Where to copy | Auto-loads |
|---|---|---|
| Claude Code / Desktop / claude.ai | `.claude/skills/ran-bar-zik/` (the full skill) | Yes |
| Cursor | `.cursor/rules/ran-bar-zik.mdc` | Yes |
| Windsurf | `.windsurf/rules/ran-bar-zik.md` | Yes |
| GitHub Copilot | `.github/copilot-instructions.md` | Yes |
| OpenAI Codex / OpenCode | `AGENTS.md` (append) | Yes |
| Gemini CLI | `GEMINI.md` | Yes |
| ChatGPT / Manus | paste as a custom instruction / project prompt | Manual |

The scanner `scripts/scan.sh` runs standalone in any shell, no agent at all:
`bash scripts/scan.sh <path>`.

## The ten commandments

| # | Commandment | Catches |
|---|---|---|
| 1 | Don't trust the client | security decisions in JS, hidden fields, `if (isAdmin)` on the client |
| 2 | Every input is hostile | SQL/NoSQL injection, path traversal, open redirect, CSV |
| 3 | Encode output by context | XSS: `innerHTML`, `dangerouslySetInnerHTML`, `javascript:` |
| 4 | Authorize every object | IDOR: `GET /doc/:id` with no ownership check |
| 5 | No secrets client-side | keys in the bundle, `.env` in git, `NEXT_PUBLIC_*_SECRET` |
| 6 | "You weren't hacked, you leaked" | `res.json(user)`, `SELECT *`, unbounded exports |
| 7 | Encrypt everything | md5/sha1 for passwords, cookies without flags, `alg:none` |
| 8 | The supply chain | no lockfile, CDN without SRI, vulnerable dependencies |
| 9 | Guard your LLM | prompt injection, model output into `innerHTML`/`exec` |
| 10 | Privacy and accountability | stack traces to the client, PII in logs, no rate-limit |

## How it works

1. `scripts/scan.sh` scans for red flags (10 categories, ripgrep with a grep
   fallback). The output is **leads, not findings**.
2. The agent reads every lead in context: `innerHTML` on a constant is not a
   finding.
3. Every finding gets `file:line`, a **concrete exploit scenario**, and a fix as
   a diff. No exploit scenario means no finding.
4. Verdict: pass / pass with reservations / fail.

```bash
skills/ran-bar-zik/scripts/test_scan.sh
# PASS [grep]: 12/12 sections detected, clean file silent
# PASS [rg]:   12/12 sections detected, clean file silent
```

The self-check runs **under both engines**. This is not needless rigor: `rg`
(Rust regex) and `grep -E` (POSIX ERE) accept different dialects, and in an
early version one expression was rejected by `rg` only, while `2>/dev/null`
swallowed the error and the whole category looked "clean". Today a rejected
expression is printed loudly (`PATTERN FAILED`) and the script exits with 2.

## Layout

```
skills/ran-bar-zik/
├── SKILL.md                      # main action (English), subcommands, report format
├── SKILL_HE.md                   # the full Hebrew version
├── metadata.json                 # Skills IL metadata (name, tags, supported agents)
├── evidence.json                 # verifying sources per claim (Elector, OWASP, Privacy Law)
├── optimization-log.json         # the skill's improvement log
├── references/
│   ├── commandments.md           # full detail + bad->good examples per commandment
│   ├── harden.md                 # CSP, headers, cookies, rate-limit, CI
│   └── community-app.md          # emphases for a community app with UGC and CSV
└── scripts/
    ├── scan.sh                   # red-flag scanner
    └── test_scan.sh              # self-check

adapters/
└── security-rules.md             # portable version for non-Claude agents
```

## Limits

`scan.sh` is grep, not an AST: it misses obfuscated code and cross-file flows.
That is why the read-in-context step is mandatory, not decoration. The review is
**not a substitute for a penetration test** or a full security audit.

## What this is based on

### Who is Ran Bar-Zik

Ran Bar-Zik is a veteran web developer, a senior software architect at CyberArk,
a technology journalist at TheMarker (Haaretz Group), and a lecturer at Ono
Academic College.[^about][^wiki] Since 2008 he has run the blog "Internet
Israel", a Hebrew programming blog updated weekly,[^about] and he wrote a series
of Hebrew programming textbooks.[^books] He is known mainly as a white-hat who
exposes security holes and data leaks in Israeli organizations.[^wiki]

### Disclaimer: this is not an official list

**Bar-Zik did not publish a document called "the ten commandments".** A search
of his sources found no such list. The number ten and the wording here are **our
synthesis** of the recurring messages in his writing and disclosures, packaged
as a checklist an agent can review against. This project is not affiliated with
him, was not reviewed by him, and does not represent him. Any error in wording
is ours, not his.

### Derived directly from his work

| Source | Commandment derived |
|---|---|
| The **Elector** app disclosure (2020): the Likud voter database with details of **6,453,254** Israelis, reachable through the browser alone[^wiki][^elector] | **Commandment 1**, "the browser is the attacker's tool" |
| **"We were not hacked, it just leaked, technical lessons from the Elector affair"**[^elector] | **Commandment 6**, the slogan, and the insight that the absence of attacker traces is not proof that data did not leak |
| The "Captain Internet" series at TheMarker: a **Beit Shemesh municipality** system that exposed residents' disability percentages and mental-health information (2025)[^bs]; **400,000+ documents** with medical information from a cannabis-sales site (2024)[^cannabis] | **Commandments 6 and 10**, minimizing exposure and Israeli PII. The same pattern repeats: sensitive data reachable by anyone with a browser, with nobody "hacking" |

Hence also the skill's rule **"speed doesn't buy security"**: an optimization
that moves data or authorization decisions to the client is a regression, not an
improvement.

### Derived from external standards

So the checklist is not opinion alone, the remaining commandments map to accepted
standards:

| Commandment | Standard |
|---|---|
| 4 | OWASP A01:2021, Broken Access Control[^owasp-a01] |
| 2, 3 | OWASP A03:2021, Injection (including XSS)[^owasp] |
| 7 | OWASP A02:2021, Cryptographic Failures · A05, Security Misconfiguration[^owasp] |
| 8 | OWASP A06:2021, Vulnerable and Outdated Components[^owasp] |
| 10 | OWASP A09:2021, Security Logging and Monitoring Failures[^owasp] |
| 9 | OWASP Top 10 for LLM Applications, LLM01 Prompt Injection · LLM05 Improper Output Handling[^owasp-llm] |
| 10 | Protection of Privacy (Data Security) Regulations, 5777-2017[^privacy], access-control, authorization, documentation and breach-reporting duties |

## Sources

[^about]: [About Ran Bar-Zik and Internet Israel](https://internet-israel.com/about/), internet-israel.com.
[^wiki]: [Ran Bar-Zik](https://he.wikipedia.org/wiki/%D7%A8%D7%9F_%D7%91%D7%A8-%D7%96%D7%99%D7%A7), Hebrew Wikipedia.
[^books]: [Hebrew development books](https://hebdevbook.com/), hebdevbook.com.
[^elector]: Ran Bar-Zik, [We were not hacked, it just leaked, technical lessons from the Elector affair](https://internet-israel.com/פיתוח-אינטרנט/בניית-אתרי-אינטרנט-למפתחים/לא-פרצו-לנו-רק-דלף-לנו-לקחים-טכניים-מפר/), Internet Israel (Hebrew).
[^bs]: Ran Bar-Zik, [Disability percentages and mental illness: a Beit Shemesh municipality system exposed sensitive resident data](https://www.themarker.com/captain-internet/2025-08-25/ty-article/.premium/00000198-e064-d9a7-add9-e2e51a110000), Captain Internet, TheMarker, 25 Aug 2025 (paywalled, Hebrew).
[^cannabis]: Ran Bar-Zik, [More than 400,000 documents: personal and sensitive medical data leaked from a cannabis-sales site](https://www.themarker.com/captain-internet/2024-09-15/ty-article/.premium/00000191-e15d-d084-a5db-eb5f16230000), Captain Internet, TheMarker, 15 Sep 2024 (paywalled, Hebrew).
[^owasp]: [OWASP Top 10:2021](https://owasp.org/Top10/2021/), OWASP Foundation.
[^owasp-a01]: [A01:2021, Broken Access Control](https://owasp.org/Top10/2021/A01_2021-Broken_Access_Control/), OWASP Top 10:2021.
[^owasp-llm]: [OWASP Top 10 for LLM Applications](https://genai.owasp.org/llm-top-10/), OWASP Gen AI Security Project.
[^privacy]: [Protection of Privacy (Data Security) Regulations, 5777-2017](https://www.nevo.co.il/law_html/law00/144811.htm), Nevo. See also the [regulations page](https://www.gov.il/he/pages/data_security_regulation) on the Privacy Protection Authority site.

All links checked on 21 Jul 2026.

## License

MIT, see [LICENSE](LICENSE). The skill is an independent implementation and is
not affiliated with Ran Bar-Zik.
