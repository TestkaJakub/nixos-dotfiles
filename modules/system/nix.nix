{ pkgs, lib, config, ... }:

# ── Nix & system core ──────────────────────────────────────────────────────────
# Reads: config.profile.stateVersion, config.profile.hostname
{
  networking.hostName = config.profile.hostname;


  nix = {
	  extraSettings = ''
	    !include /etc/nix/github-token.conf
	  '';
    settings.experimental-features = [ "nix-command" "flakes" ];
    gc = {
      automatic = true;
      dates     = "weekly";
      options   = "--delete-older-than 30d";
    };
  };

  system.stateVersion = config.profile.stateVersion;

  # nix-ld: run unpatched dynamic binaries (e.g. VSCode extensions, JetBrains)
  programs.nix-ld = {
    enable    = true;
    libraries = with pkgs; [ zlib stdenv.cc.cc.lib icu ];
  };

  # AppImage support via binfmt
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

	security.pki.certificateFiles = [
	  ../meta/homelab-root.crt  # relative to the module file using it
	];
}
