{ lib, pkgs, ... }:

# ── User scripts ───────────────────────────────────────────────────────────────
# Standalone binaries that need to be reachable both from the terminal and
# from the compositor (which has no user PATH). Exposing them as
# config.scripts.* lets compositor.nix reference the full store path directly.
{
  options.scripts = {
    kbm = lib.mkOption {
      type        = lib.types.package;
      readOnly    = true;
      description = "Cycle keyboard backlight brightness.";
    };
    cpc = lib.mkOption {
      type        = lib.types.package;
      readOnly    = true;
      description = "Copy all .nix configs to clipboard.";
    };
  };

  config.scripts = {
    kbm = pkgs.writeShellScriptBin "kbm" ''
      path="/sys/class/leds/tpacpi::kbd_backlight/brightness"
      max_path="/sys/class/leds/tpacpi::kbd_backlight/max_brightness"
      cur=$(cat "$path" 2>/dev/null || echo 0)
      max=$(cat "$max_path" 2>/dev/null || echo 2)
      val=$(( (cur + 1) % (max + 1) ))
      echo "$val" > "$path"
    '';

    cpc = pkgs.writeShellScriptBin "cpc" ''
      echo "Copying .nix configs to clipboard..."
      find ~/nixos-dotfiles -type f -name '*.nix' \
        -exec echo "===== {} =====" \; -exec cat {} \; | ${pkgs.wl-clipboard}/bin/wl-copy
      ${pkgs.libnotify}/bin/notify-send "✅ Config copied to clipboard"
    '';
  };
}
