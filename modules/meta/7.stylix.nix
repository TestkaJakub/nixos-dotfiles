# modules/meta/7.stylix.nix
{ pkgs, inputs, ... }:
{
  imports = [ inputs.stylix.nixosModules.stylix ];

  environment.systemPackages = [ pkgs.pastel ];

  stylix = {
    enable   = true;
    polarity = "dark";

    base16Scheme = {
      # ── backgrounds (dark → light) ──
      base00 = "1f1f1f";  # main background
      base01 = "282828";  # bars, panels
      base02 = "353535";  # selection
      base03 = "5c6370";  # comments, unfocused borders
      # ── foregrounds (dim → bright) ──
      base04 = "8a8a8a";  # muted text
      base05 = "b1b1b1";  # main text
      base06 = "d0d0d0";
      base07 = "eeeeee";
      # ── accents ──
      base08 = "e06c75";  # red: errors, urgent
      base09 = "d19a66";  # orange
      base0A = "e5c07b";  # yellow
      base0B = "98c379";  # green
      base0C = "56b6c2";  # cyan
      base0D = "ff69b4";  # MAIN ACCENT: focused border, selection
      base0E = "c678dd";  # purple: keywords
      base0F = "6666cc";  # your indigo
    };

    fonts = {
      monospace = { package = pkgs.nerd-fonts.jetbrains-mono; name = "JetBrainsMono Nerd Font"; };
      sansSerif = { package = pkgs.noto-fonts;                name = "Noto Sans"; };
      serif     = { package = pkgs.noto-fonts;                name = "Noto Serif"; };
      emoji     = { package = pkgs.noto-fonts-color-emoji;    name = "Noto Color Emoji"; };
      sizes     = { terminal = 13; applications = 12; desktop = 12; popups = 12; };
    };

    cursor  = { package = pkgs.adwaita-icon-theme; name = "Adwaita"; size = 32; };
    opacity.terminal = 0.85;
  };
}