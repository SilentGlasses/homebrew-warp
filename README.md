[![Autoupdate Warp](https://github.com/SilentGlasses/homebrew-warp/actions/workflows/update-version.yml/badge.svg)](https://github.com/SilentGlasses/homebrew-warp/actions/workflows/update-version.yml)
![Warp Version](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/SilentGlasses/403337b2dfb42504cfdcaf2b9c58fbfd/raw/warp-terminal.json)

# brew-warp

A dedicated Homebrew Tap for installing **Warp Terminal** on Linux distributions.

Warp is a modern, Rust-based terminal with AI and collaborative features. While the official Homebrew repository primarily focuses on macOS Casks, this tap provides a managed Formula specifically for Linux users.

## Features

- **Automated Updates:** The formula is monitored every 6 hours and automatically updated to the latest stable release.
- **Security First:** Every update includes a fresh SHA-256 checksum verification of the official Warp binaries.
- **Cross-Architecture:** Supports both **x86_64** and **ARM64** (Aarch64) Linux environments.

## Installation

First, ensure you have [Homebrew](https://brew.sh/) installed on your Linux machine.

### 1. Add the Tap

```bash
brew tap SilentGlasses/warp
```

### 2. Install Warp

```bash
brew install warp-terminal
```

## Prerequisites (FUSE)

Warp is distributed as an **AppImage**. For the terminal to launch, you must have `libfuse2` installed on your system.

**Ubuntu/Debian:**

```bash
sudo apt install libfuse2
```

**Fedora:**

```bash
sudo dnf install fuse-libs
```

**Arch Linux:**

```bash
sudo pacman -S fuse2
```

## Testing the Installation

To verify that Warp was installed correctly through Homebrew, you can run:

```bash
warp --version
```

## How it Works

This repository uses **GitHub Actions** to maintain parity with Warp's release cycle:

1. **Scraper:** A workflow checks `releases.warp.dev` for new versions.
2. **Validator:** It downloads the new binary, calculates the SHA256 hash, and updates the Formula.
3. **Badge:** The live version badge at the top of this README is updated via a Gist endpoint to reflect the current state of the tap.

## License

The Homebrew Formula code in this repository is available under the [MIT License](LICENSE).

> [!NOTE]
> Warp Terminal itself is proprietary software. Please refer to [Warp's Terms of Service](https://www.warp.dev/terms-of-service) for details.

*Maintained by [@SilentGlasses](https://github.com/SilentGlasses)*
