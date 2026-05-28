{
  description = "Jakub's NixOS configuration";

  inputs = {
    flake-parts.url  = "github:hercules-ci/flake-parts";
    nixpkgs.url      = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager = {
      url                    = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wrappers.url = "github:lassulus/wrappers";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } ({ lib, ... }:
    let
      # ── Roles and configurations ────────────────────────────────────────────
      # Single source of truth — imported by profile.nix and scripts.nix
      # via specialArgs. Add new machines here only.
      data = import ./modules/meta/roles.nix;

      # ── Role bitmask ────────────────────────────────────────────────────────
      # server      = 1
      # workstation = 2
      # personal    = 4
      # testing     = 8
      #
      # File prefix encodes which roles load the module:
      #   1.foo.nix   → server only
      #   2.foo.nix   → workstation only
      #   3.foo.nix   → server + workstation
      #   4.foo.nix   → personal only
      #   5.foo.nix   → server + personal
      #   6.foo.nix   → workstation + personal
      #   7.foo.nix   → all roles (same as no prefix)
      #   8.foo.nix   → testing
      #   foo.nix     → all roles (no prefix = 7, emits a warning)
      roleBits = {
        server      = 1;
        workstation = 2;
        personal    = 4;
        test        = 8;
      };

      # ── Recursive module walker ─────────────────────────────────────────────
      # Accepts the target role string and filters files by bitmask prefix.
      # Files without a numeric prefix are included for all roles but emit
      # a warning so uncategorized modules are easy to spot and migrate.
      collectModules = dir: blacklist: role:
        let
          bit = roleBits.${role};

          # Returns the bitmask encoded in the filename prefix, or 7 if absent.
          # Filename format: "<digits>.<rest>.nix" — prefix must be all digits.
          # Unprefixed files emit a warning and default to 7 (all roles).
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

      # ── Blacklist ───────────────────────────────────────────────────────────
      # Hardware files are machine-specific and passed explicitly to mkConfig.
      # The walker must never load them automatically.
      moduleBlacklist = [
        "meta/roles.nix"
      ];

      # ── Patched pkgs ────────────────────────────────────────────────────────
      pkgs = import inputs.nixpkgs {
        system   = "x86_64-linux";
        overlays = [];
        config   = {
          allowUnfree                = true;
          android_sdk.accept_license = true;
          nvidia.acceptLicense       = true;
        };
      };

      # ── Base configuration factory ──────────────────────────────────────────
      # hardwarePath — path to the machine's hardware.nix
      # role         — "server" | "workstation" | "personal"
      # extraModules — profile overrides (hostname, hardware flags, etc.)
      mkConfig = role: extraModules:
        inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          inherit pkgs;
          modules =
            (collectModules ./modules moduleBlacklist role)
            ++ [ inputs.home-manager.nixosModules.home-manager ]
            ++ extraModules;
          specialArgs = {
            inherit inputs;
            inherit (data) roles configurations;
          };
        };

    in {
      systems = [ "x86_64-linux" ];

      flake.nixosConfigurations = {

        # ── ThinkPad — workstation profile ──────────────────────────────────
        nixos = mkConfig "workstation" [{
          profile.role             = data.configurations.nixos.role;
          profile.hostname         = data.configurations.nixos.hostname;
          profile.lanInterface     = "enp5s0";
          profile.hasBattery       = true;
          profile.hasBacklight     = true;
          profile.hasBluetooth     = true;
        }];

        # ── ThinkPad — server profile ───────────────────────────────────────
        nixos-server = mkConfig "server" [{
          profile.role             = data.configurations.nixos-server.role;
          profile.hostname         = data.configurations.nixos-server.hostname;
          profile.lanInterface     = "enp5s0";
          profile.hasBattery       = true;
          profile.hasBacklight     = true;
          profile.hasBluetooth     = true;
        }];

        # ── Gigabyte desktop — always personal ──────────────────────────────
        # Gaming, entertainment, full desktop stack. Never server or workstation.
        desktop = mkConfig "personal" [{
          profile.role             = data.configurations.desktop.role;
          profile.hostname         = data.configurations.desktop.hostname;
          profile.lanInterface     = "enp6s0";
          profile.hasBattery       = false;
          profile.hasBacklight     = false;
          profile.hasBluetooth     = false;
        }];

        test = mkConfig "testin" [{
          profile.role             = data.configurations.test.role;
          profile.hostname         = data.configurations.test.hostname;
          profile.lanInterface     = "enp6s0";
          profile.hasBattery       = false;
          profile.hasBacklight     = false;
          profile.hasBluetooth     = false;
        }];

      };
    });
}
