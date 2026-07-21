#!/usr/bin/env bash
# Self-check for scan.sh.
#
# Each commandment is asserted on its OWN full section label, not a "N ·"
# prefix — two sections sharing a number (5/5b, 7/7b) would otherwise let a
# dead pattern pass on its sibling's hits. Runs under both engines: the rg
# path and the grep path accept different regex dialects, and a pattern that
# only one of them rejects is exactly the bug this file exists to catch.
set -uo pipefail
cd "$(dirname "$0")"

FIX=$(mktemp -d)
trap 'rm -rf "$FIX"' EXIT
FAILED=0

# Split so this file does not itself look like a leaked key to secret scanners.
FAKE_STRIPE="sk_live_""EXAMPLE_NOT_A_REAL_KEY"

cat > "$FIX/vuln.js" <<EOF
if (user.isAdmin) { showDeleteButton(); }
db.query(\`SELECT * FROM users WHERE email='\${req.body.email}'\`);
el.innerHTML = "שלום " + userName;
app.get('/api/doc/:id', (req, res) => res.json(db.findById(req.params.id)));
const stripeSecret = "$FAKE_STRIPE";
const map = process.env.NEXT_PUBLIC_MAPS_SECRET;
res.json(user);
user.password = md5(pw);
res.cookie('sid', s, { httpOnly: false, secure: false });
fetch('http://api.evil-corp.net/pay');
el.innerHTML = completion.content;
catchAll((e) => res.status(500).send(e.stack));
EOF

cat > "$FIX/index.html" <<'EOF'
<script src="https://cdn.untrusted.net/lib.js"></script>
EOF

cat > "$FIX/clean.js" <<'EOF'
const el = document.createElement('div');
el.textContent = greet(userName);
const doc = await db.getDoc({ id, ownerId: req.user.id });
if (!doc) return res.status(404).end();
res.json({ title: doc.title });
user.passwordHash = await bcrypt.hash(pw, 12);
fetch('http://localhost:3000/dev');
EOF

# One assertion per section label — a section that stops matching cannot be
# covered by another section that happens to share its commandment number.
SECTIONS=(
  "1 · client-side trust"
  "2 · unvalidated input / injection"
  "3 · XSS sinks"
  "4 · IDOR"
  "5 · hardcoded secrets"
  "5b · public env vars that smell secret"
  "6 · over-fetching"
  "7 · weak crypto & cookie flags"
  "7b · plaintext http"
  "8 · supply chain"
  "9 · LLM output used as trusted"
  "10 · leaky errors & logs"
)

run_engine() { # $1 = label, $2 = PATH to run under
  local out clean
  out=$(PATH="$2" ./scan.sh "$FIX" 2>&1)

  # A rejected regex must be loud, never silently "clean".
  case "$out" in
    *"PATTERN FAILED"*)
      echo "FAIL [$1]: a pattern was rejected by the engine"
      printf '%s\n' "$out" | grep -A2 'PATTERN FAILED'
      FAILED=1; return ;;
  esac

  local s
  for s in "${SECTIONS[@]}"; do
    case "$out" in
      *"$s"*) ;;
      *) echo "FAIL [$1]: no lead for section '$s' on the vulnerable fixture"; FAILED=1 ;;
    esac
  done

  clean=$(PATH="$2" ./scan.sh "$FIX/clean.js" 2>&1)
  case "$clean" in
    *"no red-flag patterns matched"*) ;;
    *) echo "FAIL [$1]: clean file produced leads:"; printf '%s\n' "$clean"; FAILED=1 ;;
  esac

  [ "$FAILED" -eq 0 ] && echo "PASS [$1]: ${#SECTIONS[@]}/${#SECTIONS[@]} sections detected, clean file silent"
}

# grep path: a PATH with no rg on it.
run_engine grep "/usr/bin:/bin:/usr/sbin:/sbin"

# rg path: only if a real rg binary exists (a shell alias is not enough).
RG=$(PATH="$PATH" command -v rg 2>/dev/null)
if [ -n "$RG" ] && [ -x "$RG" ]; then
  run_engine rg "$(dirname "$RG"):/usr/bin:/bin"
else
  echo "SKIP [rg]: no ripgrep binary on PATH — grep path only"
fi

exit "$FAILED"
