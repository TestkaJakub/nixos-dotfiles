{
  programs.bash = {
    enable = true;
    shellAliases = {
      nsc = "sudo nvim ~/nixos-dotfiles/configuration.nix";
      nhc = "sudo nvim ~/nixos-dotfiles/home.nix";
      nfc = "sudo nvim ~/nixos-dotfiles/flake.nix";
      nbc = "sudo nvim ~/nixos-dotfiles/bash.nix";
    };

    initExtra = ''
      #kbm() {
      #  echo "$1" > /sys/class/leds/tpacpi::kbd_backlight/brightness
      #}

      ard() {
        if [ -z "$1" ]; then
          echo "Usage: ard <SketchDir>"
          return 1
        fi

        # strip trailing slash safely
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
          echo "Only one board, auto-selecting it."
          choice=1
        else
          echo -n "Select board number to upload to: "
          read choice
        fi

        # get selected line from the captured list, not a new call
        line=$(echo "$boards" | awk "NR==$choice")
        port=$(echo "$line" | awk '{print $1}')
        fqbn=$(echo "$line" | awk '{print $(NF-1)}')

        if [ -z "$port" ] || [ -z "$fqbn" ]; then
          echo "Couldn't determine port or FQBN"
          return 1
        fi

        echo "Compiling $sketch for $fqbn..."
        arduino-cli compile --fqbn "$fqbn" "$sketch" || return 1

        echo "Uploading $sketch to $port ($fqbn)..."
        arduino-cli upload -p "$port" --fqbn "$fqbn" "$sketch"
      }
    
      nrs() {
        OLDPWD=$(pwd)
        cd ~/nixos-dotfiles || return 1

        # Ensure we're on development branch
        if ! git rev-parse --verify development &>/dev/null; then
          echo "Branch 'development' does not exist locally. Creating it..."
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
        result=$?
        cd "$OLDPWD" || return 1
        return $result
      }

      nrsr() {
	if nrs; then
	  echo "Rebuild succeeded. Rebooting..."
	  reboot
	else
	  echo "Rebuild failed, NOT rebooting"
	fi
      }

      PS1='\[\e[38;5;206m\]\u\[\e[38;5;63m\]@\[\e[38;5;206m\]\h\[\e[0m\] \D{%d-%m-%Y %H:%m:%S} \w \[\e[38;5;63m\]>\[\e[0m\] '
    '';
  };
}
