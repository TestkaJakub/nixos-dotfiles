# modules/webbrowsers/6.brave-origin-nightly.nix
{ pkgs, lib, ... }:
let
  version = "1.93.30"; # bump this when updating
  src = pkgs.fetchurl {
    url    = "https://github.com/brave/brave-browser/releases/download/v${version}/brave-origin-nightly_${version}_amd64.deb";
    sha256 = "0ysfrfjrqkzixzcjv5wasfgfrm8d4pwwfwxlkisc7v3mwlyf6kx0";
  };

  brave-origin-nightly = pkgs.stdenv.mkDerivation {
    pname   = "brave-origin-nightly";
    inherit version src;

    nativeBuildInputs = [ pkgs.dpkg pkgs.makeWrapper pkgs.autoPatchelfHook ];

    autoPatchelfIgnoreMissingDeps = [
      "libQt5Core.so.5"
      "libQt5Gui.so.5"
      "libQt5Widgets.so.5"
      "libQt6Core.so.6"
      "libQt6Gui.so.6"
      "libQt6Widgets.so.6"
    ];

    buildInputs = with pkgs; [
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
      dpkg-deb --fsys-tarfile $src | tar -x --no-same-permissions --no-same-owner
    '';

    installPhase = ''
      mkdir -p $out/bin
      mkdir -p $out/opt/brave.com
      mkdir -p $out/share/applications
      chmod -R +x opt/brave.com/brave-origin-nightly
      cp -r opt/brave.com/brave-origin-nightly $out/opt/brave.com/brave-origin-nightly
      makeWrapper $out/opt/brave.com/brave-origin-nightly/brave-origin-nightly \
        $out/bin/brave-origin-nightly \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ pkgs.libGL pkgs.vulkan-loader ]}"
      cat > $out/share/applications/brave-origin-nightly.desktop << EOF
      [Desktop Entry]
      Name=Brave Origin Nightly
      Comment=Brave Origin Nightly Browser
      Exec=brave-origin-nightly %U
      Icon=brave-origin-nightly
      Type=Application
      Categories=Network;WebBrowser;
      MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
      EOF
    '';

    dontAutoPatchelf = false;
  };
in
{
  environment.systemPackages = [ brave-origin-nightly ];
}