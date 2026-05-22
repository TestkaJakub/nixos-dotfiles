{ pkgs, config, ... }:

# ── EasyEffects ────────────────────────────────────────────────────────────────
# PipeWire audio effects processor.
# Runs as a systemd user service (hidden, no window) so effects are always
# active without keeping the UI open.
#
# Virtual devices created by EasyEffects:
#   easyeffects_sink        — processed output (set as default sink)
#   easyeffects_source      — processed input  (set as default source)
#
# WirePlumber rules in wireplumber.conf.d/ take care of the defaults so
# they survive reboots and PipeWire restarts without any manual steps.
#
# To open the UI:  easyeffects
# To tweak presets: open UI → Presets tab → save/load JSON presets
let
  user = config.profile.username;
in
{
  home-manager.users.${user} = {
    home.packages = [ pkgs.easyeffects ];

    # ── Autostart as a systemd user service ───────────────────────────────────
    # --gapplication-service launches EasyEffects in the background with no
    # window — it registers as a D-Bus service and waits for the UI to connect.
    systemd.user.services.easyeffects = {
      Unit = {
        Description = "EasyEffects audio effects processor";
        # Wait for PipeWire and the session to be ready
        After    = [ "pipewire.service" "pipewire-pulse.service" "graphical-session.target" ];
        Requires = [ "pipewire.service" ];
        PartOf   = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart  = "${pkgs.easyeffects}/bin/easyeffects --gapplication-service";
        Restart    = "on-failure";
        RestartSec = "5s";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    # ── WirePlumber: set EasyEffects virtual devices as system defaults ────────
    # WirePlumber reads all *.conf files under wireplumber/wireplumber.conf.d/
    # and merges them. The rules below match EasyEffects' virtual sink and
    # source by name and apply the default node role to each.
    #
    # Priority 1010 puts these above WirePlumber's built-in defaults (1000)
    # so they win without needing to touch the main config.
    xdg.configFile."wireplumber/wireplumber.conf.d/99-easyeffects-defaults.conf".text = ''
      monitor.alsa.rules = []

      wireplumber.settings = {
        default-sink   = "easyeffects_sink"
        default-source = "easyeffects_source"
      }
    '';
  };
}
