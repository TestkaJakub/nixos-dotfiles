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
      extraProfile = ''
        export LD_LIBRARY_PATH=/run/opengl-driver/lib:/run/opengl-driver-32/lib:$LD_LIBRARY_PATH
      '';
    };

    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };
  

  # Install GE-Proton into Steam's compatibility tools directory.
  # The sentinel check skips unpacking when the version is already present,
  # so rebuilds that don't bump geProtonVersion are instant.
  home-manager.users.${user} = { lib, ... }: {
    home.activation.installProtonGE =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        dest="$HOME/.local/share/Steam/compatibilitytools.d"
        mkdir -p "$dest"
        if [ ! -d "$dest/${geProtonVersion}" ]; then
          echo "Unpacking ${geProtonVersion}..."
          ${pkgs.gnutar}/bin/tar --use-compress-program=${pkgs.gzip}/bin/gzip \
            -x -f ${geProtonTarball} -C "$dest"
          echo "${geProtonVersion} ready"
        else
          echo "${geProtonVersion} already installed, skipping."
        fi
      '';
  };

  environment.sessionVariables = {
    STEAM_COMPAT_MOUNTS = "/run/opengl-driver:/run/opengl-driver-32";
  };
}
