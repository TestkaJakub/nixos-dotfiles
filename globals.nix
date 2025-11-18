{
  system = "x86_64-linux";
  version = "25.05";
  user = "jakub";
  host = "nixos";
  timezone = "Europe/Warsaw";
  
  #theming = import ./globals/theming.nix;
  configs = import ./globals/configs.nix;
  localisation = import ./globals/localisation.nix;
}
