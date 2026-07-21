#!/usr/bin/env bash
# scan.sh — red-flag pre-scan for the /ran-bar-zik security review.
#
# Output is LEADS, not findings. Every hit must be read in context before it
# becomes a finding. Exit code is 0 for "scan ran", 2 for "scan is broken" —
# a lead is not a failure, but a silently-broken pattern is.
#
#   ./scan.sh [path]          scan a path (default: .)
#   ./scan.sh --diff [ref]    scan only files changed vs ref (default: HEAD)
#
# ponytail: grep, not an AST. Misses obfuscated code and cross-file flows;
# that is what the agent's read-in-context step is for. Upgrade to semgrep if
# the false-positive rate ever becomes the bottleneck.
#
# SECURITY: this tool is pointed at untrusted code by design. Filenames from
# `git diff` are attacker-controlled, so they are passed NUL-delimited and
# after a `--` terminator. Never interpolate them into a command line.

set -uo pipefail

MAXCOL=200           # truncate long lines; bundled assets have 90k-char lines
MAXHITS=25           # per-section cap, reported when it bites
LIST=""

cleanup() { [ -n "$LIST" ] && rm -f "$LIST"; }
trap cleanup EXIT

TARGET="${1:-.}"

if [ "$TARGET" = "--diff" ]; then
  REF="${2:-HEAD}"
  ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "not a git repository — use: scan.sh <path>" >&2; exit 2; }
  # git prints repo-root-relative paths, so scan from the root
  cd "$ROOT" || exit 2
  git rev-parse --verify --quiet "$REF^{commit}" >/dev/null || {
    echo "unknown ref: $REF" >&2; exit 2; }

  LIST=$(mktemp) || exit 2
  git diff -z --name-only --diff-filter=d "$REF" > "$LIST"
  [ ! -s "$LIST" ] && git diff -z --name-only --diff-filter=d > "$LIST"
  if [ ! -s "$LIST" ]; then
    echo "no changed files vs $REF — nothing to scan"; exit 0
  fi
  TARGET=""
fi

# xargs exits 123 when a child exits 1-125, so "grep found nothing" surfaces as
# 123. Normalize it to 1, or every clean category would look like a broken regex.
SEARCH() { # $1 = pattern; rc: 0 = hits, 1 = none, >1 = pattern rejected
  local rc
  _search "$1"; rc=$?
  [ "$rc" -eq 123 ] && rc=1
  return $rc
}

if command -v rg >/dev/null 2>&1; then
  _search() { # $1 = pattern
    if [ -n "$LIST" ]; then
      # -uu: do not skip gitignored/hidden files — .env is exactly what we want
      xargs -0 -r rg -H -n --no-heading --color=never -uu -e "$1" -- < "$LIST"
    else
      rg -H -n --no-heading --color=never -uu \
         -g '!.git/' -g '!node_modules/' -g '!vendor/' \
         -g '!dist/' -g '!build/' -g '!out/' -g '!.next/' -g '!coverage/' \
         -g '!*.min.js' -g '!*.map' -g '!*.lock' -g '!*-lock.json' \
         -e "$1" -- "$TARGET"
    fi
  }
  ENGINE="rg"
else
  _search() {
    if [ -n "$LIST" ]; then
      xargs -0 -r grep -H -nEI -e "$1" -- < "$LIST"
    else
      grep -rnEIH \
        --exclude-dir={.git,node_modules,vendor,dist,build,out,.next,coverage} \
        --exclude={'*.min.js','*.map','*.lock','*-lock.json'} \
        -e "$1" -- "$TARGET"
    fi
  }
  ENGINE="grep"
fi

BROKEN=0

section() { # $1 = label, $2 = pattern, $3 = optional exclude pattern
  local raw err rc out shown total
  err=$(mktemp)
  raw=$(SEARCH "$2" 2>"$err"); rc=$?
  # rc 0 = hits, 1 = no hits, >1 = the pattern itself is bad. Never swallow >1:
  # a regex the engine rejects looks exactly like "this category is clean".
  if [ "$rc" -gt 1 ]; then
    printf '\n!!! %s — PATTERN FAILED under %s (this category was NOT scanned)\n%s\n' \
      "$1" "$ENGINE" "$(head -3 "$err")" >&2
    BROKEN=$((BROKEN + 1)); rm -f "$err"; return
  fi
  rm -f "$err"

  [ -n "${3:-}" ] && raw=$(printf '%s' "$raw" | grep -Ev "$3")
  [ -z "$raw" ] && return

  total=$(printf '%s\n' "$raw" | grep -c .)
  out=$(printf '%s\n' "$raw" | head -"$MAXHITS" | cut -c1-"$MAXCOL")
  shown=$(printf '%s\n' "$out" | grep -c .)

  printf '\n=== %s ===\n%s\n' "$1" "$out"
  [ "$total" -gt "$shown" ] && printf '... %d more hits not shown (cap %d)\n' \
    "$((total - shown))" "$MAXHITS"
  HITS=$((HITS + 1))
}

