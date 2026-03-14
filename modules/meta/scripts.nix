{ lib, pkgs, ... }:

# ── User scripts ───────────────────────────────────────────────────────────────
# Standalone binaries reachable both from the terminal and from the compositor
# (which has no user PATH). Exposing them as config.scripts.* lets
# compositor.nix reference the full store path directly.
#
# nrs / nrsr live here rather than bash.nix because they are system-management
# binaries, not shell configuration — they need to work from fish too.
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
    nrs = lib.mkOption {
      type        = lib.types.package;
      readOnly    = true;
      description = "Commit dotfiles to git and run nixos-rebuild switch.";
    };
    nrsr = lib.mkOption {
      type        = lib.types.package;
      readOnly    = true;
      description = "Run nrs and reboot on success.";
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

    # ── nrs: commit dotfiles + rebuild ────────────────────────────────────────
    nrs = pkgs.writeShellScriptBin "nrs" ''
      OLDPWD=$(pwd)
      cd ~/nixos-dotfiles || exit 1

      if ! git rev-parse --verify development &>/dev/null; then
        echo "Creating branch 'development'..."
        git checkout -b development || exit 1
      else
        git checkout development || exit 1
      fi

      git add . || exit 1
      if ! git diff --cached --quiet; then
        git commit -m "upgrade $(date '+%Y-%m-%d %H:%M')" || exit 1
      fi

      git push -u origin development || exit 1
      sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos
      result=$?
      cd "$OLDPWD" || exit 1
      exit $result
    '';

    # ── nrsr: rebuild + reboot on success ─────────────────────────────────────
    nrsr = pkgs.writeShellScriptBin "nrsr" ''
      if nrs; then
        echo "Rebuild succeeded. Rebooting..."
        reboot
      else
        echo "Rebuild failed, NOT rebooting."
      fi
    '';
  };
}
