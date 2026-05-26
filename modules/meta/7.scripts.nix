{ lib, pkgs, config, configurations, ... }:

# ── User scripts ───────────────────────────────────────────────────────────────
# Standalone binaries reachable both from the terminal and from the compositor
# (which has no user PATH). Exposing them as config.scripts.* lets
# compositor.nix reference the full store path directly.
#
# nrs   — smart rebuild: checks DMI + hostname, offers to fix, commits + switches
# nrsr  — nrs + reboot on success
# dpt   — display power toggle via wlopm
# kbm   — cycle keyboard backlight brightness
# cpc   — copy all .nix configs to clipboard
# cpcs  — copy server .nix configs to clipboard over SSH
#
# WARNING: always use 'nrs [configuration]' to rebuild — never nixos-rebuild
# directly. nrs performs DMI and hostname validation before building.
let
  hostnameMapEntries = lib.concatStringsSep "\n" (
    lib.mapAttrsToList
      (cfg: v: "  [\"${cfg}\"]=\"${v.hostname}\"")
      configurations
  );

  dmiMapEntries = lib.concatStringsSep "\n" (
    lib.mapAttrsToList
      (cfg: v: "  [\"${cfg}\"]=\"${v.dmi}\"")
      configurations
  );

  configNames = lib.concatStringsSep " | " (builtins.attrNames configurations);
in
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
    cpcs = lib.mkOption {
      type        = lib.types.package;
      readOnly    = true;
      description = "Copy server .nix configs to clipboard over SSH.";
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

      cpcs = pkgs.writeShellScriptBin "cpcs" ''
        echo "Copying server .nix configs to clipboard..."
        ssh server cpc | ${pkgs.wl-clipboard}/bin/wl-copy
        ${pkgs.libnotify}/bin/notify-send "✅ Server config copied to clipboard"
      '';

      nrs = pkgs.writeShellScriptBin "nrs" ''
        set -e

        FLAKE="$HOME/nixos-dotfiles"
        CURRENT_HOSTNAME=$(cat /proc/sys/kernel/hostname | tr -d '[:space:]')
        CURRENT_DMI=$(cat /sys/devices/virtual/dmi/id/board_name | tr -d '[:space:]')

        # ── Known configurations (generated from roles.nix) ─────────────────
        declare -A EXPECTED_HOSTNAME=(
        ${hostnameMapEntries}
        )

        declare -A EXPECTED_DMI=(
        ${dmiMapEntries}
        )

        # ── Determine target configuration ──────────────────────────────────
        if [ -n "$1" ]; then
          TARGET="$1"

          if [ -z "''${EXPECTED_HOSTNAME[$TARGET]+_}" ]; then
            echo "ERROR: Unknown configuration '$TARGET'."
            echo "Known configurations: ${configNames}"
            exit 1
          fi
        else
          TARGET=""
          for cfg in "''${!EXPECTED_HOSTNAME[@]}"; do
            if [ "''${EXPECTED_HOSTNAME[$cfg]}" = "$CURRENT_HOSTNAME" ]; then
              TARGET="$cfg"
              break
            fi
          done

          if [ -z "$TARGET" ]; then
            echo ""
            echo "ERROR: Could not auto-detect configuration for hostname '$CURRENT_HOSTNAME'."
            echo "Known configurations: ${configNames}"
            echo ""
            echo "Either:"
            echo "  1) Pass the configuration explicitly: nrs <configuration>"
            echo "  2) Set the correct hostname and retry"
            exit 1
          fi

          echo "Auto-detected configuration: $TARGET"
        fi

        # ── DMI check ────────────────────────────────────────────────────────
        REQUIRED_DMI="''${EXPECTED_DMI[$TARGET]}"

        if [ "$CURRENT_DMI" != "$REQUIRED_DMI" ]; then
          echo ""
          echo "❌ HARDWARE MISMATCH — ABORTING"
          echo "   Configuration : #$TARGET"
          echo "   Expected DMI  : $REQUIRED_DMI"
          echo "   Current DMI   : $CURRENT_DMI"
          echo ""
          echo "   You are trying to build the wrong configuration for this machine."
          echo "   This has been blocked to protect your system."
          exit 1
        fi

        # ── Hostname check ───────────────────────────────────────────────────
        REQUIRED_HOSTNAME="''${EXPECTED_HOSTNAME[$TARGET]}"

        if [ "$CURRENT_HOSTNAME" != "$REQUIRED_HOSTNAME" ]; then
          echo ""
          echo "WARNING: This machine's hostname is '$CURRENT_HOSTNAME'."
          echo "         Configuration '#$TARGET' expects hostname '$REQUIRED_HOSTNAME'."
          echo ""
          echo "Options:"
          echo "  1) Set hostname to '$REQUIRED_HOSTNAME' and continue"
          echo "     (nixos-rebuild will make it permanent on activation)"
          echo "  2) Abort"
          echo ""
          printf "Choose [1/2]: "
          read -r choice

          case "$choice" in
            1)
              echo "Setting hostname to '$REQUIRED_HOSTNAME' for this session..."
              sudo hostname "$REQUIRED_HOSTNAME"
              echo "Hostname set. nixos-rebuild will persist it on activation."
              ;;
            *)
              echo "Aborted."
              exit 1
              ;;
          esac
        fi

        # ── Commit dotfiles ──────────────────────────────────────────────────
        SAVED_DIR=$(pwd)
        cd "$FLAKE" || exit 1

        if ! git rev-parse --verify development &>/dev/null; then
          git checkout -b development || exit 1
        else
          git checkout development || exit 1
        fi

        git add . || exit 1
        if ! git diff --cached --quiet; then
          git commit -m "upgrade $(date '+%Y-%m-%d %H:%M')" || exit 1
        fi

        git push -u origin development || exit 1

        # ── Rebuild ──────────────────────────────────────────────────────────
        sudo nixos-rebuild switch --flake "$FLAKE#$TARGET"
        result=$?
        cd "$SAVED_DIR" || exit 1
        exit $result
      '';

      nrsr = pkgs.writeShellScriptBin "nrsr" ''
        if nrs "$@"; then
          echo "Rebuild succeeded. Rebooting..."
          reboot
        else
          echo "Rebuild failed, NOT rebooting."
        fi
      '';

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
