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
          border_size = 1;
	  gaps_in = 2;
	  gaps_out = 4;
	  "col.active_border" = "rgba(ff5fd7ff) rgba(ff5fd7ff) 0deg";
	  "col.inactive_border" = "rgba(5f5fffff) rgba(5f5fffff) 0deg";
	};
	decoration = {
          rounding = 2;
	  rounding_power = "2.0";
	  inactive_opacity = "0.7";
	};
        "$mod" = "SUPER";
        bind = [
	  "$mod, L, exec, bash kbm"
          "$mod, B, exec, firefox"
	  "$mod, Q, exec, alacritty"
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

