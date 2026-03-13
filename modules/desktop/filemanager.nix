{ pkgs, config, ... }:

# ── Yazi — file manager ────────────────────────────────────────────────────────
# Reads: config.theme.palette
#        config.profile.username
#        config.meta.defaults.fileManager / fileManagerDesktop
#
# Replaces Thunar. Terminal-based, fully palette-themed.
let
  user = config.profile.username;
  t    = config.theme;

  bg      = t.palette.secondary;
  fg      = t.functions.textcolor t.palette.secondary;
  accent  = t.palette.primary;
  border  = t.palette.border;
  dimmed  = t.functions.darken t.palette.primary 0.15;
in
{
  environment.systemPackages = with pkgs; [
    yazi
    ffmpegthumbnailer  # video thumbnails
    unar               # archive previews
    jq                 # JSON previews
    poppler_utils      # PDF previews
    fd                 # faster file search
    ripgrep            # content search
    fzf                # fuzzy finder integration
  ];

  home-manager.users.${user} = {
    xdg.configFile."yazi/theme.toml".text = ''
      [manager]
      cwd = { fg = "${accent}" }

      hovered         = { fg = "${bg}", bg = "${accent}" }
      preview_hovered = { underline = true }

      find_keyword  = { fg = "${accent}", bold = true }
      find_position = { fg = "${accent}", bg = "${bg}", bold = true }

      marker_copied = { fg = "${accent}", bg = "${accent}" }
      marker_cut    = { fg = "${dimmed}", bg = "${dimmed}" }

      tab_active   = { fg = "${bg}", bg = "${accent}" }
      tab_inactive = { fg = "${fg}", bg = "${bg}" }
      tab_width    = 1

      border_style  = { fg = "${border}" }
      border_symbol = "│"

      [status]
      separator_open  = ""
      separator_close = ""

      [input]
      border   = { fg = "${accent}" }
      title    = { fg = "${accent}" }
      value    = { fg = "${fg}" }
      selected = { reversed = true }

      [select]
      border   = { fg = "${accent}" }
      active   = { fg = "${accent}" }
      inactive = { fg = "${dimmed}" }

      [tasks]
      border  = { fg = "${accent}" }
      title   = { fg = "${accent}" }
      hovered = { underline = true }

      [which]
      mask            = { bg = "${bg}" }
      cand            = { fg = "${accent}" }
      rest            = { fg = "${dimmed}" }
      desc            = { fg = "${fg}" }
      separator       = "  "
      separator_style = { fg = "${dimmed}" }

      [help]
      on      = { fg = "${accent}" }
      run     = { fg = "${fg}" }
      desc    = { fg = "${dimmed}" }
      hovered = { bg = "${bg}", bold = true }
      footer  = { fg = "${bg}", bg = "${accent}" }
    '';

    # Shell integration — `y` opens yazi and cds into the last directory on exit
    programs.bash.initExtra = ''
      y() {
        local tmp
        tmp=$(mktemp -t yazi-cwd.XXXXXX)
        yazi "$@" --cwd-file="$tmp"
        if [ -f "$tmp" ]; then
          local cwd
          cwd=$(cat "$tmp")
          [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && cd "$cwd"
          rm -f "$tmp"
        fi
      }
    '';
  };
}
