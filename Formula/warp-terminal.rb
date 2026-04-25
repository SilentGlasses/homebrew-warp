class WarpTerminal < Formula
  desc "Rust-based terminal with AI, built for teams"
  homepage "https://www.warp.dev/"
  # Warp is proprietary — no standard SPDX identifier applies.
  license :cannot_represent

  # ── DSL order: livecheck → disable! → depends_on → on_* ───────────
  #
  # livecheck parses the version from the download URL itself.
  # Warp URLs look like: .../stable/v0.2026.04.22.08.46.stable_02/Warp-x86_64.AppImage
  # The regex captures everything after /stable/ and before the next slash.
  livecheck do
    url :stable
    regex(%r{/stable/(v[^/]+)/}i)
  end

  # This formula is Linux-only. disable! at the top level (outside any
  # on_* block) is evaluated by brew readall for every simulated OS target,
  # which prevents the "formula requires at least a URL" error on macOS.
  disable! date:    "2024-01-01",
           because: "macOS users should install via: brew install --cask warp"

  depends_on :linux

  # ── Architecture-specific downloads ───────────────────────────────
  # IMPORTANT: The autoupdate workflow targets lines by their trailing
  # anchor comments. Do NOT remove or rename those comments.
  on_linux do
    if Hardware::CPU.intel?
      url "https://releases.warp.dev/stable/v0.2026.04.22.08.46.stable_02/Warp-x86_64.AppImage" # x86_64_url
      sha256 "6a1005b87130623a319409893630f989c0a6b47936a71e3540306c3683a9d554" # x86_64_sha256
    elsif Hardware::CPU.arm?
      url "https://releases.warp.dev/stable/v0.2026.04.22.08.46.stable_02/Warp-aarch64.AppImage" # arm64_url
      sha256 "d8324e5a9590623a319409893630f989c0a6b47936a71e3540306c3683a9d554" # arm64_sha256
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
      desktop_contents.gsub!(/^Exec=.*$/, "Exec=#{bin}/warp %U")
      desktop_contents.gsub!(/^TryExec=.*$/, "TryExec=#{bin}/warp")
      desktop_contents += "Categories=System;TerminalEmulator;\n" unless desktop_contents.match?(/^Categories=/)
      (share/"applications").mkpath
      (share/"applications/warp.desktop").write(desktop_contents)
    end

    # Icons — walk the XDG hicolor tree; fall back to root-level images.
    icon_installed = false
    extracted.glob("usr/share/icons/**/*.{png,svg}").each do |icon|
      rel = icon.relative_path_from(extracted/"usr/share")
      dest = share/rel
      dest.dirname.mkpath
      dest.install icon
      icon_installed = true
    end

    unless icon_installed
      extracted.glob("*.{png,svg}").each do |icon|
        size_dir = share/"icons/hicolor/256x256/apps"
        size_dir.mkpath
        (size_dir/"warp.#{icon.extname.delete(".")}").write(icon.read)
      end
    end
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

      After installing FUSE, launch Warp from your application menu or run:
        warp

      To refresh your desktop icon cache after install:
        update-desktop-database ~/.local/share/applications 2>/dev/null; true
        gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor 2>/dev/null; true
    EOS
  end

  # AppImages fail in headless CI (no display/FUSE) so we only verify
  # the binary and .desktop file exist and are correctly formed.
  test do
    assert_path_exists bin/"warp"
    assert_predicate bin/"warp", :executable?
    assert_path_exists share/"applications/warp.desktop"
    assert_match "Exec=", (share/"applications/warp.desktop").read
  end
end
