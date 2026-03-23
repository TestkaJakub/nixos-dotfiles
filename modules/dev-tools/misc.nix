{ pkgs, config, ... }:

# ── Misc dev tools ─────────────────────────────────────────────────────────────
let
  user = config.profile.username;

  fastfetchLogo = pkgs.writeText "fastfetch-logo.txt" ''
          .--.        .--.    .--.             
          \   \       \   \  /   /             
           \   \       \ n \/   /              
      ______\   \______ \ i    /               
     / nixos           \ \ x  /     /\         
    /___________________\ \ o \    /  \        
           ____            \ s \  /   /        
          /   /             \  / / n /         
 ________/ n /     I use     \/ / i /______     
/         i /      nixos       / x         \    
\______  x /        btw       / o _________/    
      / o / /\               / s /             
     / s / /  \             /___/              
    /   /  \ n \  ____________________         
    \  /    \ i \ \ nixos            /         
     \/     /  x \ \______    ______/          
           /    o \       \   \                  
          /   /\ s \       \   \               
         /   /  \   \       \   \              
         \__/    \__/        \__/                      
  '';
in
{
  # System-wide tools — available to all users and in nix-shell environments
  environment.systemPackages = with pkgs; [
    git
    glow
    wget
    micro
    polkit
    exfatprogs
    unzip
    nix-diff
    parted
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

    xdg.configFile."micro/init.lua".text = ''
        local config = import("micro/config")
        local shell  = import("micro/shell")
    
        function init()
          config.TryBindKey("Ctrl-m", "lua:initlua.glowPreview", true)
        end
    
        function glowPreview(bp)
          local path = bp.Buf.Path
          shell.RunInteractiveShell("${pkgs.glow}/bin/glow " .. path .. " | less -R", true, false)
        end
      '';
  };

  environment.variables = {
    PF_INFO   = "ascii title os host kernel uptime pkgs memory";
    PF_SOURCE = "";
  };
}
