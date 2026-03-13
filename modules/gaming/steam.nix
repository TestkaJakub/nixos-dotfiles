{ pkgs, config, ... }:

# ── Steam ──────────────────────────────────────────────────────────────────────
# Reads: config.profile.username
let
  user = config.profile.username;

  geProtonVersion = "GE-Proton10-28";
  geProtonTarball = builtins.fetchurl {
    url    = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${geProtonVersion}/${geProtonVersion}.tar.gz";
    sha256 = "05p39lnai27m5qvp401b0wpdic0d8z4hpih21rhkzx8sgxpc8p2c";
  };
in
{
  programs.steam = {
    enable                       = true;
    dedicatedServer.openFirewall = true;
    package = pkgs.steam.override {
      extraPkgs = p: with p; [ mesa libdrm SDL2 openal faudio gamemode ];
    };
  };

  programs.mango.enable = true;   # MangoHUD FPS overlay

  # Install GE-Proton into Steam's compatibility tools directory
  home-manager.users.${user} = { lib, ... }: {
    home.activation.installProtonGE =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        dest="$HOME/.local/share/Steam/compatibilitytools.d"
        mkdir -p "$dest"
        rm -rf "$dest/${geProtonVersion}"
        echo "Unpacking ${geProtonVersion}..."
        ${pkgs.gnutar}/bin/tar --use-compress-program=${pkgs.gzip}/bin/gzip \
          -x -f ${geProtonTarball} -C "$dest"
        echo "${geProtonVersion} ready"
      '';
  };
}
