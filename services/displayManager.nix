{ pkgs, ... }:
let
  tokyo-night-sddm = pkgs.libsForQt5.callPackage ../tokyo-night-sddm/default.nix { };
in
{
  services.displayManager = {
    enable = true;
    sddm = {
      enable = true;
      theme = "tokyo-night-sddm";
      wayland.enable = true;
    };
  };

  environment.systemPackages = [ tokyo-night-sddm ];
}
