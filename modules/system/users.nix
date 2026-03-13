{ pkgs, config, ... }:

# ── Users ──────────────────────────────────────────────────────────────────────
# Reads: config.profile.{username, stateVersion}
# home-manager stateVersion is set here centrally for the user session.
{
  users.users.${config.profile.username} = {
    isNormalUser = true;
    group        = config.profile.username;
    extraGroups  = [ "wheel" "dialout" "libvirtd" "adbusers" "scanner" "lp" "docker" ];
    shell        = pkgs.bashInteractive;
  };

  users.groups.${config.profile.username} = {};

  home-manager = {
    useGlobalPkgs   = true;
    useUserPackages = true;

    users.${config.profile.username} = { ... }: {
      home.stateVersion = config.profile.stateVersion;
    };
  };
}
