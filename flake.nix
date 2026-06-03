{
  # Welcome to my flakes,
  #
  # !!!This project is constantly evolving as it's deployed on a living computer system!!!
  #
  # Following dotfiles use dendritic pattern with flake-parts.
  # Additionally they use home-manager and wrappers.
  #
  # There is a custom bitmask based environment dependant files separation,
  # as well as custom functions that allow for separating parts of a given dotfiles in contrast to separating whole dotfile file.
  #
  # Environments further called roles are currently hardware bound to ensure proper hardware.nix is loaded,
  # but I plan to separate them in the future.
  # 
  # Module walker imports each flake in the dotfiles codebase,
  # unless it's blacklisted.

  # TODO:
  # * Separate the roles from the hardware
  # * Update comments in the whole dotfiles codebase

  description = "Jakub's NixOS configuration";

  inputs = {
    flake-parts.url  = "github:hercules-ci/flake-parts";
    nixpkgs.url      = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager = {
      url                    = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wrappers.url = "github:lassulus/wrappers";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } ({ lib, ... }:
    let
      # Roles and configurations
      # Each role and configuration is stored in the ./modules/meta/roles.nix

      data = import ./modules/meta/roles.nix;

      # Role bitmask
      # server      = 1
      # workstation = 2
      # personal    = 4
      #
      # File prefix encodes which roles load the module:
      #   1.foo.nix   -> server only
      #   2.foo.nix   -> workstation only
      #   3.foo.nix   -> server + workstation
      #   4.foo.nix   -> personal only
      #   5.foo.nix   -> server + personal
      #   6.foo.nix   -> workstation + personal
      #   7.foo.nix   -> all roles (same as no prefix)
      #   foo.nix     -> all roles (no prefix = 7, emits a warning)

      roleBits = {
        server      = 1;
        workstation = 2;
        personal    = 4;
      };

      # Module walker
      # Walks over the modules in the dotfiles codebase,
      # loads only those modules that correspond to the current role.
      # If a module name doesn't start with the bitmask prefix,
      # it get's loaded for all the roles and produces a warning.

      collectModules = dir: blacklist: role:
        let
          bit = roleBits.${role};
          fileMask = name:
            let
              m = builtins.match "^([0-9]+)\\..*\\.nix$" name;
            in
              if m != null
              then lib.toInt (builtins.head m)
              else builtins.trace
                "WARNING: module '${name}' has no role prefix — loaded for all roles. Consider prefixing with a bitmask (1=server, 2=workstation, 4=personal)."
                7;

          walk = prefix: entries:
            lib.concatMap (name:
              let
                path    = dir + "/${prefix}${name}";
                relPath = "${prefix}${name}";
                type    = entries.${name};
                mask    = fileMask name;
              in
              if type == "directory" then
                walk "${prefix}${name}/" (builtins.readDir path)
              else if type == "regular"
                && lib.hasSuffix ".nix" name
                && !(builtins.elem relPath blacklist)
                && (lib.bitAnd mask bit != 0)
              then [ path ]
              else []
            ) (builtins.attrNames entries);
        in
          walk "" (builtins.readDir dir);

      # Blacklist
      # Files specified bellow will be omitted by the automatic walker.

      moduleBlacklist = [
        "meta/roles.nix"
      ];

      pkgs = import inputs.nixpkgs {
        system   = "x86_64-linux";
        overlays = [];
        config   = {
          allowUnfree                = true;
          android_sdk.accept_license = true;
          nvidia.acceptLicense       = true;
        };
      };

      # Configuration
      # role         - "server" | "workstation" | "personal"
      # extraModules - profile overrides (hostname, hardware flags, etc.)

      mkConfig = role: extraModules:
        inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          inherit pkgs;
          modules =
            (collectModules ./modules moduleBlacklist role)
            ++ [ inputs.home-manager.nixosModules.home-manager ]
            ++ [ inputs.vscode-server.nixosModules.default ]
            ++ extraModules;
          specialArgs = {
            inherit inputs;
            inherit (data) roles configurations;
          };
        };

    in {
      systems = [ "x86_64-linux" ];

      flake.nixosConfigurations = {

        # Workstation profile

        nixos = mkConfig "workstation" [{
          profile.role             = data.configurations.nixos.role;
          profile.hostname         = data.configurations.nixos.hostname;
          profile.lanInterface     = "enp5s0";
          profile.hasBattery       = true;
          profile.hasBacklight     = true;
          profile.hasBluetooth     = true;
        }];

        # Server profile

        nixos-server = mkConfig "server" [{
          profile.role             = data.configurations.nixos-server.role;
          profile.hostname         = data.configurations.nixos-server.hostname;
          profile.lanInterface     = "enp5s0";
          profile.hasBattery       = true;
          profile.hasBacklight     = true;
          profile.hasBluetooth     = true;
        }];

        # Desktop profile
        
        desktop = mkConfig "personal" [{
          profile.role             = data.configurations.desktop.role;
          profile.hostname         = data.configurations.desktop.hostname;
          profile.lanInterface     = "enp6s0";
          profile.hasBattery       = false;
          profile.hasBacklight     = false;
          profile.hasBluetooth     = false;
        }];
      };
    });
}
