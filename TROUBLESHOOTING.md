# Troubleshooting

## Confirm Homebrew actually installed the package

```bash
brew info warp-terminal
brew list warp-terminal | head
which warp
ls -la "$(brew --prefix)/bin/warp"
```

If those paths exist, the formula installed correctly even if the app menu is empty or launch fails.

## Read launch errors (missing system libraries)

Run Warp from a terminal so you see the real error:

```bash
warp
```

| Error pattern | Typical fix (Ubuntu/Debian) |
|---|---|
| `libfuse` / AppImage mount / FUSE | `sudo apt install libfuse2` |
| `libxkbcommon-x11.so` / `libxkbcommon-x11.so.0` | `sudo apt install libxkbcommon-x11-0` |
| `libxkbcommon.so` | `sudo apt install libxkbcommon0` |
| `cannot open shared object file: ... libXYZ.so` | Install the distro package that provides that library |

**How to map a missing `.so` to a package (Ubuntu/Debian):**

```bash
# example from the error text:
#   libxkbcommon-x11.so.0: cannot open shared object file
sudo apt update
apt-file update 2>/dev/null || sudo apt install apt-file && sudo apt-file update
apt-file search libxkbcommon-x11.so.0
# then: sudo apt install <package-from-search>
```

On Fedora: `dnf provides '*/libxkbcommon-x11.so.0'`.  
On Arch: `pacman -F libxkbcommon-x11.so.0`.

This tap does not try to own every OS library—when Warp (or the AppImage runtime) prints a missing file, install that dependency from your distro and re-run `warp`.

## App menu icon / launcher missing

The binary can be installed while the user launcher symlink is missing:

```bash
ls -la "$(brew --prefix)/opt/warp-terminal/share/applications/warp.desktop"
ls -la ~/.local/share/applications/warp.desktop
```

Recreate the launcher and refresh:

```bash
mkdir -p ~/.local/share/applications
ln -sf "$(brew --prefix)/opt/warp-terminal/share/applications/warp.desktop"   ~/.local/share/applications/warp.desktop
update-desktop-database ~/.local/share/applications
gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor 2>/dev/null || true
```

Or re-run post-install:

```bash
brew reinstall warp-terminal
# if available on your Homebrew version:
brew postinstall warp-terminal
```

Then log out/in or search “Warp” in the app grid. You can always launch with `warp` once PATH includes `$(brew --prefix)/bin` (`eval "$(brew shellenv)"`).

## FUSE / AppImage launch error

Install `libfuse2` for your distro (see [Prerequisites](#prerequisites)). `libfuse3` alone is not enough.

## `command not found: warp` but `brew list` shows files

Homebrew’s bin dir is not on your `PATH`:

```bash
eval "$(brew shellenv)"
# add that line to ~/.bashrc or ~/.zshrc for new terminals
```

## `brew install warp` did the wrong thing

That resolves the official macOS **cask**. For this tap use `warp-terminal`.

## Refusing to load formula from untrusted tap

On recent Homebrew, trust the tap once:

```bash
brew trust silentglasses/warp
```
