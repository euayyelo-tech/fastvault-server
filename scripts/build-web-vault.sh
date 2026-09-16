#!/usr/bin/env bash
# Downloads the pinned prebuilt web vault and applies FastVault branding.
# Output: ./web-vault (git-ignored), copied into the image by the Dockerfile.
set -euo pipefail
VER="${WEB_VAULT_VERSION:-v2026.7.0}"
TAG="${IMAGE_TAG:-dev}"
PY="$(command -v python3 || command -v python)"
cd "$(dirname "$0")/.."
rm -rf web-vault && mkdir -p .cache
[ -f ".cache/bw_web_$VER.tar.gz" ] || curl -sSL -o ".cache/bw_web_$VER.tar.gz" \
  "https://github.com/dani-garcia/bw_web_builds/releases/download/$VER/bw_web_$VER.tar.gz"
tar -xzf ".cache/bw_web_$VER.tar.gz"           # creates ./web-vault
[ -d web-vault ] || { echo "tarball did not contain web-vault/"; exit 1; }

# 1. Logos/icons: overwrite every raster/vector the UI uses with ours.
for f in web-vault/images/logo.svg web-vault/images/logo-dark.svg web-vault/images/logo-white.svg; do
  [ -f "$f" ] && cp branding/logo.svg "$f"
done
for f in web-vault/images/icon-white.png web-vault/images/icon-dark.png web-vault/images/icon-white.svg web-vault/images/icon-dark.svg web-vault/favicon.ico web-vault/images/icons/favicon-32x32.png web-vault/images/icons/favicon-16x16.png web-vault/images/icons/android-chrome-192x192.png web-vault/images/icons/apple-touch-icon.png; do
  [ -f "$f" ] || continue
  case "$f" in *.svg) cp branding/icon.svg "$f";; *) "$PY" - "$f" <<'EOF'
import sys, cairosvg
out=sys.argv[1]; size=192 if "192" in out else (180 if "apple" in out else (32 if "32x32" in out else (16 if "16x16" in out else 64)))
cairosvg.svg2png(url="branding/icon.svg", write_to=out, output_width=size, output_height=size)
EOF
  ;; esac
done

# 2. Display strings: only the capitalised brand name and the marketing links.
#    Lowercase 'bitwarden'/'vaultwarden' is left alone — it is used in package
#    names, storage keys, API paths and the upstream GitHub link that the apps
#    and this AGPL notice depend on. This pinned build brands itself
#    "Vaultwarden" (not "Bitwarden") throughout its own UI strings, so both
#    capitalised forms are rewritten to FastVault.
find web-vault -type f \( -name '*.js' -o -name '*.html' -o -name '*.json' -o -name '*.webmanifest' -o -name '*.map' -o -name '*.css' \) -print0 \
 | xargs -0 sed -i \
   -e 's/Bitwarden Web Vault/FastVault/g' \
   -e 's/Vaultwarden Web/FastVault/g' \
   -e 's/Bitwarden/FastVault/g' \
   -e 's/Vaultwarden/FastVault/g' \
   -e 's#https://bitwarden\.com/help[^"'"'"' ]*#https://fastvault.app/support#g' \
   -e 's#https://bitwarden\.com#https://fastvault.app#g' \
   -e 's#https://github\.com/dani-garcia/vaultwarden/wiki/[^"'"'"' ]*#https://fastvault.app/support#g' \
   -e 's#https://github\.com/dani-garcia/vaultwarden#https://github.com/euayyelo-tech/fastvault-server#g'

# 2b. Restore the two things step 2's blanket replace incorrectly renamed:
#     - the real Bitwarden trademark in the upstream "about" screen's honest
#       attribution (same spirit as our own source.html)
#     - the HTTP client identification header NAMES (Bitwarden-Client-Name /
#       Bitwarden-Client-Version) that the server matches on to recognise the
#       client during sync; renaming these breaks SSH-key item sync and can
#       cause duplicate email-2FA codes.
find web-vault -type f -name '*.js' -print0 \
 | xargs -0 sed -i \
   -e 's/A modified version of the FastVault® Web Vault for FastVault (an unofficial rewrite of the FastVault® server)\./A modified version of the Bitwarden® Web Vault for FastVault (an unofficial rewrite of the Bitwarden® server)./g' \
   -e 's/FastVault is not associated with the FastVault® project nor FastVault Inc\./FastVault is not associated with the Bitwarden® project nor Bitwarden Inc./g' \
   -e 's/FastVault-Client-Name/Bitwarden-Client-Name/g' \
   -e 's/FastVault-Client-Version/Bitwarden-Client-Version/g'

