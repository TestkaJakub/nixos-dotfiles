{ pkgs, config, ... }:

# ── Heroic Games Launcher ──────────────────────────────────────────────────────
# GOG, Epic Games Store, and Amazon Games client for Linux.
# Uses nixpkgs' GE-Proton (same build Steam gets via extraCompatPackages),
# linked under a fixed name so the path survives version bumps.
let
  user      = config.profile.username;
  protonDir = ".config/heroic/tools/proton/GE-Proton-nix";
in
{
  environment.systemPackages = [ pkgs.heroic ];

  home-manager.users.${user} = { lib, ... }: {
    home.file.${protonDir}.source = pkgs.proton-ge-bin.steamcompattool;

    # Set it as the default for new games. config.json is owned by Heroic,
    # so only this one key is patched; it only exists after Heroic's first launch.
    home.activation.heroicDefaultProton =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        cfg="$HOME/.config/heroic/config.json"
        if [ -f "$cfg" ]; then
          tmp=$(mktemp)
          ${pkgs.jq}/bin/jq --arg bin "$HOME/${protonDir}/proton" \
            '.defaultSettings.wineVersion = { bin: $bin, name: "Proton - GE-Proton-nix", type: "proton" }' \
            "$cfg" > "$tmp" && mv "$tmp" "$cfg"
        fi
      '';
  };
}