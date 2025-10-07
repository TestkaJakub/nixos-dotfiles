{ pkgs, ... }:
let
  tokyo-night-sddm = pkgs.libsForQt5.callPackage ../themes/tokyo-night-sddm.nix { };
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
