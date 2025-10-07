{ pkgs, ... }:
{
  hardware.graphics.enable = true;
  fonts.packages = with pkgs; [ jetbrains-mono ];
}
