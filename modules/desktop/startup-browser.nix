{ pkgs, config, lib, ... }:

# ── Startup browser ────────────────────────────────────────────────────────────
# Opens the default browser with a fixed set of URLs once per boot.
# Called from desktop/compositor.nix autostart — graphical-session.target is
# not activated by MangoWC so systemd user services can't be used here.
#
# Flag lives under /run/user/<uid>/ which is wiped on every reboot, so the
# URLs open on first compositor launch after boot only.
let
  meta    = config.meta.defaults;
  browser = "${meta.browserPackage}/bin/${meta.browser}";

  startupUrls = [
    "https://github.com"
    "https://news.ycombinator.com"
  ];

  urlArgs = builtins.concatStringsSep " " startupUrls;
in
{
  options.scripts.startupBrowser = lib.mkOption {
    type        = lib.types.package;
    readOnly    = true;
    description = "Open default browser with startup URLs once per boot.";
  };

  config.scripts.startupBrowser = pkgs.writeShellScriptBin "startup-browser" ''
    flag="/run/user/$(id -u)/startup-browser/opened"
    mkdir -p "$(dirname "$flag")"
    if [ ! -f "$flag" ]; then
      touch "$flag"
      exec ${browser} ${urlArgs} &
    fi
  '';
}
