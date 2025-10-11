{ pkgs, ... }:
{
  services.swww = {
    enable = true;
    extraArgs = [
      "img" "/home/jakub/Wallpapers/makima.gif"
    ];
  };
}
