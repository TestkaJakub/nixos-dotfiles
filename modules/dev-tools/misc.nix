{ pkgs, config, ... }:

# ── Misc dev tools ─────────────────────────────────────────────────────────────
# Small utilities that don't warrant their own file.
# If any of these grow configuration, split them out.
let
  user = config.profile.username;
in
{
  environment.systemPackages = with pkgs; [
    git
    wget
    micro        # simple terminal editor (fallback to neovim)
    polkit       # privilege escalation (required by various GUI tools)
    exfatprogs
    parted
  ];

  home-manager.users.${user} = {
    home.packages = with pkgs; [
      podman       # rootless containers (dev use; production containers are in containers/)
      bat          # syntax-highlighted cat
      fastfetch    # system info
      pfetch-rs    # minimal system info
      scrcpy       # Android screen mirror
      wev          # Wayland event viewer (key code lookup)
      git          # also in home profile for user-level git config
    ];

    programs.fastfetch.enable = true;
  };

  environment.variables = {
    PF_INFO   = "ascii title os host kernel uptime pkgs memory";
    PF_SOURCE = "";
  };
}
