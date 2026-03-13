{ config, ... }:

# ── Mako — notification daemon ─────────────────────────────────────────────────
# Reads: config.theme.palette
#        config.profile.username
let
  user = config.profile.username;
  t    = config.theme;

  bg       = t.palette.secondary;
  fg       = t.functions.textcolor t.palette.secondary;
  border   = t.palette.primary;
  urgentBg = t.functions.darken t.palette.secondary 0.05;
in
{
  home-manager.users.${user} = {
    services.mako = {
      enable   = true;
      settings = {
        width          = 300;
        height         = 100;
        margin         = "10";
        padding        = "10,14";
        border-size    = 1;
        border-radius  = 4;

        background-color = bg;
        text-color       = fg;
        border-color     = border;

        font            = "JetBrains Mono 11";
        default-timeout = 5000;
        ignore-timeout  = false;
        max-visible     = 5;
        sort            = "-time";

        "[urgency=high]" = {
          background-color = urgentBg;
          border-color     = t.functions.complement t.palette.primary;
          default-timeout  = 0;
        };
      };
    };

    # Ensure mako starts with the graphical-session target
    systemd.user.services.mako = {
      Unit = {
        Description = "Lightweight Wayland notification daemon";
        After       = [ "graphical-session.target" ];
        PartOf      = [ "graphical-session.target" ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
