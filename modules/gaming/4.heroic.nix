{ pkgs, config, ... }:

# ── Heroic Games Launcher ──────────────────────────────────────────────────────
# GOG, Epic Games Store, and Amazon Games client for Linux.
#
# Declared here: Proton build, default install/prefix paths, GameMode, MangoHud.
# Heroic owns ~/.config/heroic/config.json, so heroicDefaults is merged into
# its defaultSettings on activation instead of replacing the file.
# Each rebuild resets these defaults; per-game settings are untouched.
# Close Heroic before nrs, or it may write its old settings back on exit.
let
  user      = config.profile.username;
  home      = "/home/${user}";
  games     = "${home}/data/Games/Heroic";
  protonRel = ".config/heroic/tools/proton/GE-Proton-nix";

  heroicDefaults = {
    # Games on the data disk, next to VotV, not in ~/Games on the root SSD
    defaultInstallPath = games;
    defaultWinePrefix  = "${games}/Prefixes";

    wineVersion = {
      bin  = "${home}/${protonRel}/proton";
      name = "Proton - GE-Proton-nix";
      type = "proton";
    };

    useGameMode  = true;
    showMangohud = false;   # flip on for an FPS/frametime overlay

    # Heroic's own updater is useless on NixOS — nix flake update handles it
    checkForUpdatesOnStartup = false;
  };
in
{
  environment.systemPackages = [ pkgs.heroic pkgs.mangohud ];

  # Without the daemon, Heroic's GameMode toggle does nothing
  programs.gamemode.enable = true;

  home-manager.users.${user} = { lib, ... }: {
    home.file.${protonRel}.source = pkgs.proton-ge-bin.steamcompattool;

    home.activation.heroicDefaults =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "${games}/Prefixes"
        cfg="$HOME/.config/heroic/config.json"
        if [ -f "$cfg" ]; then
          tmp=$(mktemp)
          ${pkgs.jq}/bin/jq --argjson d '${builtins.toJSON heroicDefaults}' \
            '.defaultSettings += $d' "$cfg" > "$tmp" && mv "$tmp" "$cfg"
        fi
      '';
  };
}