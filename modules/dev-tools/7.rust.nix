{ pkgs, lib, config, ... }:

# ── Rustup ─────────────────────────────────────────────────────────────────────
# Rust toolchain manager. Toolchain and components are declared via a global
# rust-toolchain.toml written to ~/ — rustup reads this automatically and
# installs the correct toolchain on first use (or after rebuild if changed).
#
# No manual `rustup default stable` needed — the toolchain file handles it.
# A home activation script runs `rustup show` once to trigger the install.
#
# PKG_CONFIG_PATH is set so that `cargo build` finds GTK4 headers in the
# Nix store when compiling outside a Nix derivation.
let
  user = config.profile.username;
in
{
  environment.systemPackages = with pkgs; [
    rustup
    gcc        # linker
    pkg-config # needed by gtk4-rs and most C-binding crates
  ];

  home-manager.users.${user} = { lib, ... }: {
    # Declare the toolchain declaratively — rustup reads this from ~/
    home.file."rust-toolchain.toml".text = ''
      [toolchain]
      channel    = "stable"
      components = ["rust-analyzer", "rust-src", "clippy", "rustfmt"]
    '';

    # GTK4 headers for cargo builds outside Nix derivations
    home.sessionVariables.PKG_CONFIG_PATH = lib.concatStringsSep ":" [
      "${pkgs.gtk4.dev}/lib/pkgconfig"
      "${pkgs.glib.dev}/lib/pkgconfig"
      "${pkgs.cairo.dev}/lib/pkgconfig"
      "${pkgs.pango.dev}/lib/pkgconfig"
      "${pkgs.gdk-pixbuf.dev}/lib/pkgconfig"
      "${pkgs.graphene.dev}/lib/pkgconfig"
      "${pkgs.harfbuzz.dev}/lib/pkgconfig"
    ];

    # Trigger rustup to install the declared toolchain on first activation
    home.activation.installRustToolchain =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        export RUSTUP_HOME="''${RUSTUP_HOME:-$HOME/.rustup}"
        export CARGO_HOME="''${CARGO_HOME:-$HOME/.cargo}"
        if command -v rustup >/dev/null 2>&1; then
          rustup show >/dev/null 2>&1 || true
        fi
      '';
  };
}
