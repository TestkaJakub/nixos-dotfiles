{ config, pkgs, ... }:

{
  home = {
    username = "jakub";
    stateVersion = "25.05";
  
    packages = with pkgs; [
      bat
      btop
      git
      pfetch
    ];
  };
  
  programs = {
    bash = {
      enable = true;
      shellAliases = {
        nsc = "sudo nvim ~/nixos-dotfiles/configuration.nix";
        nhc = "sudo nvim ~/nixos-dotfiles/home.nix";
	nfc = "sudo nvim ~/nixos-dotfiles/flake.nix";
      };

      initExtra = ''
        nrs() {
	  OLDPWD=$(pwd)
	  cd ~/nixos-dotfiles && \
	  git add . && \
	  (git diff --cached --quiet || git commit -m "update $(date '+%Y-%m-%d %H:%M')") && \
	  git push && \
	  sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos
	  status = $?
	  cd "$OLDPWD"
	  return $status
	}

	nrsr() {
	  nrs 
	  if [ $? -eq 0 ]; then
	    echo "Rebuild succeeded. Rebooting..."
	    reboot
	  else
	   echo "Rebuild failed, NOT rebooting"
	  fi
        }

        PS1='\[\e[38;5;206m\]\u\[\e[38;5;63m\]@\[\e[38;5;206m\]\h\[\e[0m\] \D{%d-%m-%Y %H:%m:%S} \w \[\e[38;5;63m\]>\[\e[0m\]'
      '';
    };

    alacritty = {
      enable = true;
      settings = {
        window.opacity = 0.9;
        font.normal = {
          family = "JetBrains Mono";
          style = "Regular";
        };
      };
    };

    neovim = {
      enable = true;
      defaultEditor = true;
      plugins = with pkgs.vimPlugins; [
	gruvbox-material
	nerdtree
      ];
    };
  };

  home.file.".config/bat/config".text = ''
    --theme="Nord"
    --style="numbers,changes,grid"
    --paging=auto
  '';

  home.file.".config/qtile".source = ./qtile;
}

