{
  description = "Jakub's NixOS configuration";

  inputs = {
    flake-parts.url  = "github:hercules-ci/flake-parts";
    nixpkgs.url      = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager = {
      url            = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
	mangowc.url = "github:DreamMaoMao/mangowc/b9300aac8292d6d11a71252d6ee179c23f6076ba";
    #mangowc.url = "github:DreamMaoMao/mangowc/3fa306fc191fd70ea2cdb8f2328685af7d44e419";
    wrappers.url     = "github:lassulus/wrappers";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } ({ lib, ... }:
    let
      # ── Recursive module walker ─────────────────────────────────────────────
      collectModules = dir: blacklist:
        let
          walk = prefix: entries:
            lib.concatMap (name:
              let
                path    = dir + "/${prefix}${name}";
                relPath = "${prefix}${name}";
                type    = entries.${name};
              in
              if type == "directory" then
                walk "${prefix}${name}/" (builtins.readDir path)
              else if type == "regular"
                && lib.hasSuffix ".nix" name
                && !(builtins.elem relPath blacklist)
              then [ path ]
              else []
            ) (builtins.attrNames entries);
        in
          walk "" (builtins.readDir dir);

      # ── Blacklist ───────────────────────────────────────────────────────────
      moduleBlacklist = [
        "system/hardware.nix"
      ];

      # ── Patched pkgs ────────────────────────────────────────────────────────
      pkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        overlays = [];
        config.allowUnfree = true;
      };

      # ── Private modules ─────────────────────────────────────────────────────
      # Only loaded when /home/jakub/nixos-private actually exists on disk.
      privateModules =
        let privatePath = /home/jakub/nixos-private;
        in lib.optionals (builtins.pathExists privatePath) (
          let
            names    = builtins.attrNames (builtins.readDir privatePath);
            nixFiles = builtins.filter (n: lib.hasSuffix ".nix" n) names;
          in
            map (n: privatePath + "/${n}") nixFiles
        );

    in {
      systems = [ "x86_64-linux" ];

      flake.nixosConfigurations.nixos = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        inherit pkgs;

        modules =
          (collectModules ./modules moduleBlacklist)
          ++ [ ./modules/system/hardware.nix ]
          ++ [ inputs.home-manager.nixosModules.home-manager ]
          ++ [ inputs.mangowc.nixosModules.mango ]
          ++ privateModules;

        specialArgs = { inherit inputs; };
      };
    });
}
