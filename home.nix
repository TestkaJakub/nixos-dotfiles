{ config, pkgs, ... }:
{
#  home-manager.backupFileExtension = "backup";
  home = {
    username = "jakub";
    stateVersion = "25.05";
    packages = with pkgs; [
      bat
      btop
      git
      arduino-core
      arduino-cli
    ];
  };
  imports = [
    ./bash.nix
  ];

  programs.home-manager = { 
    enable = true;
  };

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

  wayland = {
    systemd.target = "wayland-session.target";
    windowManager.hyprland = {
      enable = true;
      package = null;
      portalPackage = null;
      settings = {
        general = {
          border_size = 10;
        };
        decoration = {
          shadow_offset = "0.1";
	  "col.shadow" = "rgba(00000099)";
        };
        "$mod" = "SUPER";
        bind = [
          "$mod, B, exec, firefox"
	  "$mod, q, exec, alacritty"
        ];
        bindm = [
          "$mod, mouse:272, movewindow"
	  "$mod, mouse:273, resizewindow"
	  "$mod ALT, mouse:272, resizewindow"
        ];
      };
    };
  };

  home.file.".config/bat/config".text = ''
    --theme="Nord"
    --style="numbers,changes,grid"
    --paging=auto
  '';

  home.file.".config/qtile".source = ./qtile;
}

