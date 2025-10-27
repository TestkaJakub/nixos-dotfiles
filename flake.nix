{
  description = "Jakub's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mangowc.url = "github:DreamMaoMao/mangowc";
  };

  outputs = { self, nixpkgs, home-manager, mangowc, ... } @ inputs:
    let
      globals = import ./globals.nix;
      #version = "25.05";
      #system  = "x86_64-linux";
      #user    = "jakub";
      pkgs = import nixpkgs { inherit (globals) system; config.allowUnfree = true; };
    in {
      nixosConfigurations.${globals.host} = nixpkgs.lib.nixosSystem {
        system = globals.system;

        specialArgs = { inherit (globals) system version user; inherit inputs; };

        modules = [
          globals.configs.configurationPath
          home-manager.nixosModules.home-manager
          {
            home-manager.extraSpecialArgs =
              { inherit (globals) system version user; inherit inputs pkgs; };
            home-manager.users.${globals.user} = import globals.configs.homePath;
          }
          mangowc.nixosModules.mango
        ];
      };
    };
}
