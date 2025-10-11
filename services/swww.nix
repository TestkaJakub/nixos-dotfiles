{ pkgs, ... }:
{
  services.swww = {
    enable = true;
    extraArgs = [
      img ~/Wallpapers/makima.gif
    ];
  };
}
