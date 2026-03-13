{ pkgs, ... }:

# ── Wine ───────────────────────────────────────────────────────────────────────
let
  winetricksUpdated = (pkgs.winetricks.overrideAttrs (_: {
    version = "20260125";
    src = pkgs.fetchurl {
      url    = "https://github.com/Winetricks/winetricks/archive/20260125/winetricks-20260125.tar.gz";
      sha256 = "sha256-KJC9n7ut5GOOWLSZmiNycxkt8DtYUWrnuHceCcItL1Y=";
    };
  })).overrideAttrs (old: {
    # Wrap the final script to suppress the 64-bit prefix warning and
    # version nag without touching the source.
    postInstall = (old.postInstall or "") + ''
      wrapProgram $out/bin/winetricks \
        --set WINETRICKS_LATEST_VERSION_CHECK disabled \
        --set WINETRICKS_SUPER_QUIET 1
    '';
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ pkgs.makeWrapper ];
  });
in
{
  environment.systemPackages = with pkgs; [
    wineWowPackages.stable
    winetricksUpdated
  ];
}
