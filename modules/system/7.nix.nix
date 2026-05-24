{ pkgs, lib, config, ... }:

# ── Nix & system core ──────────────────────────────────────────────────────────
# Reads: config.profile.stateVersion, config.profile.hostname
let
  isServer    = config.profile.isRole [ "server" ];
  isNotServer = !isServer;
in
{
  networking.hostName = config.profile.hostname;


  nix = {
    settings.experimental-features = [ "nix-command" "flakes" ];
   	extraOptions = lib.mkIf isNotServer ''
      !include /etc/nix/github-token.conf
    '';
   	gc = {
     	automatic = true;
     	dates     = "weekly";
     	options   = "--delete-older-than 30d";
 	  };
  };

  system.stateVersion = config.profile.stateVersion;

  # nix-ld: run unpatched dynamic binaries (e.g. VSCode extensions, JetBrains)
  programs.nix-ld = lib.mkIf isNotServer {
    enable    = true;
    libraries = with pkgs; [ zlib stdenv.cc.cc.lib icu ];
  };

  # AppImage support via binfmt
  programs.appimage = lib.mkIf isNotServer {
    enable = true;
    binfmt = true;
  };
}
