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
  
  imports = [
    ./bash.nix
  ];

  programs.alacritty = {
      enable = true;
      settings = {
        window.opacity = 0.9;
        font.normal = {
          family = "JetBrains Mono";
          style = "Regular";
        };
      };
    };
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    plugins = with pkgs.vimPlugins; [
      gruvbox-material
      nerdtree
    ];
  };

  home.file.".config/bat/config".text = ''
    --theme="Nord"
    --style="numbers,changes,grid"
    --paging=auto
  '';

  home.file.".config/qtile".source = ./qtile;
}

