![Warp Version](https://byob.yarr.is/SilentGlasses/homebrew-warp/warp-linux)

# Homebrew Warp

A Homebrew tap that installs [Warp Terminal](https://www.warp.dev/) on Linux. The official Homebrew cask is macOS-only; this formula provides x86_64 and ARM64 Linux support via Warp's official AppImage builds.

The formula name is **`warp-terminal`** not `warp`, that name is already the official macOS cask. After install, use normal Homebrew update/upgrade commands. Version pins and SHA-256 checksums are refreshed automatically by GitHub Actions.

## Prerequisites

Warp's AppImage needs **libfuse2** (not libfuse3):

| Distro          | Command                        |
|-----------------|--------------------------------|
| Ubuntu / Debian | `sudo apt install libfuse2`    |
| Fedora          | `sudo dnf install fuse-libs`   |
| Arch Linux      | `sudo pacman -S fuse2`         |
| openSUSE        | `sudo zypper install libfuse2` |

> [!NOTE]
> If Warp fails to launch after installing FUSE, confirm `libfuse2` is present. `libfuse3` alone is not enough.

## Install

Either approach works. Pick one.

### Option A: tap once, then short name (recommended)

Best if you want ordinary Homebrew day-to-day commands afterward:

```bash
brew tap silentglasses/warp
brew install warp-terminal
```

### Option B: one-shot fully qualified install

Homebrew taps the repo automatically as part of install:

```bash
brew install silentglasses/warp/warp-terminal
```

> [!IMPORTANT]
> Use **`warp-terminal`**, not `warp`.
> `brew install warp` targets the official macOS cask and is the wrong package for this Linux tap.

## Upgrade

Once installed and the tap has pulled the latest formula pin:

```bash
brew update && brew upgrade
```

That upgrades every outdated formula, including `warp-terminal`.

To upgrade only Warp:

```bash
# after Option A (tap installed)
brew update && brew upgrade warp-terminal

# always works (fully qualified)
brew update && brew upgrade silentglasses/warp/warp-terminal
```

## Uninstall

```bash
brew uninstall warp-terminal
# or
brew uninstall silentglasses/warp/warp-terminal
```

Removes the binary, desktop launcher, and icons.

Optional, remove the tap entirely:

```bash
brew untap silentglasses/warp
```

## Command cheat sheet

| Goal               | After tapping (`brew tap silentglasses/warp`) | Fully qualified (always works)                     |
|--------------------|-----------------------------------------------|----------------------------------------------------|
| Install            | `brew install warp-terminal`                  | `brew install silentglasses/warp/warp-terminal`    |
| Upgrade everything | `brew update && brew upgrade`                 | same                                               |
| Upgrade Warp only  | `brew upgrade warp-terminal`                  | `brew upgrade silentglasses/warp/warp-terminal`    |
| Remove             | `brew uninstall warp-terminal`                | `brew uninstall silentglasses/warp/warp-terminal`  |

## How updates work

This tap uses **pinned `version` + SHA-256** values (same integrity model as the official macOS cask), kept current by automation:

1. Every 6 hours, GitHub Actions reads `https://releases.warp.dev/channel_versions.json`.
2. If `stable.version` is newer than the formula pin, CI downloads both AppImages from `releases.warp.dev`.
3. CI computes fresh SHA-256 digests and patches `Formula/warp-terminal.rb`.
4. CI opens a PR and enables **auto-merge** (or merges immediately when allowed).
5. Users run `brew update && brew upgrade` to receive the new pin.

## Features

- **Pinned SHA-256 verification** on every install/upgrade
- **Automated bumps** when Warp ships a new stable release
- **x86_64 and ARM64 (aarch64)** Linux
- **Desktop integration**: `.desktop` launcher and icons installed on install, removed on uninstall

## Troubleshooting

**Icon missing from the app menu**

```bash
update-desktop-database ~/.local/share/applications
gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor
```

**FUSE / AppImage launch error**

Install `libfuse2` for your distro (see [Prerequisites](#prerequisites)).

**Confirm the package is present**

```bash
brew list warp-terminal
brew info warp-terminal
```

**`brew install warp` did the wrong thing**

That resolves the official macOS **cask**. For this tap use `warp-terminal`.

## Security model

| Control                | Behavior                                                                                                 |
|------------------------|----------------------------------------------------------------------------------------------------------|
| Transport              | HTTPS to `releases.warp.dev` for metadata and AppImages                                                  |
| Artifact integrity     | Pinned per-arch `sha256` in the formula; Homebrew verifies before install                                |
| Version pins           | Updated by GitHub Actions from Warp's stable channel; not chosen at install time by the client           |
| Install-time execution | Runs the AppImage with `--appimage-extract` for `.desktop`/icons (vendor installer trust class)          |
| Desktop/icon install   | Fixed `.desktop` path; icon copy/link rejects `..` path segments                                         |
| macOS                  | Not supported (`depends_on :linux`); use `brew install --cask warp`                                      |

**What checksums buy you**

- Detect corrupted or substituted AppImage bytes that do not match the pin recorded in git
- Stable, auditable formula history for each release

**Residual risks**

- A compromised Warp release host at the moment CI computes hashes can still poison a bump (same class of risk as the official macOS cask bot)
- A fully compromised GitHub owner account can still ship a bad pin (2FA + branch protection + pin allowlist raise the bar substantially)
- This is a third-party tap; trust both this repository and Warp

Stronger than `sha256 :no_check` live installs for artifact consistency; not a substitute for vendor code-signing.

## License

The Homebrew formula in this repository is available under the [MIT License](LICENSE).

> [!NOTE]
> Warp Terminal is proprietary. See [Warp's Terms of Service](https://www.warp.dev/terms-of-service).

*Maintained by [@SilentGlasses](https://github.com/SilentGlasses)*
