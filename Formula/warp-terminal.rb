class WarpTerminal < Formula
  desc "Rust-based terminal with AI, built for teams"
  homepage "https://www.warp.dev/"
  license "Closed Source"

  # This formula is strictly for Linux.
  # macOS users should use 'brew install --cask warp'

  depends_on :linux

  # ──────────────────────────────────────────────
  # Architecture-specific downloads
  # NOTE: The autoupdate workflow targets lines anchored by the
  # trailing comments (# x86_64_url, # x86_64_sha256, etc.).
  # Do NOT remove or rename those anchor comments.
  # ──────────────────────────────────────────────
  on_linux do
    if Hardware::CPU.intel?
      url "https://releases.warp.dev/stable/v0.2026.04.22.08.46.stable_02/Warp-x86_64.AppImage" # x86_64_url
      sha256 "03d52e68d59f4679ef2ee4a8ca7aff26ebd36eae7974a7387761971ac2069110" # x86_64_sha256
    elsif Hardware::CPU.arm?
      url "https://releases.warp.dev/stable/v0.2026.04.22.08.46.stable_02/Warp-aarch64.AppImage" # arm64_url
      sha256 "44b7a70f3edd8dcf6fc163a1d03503c521488503023ae37f0a72095408b13a6b" # arm64_sha256
    end
  end

  # ──────────────────────────────────────────────
  # Livecheck — helps `brew livecheck` identify the latest version.
  # Warp version strings look like: v0.2026.04.15.08.45.stable_02
  # ──────────────────────────────────────────────
  livecheck do
    url "https://releases.warp.dev/channel_versions.json"
    strategy :json do |json|
      json.dig("stable", "version")
    end
  end

  # ──────────────────────────────────────────────
  # Installation
  # ──────────────────────────────────────────────
  def install
    bin_name = Hardware::CPU.intel? ? "Warp-x86_64.AppImage" : "Warp-aarch64.AppImage"
    bin.install bin_name => "warp"
    chmod 0755, bin/"warp"
  end

  # ──────────────────────────────────────────────
  # Post-install guidance
  # ──────────────────────────────────────────────
  def caveats
    <<~EOS
      Warp Terminal is distributed as an AppImage.
      You must have FUSE (Filesystem in Userspace) installed for it to run.

      Ubuntu/Debian:
        sudo apt install libfuse2

      Fedora:
        sudo dnf install fuse-libs

      Arch Linux:
        sudo pacman -S fuse2

      After installing FUSE, launch Warp with:
        warp
    EOS
  end

  # ──────────────────────────────────────────────
  # Test
  # AppImages exit non-zero in headless CI (no display/FUSE),
  # so we just confirm the file is present and executable.
  # ──────────────────────────────────────────────
  test do
    assert_predicate bin/"warp", :exist?
    assert_predicate bin/"warp", :executable?
  end
end
