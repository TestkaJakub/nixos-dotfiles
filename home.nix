{ config, pkgs, ... }:
{
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

  programs.home-manager.enable = true;

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
  programs.hyprlock.enable = true;
  programs.hyprlock.settings = {
    general = {
      hide_cursor = false;
    };
    background = [
      {
        path = toString ../../assets/lockscreen.png;
        blur_passes = 3;
        blur_size = 6;
      }
    ];
    shape = [
      {
        size = "280, 280";
        color = "rgb(ff0000)";
        rounding = 48;
        position = "0, 45";
        halign = "center"; valign = "center";
        shadow_passes = 3;
        shadow_size = 8;
      }
    ];
    label = [
      {
        position = "0, 105";
        text = "cmd[update:1000] echo \"<span font_weight='1000'>$(date +'%H')</span>\"";
        font_size = 78;
        color = "rgb(eba0ac)"; # mauve
        font_family = "Inter";
        halign = "center"; valign = "center";
      }
      {
        position = "0, 20";
        text = "cmd[update:1000] echo \"<span font_weight='1000'>$(date +'%M')</span>\"";
        font_size = 78;
        color = "rgb(00ff00)";
        font_family = "Inter";
        halign = "center"; valign = "center";
      }
      {
        position = "0, -45";
        text = "cmd[update:1000] echo \"$(date +'%A, %d %B')\"";
        font_size = 14;
        color = "rgb(00ff00)";
        font_family = "Inter";
        halign = "center"; valign = "center";
      }
      {
        position = "0, 10";
        halign = "center"; valign = "bottom";
        color = "rgb(9399b2)";
        font_size = 8;
        font_family = "Inter";
        text = "$LAYOUT";
      }
      {
        position = "-15, -13";
        halign = "right"; valign = "top";
        color = "rgb(ffffff)";
        font_size = 14;
        font_family = "Font Awesome 6 Free";
        text = "";
        shadow_passes = 3;
        shadow_size = 8;
      }
      {
        position = "-41, -10";
        halign = "right"; valign = "top";
        color = "rgb(ffffff)";
        font_size = 14;
        font_family = "Inter";
        text = "cmd[update:4000] echo \"<span font_weight='600'>$(cat /sys/class/power_supply/BAT0/capacity)%</span>\"";
        shadow_passes = 3;
        shadow_size = 8;
      }
    ];
    input-field = [
      {
        position = "0, -140";
        size = "280, 48";
        outline_thickness = 2;
        dots_size = 0.3;
        fade_on_empty = false;
        placeholder_text = "";
        outer_color = "rgb(ff0000)";
        inner_color = "rgb(ff0000)";
        font_color = "rgb(00ff00)";
        check_color = "rgb(0000ff)";
        fail_color = "rgb(ffff00)";
        capslock_color = "rgb(ff00ff)";
      }
    ];
  };

  wayland.windowManager.hyprland.settings = {
    decoration = {
      shadow_offset = "0.1";
      "col.shadow" = "rgba(00000099)";
    };
    "$mod" = "SUPER";
    bindm = [
      "$mod, mouse:272, movewindow"
      "$mod, mouse:273, resizewindow"
      "$mod ALT, mouse:272, resizewindow"
    ];
  };

  #wayland.windowManager.sway = {
  #  enable = true;
  #  config = rec {
  #    modifier = "Mod4";
  #    output = {
  #      "Virtual-1" = {
  #        mode = "1920x1080@60Hz";
  #      };
  #    };
  #  };
  #};

  home.file.".config/bat/config".text = ''
    --theme="Nord"
    --style="numbers,changes,grid"
    --paging=auto
  '';

  home.file.".config/qtile".source = ./qtile;
}

