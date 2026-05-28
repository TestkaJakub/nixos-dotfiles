{ pkgs, config, ... }:

# ── Bash ───────────────────────────────────────────────────────────────────────
# PS1 colors come from config.theme.palette.term* so they stay in sync with
# fish and can be changed from theming.nix alone.
#
# ard is a real binary (writeShellScriptBin) so it works from fish, bash, and
# anywhere else — not just inside an interactive bash session.
#
# Screenshots  → desktop/screenshots.nix
# nrs / nrsr   → meta/scripts.nix
# Common aliases live in shell/aliases.nix — do not redeclare.
let
  user = config.profile.username;
  kbm  = config.scripts.kbm;
  cpc  = config.scripts.cpc;
  cpcs = config.scripts.cpcs;

  p      = config.theme.palette;
  toPs1  = config.theme.functions.toPs1;
  clUser = toPs1 p.termUser;
  clAcc  = toPs1 p.termAccent;
  reset  = "\\033[0m";
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
      xclip
      kbm
      cpc
      cpcs

      # ── ard: compile + upload an Arduino sketch ───────────────────────────
      (writeShellScriptBin "ard" ''
        if [ -z "$1" ]; then
          echo "Usage: ard <SketchDir>"
          exit 1
        fi

        sketch=$(echo "$1" | sed 's:/*$::')

        echo "Scanning for connected boards..."
        boards=$(arduino-cli board list | awk 'NR>1 && NF>2 && $(NF-1)!="" {print $0}')

        if [ -z "$boards" ]; then
          echo "No boards detected."
          exit 1
        fi

        echo "Available boards:"
        echo "$boards" | awk '{printf "%d. %s %s\n", NR, $1, $(NF-1)}'

        count=$(echo "$boards" | wc -l)

        if [ "$count" -eq 1 ]; then
          echo "Only one board, auto-selecting."
          choice=1
        else
          printf "Select board number: "
          read -r choice
        fi

        line=$(echo "$boards" | awk "NR==$choice")
        port=$(echo "$line" | awk '{print $1}')
        fqbn=$(echo "$line" | awk '{print $(NF-1)}')

        if [ -z "$port" ] || [ -z "$fqbn" ]; then
          echo "Couldn't determine port or FQBN."
          exit 1
        fi

        echo "Compiling $sketch for $fqbn..."
        arduino-cli compile --fqbn "$fqbn" "$sketch" || exit 1

        echo "Uploading to $port ($fqbn)..."
        arduino-cli upload -p "$port" --fqbn "$fqbn" "$sketch"
      '')
    ];

    programs.bash = {
      enable           = true;
      enableCompletion = false;

      # Shell-specific alias only — common aliases come from shell/aliases.nix.
      shellAliases = {};

      initExtra = ''
        # ── Prompt ────────────────────────────────────────────────────────────
        # PS1 is rebuilt before every prompt via PROMPT_COMMAND so the date/time
        # reflects when the previous command finished, not when the shell started.
        if [[ $- == *i* ]]; then
          _build_ps1() {
            local date_str
            date_str=$(date '+%d-%m-%Y %H:%M:%S')
            PS1="\[${clUser}\]\u\[${clAcc}\]@\[${clUser}\]\h\[${reset}\] $date_str \w \[${clAcc}\]bash >\[${reset}\] "
          }
          PROMPT_COMMAND=_build_ps1
        fi
      '';
    };
  };
}
