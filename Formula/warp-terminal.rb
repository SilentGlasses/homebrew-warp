# frozen_string_literal: true

class WarpTerminal < Formula
  desc "Rust-based terminal with AI, built for teams"
  homepage "https://www.warp.dev/"

  # Official Warp hosts only. Never interpolate untrusted hosts into download URLs.
  META_HOST = "releases.warp.dev"
  META_URL = "https://#{META_HOST}/channel_versions.json"
  DOWNLOAD_HOST = META_HOST
  # Same shape as Homebrew/homebrew-cask Casks/w/warp.rb after delete_prefix("v"):
  #   0.2026.08.18.02.52.stable_00
  VERSION_FORM = /\A\d+(?:\.\d+)+\.stable_\d+\z/

  # Resolve the current stable release when Homebrew loads this formula so
  # `brew upgrade` can detect new upstream versions without a tap commit for
  # every bump. Cached per process to avoid repeated network calls.
  def self.stable_version
    return @stable_version if defined?(@stable_version)

    require "json"
    require "net/http"
    require "uri"

    uri = URI(META_URL)
    raise "refusing non-HTTPS metadata URL" unless uri.scheme == "https"
    raise "refusing unexpected metadata host #{uri.host.inspect}" unless uri.host == META_HOST

    response = Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl:      true,
      open_timeout: 10,
      read_timeout: 10,
    ) do |http|
      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = "Homebrew-silentglasses-warp"
      request["Accept"] = "application/json"
      http.request(request)
    end

    raise "HTTP #{response.code} from #{uri}" unless response.is_a?(Net::HTTPSuccess)
    # Bound parser work if the endpoint ever misbehaves.
    raise "metadata response too large" if response.body.bytesize > 8_388_608

    resolved = JSON.parse(response.body).dig("stable", "version")
    raise "missing stable.version in metadata" if resolved.nil? || resolved.to_s.strip.empty?

    # Match Homebrew/homebrew-cask's warp.rb: store version without the leading "v",
    # and put "v" back only in the download URL path.
    normalized = resolved.to_s.delete_prefix("v")
    raise "unexpected version format #{normalized.inspect}" unless normalized.match?(VERSION_FORM)

    @stable_version = normalized
  rescue
    # Fall back to the redirecting "latest" download endpoints when offline or
    # the metadata API is unavailable. `brew upgrade` cannot compare versions
    # in that mode, but install/reinstall still gets current binaries.
    # Avoid odie/opoo here: this runs while the formula class is loading.
    $stderr.puts "Warning: could not resolve Warp stable version; using latest redirect URLs"
    @stable_version = nil
  end

  def self.release_url(package)
    ver = stable_version
    if ver
      # Defense in depth: never build a path from an unchecked version string.
      raise "refusing unsafe version #{ver.inspect}" unless ver.match?(VERSION_FORM)

      arch = (package == :arm64) ? "aarch64" : "x86_64"
      "https://#{DOWNLOAD_HOST}/stable/v#{ver}/Warp-#{arch}.AppImage"
    else
      # Official Warp download redirects (also used by the macOS cask ecosystem).
      query = (package == :arm64) ? "appimage_arm64" : "appimage"
      "https://app.warp.dev/download?package=#{query}"
    end
  end

  # Prefer the resolved upstream tag when available. Homebrew compares this to
  # the installed receipt to decide whether `brew upgrade` should reinstall.
  # Dynamic version strings trip FormulaAudit/Version ("empty string") because
  # the DSL cannot statically inspect the runtime-resolved value.
  version stable_version || "latest"

  # Warp is proprietary — no standard SPDX identifier applies.
  license :cannot_represent

  # Same livecheck source/strategy as Homebrew/homebrew-cask Casks/w/warp.rb.
  livecheck do
    url "https://releases.warp.dev/channel_versions.json"
    strategy :json do |json|
      json.dig("stable", "version")&.delete_prefix("v")
    end
  end

  depends_on :linux

  on_macos do
    disable! date:    "2024-01-01",
             because: "macOS users should install via: brew install --cask warp"
  end

  # Checksums are intentionally unchecked: the upstream stable artifact is
  # resolved at install time, so pinning SHAs would reintroduce manual bumps.
  # Integrity relies on HTTPS to Warp's official hosts (see caveats).
  on_linux do
    on_intel do
      url release_url(:intel)
      sha256 :no_check
    end
    on_arm do
      url release_url(:arm64)
      sha256 :no_check
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

    bin.install appimage => "warp"

    # ── Desktop integration ──────────────────────────────────────────
    # Extract AppImage contents without FUSE so we can install the
    # bundled .desktop file and icons into the standard XDG locations.
    # This makes Warp appear in application menus after install.
    # NOTE: This executes the downloaded AppImage helper path (same trust
    # model as running any upstream binary installer over HTTPS).
    system bin/"warp", "--appimage-extract"

    extracted = Pathname("squashfs-root")
    odie "AppImage extraction did not produce squashfs-root" unless extracted.directory?

    # .desktop — rewrite Exec= to the absolute Homebrew bin path so the
    # launcher works even when brew's bin is not in the user's $PATH.
    # Target the known path directly rather than globbing to avoid picking
    # up any secondary .desktop files that may be bundled in future releases.
    desktop_src = extracted/"usr/share/applications/dev.warp.Warp.desktop"
    if desktop_src.exist?
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
    icon_src = extracted/"usr/share/icons"
    if icon_src.directory?
      (share/"icons").mkpath
      icon_src.find do |src|
        next unless src.file?

        rel = src.relative_path_from(icon_src)
        # Reject path traversal from a malicious archive layout.
        next if rel.to_s.empty? || rel.to_s.start_with?("/") || rel.each_filename.any? { |p| p == ".." }

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
        next if rel.each_filename.any? { |p| p == ".." }

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
      next if rel.each_filename.any? { |p| p == ".." }

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

      This formula resolves the latest stable Warp release at install/upgrade
      time from releases.warp.dev. No manual version bumps are required in the
      tap — run `brew update && brew upgrade silentglasses/warp/warp-terminal`
      to pick up new upstream releases.

      Security note:
        Version metadata and AppImages are fetched over HTTPS from Warp's
        official hosts (releases.warp.dev / app.warp.dev). SHA-256 checksums
        are not pinned (sha256 :no_check) so the formula can track upstream
        automatically. Install runs the AppImage's --appimage-extract helper,
        which means you are trusting Warp's signed transport and release
        infrastructure the same way a direct download would.

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
    assert_predicate share/"icons", :directory?
    desktop = (share/"applications/warp.desktop").read
    assert_match "Exec=#{opt_bin}/warp", desktop
    assert_match "TryExec=#{opt_bin}/warp", desktop
    assert_match "Categories=System;TerminalEmulator;", desktop
    assert_match "Icon=dev.warp.Warp", desktop
    assert_match "Type=Application", desktop
  end
end
