#!/usr/bin/env bash
# Validates Formula/warp-terminal.rb security invariants and, when a git base
# ref is provided, ensures bump diffs only touch allowed pin lines.
set -euo pipefail

FORMULA="${FORMULA_PATH:-Formula/warp-terminal.rb}"
BASE_REF="${1:-}"

if [[ ! -f "$FORMULA" ]]; then
  echo "error: missing $FORMULA" >&2
  exit 1
fi

python3 - "$FORMULA" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text()

version_m = re.search(r'^  version "([^"]+)"', text, re.M)
if not version_m:
    raise SystemExit("missing version line")
version = version_m.group(1)
if not re.fullmatch(r"\d+(?:\.\d+)+\.stable_\d+", version):
    raise SystemExit(f"unexpected version shape: {version!r}")

# Download hosts must stay on Warp's release domain via version interpolation.
for arch, anchor in (("x86_64", "x86_64_url"), ("aarch64", "arm64_url")):
    pat = rf'url "https://releases\.warp\.dev/stable/v#\{{version\}}/Warp-{arch}\.AppImage" # {anchor}'
    if not re.search(pat, text):
        raise SystemExit(f"missing or unsafe url for {arch} (anchor {anchor})")

for anchor in ("x86_64_sha256", "arm64_sha256"):
    m = re.search(rf'sha256 "([0-9a-f]{{64}})" # {anchor}', text)
    if not m:
        raise SystemExit(f"missing pinned sha256 for {anchor}")

if "sha256 :no_check" in text or "no_check" in text:
    raise SystemExit("sha256 :no_check is not allowed")

# Reject unexpected download hosts anywhere in the formula.
for m in re.finditer(r'https?://([^"/]+)', text):
    host = m.group(1)
    if host in {"www.warp.dev", "releases.warp.dev"}:
        continue
    # livecheck/homepage only
    if host.endswith("warp.dev"):
        continue
    raise SystemExit(f"unexpected host in formula: {host}")

print(f"ok: formula security invariants hold (version={version})")
PY

if [[ -n "$BASE_REF" ]]; then
  if ! git rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
    echo "error: base ref not found: $BASE_REF" >&2
    exit 1
  fi

  # Only Formula/warp-terminal.rb may change in automated bump commits/PRs.
  mapfile -t changed < <(git diff --name-only "$BASE_REF"...HEAD)
  if [[ ${#changed[@]} -eq 0 ]]; then
    echo "ok: empty diff vs $BASE_REF"
    exit 0
  fi

  for f in "${changed[@]}"; do
    if [[ "$f" != "Formula/warp-terminal.rb" ]]; then
      echo "error: bump/security gate disallows change to '$f' (only Formula/warp-terminal.rb pin lines permitted)" >&2
      exit 1
    fi
  done

  # Unified diff of formula: only version + sha256 anchor lines may change.
  python3 - "$BASE_REF" "$FORMULA" <<'PY'
import re
import subprocess
import sys

base, formula = sys.argv[1], sys.argv[2]
diff = subprocess.check_output(["git", "diff", f"{base}...HEAD", "--", formula], text=True)

allowed_add_del = re.compile(
    r'^[-+]  version "[^"]+"\s*$'
    r'|^[-+]      sha256 "[0-9a-f]{64}" # (?:x86_64|arm64)_sha256\s*$'
)

for line in diff.splitlines():
    if not line.startswith("+") and not line.startswith("-"):
        continue
    if line.startswith("+++") or line.startswith("---"):
        continue
    if allowed_add_del.match(line):
        continue
    raise SystemExit(
        "error: formula diff contains a disallowed line (only version + sha256 anchor pins may change):\n"
        + line
    )

print(f"ok: bump diff vs {base} only changes version/sha256 pins")
PY
fi
