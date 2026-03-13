{ pkgs, ... }:

# ── Wine ───────────────────────────────────────────────────────────────────────
let
  winetricksUpdated = pkgs.winetricks.overrideAttrs (old: {
    version = "20260125";
    src = pkgs.fetchurl {
      url    = "https://github.com/Winetricks/winetricks/archive/20260125/winetricks-20260125.tar.gz";
      sha256 = "sha256-KJC9n7ut5GOOWLSZmiNycxkt8DtYUWrnuHceCcItL1Y=";
    };

    # Patch out the 64-bit prefix warning — it's noise for a system that
    # intentionally uses a 64-bit prefix.
    postPatch = (old.postPatch or "") + ''
      sed -i '/You are using a 64-bit WINEPREFIX/d' src/winetricks
    '';
  });
in
{
  environment.systemPackages = with pkgs; [
    wineWowPackages.stable
    winetricksUpdated
  ];
}
