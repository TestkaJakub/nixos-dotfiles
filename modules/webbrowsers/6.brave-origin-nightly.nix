# modules/webbrowsers/6.brave-origin-nightly.nix
{ pkgs, lib, ... }:

let
  version = "1.93.30";   # bump this when updating
  src = pkgs.fetchurl {
    url    = "https://github.com/brave/brave-browser/releases/download/v${version}/brave-origin-nightly_${version}_amd64.deb";
    sha256 = "0ysfrfjrqkzixzcjv5wasfgfrm8d4pwwfwxlkisc7v3mwlyf6kx0";
  };

  brave-origin-nightly = pkgs.stdenv.mkDerivation {
    pname   = "brave-origin-nightly";
    inherit version src;

    nativeBuildInputs = [ pkgs.dpkg pkgs.makeWrapper pkgs.autoPatchelfHook ];

    buildInputs = with pkgs; [
      # Chromium-based browser runtime deps
      glib
      nss
      nspr
      atk
      at-spi2-atk
      xorg.libX11
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXrandr
      xorg.libxcb
      libxkbcommon
      mesa
      expat
      alsa-lib
      cups
      dbus
      libdrm
      pango
      cairo
      gtk3
      wayland
    ];

    unpackPhase = ''
      dpkg-deb -x $src $out
    '';

    installPhase = ''
      # Binary lands at $out/opt/brave.com/brave-origin-nightly/brave-origin-nightly
      # Expose it as a proper bin entry
      mkdir -p $out/bin
      makeWrapper $out/opt/brave.com/brave-origin-nightly/brave-origin-nightly \
        $out/bin/brave-origin-nightly \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ pkgs.libGL pkgs.vulkan-loader ]}"
    '';

    # autoPatchelfHook rewrites ELF rpath entries so NixOS can run
    # the pre-built Chromium binary without needing nix-ld
    dontAutoPatchelf = false;
  };
in
{
  environment.systemPackages = [ brave-origin-nightly ];
}