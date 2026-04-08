{ pkgs, lib, config, ... }:

# ── Rustup ─────────────────────────────────────────────────────────────────────
# Rust toolchain manager, fully declarative via home-manager's programs.rustup.
# Toolchain, components, and targets are all set here — no manual rustup calls
# needed after rebuild.
#
# NixOS note: rustup manages toolchains under ~/.rustup. The Nix-provided
# rustPlatform is still used for building Nix derivations (e.g. app-drawer) —
# rustup is for interactive development only.
#
# PKG_CONFIG_PATH is set so that `cargo build` can find GTK4 headers in the
# Nix store when compiling outside of a Nix derivation.
let
  user = config.profile.username;
in
{
  environment.systemPackages = with pkgs; [
    gcc        # linker
    pkg-config # needed by gtk4-rs and most C-binding crates
  ];

  home-manager.users.${user} = {
    programs.rustup = {
      enable   = true;
      toolchains = [ "stable" ];
      components = [ "rust-analyzer" "rust-src" "clippy" "rustfmt" ];
    };

    # GTK4 and other build-time libraries that gtk4-rs needs to find via
    # pkg-config when compiling with cargo directly (outside a Nix derivation)
    home.sessionVariables.PKG_CONFIG_PATH = lib.concatStringsSep ":" [
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
