# frozen_string_literal: true

class WarpTerminal < Formula
  desc "Rust-based terminal with AI, built for teams"
  homepage "https://www.warp.dev/"
  version "0.2026.09.02.08.27.stable_01"
  # Warp is proprietary so no standard SPDX identifier applies.
  license :cannot_represent

  livecheck do
    url "https://releases.warp.dev/channel_versions.json"
    strategy :json do |json|
      json.dig("stable", "version")&.delete_prefix("v")
    end
  end

  # Linux-only. Do not use disable!
  depends_on :linux

  # IMPORTANT: The autoupdate workflow targets lines by their trailing
  # anchor comments. Do NOT remove or rename those comments.
  on_linux do
    on_intel do
      url "https://releases.warp.dev/stable/v#{version}/Warp-x86_64.AppImage" # x86_64_url
      sha256 "57426e3b316a990cfde82912bed3f26168d0a5affde0b40eb92da1c383f01832" # x86_64_sha256
    end
    on_arm do
      url "https://releases.warp.dev/stable/v#{version}/Warp-aarch64.AppImage" # arm64_url
      sha256 "ef97433689bc43d172099d7744e45f61e9ef8b334cde8b8a0b81f2f96dc22747" # arm64_sha256
    end
  end

  def install
    expected = Hardware::CPU.arm? ? "Warp-aarch64.AppImage" : "Warp-x86_64.AppImage"
    appimage = if File.exist?(expected)
      expected
    else
      matches = Dir["*.AppImage"]
      odie "Warp AppImage was not downloaded" if matches.empty?
      odie "Refusing to install: multiple AppImages staged (#{matches.join(", ")})" if matches.length > 1
      matches.fetch(0)
    end

    # Homebrew stages downloads without +x. Formula#system uses Kernel.exec,
    # which fails with a bare "Failed to execute" if the AppImage is not
    # executable. Extract from the buildpath *before* bin.install — running
    # the Cellar copy via `system bin/"warp"` is unreliable under Homebrew's
    # Linux install runner. --appimage-extract does not require FUSE.
    chmod "+x", appimage
    system buildpath/appimage, "--appimage-extract"

    extracted = Pathname("squashfs-root")
    odie "AppImage extraction did not produce squashfs-root" unless extracted.directory?

    bin.install appimage => "warp"

    # ── Desktop integration ──────────────────────────────────────────

    # For .desktop, rewrite Exec= to the absolute Homebrew bin path so the
    # launcher works even when brew's bin is not in the user's $PATH.
    desktop_src = extracted/"usr/share/applications/dev.warp.Warp.desktop"
    if desktop_src.exist?
      desktop_contents = desktop_src.read

      desktop_contents.gsub!(/^Exec=.*$/, "Exec=#{opt_bin}/warp %U")
      desktop_contents.gsub!(/^TryExec=.*$/, "TryExec=#{opt_bin}/warp")
      desktop_contents += "Categories=System;TerminalEmulator;\n" unless desktop_contents.match?(/^Categories=/)
      (share/"applications").mkpath
      (share/"applications/warp.desktop").write(desktop_contents)
    end

    # Install icons from the hicolor tree inside the AppImage.
    icon_src = extracted/"usr/share/icons"
    if icon_src.directory?
      (share/"icons").mkpath
      icon_src.find do |src|
        next unless src.file?

        rel = src.relative_path_from(icon_src)
        # Reject path traversal from a malicious archive layout.
        next if rel.to_s.empty? || rel.to_s.start_with?("/") || rel.each_filename.any?("..")

        dest = share/"icons"/rel
        dest.dirname.mkpath
        cp src, dest
      end
    end
  end

  def uninstall
    home      = Pathname(Dir.home)
    xdg_apps  = home/".local/share/applications"
    xdg_icons = home/".local/share/icons"

    desktop = xdg_apps/"warp.desktop"
    desktop.unlink if desktop.exist? || desktop.symlink?

    icons_removed = false
    icons_root = share/"icons"
    if icons_root.directory?
      icons_root.find do |src|
        next unless src.file?

        rel = src.relative_path_from(icons_root)
        next if rel.each_filename.any?("..")

        link = xdg_icons/rel
        if link.exist? || link.symlink?
          link.unlink
          icons_removed = true
        end
      end
    end

    xdg_cache_update(xdg_apps, xdg_icons/"hicolor") if icons_removed
  end

  def post_install
    home      = Pathname(Dir.home)
    xdg_apps  = home/".local/share/applications"
    xdg_icons = home/".local/share/icons"

    xdg_apps.mkpath
    ln_sf share/"applications/warp.desktop", xdg_apps/"warp.desktop"

    icons_root = share/"icons"
    return unless icons_root.directory?

    icons_installed = false
    icons_root.find do |src|
      next unless src.file?

      rel = src.relative_path_from(icons_root)
      next if rel.each_filename.any?("..")

      dest = xdg_icons/rel
      dest.dirname.mkpath
      ln_sf src, dest
      icons_installed = true
    end

    xdg_cache_update(xdg_apps, xdg_icons/"hicolor") if icons_installed
  end

  def xdg_cache_update(apps_dir, hicolor_dir)
    if which("update-desktop-database")
      begin
        system "update-desktop-database", apps_dir.to_s
      rescue SystemCallError => e
        opoo "update-desktop-database failed: #{e.message}"
      end
    end
    if which("gtk-update-icon-cache")
      begin
        system "gtk-update-icon-cache", "-f", "-t", hicolor_dir.to_s
      rescue SystemCallError => e
        opoo "gtk-update-icon-cache failed: #{e.message}"
      end
    end
  end

  def caveats
    <<~EOS
      Warp is an AppImage. Homebrew installs the app; your distro provides
      system libraries. If `warp` crashes on launch, read the terminal error—
      missing `lib*.so` files must be installed with your package manager.

      Required for the AppImage runtime (libfuse2, not libfuse3 alone):

        Ubuntu / Debian / Mint:
          sudo apt install libfuse2
          # package may be named libfuse2t64 on newer releases

        Fedora:
          sudo dnf install fuse-libs

        Arch Linux:
          sudo pacman -S fuse2

        openSUSE:
          sudo zypper install libfuse2

      Common on minimal desktops (fixes libxkbcommon-x11 launch panics):

        Ubuntu / Debian / Mint:
          sudo apt install libxkbcommon0 libxkbcommon-x11-0

        Fedora:
          sudo dnf install libxkbcommon libxkbcommon-x11

        Arch Linux:
          sudo pacman -S libxkbcommon libxkbcommon-x11

      Map any other missing library from the error text, e.g.:
        apt-file search libxkbcommon-x11.so.0
        dnf provides '*/libxkbcommon-x11.so.0'

      This formula is Linux-only. On macOS install the official cask instead:
        brew install --cask warp

      After Warp publishes a new stable release and this tap updates:
        brew update && brew upgrade warp-terminal

      Launcher shortcut (may need a session refresh):
        ~/.local/share/applications/warp.desktop

      If the menu entry is missing:
        mkdir -p ~/.local/share/applications
        ln -sf #{opt_share}/applications/warp.desktop ~/.local/share/applications/warp.desktop
        update-desktop-database ~/.local/share/applications
    EOS
  end

  # AppImages fail in headless CI (no display/FUSE) so we only verify
  # the binary and .desktop file exist and are correctly formed.
  test do
    assert_path_exists bin/"warp"
    assert_predicate bin/"warp", :executable?
    assert_path_exists share/"applications/warp.desktop"
    assert_predicate share/"icons", :directory?
    desktop = (share/"applications/warp.desktop").read
    assert_match "Exec=#{opt_bin}/warp", desktop
    assert_match "TryExec=#{opt_bin}/warp", desktop
    assert_match "Categories=System;TerminalEmulator;", desktop
    assert_match "Icon=dev.warp.Warp", desktop
    assert_match "Type=Application", desktop
  end
end
