{ pkgs, ... }:

# ── VSCodium ───────────────────────────────────────────────────────────────────
# System package so it is available in nix-shell dev environments and via
# the node dev flake (flakes/node/flake.nix).
{
  environment.systemPackages = [ pkgs.vscodium ];
}
