{ pkgs, config, ... }:
let
  isServer = config.profile.isRole [ "server" ];
in
{
  hardware.graphics = {
    enable      = true;
    enable32Bit = true;
    extraPackages = with pkgs; (if isServer then [] else [
      mesa
      libdrm
    ]);
  };
}
