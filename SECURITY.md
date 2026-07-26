# Security Policy

## Reporting a vulnerability

Please **do not** open a public issue for security problems.

Use GitHub's private reporting: go to the **Security** tab → **Report a
vulnerability** (private vulnerability reporting is enabled on this repo). Only
the maintainer sees the report.

Include: a clear description, steps to reproduce, impact, and a proof of concept
if you have one. We aim to acknowledge within a few days.

דיווח על חולשת אבטחה: אנא **אל** תפתחו issue ציבורי. השתמשו בדיווח הפרטי של
GitHub — לשונית **Security** ← **Report a vulnerability**. רק המתחזק רואה את
הדיווח.

## Scope

This repo ships a **security-review skill** (Markdown guidance + Bash scanner) —
it holds no server, secrets, or user data. Relevant reports: a flaw in
`scripts/scan.sh` (e.g. the scanner executing repo-controlled input), or guidance
in the skill that would lead a reviewer to approve insecure code.

The skill's own review method is documented in
[`skills/ran-bar-zik/SKILL.md`](skills/ran-bar-zik/SKILL.md).
