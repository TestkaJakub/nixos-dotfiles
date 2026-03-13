{ pkgs, config, ... }:

# ── Nemo — file manager ────────────────────────────────────────────────────────
# Reads: config.theme.palette
#        config.profile.username
# Note: services.gvfs.enable is set in system/peripherals.nix — not here.
let
  user   = config.profile.username;
  t      = config.theme;
  bg     = t.palette.secondary;
  accent = t.palette.primary;
in
{
  environment.systemPackages = with pkgs; [
    nemo
    nemo-fileroller
  ];

  home-manager.users.${user} = {
    gtk = {
      enable = true;
      theme = {
        name    = "Adwaita-dark";
        package = pkgs.gnome-themes-extra;
      };
      gtk3.extraCss = ''
        * {
          --accent-bg-color: ${accent};
          --accent-color: ${accent};
          --accent-fg-color: ${bg};
        }
        .view:selected,
        row:selected,
        .nemo-window .nemo-places-sidebar row:selected {
          background-color: ${accent};
          color: ${bg};
        }
      '';
    };

    qt = {
      enable        = true;
      platformTheme = { name = "gtk"; };
    };

    dconf.settings."org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };

    dconf.settings."org/nemo/preferences" = {
      default-folder-viewer     = "list-view";
      show-hidden-files         = false;
      show-advanced-permissions = true;
    };
  };
}
