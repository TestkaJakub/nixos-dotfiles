{ pkgs, config, ... }:
let
  isPersonal = config.profile.isRole [ "personal" ];
in
{
  hardware.graphics = {
    enable      = true;
    enable32Bit = true;
    extraPackages = with pkgs; (if isPersonal then [] else [
      mesa
      libdrm
    ]);
  };
}
