class WarpTerminal < Formula
  desc "Rust-based terminal with AI, built for teams"
  homepage "https://www.warp.dev/"
  # Warp is proprietary — no standard SPDX identifier applies.
  license :cannot_represent

  livecheck do
    url :stable
    regex(%r{/stable/(v[^/]+)/}i)
  end

  on_macos do
    disable! date:    "2024-01-01",
             because: "macOS users should install via: brew install --cask warp"
  end

  depends_on :linux

  # ── Architecture-specific downloads ───────────────────────────────
  # IMPORTANT: The autoupdate workflow targets lines by their trailing
  # anchor comments. Do NOT remove or rename those comments.
  on_linux do
    if Hardware::CPU.intel?
      url "https://releases.warp.dev/stable/v0.2026.04.22.08.46.stable_03/Warp-x86_64.AppImage" # x86_64_url
      sha256 "eb929d853b022680e02832964fb41756005779709de910fc16f1229c8a36a28b" # x86_64_sha256
    elsif Hardware::CPU.arm?
      url "https://releases.warp.dev/stable/v0.2026.04.22.08.46.stable_03/Warp-aarch64.AppImage" # arm64_url
      sha256 "73449ab40d3b03a38deb9180bdb59e7f0fe21a4fbf014fb39819fdd4ec909c3d" # arm64_sha256
    end
  end

  def install
    bin_name = Hardware::CPU.intel? ? "Warp-x86_64.AppImage" : "Warp-aarch64.AppImage"

    bin.install bin_name => "warp"
    chmod 0755, bin/"warp"

    # ── Desktop integration ──────────────────────────────────────────
    # Extract AppImage contents without FUSE so we can install the
    # bundled .desktop file and icons into the standard XDG locations.
    # This makes Warp appear in application menus after install.
    system bin/"warp", "--appimage-extract"

    extracted = Pathname("squashfs-root")

    # .desktop — rewrite Exec= to the absolute Homebrew bin path so the
    # launcher works even when brew's bin is not in the user's $PATH.
    desktop_src = extracted.glob("**/*.desktop").first
    if desktop_src
      desktop_contents = desktop_src.read
      # Use opt_bin so the path stays valid across upgrades
      desktop_contents.gsub!(/^Exec=.*$/, "Exec=#{opt_bin}/warp %U")
      desktop_contents.gsub!(/^TryExec=.*$/, "TryExec=#{opt_bin}/warp")
      desktop_contents += "Categories=System;TerminalEmulator;\n" unless desktop_contents.match?(/^Categories=/)
      (share/"applications").mkpath
      (share/"applications/warp.desktop").write(desktop_contents)
    end

    # Install icons from the hicolor tree inside the AppImage.
    # The .desktop file references Icon=dev.warp.Warp so filenames must match.
    extracted.glob("usr/share/icons/**/*.{png,svg}").each do |icon|
      rel  = icon.relative_path_from(extracted/"usr/share")
      dest = share/rel
      dest.dirname.mkpath
      FileUtils.cp icon, dest
    end
  end

  def uninstall
    home = Pathname(ENV["HOME"])

    desktop = home/".local/share/applications/warp.desktop"
    desktop.unlink if desktop.symlink?

    xdg_icons = home/".local/share/icons"
    Pathname(share/"icons").find do |src|
      next unless src.file?

      rel  = src.relative_path_from(share/"icons")
      link = xdg_icons/rel
      link.unlink if link.symlink?
    end

    system "update-desktop-database", (home/".local/share/applications").to_s if which("update-desktop-database")
    system "gtk-update-icon-cache", "-f", "-t",
           (home/".local/share/icons/hicolor").to_s if which("gtk-update-icon-cache")
  end

  def post_install
    home = Pathname(ENV["HOME"])

    xdg_apps = home/".local/share/applications"
    xdg_apps.mkpath
    ln_sf share/"applications/warp.desktop", xdg_apps/"warp.desktop"

    xdg_icons = home/".local/share/icons"
    Pathname(share/"icons").find do |src|
      next unless src.file?

      rel  = src.relative_path_from(share/"icons")
      dest = xdg_icons/rel
      dest.dirname.mkpath
      ln_sf src, dest
    end

    system "update-desktop-database", xdg_apps.to_s if which("update-desktop-database")
    system "gtk-update-icon-cache", "-f", "-t",
           (home/".local/share/icons/hicolor").to_s if which("gtk-update-icon-cache")
  end

  def caveats
    <<~EOS
      Warp Terminal is distributed as an AppImage and requires FUSE to run.

      Install the required FUSE library for your distro:

        Ubuntu / Debian:
          sudo apt install libfuse2

        Fedora:
          sudo dnf install fuse-libs

        Arch Linux:
          sudo pacman -S fuse2

        openSUSE:
          sudo zypper install libfuse2

      Note: AppImages require libfuse2, not libfuse3. If Warp fails to launch
      after installing FUSE, ensure libfuse2 (not just fuse3) is installed.

      A launcher shortcut is created automatically at:
        ~/.local/share/applications/warp.desktop

      If the icon does not appear immediately, log out and back in, or run:
        update-desktop-database ~/.local/share/applications
        gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor
    EOS
  end

  # AppImages fail in headless CI (no display/FUSE) so we only verify
  # the binary and .desktop file exist and are correctly formed.
  test do
    assert_path_exists bin/"warp"
    assert_predicate bin/"warp", :executable?
    assert_path_exists share/"applications/warp.desktop"
    desktop = (share/"applications/warp.desktop").read
    assert_match "Exec=#{opt_bin}/warp", desktop
    assert_match "Icon=dev.warp.Warp", desktop
    assert_match "Type=Application", desktop
  end
end
