{ config, pkgs, ... }:
{
  programs.waybar = {
    enable = true;
    style = ''
      window#waybar {
        background-color: #ff5fd7;
      }
    '';
    settings = {
      main = {
        modules-right = [ "battery" "clock" ];
      };
    };
  };
}