HITS=0
echo "ran-bar-zik pre-scan ($ENGINE) — leads only, verify each in context"

section "1 · client-side trust" \
  '(type=.hidden.|localStorage\.(getItem|setItem)\([^)]*(role|admin|price|token)|(if|&&|\|\|)[^\n]{0,20}\b(isAdmin|is_admin)\b|role\s*[:=]\s*["'"'"'](admin|owner))'

# No quote chars in this pattern on purpose — a quote class here has to survive
# three levels of shell quoting, and getting it wrong silently kills the whole
# category (it did: the class excluded the ' inside the very SQL it was hunting).
section "2 · unvalidated input / injection" \
  '((query|execute|exec|raw)\s*\([^;]*\$\{|SELECT [^;]*\+ *req\.|res\.redirect\(\s*req\.|child_process|eval\(|new Function\(|fs\.(read|write)File\w*\(\s*req)'

section "3 · XSS sinks" \
  '(innerHTML|outerHTML|dangerouslySetInnerHTML|v-html|insertAdjacentHTML|document\.write|javascript:|\$\([^)]*\)\.html\()'

section "4 · IDOR — object id used directly in a query/response" \
  '((findByPk|findById|findOne|findUnique|getDoc|get|delete|update|remove)\([^)]*(params|query|body)\.(id|userId|user_id|ownerId)|res\.(json|send)\([^)]*(params|query)\.id)'

section "5 · hardcoded secrets" \
  '(sk_live_|sk_test_|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{20,}|xox[baprs]-|-----BEGIN [A-Z ]*PRIVATE KEY|(api[_-]?key|secret|password|token)\s*[:=]\s*["'"'"'][A-Za-z0-9_\-]{16,})'

section "5b · public env vars that smell secret" \
  '(NEXT_PUBLIC_|VITE_|REACT_APP_)[A-Z_]*(SECRET|KEY|TOKEN|PASSWORD)'

section "6 · over-fetching / whole-record responses" \
  '(res\.(json|send)\(\s*(user|users|rows|result|doc|record|data)\s*\)|SELECT \*|findMany\(\s*\)|\.find\(\s*\)\s*[,)])'

section "7 · weak crypto & cookie flags" \
  '(createHash\(\s*["'"'"'](md5|sha1)|\bmd5\(|\bsha1\(|alg["'"'"']?\s*[:=]\s*["'"'"']none|httpOnly\s*:\s*false|secure\s*:\s*false|sameSite\s*:\s*["'"'"']?none)'

# grep -E has no lookahead, so local hosts are excluded after the fact.
section "7b · plaintext http" \
  'http://[a-zA-Z0-9.-]+' \
  'http://(localhost|127\.0\.0\.1|0\.0\.0\.0|\[::1\])|www\.w3\.org|schemas?\.|xmlns|//[a-z.]*example\.'

section "8 · supply chain" \
  '(<script[^>]+src=["'"'"']https?://|"[a-z0-9@/._-]+"[[:space:]]*:[[:space:]]*"(\*|latest)")' \
  'integrity='

section "9 · LLM output used as trusted" \
  '((completion|llmOutput|llmAnswer|aiResponse|answer|message)\.(content|text)[^=]{0,60}(innerHTML|exec|eval|query|JSON\.parse)|(innerHTML|\.exec|\beval|\.query)[^=]{0,10}=[^=]{0,40}(completion|llmOutput|llmAnswer|aiResponse)\b)'

section "10 · leaky errors & logs" \
  '(\.send\(\s*(e|err|error)(\.stack|\.message)?\s*\)|console\.(log|error)\(\s*(req\.body|req\.headers|password|token)|res\.status\(5[0-9][0-9]\)\.\w+\(\s*(e|err))'

echo
if [ "$BROKEN" -gt 0 ]; then
  echo "$BROKEN pattern(s) FAILED to run — the scan is incomplete. Fix before trusting it." >&2
  exit 2
fi
if [ "$HITS" -eq 0 ]; then
  echo "no red-flag patterns matched. Still read the code — grep sees text, not logic."
else
  echo "$HITS categories with leads. Read each in context before calling it a finding."
fi
exit 0
