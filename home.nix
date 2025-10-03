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
	nrs = "sudo nixos-rebuild switch";
	nrsr = "nrs && reboot";
        nsc = "sudo nvim ~/nixos-dotfiles/configuration.nix";
        nhc = "sudo nvim ~/nixos-dotfiles/home.nix"; 
      };

      initExtra = ''
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

