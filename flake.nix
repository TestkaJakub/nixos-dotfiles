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
      version = "25.05";
      system  = "x86_64-linux";
      user    = "jakub";
      pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
    in {
      # 👇 must be nixosConfigurations.nixos (the hostname you’ll use)
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = { inherit system version user inputs; };

        modules = [
          ./main.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.extraSpecialArgs =
              { inherit system version user inputs pkgs; };
            home-manager.users.${user} = import ./home.nix;
          }
          mangowc.nixosModules.mango
        ];
      };
    };
}