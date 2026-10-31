{ pkgs, config, ... }:

# ── VR — WiVRn streaming to the Pico 4 ─────────────────────────────────────────
# WiVRn is a Monado-based OpenXR runtime that streams to a standalone headset:
# the PC renders on the RX 9070 XT, encodes (VA-API/Vulkan via radeonsi/RADV)
# and sends video over the LAN; the headset runs the WiVRn client APK and sends
# back head/controller poses and input.
#
# Steam games speak OpenVR, so they go OpenVR -> xrizer -> OpenXR (WiVRn).
# Pointing openvrpaths at xrizer means SteamVR itself is bypassed.
#
# Start the server from the WiVRn dashboard, or: systemctl --user start wivrn
# The client APK must be the same WiVRn version as the server (see the dashboard).
#
# Reads: config.profile.username
let
  user = config.profile.username;
in
{
  services.wivrn = {
    enable       = true;
    openFirewall = true;   # 9757 TCP/UDP; the module also enables Avahi publishing
    autoStart    = false;  # only run while actually using the headset
    highPriority = true;   # CAP_SYS_NICE for asynchronous reprojection

    steam = {
      importOXRRuntimes = true;                         # lets pressure-vessel see WiVRn (re-login once)
      package           = config.programs.steam.package; # match the overridden Steam in gaming/4.steam.nix
    };
  };

  environment.systemPackages = with pkgs; [
    wayvr          # desktop windows as panels in VR (WiVRn can launch it from the headset)
    android-tools  # adb, for installing/updating the WiVRn client on the headset
  ];

  home-manager.users.${user} = { config, ... }: {
    # OpenVR -> xrizer. force: Steam/SteamVR like to rewrite this file.
    xdg.configFile."openvr/openvrpaths.vrpath" = {
      force = true;
      text  = builtins.toJSON {
        version          = 1;
        jsonid           = "vrpathreg";
        external_drivers = null;
        config           = [ "${config.xdg.dataHome}/Steam/config" ];
        log              = [ "${config.xdg.dataHome}/Steam/logs" ];
        runtime          = [ "${pkgs.xrizer}/lib/xrizer" ];
      };
    };
  };
}