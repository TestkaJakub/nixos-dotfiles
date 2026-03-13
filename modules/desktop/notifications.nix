{ config, pkgs, ... }:

# ── Mako — notification daemon ─────────────────────────────────────────────────
let
  user = config.profile.username;
  t    = config.theme;

  bg       = t.palette.secondary;
  fg       = t.functions.textcolor t.palette.secondary;
  border   = t.palette.primary;
  urgentBg = t.functions.darken t.palette.secondary 0.05;
  urgentBorder = t.functions.complement t.palette.primary;
in
{
  home-manager.users.${user} = {
    # Write mako config manually so urgency criteria sections work correctly
    xdg.configFile."mako/config".text = ''
      width=300
      height=100
      margin=10
      padding=10,14
      border-size=1
      border-radius=4
      background-color=${bg}
      text-color=${fg}
      border-color=${border}
      font=JetBrains Mono 11
      default-timeout=5000
      ignore-timeout=0
      max-visible=5
      sort=-time

      [urgency=high]
      background-color=${urgentBg}
      border-color=${urgentBorder}
      default-timeout=0
    '';

    home.packages = [ pkgs.mako ];
  };
}