# 2c. Inline wordmark: the anon (login) layout renders the Vaultwarden
#     wordmark as an inline <svg viewBox="0 0 290 60"> baked into the JS
#     bundle, not from web-vault/images/*, so the logo copy in step 1 never
#     touches it. Its <title> already got renamed by step 2's blanket
#     replace, but the <path> data still draws the word "vaultwarden".
#     Rewrite the whole element's inner content (title + mark + wordmark
#     text) in every JS file that contains it, preserving whichever quote
#     style (") or (\") the minifier used around the attribute values.
"$PY" - <<'PYEOF'
import glob, os, re, sys

INNER = ('<title>FastVault</title>'
         '<rect x="4" y="8" width="44" height="44" rx="10" class="tw-fill-marketing-logo"/>'
         '<rect x="16" y="24" width="20" height="14" rx="2" fill="#0b1220"/>'
         '<circle cx="26" cy="31" r="2.6" class="tw-fill-marketing-logo"/>'
         '<text x="60" y="41" font-family="Inter,Segoe UI,Arial,sans-serif" '
         'font-size="30" font-weight="700" class="tw-fill-marketing-logo">FastVault</text>')

PATTERN = re.compile(r'(<svg[^>]*viewBox=\\?"0 0 290 60\\?"[^>]*>).*?(</svg>)', re.DOTALL)

files = sorted(set(glob.glob('web-vault/**/*.js', recursive=True)))
total = 0
for path in files:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    if 'viewBox=\\"0 0 290 60\\"' not in content and 'viewBox="0 0 290 60"' not in content:
        continue
    count = 0
    def repl(m):
        global count
        count += 1
        opening, closing = m.group(1), m.group(2)
        inner = INNER.replace('"', '\\"') if '\\"' in opening else INNER
        return opening + inner + closing
    new_content = PATTERN.sub(repl, content)
    if count:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        total += count
        print(f"  {path}: {count} inline wordmark replacement(s)")

print(f"inline wordmark SVG: {total} total replacement(s)")
if total == 0:
    print("ERROR: expected at least one Vaultwarden wordmark <svg viewBox=\"0 0 290 60\"> to replace", file=sys.stderr)
    sys.exit(1)
PYEOF

# 3. Colours: append our stylesheet to every CSS bundle so it loads last.
for css in web-vault/*.css web-vault/styles*.css; do
  [ -f "$css" ] && cat branding/fastvault.css >> "$css"
done

# 4. AGPL offer page, with the tag baked in.
sed "s/__TAG__/$TAG/" branding/source.html > web-vault/source.html

echo "web-vault branded ($VER, tag $TAG): $(grep -rl 'FastVault' web-vault | wc -l) files mention FastVault"
# Remaining Bitwarden/Vaultwarden mentions are OK only when they are:
#  - source.html / *.wasm / *.map (trademark notice, compiled API header strings, debug maps)
#  - the upstream "about" screen's honest trademark attribution (step 2b), which
#    intentionally still names the real Bitwarden project/company
#  - the restored Bitwarden-Client-Name / Bitwarden-Client-Version HTTP header
#    names (step 2b), which the server matches on and must not be renamed
#
# Bundles are minified to a single line, so a whole-LINE exclude (grep -v) would
# silently swallow any *other* stray Bitwarden/Vaultwarden occurrence that happens to
# share a line with the allowed disclaimer text. Instead: strip the exact allowed
# sentences out of each candidate file's content first, then count remaining
# occurrences (not lines) in what's left.
CANDIDATES=$(grep -rlE 'Bitwarden|Vaultwarden' web-vault \
  --exclude='source.html' --exclude='*.wasm' --exclude='*.map' || true)
FAIL=0
if [ -n "$CANDIDATES" ]; then
  while IFS= read -r f; do
    STRIPPED=$(sed -E \
      -e 's/A modified version of the Bitwarden. Web Vault for FastVault \(an unofficial rewrite of the Bitwarden. server\)\.//g' \
      -e 's/FastVault is not associated with the Bitwarden. project nor Bitwarden Inc\.//g' \
      -e 's/Bitwarden-Client-Name//g' \
      -e 's/Bitwarden-Client-Version//g' \
      "$f")
    N=$(printf '%s' "$STRIPPED" | grep -oE 'Bitwarden|Vaultwarden' | wc -l || true)
    if [ "$N" -gt 0 ]; then
      CTX=$(printf '%s' "$STRIPPED" | grep -oE ".{0,30}(Bitwarden|Vaultwarden).{0,30}" | head -1 || true)
      echo "ERROR: $f has $N stray Bitwarden/Vaultwarden occurrence(s) outside the known disclaimer text"
      echo "  context: $CTX"
      FAIL=1
    fi
  done <<< "$CANDIDATES"
fi
[ "$FAIL" -eq 0 ] && echo "no stray capitalised Bitwarden/Vaultwarden left" || { echo 'ERROR: "Bitwarden"/"Vaultwarden" still present above'; exit 1; }
