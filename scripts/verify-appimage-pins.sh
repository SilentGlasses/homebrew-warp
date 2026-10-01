#!/usr/bin/env bash
# Download stable AppImages from releases.warp.dev and verify formula sha256 pins.
set -euo pipefail

FORMULA="${FORMULA_PATH:-Formula/warp-terminal.rb}"
UA="${WARP_USER_AGENT:-Homebrew-silentglasses-warp}"

if [[ ! -f "$FORMULA" ]]; then
  echo "error: missing $FORMULA" >&2
  exit 1
fi

python3 - "$FORMULA" "$UA" <<'PY'
import hashlib
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

formula_path = Path(sys.argv[1])
user_agent = sys.argv[2]
text = formula_path.read_text()

version_m = re.search(r'^  version "([^"]+)"', text, re.M)
if not version_m:
    raise SystemExit("missing version line")
version = version_m.group(1)
if not re.fullmatch(r"\d+(?:\.\d+)+\.stable_\d+", version):
    raise SystemExit(f"unexpected version shape: {version!r}")

pins = {}
for arch, anchor in (("x86_64", "x86_64_sha256"), ("aarch64", "arm64_sha256")):
    m = re.search(rf'sha256 "([0-9a-f]{{64}})" # {anchor}', text)
    if not m:
        raise SystemExit(f"missing pinned sha256 for {anchor}")
    pins[arch] = m.group(1)

# Download URLs must be the releases endpoint only.
base = f"https://releases.warp.dev/stable/v{version}"


def sha256_url(url: str) -> str:
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": user_agent,
            "Accept": "*/*",
        },
        method="GET",
    )
    digest = hashlib.sha256()
    try:
        with urllib.request.urlopen(req, timeout=180) as resp:
            final = resp.geturl()
            if not final.startswith("https://releases.warp.dev/"):
                raise SystemExit(f"refusing redirect off releases.warp.dev: {final}")
            while True:
                chunk = resp.read(1024 * 1024)
                if not chunk:
                    break
                digest.update(chunk)
    except urllib.error.HTTPError as e:
        raise SystemExit(f"download failed for {url}: HTTP {e.code}") from e
    except urllib.error.URLError as e:
        raise SystemExit(f"download failed for {url}: {e}") from e
    return digest.hexdigest()


for arch, expected in pins.items():
    url = f"{base}/Warp-{arch}.AppImage"
    print(f"fetching {url}")
    actual = sha256_url(url)
    if actual != expected:
        raise SystemExit(
            f"sha256 mismatch for {arch}:\n"
            f"  formula: {expected}\n"
            f"  actual:  {actual}"
        )
    print(f"ok: {arch} sha256 matches pin")

print(f"ok: AppImage pins verified against releases.warp.dev (version={version})")
PY
