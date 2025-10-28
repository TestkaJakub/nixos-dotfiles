{
  system = "x86_64-linux";
  version = "25.05";
  user = "jakub";
  host = "nixos";
  timezone = "Europe/Warsaw";
  
  configs = import ./globals/configs.nix;
  locales = import ./globals/localisation.nix;
}
