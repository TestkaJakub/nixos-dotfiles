{ pkgs, lib, config, ... }:

let
  user = config.profile.username;
in
{
  programs.nix-ld.enable = true;
  environment.systemPackages = with pkgs; [
    rustup
    gcc       
    pkg-config
  ];
  home-manager.users.${user}.home.sessionVariables = {
    PKG_CONFIG_PATH = lib.concatStringsSep ":" [
      "${pkgs.gtk4.dev}/lib/pkgconfig"
      "${pkgs.glib.dev}/lib/pkgconfig"
      "${pkgs.cairo.dev}/lib/pkgconfig"
      "${pkgs.pango.dev}/lib/pkgconfig"
      "${pkgs.gdk-pixbuf.dev}/lib/pkgconfig"
      "${pkgs.graphene.dev}/lib/pkgconfig"
      "${pkgs.harfbuzz.dev}/lib/pkgconfig"
    ];
  };
}
