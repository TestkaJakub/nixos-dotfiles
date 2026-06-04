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
  # Module walker imports each module in the dotfiles codebase,
  # unless it's blacklisted.

  # TODO:
  # * Separate the roles from the hardware
  # * Update comments in the whole dotfiles codebase

  description = "Jakub's NixOS configuration";

  inputs = {
    flake-parts.url  = "github:hercules-ci/flake-parts";
    wrappers.url     = "github:lassulus/wrappers";
    nixpkgs.url      = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager = {
      url                    = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vscode-server = {
      url                    = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } ({ lib, ... }:
    let
      # Configurations
      # Each configuration is stored in ./modules/meta/roles.nix
      # and identified by its hostname (the attrset key).
      # To add a new machine, add an entry to roles.nix — no changes needed here.

      data = import ./modules/meta/roles.nix;

      # Role bitmask
      # Bitmask values are defined per-configuration in roles.nix:
      #   server      = 1
      #   workstation = 2
      #   desktop     = 4
      #
      # File prefix encodes which roles load the module:
      #   1.foo.nix   -> server only
      #   2.foo.nix   -> workstation only
      #   3.foo.nix   -> server + workstation
      #   4.foo.nix   -> desktop only
      #   5.foo.nix   -> server + desktop
      #   6.foo.nix   -> workstation + desktop
      #   7.foo.nix   -> all roles (same as no prefix)
      #   foo.nix     -> all roles (no prefix = 7, emits a warning)

      # Module walker
      # Walks over the modules in the dotfiles codebase,
      # loads only those modules that correspond to the current bitmask value.
      # If a module name doesn't start with the bitmask prefix,
      # it gets loaded for all roles and produces a warning.

      collectModules = dir: blacklist: bit:
        let
          fileMask = name:
            let
              m = builtins.match "^([0-9]+)\\..*\\.nix$" name;
            in
              if m != null
              then lib.toInt (builtins.head m)
              else builtins.trace
                "WARNING: module '${name}' has no role prefix — loaded for all roles. Consider prefixing with a bitmask (1=server, 2=workstation, 4=desktop)."
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
      # Files specified below will be omitted by the automatic walker.

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

      # mkConfig
      # Builds a nixosSystem for the given hostname.
      # All configuration is sourced from data.configurations.${hostname} in roles.nix.

      mkConfig = hostname: _:
        let
          cfg = data.configurations.${hostname};
        in
          inputs.nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            inherit pkgs;
            modules =
              (collectModules ./modules moduleBlacklist cfg.bitmaskvalue)
              ++ [ inputs.home-manager.nixosModules.home-manager ]
              ++ [ inputs.vscode-server.nixosModules.default ]
              ++ [{
                profile.hostname     = hostname;
                profile.role         = hostname;
                profile.lanInterface = cfg.lanInterface;
                profile.hasBattery   = cfg.hasBattery;
                profile.hasBacklight = cfg.hasBacklight;
                profile.hasBluetooth = cfg.hasBluetooth;
              }];
            specialArgs = {
              inherit inputs;
              inherit (data) configurations;
            };
          };

    in {
      systems = [ "x86_64-linux" ];

      flake.nixosConfigurations = builtins.mapAttrs mkConfig data.configurations;
    });
}