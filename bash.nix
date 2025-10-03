{
  programs.bash = {
    enable = true;
    shellAliases = {
      nsc = "sudo nvim ~/nixos-dotfiles/configuration.nix";
      nhc = "sudo nvim ~/nixos-dotfiles/home.nix";
      nfc = "sudo nvim ~/nixos-dotfiles/flake.nix";
    };

    initExtra = ''
      nrs() {
        OLDPDW=$(pdw)
	cd ~/nixos-dotfiles || return 1
	git add . || return 1
	if ! git diff --cached --quiet; then
	  git commit -m "upgrade $(date '+%Y-%m-%d %H:%M')" || return 1
	fi
	git push || return 1
	sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos
	result=$?
	cd "$OLDPDW" || return 1
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

      PS1='\[\e[38;5;206m\]\u\[\e[38;5;63m\]@\[\e[38;206\]\h\[\e[0m\] \D{%d-%m-%Y %H:m:$S} \w \[\e[38;5;63m\]>\[\e[0m\]'
    '';
  };


}
