![Warp Version](https://byob.yarr.is/SilentGlasses/homebrew-warp/warp-linux)

# Homebrew Warp

A Homebrew tap that installs [Warp Terminal](https://www.warp.dev/) on Linux. The official Homebrew cask is macOS-only; this formula provides x86_64 and ARM64 Linux support via Warp's official AppImage builds.

The formula always tracks Warp's current **stable** release. You do not need version-bump PRs in this tap for routine upgrades.

## Install

Install [`libfuse2`](#prerequisites) first, then:

```bash
brew install silentglasses/warp/warp-terminal
```

Launch from your app menu or:

```bash
warp
```

## Upgrade

Homebrew reloads the formula on upgrade, fetches the latest stable version from Warp, and installs it when newer than your receipt:

```bash
brew update && brew upgrade silentglasses/warp/warp-terminal
```

If a new Warp release is out and `brew upgrade` still reports nothing to do, force a refresh:

```bash
brew reinstall silentglasses/warp/warp-terminal
```

## Uninstall

```bash
brew uninstall silentglasses/warp/warp-terminal
```

Removes the binary, desktop launcher, and icons.

## Prerequisites

Warp's AppImage needs **libfuse2** (not libfuse3):

| Distro | Command |
|---|---|
| Ubuntu / Debian | `sudo apt install libfuse2` |
| Fedora | `sudo dnf install fuse-libs` |
| Arch Linux | `sudo pacman -S fuse2` |
| openSUSE | `sudo zypper install libfuse2` |

> [!NOTE]
> If Warp fails to launch after installing FUSE, confirm `libfuse2` is present. `libfuse3` alone is not enough.

## How updates work

Unlike the official macOS cask (pinned `version` + `sha256`, bumped by Homebrew bots), this Linux formula resolves the release at install/upgrade time:

1. Reads `https://releases.warp.dev/channel_versions.json` over HTTPS.
2. Validates `stable.version` (same version shape as Homebrew's `warp` cask, without a leading `v`).
3. Downloads `https://releases.warp.dev/stable/v{version}/Warp-{arch}.AppImage` for your CPU.
4. Homebrew compares that version to the installed receipt and upgrades when upstream is newer.
5. If metadata is unreachable, falls back to Warp's official redirects:
   - `https://app.warp.dev/download?package=appimage`
   - `https://app.warp.dev/download?package=appimage_arm64`

Checksums use `sha256 :no_check` so the tap can track upstream without maintenance PRs. Artifacts still come only from Warp's hosts.

The version badge at the top of this README is refreshed by GitHub Actions for visibility only. It does not drive installs.

### What users run

| Goal | Command |
|---|---|
| First install | `brew install silentglasses/warp/warp-terminal` |
| Normal upgrade | `brew update && brew upgrade silentglasses/warp/warp-terminal` |
| Force latest pull | `brew reinstall silentglasses/warp/warp-terminal` |
| Remove | `brew uninstall silentglasses/warp/warp-terminal` |

### What maintainers no longer do

- Manually bump URLs or SHA-256 values in the formula
- Review/merge routine automation PRs for each Warp release

Touch this repo when install logic changes (desktop file layout, architectures, Warp API shape)—not for ordinary version churn.

## Features

- **Always latest stable** — resolved from Warp at install/upgrade time
- **x86_64 and ARM64 (aarch64)** Linux
- **Desktop integration** — `.desktop` launcher and icons installed on install, removed on uninstall

## Troubleshooting

**Icon missing from the app menu**

Log out and back in, or run:

```bash
update-desktop-database ~/.local/share/applications
gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor
```

**FUSE / AppImage launch error**

Install `libfuse2` for your distro (see [Prerequisites](#prerequisites)).

**Confirm the package is present**

```bash
brew list silentglasses/warp/warp-terminal
brew info silentglasses/warp/warp-terminal
```

## Security model

This formula trades pinned checksums for zero-touch version tracking.

| Control | Behavior |
|---|---|
| Transport | HTTPS to `releases.warp.dev` (metadata + versioned AppImages) or `app.warp.dev` (fallback redirects) |
| Version metadata | Host allowlisted; response size capped; version must match an allowlisted pattern before use in URLs |
| Artifact integrity | `sha256 :no_check` — relies on TLS and Warp's release infrastructure |
| Install-time execution | Runs the AppImage with `--appimage-extract` for `.desktop`/icons (same trust class as a vendor installer) |
| Desktop/icon install | Fixed `.desktop` path; icon copy/link rejects `..` path segments |
| macOS | Formula disabled; use `brew install --cask warp` |

**Residual risks (accepted for low maintenance):**

- A compromised Warp release host could serve a bad AppImage without a checksum failure.
- Formula load performs a short network request to Warp (timeouts applied). Metadata failure falls back to Warp's "latest" redirects.
- This is a third-party tap; trust both this repository and Warp.

Comparable to downloading Warp's AppImage from the vendor site. Weaker integrity than a pinned-SHA Homebrew core package or the official macOS cask's pinned `version` + `sha256` (which require ongoing bump PRs).

## License

The Homebrew formula in this repository is available under the [MIT License](LICENSE).

> [!NOTE]
> Warp Terminal is proprietary. See [Warp's Terms of Service](https://www.warp.dev/terms-of-service).

*Maintained by [@SilentGlasses](https://github.com/SilentGlasses)*
