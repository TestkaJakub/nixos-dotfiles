{ config, pkgs, ... }:
{
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        opacity = 0.9;
        padding = { x = 10; y = 10; };
      };
      font.normal = {
        family = "JetBrains Mono";
        style = "Regular";
      };
    };
  };
}
