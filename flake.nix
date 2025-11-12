{
  description = "Jakub's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    wrappers.url = "github:lassulus/wrappers";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mangowc.url = "github:DreamMaoMao/mangowc";
  };

  outputs = { self, nixpkgs, home-manager, mangowc, wrappers, ... } @ inputs:
    let
      globals = import ./globals.nix;
      pkgs = import nixpkgs { inherit (globals) system; config.allowUnfree = true; };
    in {
      nixosConfigurations.${globals.host} = nixpkgs.lib.nixosSystem {
        system = globals.system;

        specialArgs = { 
	  inherit (globals) system version user host timezone;
	  inherit (globals.configs) configurationModulesPath wrapsPath;
	  inherit inputs globals wrappers;
	};

        modules = [
          globals.configs.configurationPath
          home-manager.nixosModules.home-manager
          {
            home-manager.extraSpecialArgs = {
	      inherit (globals) system version user;
	      inherit (globals.configs) homeConfigurationPath;
	      inherit (globals.localisation) latitude longitude keyboardLayout;
	      inherit inputs pkgs wrappers; 
	    };
            home-manager.users.${globals.user} = import globals.configs.homePath;
          }
          mangowc.nixosModules.mango
        ];
      };
    };
}
