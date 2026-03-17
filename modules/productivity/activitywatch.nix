{ pkgs, config, ... }:

# ── ActivityWatch ──────────────────────────────────────────────────────────────
# Passive time tracker — automatically logs which window is active and for
# how long. Web UI is available at http://localhost:5600
#
# Three components:
#   aw-server-rust          — local database + web UI
#   aw-watcher-window-wayland — active window tracking via wlr-foreign-toplevel
#   aw-watcher-afk          — idle/AFK detection
#
# All three run as systemd user services. aw-server-rust starts first;
# the watchers wait for it via After/Requires. A 3s ExecStartPre delay on
# the watchers avoids the RecvError race that occurs when they connect before
# the server's DB worker is ready.
#
# Placed in productivity/ alongside taskwarrior and timewarrior.
let
  user = config.profile.username;

  awServer  = "${pkgs.aw-server-rust}/bin/aw-server";
  awWindow  = "${pkgs.aw-watcher-window-wayland}/bin/aw-watcher-window-wayland";
  awAfk     = "${pkgs.aw-watcher-afk}/bin/aw-watcher-afk";
  sleep     = "${pkgs.coreutils}/bin/sleep";
in
{
  home-manager.users.${user} = {
    home.packages = [
      pkgs.aw-server-rust
      pkgs.aw-watcher-window-wayland
      pkgs.aw-watcher-afk
    ];

    # ── systemd user services ──────────────────────────────────────────────

    systemd.user.services.aw-server = {
      Unit = {
        Description = "ActivityWatch server";
        After       = [ "graphical-session.target" ];
        PartOf      = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart      = awServer;
        Restart        = "on-failure";
        RestartSec     = "5s";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    systemd.user.services.aw-watcher-window = {
      Unit = {
        Description = "ActivityWatch window watcher (Wayland)";
        After       = [ "aw-server.service" ];
        Requires    = [ "aw-server.service" ];
      };
      Service = {
        ExecStartPre   = "${sleep} 3";
        ExecStart      = awWindow;
        Restart        = "on-failure";
        RestartSec     = "5s";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    systemd.user.services.aw-watcher-afk = {
      Unit = {
        Description = "ActivityWatch AFK watcher";
        After       = [ "aw-server.service" ];
        Requires    = [ "aw-server.service" ];
      };
      Service = {
        ExecStartPre   = "${sleep} 3";
        ExecStart      = "${awAfk} --no-tray";
        Restart        = "on-failure";
        RestartSec     = "5s";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
