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
      system  = "x86_64-linux";
      user    = "jakub";
      version = "25.05";
      pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
    in {
      nixosConfigurations.${system} =
        nixpkgs.lib.nixosSystem {
          inherit system;

          # Global arguments – visible to every NixOS module (incl. home-manager)
          specialArgs = { inherit system version user inputs; };

          modules = [
            ./main.nix
            home-manager.nixosModules.home-manager
            {
              # 👇 repeat specialArgs for Home‑Manager itself
              home-manager.extraSpecialArgs = { inherit system version user inputs pkgs; };

              home-manager.users.${user} = import ./home.nix;
            }
            mangowc.nixosModules.mango
          ];
        };
    };
}