class WarpTerminal < Formula
  desc "Rust-based terminal with AI, built for teams"
  homepage "https://www.warp.dev/"
  # Warp is proprietary — no SPDX identifier exists for it.
  license :cannot_represent

  # ──────────────────────────────────────────────
  # Livecheck must appear before depends_on per
  # Homebrew component ordering rules (FormulaAudit/ComponentsOrder).
  # Warp version strings look like: v0.2026.04.15.08.45.stable_02
  # ──────────────────────────────────────────────
  livecheck do
    url "https://releases.warp.dev/channel_versions.json"
    strategy :json do |json|
      json.dig("stable", "version")
    end
  end

  # ──────────────────────────────────────────────
  # This formula is Linux-only.
  # macOS users should use 'brew install --cask warp'.
  # Declaring on_macos/disable! prevents "formula requires at least a URL"
  # errors when brew readall simulates macOS targets.
  # ──────────────────────────────────────────────
  on_macos do
    disable! date: "2024-01-01", because: "Warp is only available for Linux via this formula; macOS users should use the Warp cask instead"
  end

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
  # Installation
  # ──────────────────────────────────────────────
  def install
    bin_name = Hardware::CPU.intel? ? "Warp-x86_64.AppImage" : "Warp-aarch64.AppImage"

    # Install the AppImage binary
    bin.install bin_name => "warp"
    chmod 0755, bin/"warp"

    # ── Desktop integration ──────────────────────
    # Extract the AppImage contents (no FUSE needed at install time)
    # and pull out the bundled .desktop file and icon so the app
    # appears in application launchers / menus after install.
    system bin/"warp", "--appimage-extract",
           "warp.desktop",
           "usr/share/icons",
           "*.png",
           "*.svg"

    # The extracted tree lands in ./squashfs-root/
    extracted = Pathname("squashfs-root")

    # ── .desktop file ────────────────────────────
    # Find whichever .desktop file the AppImage bundled.
    desktop_src = extracted.glob("**/*.desktop").first
    if desktop_src
      desktop_contents = desktop_src.read

      # Rewrite Exec= to use the absolute Homebrew bin path so the
      # launcher works regardless of whether brew's bin is in PATH.
      desktop_contents.gsub!(/^Exec=.*$/, "Exec=#{bin}/warp %U")
      desktop_contents.gsub!(/^TryExec=.*$/, "TryExec=#{bin}/warp")

      # Ensure the app shows up in terminal-emulator searches.
      desktop_contents += "Categories=System;TerminalEmulator;\n" unless desktop_contents.match?(/^Categories=/)

      (share/"applications").mkpath
      (share/"applications/warp.desktop").write(desktop_contents)
    end

    # ── Icons ────────────────────────────────────
    # Install every resolution the AppImage ships; fall back to any
    # PNG/SVG at the root level if the standard XDG tree is absent.
    icon_installed = false

    # Standard XDG hicolor tree: usr/share/icons/hicolor/<size>/apps/<name>
    extracted.glob("usr/share/icons/**/*.{png,svg}").each do |icon|
      # Preserve the hicolor/<size>/apps/ hierarchy under share/icons/
      rel = icon.relative_path_from(extracted/"usr/share")
      dest = share/rel
      dest.dirname.mkpath
      dest.install icon
      icon_installed = true
    end

    # Fallback: root-level PNG/SVG (some AppImages skip the XDG tree)
    unless icon_installed
      extracted.glob("*.{png,svg}").each do |icon|
        size_dir = share/"icons/hicolor/256x256/apps"
        size_dir.mkpath
        (size_dir/"warp.#{icon.extname.delete(".")}").write(icon.read)
      end
    end
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

      After installing FUSE, launch Warp from your application menu or run:
        warp

      To refresh your desktop icon cache after install:
        update-desktop-database ~/.local/share/applications 2>/dev/null; true
        gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor 2>/dev/null; true
    EOS
  end

  # ──────────────────────────────────────────────
  # Test
  # AppImages exit non-zero in headless CI (no display/FUSE),
  # so we confirm the binary and desktop file are both present.
  # ──────────────────────────────────────────────
  test do
    assert_path_exists bin/"warp"
    assert_predicate bin/"warp", :executable?
    assert_path_exists share/"applications/warp.desktop"
    assert_match "Exec=", (share/"applications/warp.desktop").read
  end
end
