{ pkgs, config, ... }:

# ── Users ──────────────────────────────────────────────────────────────────────
# Reads: config.profile.{username, stateVersion}
{
  users.users.${config.profile.username} = {
    isNormalUser = true;
    group        = config.profile.username;
    extraGroups  = [ "wheel" "dialout" "libvirtd" "adbusers" "scanner" "lp" "docker" "video" "render" ];
    shell        = pkgs.fish;                          # changed from pkgs.bashInteractive
  };

  users.groups.${config.profile.username} = {};

  home-manager = {
    useGlobalPkgs        = true;
    useUserPackages      = true;
    backupFileExtension  = "bak";

    users.${config.profile.username} = { ... }: {
      home.stateVersion = config.profile.stateVersion;
    };
  };
}
