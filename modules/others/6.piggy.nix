{ pkgs, lib, ... }:

# ── piggy — terminal piggy bank tracker ────────────────────────────────────────
# Built from source on GitHub with rustPlatform.buildRustPackage.
#
# Updating: change rev, set both hashes back to lib.fakeHash, run nrs, and
# copy the real hashes from the error messages ("got: sha256-...").
let
  piggy = pkgs.rustPlatform.buildRustPackage {
    pname   = "piggy";
    version = "0.1.0";

    src = pkgs.fetchFromGitHub {
      owner = "TestkaJakub";
      repo  = "piggy";
      rev   = "37b4075c84c252139bead033c44de246db8c6cd4";
      hash  = lib.fakeHash;
    };

    cargoHash = lib.fakeHash;
  };
in
{
  environment.systemPackages = [ piggy ];
}