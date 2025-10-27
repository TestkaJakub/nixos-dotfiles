{
  system = "x86_64-linux";
  version = "25.05";
  user = "jakub";
  host = "nixos";
  
  configs = import ./globals/configs.nix;
}
