{ pkgs, config, ... }:

# ── Bash ───────────────────────────────────────────────────────────────────────
# Reads: config.profile.username
# Contains all interactive shell functions:
#   kbm   — cycle keyboard backlight
#   cpc   — copy all .nix configs to clipboard
#   ard   — compile + upload Arduino sketch
#   nrs   — commit dotfiles + nixos-rebuild switch
#   nrsr  — nrs + reboot on success
#   screenshot-region / screenshot-full — grim helpers
let
  user = config.profile.username;
in
{
  home-manager.users.${user} = {
    home.packages = with pkgs; [
      wl-clipboard  # wl-copy used by cpc
      grim          # screenshot capture
      slurp         # region selection for screenshots
      pamixer       # volume control (used by keybinds + waybar)
      wayvnc        # VNC server (launched via keybind in compositor)
      hyprpaper     # wallpaper daemon (launched by compositor autostart)
      gammastep     # night light (launched by compositor autostart)
      libnotify     # provides notify-send binary

      # Screenshot helpers as standalone binaries
      (writeShellScriptBin "screenshot-region" ''
        mkdir -p ~/Pictures/screenshots
        grim -g "$(slurp)" ~/Pictures/screenshots/$(date +%Y-%m-%d_%H-%M-%S).png
        notify-send "Screenshot saved"
      '')
      (writeShellScriptBin "screenshot-full" ''
        mkdir -p ~/Pictures/screenshots
        grim ~/Pictures/screenshots/$(date +%Y-%m-%d_%H-%M-%S).png
        notify-send "Fullscreen screenshot saved"
      '')
    ];

    programs.bash = {
      enable           = true;
      enableCompletion = false;

      shellAliases = {
        nmc = "sudo nvim ~/nixos-dotfiles/flake.nix";
        nhc = "sudo nvim ~/nixos-dotfiles/modules";
        vnc = "wayvnc 192.168.0.16 5900";
      };

      initExtra = ''
        # ── Prompt ──────────────────────────────────────────────────────────────
        if [[ $- == *i* ]]; then
          unset PS1
          PS1="\033[38;5;206m\u\033[38;5;63m@\033[38;5;206m\h\033[0m \
\D{%d-%m-%Y %H:%M:%S} \w \033[38;5;63m>\033[0m "
          export PS1
        fi

        # ── kbm: cycle keyboard backlight ───────────────────────────────────────
        kbm() {
          local path="/sys/class/leds/tpacpi::kbd_backlight/brightness"
          local max_path="/sys/class/leds/tpacpi::kbd_backlight/max_brightness"
          local cur max val
          cur=$(cat "$path" 2>/dev/null || echo 0)
          max=$(cat "$max_path" 2>/dev/null || echo 2)
          val=$(( (cur + 1) % (max + 1) ))
          echo "$val" > "$path"
        }

        # ── cpc: copy all .nix configs to clipboard ─────────────────────────────
        cpc() {
          echo "Copying .nix configs to clipboard..."
          find ~/nixos-dotfiles -type f -name '*.nix' \
            -exec echo "===== {} =====" \; -exec cat {} \; | wl-copy
          notify-send "Config copied to clipboard"
        }

        # ── ard: compile + upload an Arduino sketch ─────────────────────────────
        ard() {
          if [ -z "$1" ]; then
            echo "Usage: ard <SketchDir>"
            return 1
          fi

          local sketch
          sketch=$(echo "$1" | sed 's:/*$::')

          echo "Scanning for connected boards..."
          local boards
          boards=$(arduino-cli board list | awk 'NR>1 && NF>2 && $(NF-1)!="" {print $0}')

          if [ -z "$boards" ]; then
            echo "No boards detected."
            return 1
          fi

          echo "Available boards:"
          echo "$boards" | awk '{printf "%d. %s %s\n", NR, $1, $(NF-1)}'

          local count choice line port fqbn
          count=$(echo "$boards" | wc -l)

          if [ "$count" -eq 1 ]; then
            echo "Only one board, auto-selecting."
            choice=1
          else
            echo -n "Select board number: "
            read -r choice
          fi

          line=$(echo "$boards" | awk "NR==$choice")
          port=$(echo "$line" | awk '{print $1}')
          fqbn=$(echo "$line" | awk '{print $(NF-1)}')

          if [ -z "$port" ] || [ -z "$fqbn" ]; then
            echo "Couldn't determine port or FQBN."
            return 1
          fi

          echo "Compiling $sketch for $fqbn..."
          arduino-cli compile --fqbn "$fqbn" "$sketch" || return 1

          echo "Uploading to $port ($fqbn)..."
          arduino-cli upload -p "$port" --fqbn "$fqbn" "$sketch"
        }

        # ── nrs: commit dotfiles + rebuild ──────────────────────────────────────
        nrs() {
          local OLDPWD
          OLDPWD=$(pwd)
          cd ~/nixos-dotfiles || return 1

          if ! git rev-parse --verify development &>/dev/null; then
            echo "Creating branch 'development'..."
            git checkout -b development || return 1
          else
            git checkout development || return 1
          fi

          git add . || return 1
          if ! git diff --cached --quiet; then
            git commit -m "upgrade $(date '+%Y-%m-%d %H:%M')" || return 1
          fi

          git push -u origin development || return 1
          sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos
          local result=$?
          cd "$OLDPWD" || return 1
          return $result
        }

        # ── nrsr: rebuild + reboot on success ───────────────────────────────────
        nrsr() {
          if nrs; then
            echo "Rebuild succeeded. Rebooting..."
            reboot
          else
            echo "Rebuild failed, NOT rebooting."
          fi
        }
      '';
    };
  };
}
