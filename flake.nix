{
  description = "Welcome to my NixOs configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-${version}";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mangowc.url = "github:DreamMaoMao/mangowc";
  };

  outputs = { self, nixpkgs, home-manager, mangowc, ... }:
    let
      version = "25.05";
      system = "x86_64-linux";
      user = "jakub";
    in {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit system version user; };
        modules = [
          ./main.nix
          home-manager.nixosModules.home-manager
          { home-manager.users.${user} = import ./home.nix; }
          mangowc.nixosModules.mango
        ];
      };
    };
}