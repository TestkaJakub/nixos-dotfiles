{ pkgs, config, ... }:

# ── Tauri ──────────────────────────────────────────────────────────────────────
# System-wide Tauri v2 build prerequisites, so `cargo tauri dev|build` works on
# the host directly — no per-project shell.nix / devShell needed.
#
# Rust itself comes from rustup (dev-tools/7.rust.nix), so it is NOT duplicated
# here. cargo-tauri shells out to whatever `cargo` is on PATH, which is the
# rustup toolchain.
#
# PKG_CONFIG_PATH note:
#   7.rust.nix already sets home.sessionVariables.PKG_CONFIG_PATH (for gtk4-rs).
#   home.sessionVariables can't set the same key from two modules — it's a
#   conflict, not a merge — so the WebKit/GTK3 pkg-config paths Tauri needs are
#   added to the list *in rust.nix* (see the delta below), not here. This module
#   provides the CLI, the libraries, and the WebKit runtime env only.
#
# Prefix 6 = workstation + desktop (mirrors 6.python-ml.nix). The headless
# server has no use for a webkitgtk build.
{
  environment.systemPackages = with pkgs; [
    cargo-tauri            # the `cargo tauri` / `tauri` CLI
    nodejs                 # JS frontend (npm / pnpm / vite)
    gobject-introspection  # needed by some -sys crates at build time

    # WebKit + GTK3 stack Tauri v2 links against
    gtk3
    webkitgtk_4_1
    libsoup_3
    librsvg
    atk
    at-spi2-atk
    openssl
  ];

  # Blank/white WebKit window fix on amdgpu (and generally under Wayland).
  # If windows render fine without it, drop this line. Uses the same mechanism
  # as 6.ozone-wayland.nix's NIXOS_OZONE_WL.
  environment.sessionVariables.WEBKIT_DISABLE_DMABUF_RENDERER = "1";
}