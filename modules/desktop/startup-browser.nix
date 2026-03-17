{ pkgs, config, ... }:

# ── Startup browser ────────────────────────────────────────────────────────────
# Opens the default browser with a fixed set of URLs once per boot.
# Uses a flag file under RuntimeDirectory (/run/user/<uid>/startup-browser/)
# which is wiped automatically on reboot — so URLs open on first login after
# boot, but not on subsequent logins or session restarts.
#
# Default browser is read from config.meta.defaults so changing the browser
# in defaults.nix automatically applies here too.
#
# To change the URLs, edit startupUrls below and run nrs.
let
  user    = config.profile.username;
  meta    = config.meta.defaults;
  browser = "${meta.browserPackage}/bin/${meta.browser}";

  startupUrls = [
    "https://github.com"
    "https://news.ycombinator.com"
  ];

  urlArgs = builtins.concatStringsSep " " startupUrls;
in
{
  home-manager.users.${user} = {
    systemd.user.services.startup-browser = {
      Unit = {
        Description = "Open default browser with startup URLs once per boot";
        After       = [ "graphical-session.target" ];
        PartOf      = [ "graphical-session.target" ];
      };

      Service = {
        Type             = "oneshot";
        RemainAfterExit  = true;
        RuntimeDirectory = "startup-browser";
        ExecStart        = pkgs.writeShellScript "startup-browser" ''
          flag="/run/user/$(id -u)/startup-browser/opened"
          if [ ! -f "$flag" ]; then
            touch "$flag"
            exec ${browser} ${urlArgs}
          fi
        '';
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
