{ ... }:

# ── nix-index + comma ──────────────────────────────────────────────────────────
# Prebuilt nix-index database (nix-index-database flake input) instead of
# building it locally.
#
#   , cowsay hi              run any nixpkgs program without installing it
#   nix-locate bin/rg        which package provides a file
#   unknown-command          fish/bash suggest the package that provides it
#
# Database refresh: nix flake update nix-index-database
{
  programs.nix-index = {
    enable                = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
  };

  programs.nix-index-database.comma.enable = true;

  # The stock command-not-found needs channels (programs.sqlite), which a
  # flakes-only system doesn't have. nix-index's handler replaces it.
  programs.command-not-found.enable = false;
}