{ pkgs, config, ... }:

# ── Misc dev tools ─────────────────────────────────────────────────────────────
let
  user = config.profile.username;
in
{
  # System-wide tools — available to all users and in nix-shell environments
  environment.systemPackages = with pkgs; [
    git
    wget
    micro
    polkit
    exfatprogs
    parted
    unzip
  ];

  # User-only tools
  home-manager.users.${user} = {
    home.packages = with pkgs; [
      podman
      bat
      pfetch-rs
      scrcpy
      wev
    ];

    # programs.fastfetch manages both the package and config
    programs.fastfetch.enable = true;
  };

  environment.variables = {
    PF_INFO   = "ascii title os host kernel uptime pkgs memory";
    PF_SOURCE = "";
  };
}
