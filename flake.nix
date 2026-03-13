{
  description = "Jakub's NixOS configuration";

  inputs = {
    flake-parts.url  = "github:hercules-ci/flake-parts";
    nixpkgs.url      = "github:NixOS/nixpkgs/nixos-25.05";

    home-manager = {
      url            = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mangowc.url      = "github:DreamMaoMao/mangowc";
    wrappers.url     = "github:lassulus/wrappers";

    private = {
      url   = "path:/home/jakub/nixos-private";
      flake = false;
    };
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
      # nixpkgs 25.05 moved lndir into pkgs.xorg.lndir but home-manager's
      # internal fontconfig module still references pkgs.lndir directly.
      # This overlay bridges the gap until home-manager is updated.
      pkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        overlays = [ (_final: prev: { lndir = prev.xorg.lndir; }) ];
        config.allowUnfree = true;
      };

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
          ++ (
            let
              privateDir = inputs.private;
              names      = builtins.attrNames (builtins.readDir privateDir);
              nixFiles   = builtins.filter (n: lib.hasSuffix ".nix" n) names;
            in
              map (n: privateDir + "/${n}") nixFiles
          );

        specialArgs = { inherit inputs; };
      };
    });
}
