{ config, lib, pkgs, ... }:

# ── Peripheral tuning ───────────────────────────────────────────────────────────
# ratbagd (libratbag) — reads/writes onboard mouse profiles: DPI stages, report
# rate, and any firmware-side acceleration baked into the Glorious Model O-.
# piper is the GUI front-end.
#
# Why: libinput is confirmed flat (acceleration off) yet the pointer still
# changes speed with movement — that points to acceleration applied *inside the
# mouse*, which libinput cannot override. ratbagd talks to the mouse's onboard
# memory to inspect and disable it.
#
# Enabling the service (rather than running ratbagd by hand) is required — it
# installs the udev rules and D-Bus policy the daemon needs to access the
# device. Running the binary straight from `nix shell` fails with "Permission
# denied" precisely because those aren't present.
#
# After a rebuild: launch `piper` from the app launcher.
let
  isDesktop = config.profile.isRole [ "desktop" ];
in
{
  services.ratbagd.enable = lib.mkIf isDesktop true;

  environment.systemPackages = lib.mkIf isDesktop [ pkgs.piper ];
}