{ pkgs, config, ... }:

# ── Misc dev tools ─────────────────────────────────────────────────────────────
let
  user = config.profile.username;

  fastfetchLogo = pkgs.writeText "fastfetch-logo.txt" ''
          .--.        .--.    .--.             
          \   \       \   \  /   /             
           \   \       \   \/   /              
      ______\   \______ \      /               
     /                 \ \    /     /\         
    /___________________\ \   \    /  \        
           ____            \   \  /   /        
          /   /             \  / /   /         
 ________/   /               \/ /   /______     
/           /                  /           \    
\______    /                  /   _________/    
      /   / /\               /   /             
     /   / /  \             /___/              
    /   /  \   \  ____________________         
    \  /    \   \ \                  /         
     \/     /    \ \______    ______/          
           /      \       \   \                  
          /   /\   \       \   \               
         /   /  \   \       \   \              
         \__/    \__/        \__/                      
  '';
in
{
  # System-wide tools — available to all users and in nix-shell environments
  environment.systemPackages = with pkgs; [
    git
    wget
    micro
    polkit
    exfatprogs
    unzip
    nix-diff
    parted
    unzip
    nix-diff
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

    programs.fastfetch = {
      enable = true;
      settings = {
        logo = {
          source  = "${fastfetchLogo}";
          type    = "file";
          padding = {
            top   = 1;
            left  = 2;
          };
        };
        display = {
          separator = "  ";
        };
        modules = [
          "title"
          "separator"
          "os"
          "kernel"
          "uptime"
          "packages"
          "shell"
          "terminal"
          "cpu"
          "memory"
          "disk"
        ];
      };
    };
  };

  environment.variables = {
    PF_INFO   = "ascii title os host kernel uptime pkgs memory";
    PF_SOURCE = "";
  };
}
