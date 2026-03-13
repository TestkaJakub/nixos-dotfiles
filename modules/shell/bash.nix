{ pkgs, config, ... }:

# ── Bash ───────────────────────────────────────────────────────────────────────
# kbm and cpc are defined in generals/scripts.nix and referenced here via
# config.scripts so the compositor can use the same store paths.
let
  user = config.profile.username;
  kbm  = config.scripts.kbm;
  cpc  = config.scripts.cpc;
in
{
  home-manager.users.${user} = {
    home.packages = with pkgs; [
      wl-clipboard
      grim
      slurp
      pamixer
      wayvnc
      hyprpaper
      gammastep
      libnotify
      kbm
      cpc

      (writeShellScriptBin "screenshot-region" ''
        dir="$HOME/Pictures/$(date +%Y-%m)"
        mkdir -p "$dir"
        base="$(date +%d_%H.%M.%S)"
        file="$dir/$base.png"
        n=1
        while [ -e "$file" ]; do
          file="$dir/$base.$n.png"
          n=$(( n + 1 ))
        done
        grim -g "$(slurp)" "$file"
        ${pkgs.wl-clipboard}/bin/wl-copy < "$file"
        ${pkgs.libnotify}/bin/notify-send "Screenshot saved" "$file"
      '')
      (writeShellScriptBin "screenshot-full" ''
        dir="$HOME/Pictures/$(date +%Y-%m)"
        mkdir -p "$dir"
        base="$(date +%d_%H.%M.%S)"
        file="$dir/$base.png"
        n=1
        while [ -e "$file" ]; do
          file="$dir/$base.$n.png"
          n=$(( n + 1 ))
        done
        grim "$file"
        ${pkgs.wl-clipboard}/bin/wl-copy < "$file"
        ${pkgs.libnotify}/bin/notify-send "Screenshot saved" "$file"
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
