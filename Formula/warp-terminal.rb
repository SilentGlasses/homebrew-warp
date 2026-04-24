class WarpTerminal < Formula
  desc "Rust-based terminal with AI, built for teams"
  homepage "https://www.warp.dev/"
  license "Closed Source"

  # This formula is strictly for Linux.
  # macOS users should use 'brew install --cask warp'
  livecheck do
    url :stable
    regex(/v(\d+(?:\.\d+)+(?:\.stable_\d+)?)/i)
  end

  depends_on :linux

  on_linux do
    if Hardware::CPU.intel?
      # The Autoupdate workflow targets the following lines:
      url "https://releases.warp.dev/stable/v0.2026.04.15.08.45.stable_02/Warp-x86_64.AppImage"
      sha256 "436d99a13e60451d12a89aeae2d32a6467d645fd10fea7b870c2e7b650f33d33" # x86_64_placeholder
    elsif Hardware::CPU.arm?
      url "https://releases.warp.dev/stable/v0.2026.04.15.08.45.stable_02/Warp-x86_64.AppImage"
      sha256 "d8324e5a9590623a319409893630f989c0a6b47936a71e3540306c3683a9d554" # arm64_placeholder
    end
  end

  # Helps 'brew livecheck' identify the latest version string

  def install
    # Determine the correct binary based on architecture
    bin_name = Hardware::CPU.intel? ? "Warp-x86_64.AppImage" : "Warp-aarch64.AppImage"

    # Install the AppImage as 'warp' in the Homebrew bin directory
    bin.install bin_name => "warp"

    # Ensure the binary is executable
    chmod 0755, bin/"warp"
  end

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
    EOS
  end

  test do
    # Basic check to ensure the binary is in the path and executable
    # We use '2>&1' because Warp may output to stderr in headless environments
    assert_match "warp", shell_output("#{bin}/warp --version 2>&1", 1)
  end
end
