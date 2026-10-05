{ pkgs, lib, config, ... }:

# ── Nix & system core ──────────────────────────────────────────────────────────
# Reads: config.profile.stateVersion, config.profile.hostname
let
  isServer    = config.profile.isRole [ "server" ];
in
{
  networking.hostName = config.profile.hostname;


  nix = {
    settings.experimental-features = [ "nix-command" "flakes" ];
   	extraOptions = lib.mkIf (!isServer) ''
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
  programs.nix-ld = lib.mkIf (!isServer) {
    enable    = true;
    libraries = with pkgs; [ zlib stdenv.cc.cc.lib icu ];
  };

  # AppImage support via binfmt
  programs.appimage = lib.mkIf (!isServer) {
    enable = true;
    binfmt = true;
  };

  services.dbus.packages = lib.optionals (!isServer) [ pkgs.dconf ];
  programs.dconf.enable  = lib.mkIf (!isServer) true;
}
