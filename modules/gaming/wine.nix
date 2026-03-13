{ pkgs, ... }:

# ── Wine ───────────────────────────────────────────────────────────────────────
let
  winetricksUpdated = pkgs.winetricks.overrideAttrs (_: {
    version = "20260125";
    src = pkgs.fetchurl {
      url    = "https://github.com/Winetricks/winetricks/archive/20260125/winetricks-20260125.tar.gz";
      sha256 = "sha256-KJC9n7ut5GOOWLSZmiNycxkt8DtYUWrnuHceCcItL1Y=";
    };
  });
in
{
  environment.systemPackages = with pkgs; [
    wineWowPackages.stable
    winetricksUpdated
  ];
}
