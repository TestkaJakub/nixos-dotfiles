{ lib, pkgs, config, ... }:

# ── User scripts ───────────────────────────────────────────────────────────────
# Standalone binaries reachable both from the terminal and from the compositor
# (which has no user PATH). Exposing them as config.scripts.* lets
# compositor.nix reference the full store path directly.
#
# nrs / nrsr live here rather than bash.nix because they are system-management
# binaries, not shell configuration — they need to work from fish too.
#
# dpt (display power toggle) turns all outputs off/on via wlopm.
# Press super+ctrl+d once → screens off, again → screens on.
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
    dpt = lib.mkOption {
      type        = lib.types.package;
      readOnly    = true;
      description = "Toggle all displays on/off via wlopm.";
    };
  };

  config = {
    scripts = {
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
        SAVED_DIR=$(pwd)
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
        cd "$SAVED_DIR" || exit 1
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

      # ── dpt: display power toggle ──────────────────────────────────────────────
      # Uses wlopm to cut power to all Wayland outputs (works on MangoWC /
      # any wlroots compositor that implements wlr-output-power-management-v1).
      # State is tracked via a flag file in /run/user/<uid>/ which is wiped
      # on every reboot, so you can never get stuck with screens "thinking"
      # they are off after a reboot.
      dpt = pkgs.writeShellScriptBin "dpt" ''
        flag="/run/user/$(id -u)/display-off"
        if [ -f "$flag" ]; then
          rm -f "$flag"
          ${pkgs.wlopm}/bin/wlopm --on '*'
        else
          touch "$flag"
          ${pkgs.wlopm}/bin/wlopm --off '*'
        fi
      '';

    };

    environment.systemPackages = [
      config.scripts.nrs
      config.scripts.nrsr
      config.scripts.dpt
    ];
  };
}
