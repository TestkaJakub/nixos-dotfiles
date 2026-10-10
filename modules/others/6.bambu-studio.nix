{ inputs, config, ... }:

# ── Bambu Studio ───────────────────────────────────────────────────────────────
# 3D printing slicer for Bambu Lab printers.
# From nixos-unstable: 25.11 ships an older version (2.05).
# Once stable catches up, switch to pkgs.bambu-studio and drop the
# nixpkgs-unstable input if nothing else uses it.
#
# Update: nix flake update nixpkgs-unstable && nrs
let
  user = config.profile.username;

  unstable = import inputs.nixpkgs-unstable {
    system = "x86_64-linux";
    config.allowUnfree = true;   # separate import → separate config
  };
in
{
  home-manager.users.${user}.home.packages = [ unstable.bambu-studio ];
}