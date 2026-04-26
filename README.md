[![Autoupdate Warp](https://github.com/SilentGlasses/homebrew-warp/actions/workflows/update-version.yml/badge.svg?branch=main)](https://github.com/SilentGlasses/homebrew-warp/actions/workflows/update-version.yml)
[![Test Formula](https://github.com/SilentGlasses/homebrew-warp/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/SilentGlasses/homebrew-warp/actions/workflows/tests.yml)
![Warp Version](https://byob.yarr.is/SilentGlasses/homebrew-warp/warp-linux)

# Homebrew Warp

<img width="100" height="100" alt="logo" align="left" src="https://github.com/user-attachments/assets/7784ea7d-deb1-44a0-af90-2bec574cbd7f" />

A streamlined Homebrew Tap designed to bring the Warp Terminal to Linux distributions with the reliability of a managed package, providing a native Formula that handles binary management, checksum verification, and architecture detection.

Warp is a modern, Rust-based terminal with AI and collaborative features. The official Homebrew cask is macOS-only, this tap provides a managed Formula specifically for Linux users.

## Features

- **Automated Updates:** Checks for new Warp releases every 6 hours and opens a PR automatically when one is found.
- **SHA-256 Verified:** Every update computes a fresh checksum of the official Warp binaries before updating the formula.
- **Cross-Architecture:** Supports both **x86_64** and **ARM64** (aarch64) Linux.
- **Desktop Integration:** Automatically installs a launcher shortcut and icons into your desktop environment on install, and removes them cleanly on uninstall.

## Prerequisites

Warp is distributed as an **AppImage** and requires `libfuse2` to run. Install it for your distro before installing Warp:

| Distro | Command |
|---|---|
| Ubuntu / Debian | `sudo apt install libfuse2` |
| Fedora | `sudo dnf install fuse-libs` |
| Arch Linux | `sudo pacman -S fuse2` |
| openSUSE | `sudo zypper install libfuse2` |

> [!NOTE]
> AppImages require `libfuse2`, not `libfuse3`. Version 3 is not backwards compatible and will not allow the AppImage to initialize.
> If Warp fails to launch after installing FUSE, ensure `libfuse2` specifically is installed.

## Installation

Ensure you have [Homebrew](https://brew.sh/) installed, then:

```bash
brew install silentglasses/warp/warp-terminal
```

After install, Warp will appear in your application menu. You can also launch it from the terminal:

```bash
warp
```

## Uninstalling

```bash
brew uninstall silentglasses/warp/warp-terminal
```

This removes the binary, the launcher shortcut, and all icons from your desktop environment automatically.

## Upgrading

Upgrades happen automatically via the autoupdate workflow. To upgrade manually:

```bash
brew update && brew upgrade silentglasses/warp/warp-terminal
```

## Troubleshooting

**The icon doesn't appear in my application menu:**

Log out and back in, or run:

```bash
update-desktop-database ~/.local/share/applications
gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor
```

**Warp fails to launch with a FUSE error:**

Ensure `libfuse2` is installed (see Prerequisites above). On some distros only `libfuse3` is installed by default — you need `libfuse2` specifically.

**Verify the installation:**

```bash
brew list silentglasses/warp/warp-terminal
```

## Automation Pipeline

This repository functions as a "living" Tap through a three-stage CI/CD pipeline:

- **Polling**: A GitHub Action scrapes `releases.warp.dev` for version increments.
- **Validation**: The workflow fetches the latest binaries, calculates new SHA256 hashes, and commits the updated Formula.
- **Telemetry**: A live version badge is maintained via the shields branch to provide real-time status of the Tap's parity.

Two GitHub Actions workflows keep this tap running:

- **`update-version.yml`** — Runs every 6 hours. Fetches the latest stable version from `releases.warp.dev`, downloads both AppImages to compute SHA-256 checksums, patches the formula, and opens a PR. Does nothing if already up to date.
- **`tests.yml`** — Runs on every PR that touches the formula. Checks Ruby syntax, runs `brew audit`, and validates the formula loads correctly on Linux.

## License

The Homebrew Formula in this repository is available under the [MIT License](LICENSE).

> [!NOTE]
> Warp Terminal itself is proprietary software. Refer to [Warp's Terms of Service](https://www.warp.dev/terms-of-service) for details.

*Maintained by [@SilentGlasses](https://github.com/SilentGlasses)*
